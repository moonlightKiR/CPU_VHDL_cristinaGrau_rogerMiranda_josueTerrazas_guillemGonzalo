library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.bus_multiplexer_pkg.all;

entity memory_manager is
	generic (
		MEMORY_ACCESSES				: integer := 3; -- nº d'accessos a la RAM
		
		RAM_ADDRESS_BUS				: integer := 32;
		RAM_DATA_BUS				: integer := 32
	);
	port (
		-- pins bloc
		clk 			: in std_logic;
		
		-- pins memoria
		w_addr			: out std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
		w_addr_valid	: out std_logic;
		w_data			: out std_logic_vector(RAM_DATA_BUS - 1 downto 0);
		w_data_valid	: out std_logic;
		w_resp			: in std_logic_vector(1 downto 0);
		w_resp_valid	: in std_logic;
		
		r_addr			: out std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
		r_addr_valid	: out std_logic;
		r_data			: in std_logic_vector(RAM_DATA_BUS - 1 downto 0);
		r_data_valid	: in std_logic;
		r_resp			: in std_logic_vector(1 downto 0);
		
		-- pins acces memoria
		enable			: in std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
		nread_write		: in std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
		addr			: in bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_ADDRESS_BUS - 1 downto 0);
		write_data		: in bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_DATA_BUS - 1 downto 0);
		read_data		: out bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_DATA_BUS - 1 downto 0);
		response		: out bus_array(MEMORY_ACCESSES - 1 downto 0)(1 downto 0);
		done			: out std_logic_vector(MEMORY_ACCESSES - 1 downto 0)
	);
end entity;

architecture behavioral of memory_manager is
	TYPE MEMORY_MANAGER_STATE_MACHINE IS (
		ss, s0, 		-- changes? read/write?
		s1, s2, s3, 	-- write
		s10, s11, s12,	-- read
		s20, s21, s22	-- increment check
	);
	
	constant ACESSOR_BUS 		: integer := integer(ceil(log2(real(MEMORY_ACCESSES))));
	signal state, next_state 	: MEMORY_MANAGER_STATE_MACHINE := ss;
	signal u_accessor			: unsigned(ACESSOR_BUS - 1 downto 0);
	signal accessor				: integer;
	
	-- variables to check if we need to recheck the RAM
	signal first_check			: std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
	signal last_addr_writted	: std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
	signal last_nread_write		: std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
	signal last_addr			: bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_ADDRESS_BUS - 1 downto 0);
	signal last_write_data		: bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_DATA_BUS - 1 downto 0);
begin
	accessor <= to_integer(u_accessor);
	
	process (state, clk)
		variable next_u_accessor : unsigned(ACESSOR_BUS - 1 downto 0);
	begin
		if rising_edge(clk) then
			case state is
					when ss =>
						u_accessor <= to_unsigned(0, ACESSOR_BUS);
						first_check <= (others => '1');
						done <= (others => '0');
						
						next_state <= s0;
						
					when s0 =>
						if enable(accessor) = '1'
							and (first_check(accessor) = '1'
								or nread_write(accessor) /= last_nread_write(accessor)
								or addr(accessor) /= last_addr(accessor)
								or (nread_write(accessor) = '1' and write_data(accessor) /= last_write_data(accessor))	-- you've updated the previous setted value
								or (nread_write(accessor) = '0' and last_addr_writted(accessor) = '1')) then			-- some other state has writted the same address, and you were reading it
							-- there's changes
							if nread_write(accessor) = '1' then
								next_state <= s1; -- write
							else
								next_state <= s10; -- read
							end if;
						else
							next_state <= s22; -- the value that you'll get it's the same; skip
						end if;
						
					when s1 =>
						done(accessor) <= '0';
						w_addr <= addr(accessor);
						w_data <= write_data(accessor);
						w_addr_valid <= '0';
						w_data_valid <= '0';
						
						next_state <= s2;
						
					when s2 =>
						w_addr <= addr(accessor);
						w_data <= write_data(accessor);
						w_addr_valid <= '1';
						w_data_valid <= '1';
						
						if w_resp_valid = '1' then
							next_state <= s3;
						end if;
						
					when s3 =>
						response(accessor) <= w_resp;
						w_addr_valid <= '0';
						w_data_valid <= '0';
						last_write_data(accessor) <= write_data(accessor);
						
						-- update last_addr_written
						for i in 0 to MEMORY_ACCESSES - 1 loop
							if enable(i) = '1' and i /= accessor 				-- ha de ser un altre entrada, estar activada...
									and last_addr(i) = addr(accessor) then		-- ... i llegir de la mateixa adreça
								last_addr_writted(i) <= '1';
							end if;
						end loop;
						
						next_state <= s20;
						
					when s10 =>
						done(accessor) <= '0';
						r_addr <= addr(accessor);
						r_addr_valid <= '0';
						
						next_state <= s11;
						
					when s11 =>
						r_addr <= addr(accessor);
						r_addr_valid <= '1';
						
						if r_data_valid = '1' then
							next_state <= s12;
						end if;
						
					when s12 =>
						response(accessor) <= r_resp;
						read_data(accessor) <= r_data;
						r_addr_valid <= '0';
						
						next_state <= s20;
						
					when s20 =>
						first_check(accessor) <= '0';
						last_addr_writted(accessor) <= '0';
						last_nread_write(accessor) <= nread_write(accessor);
						last_addr(accessor) <= addr(accessor);
						
						next_state <= s21;
					
					when s21 =>
						done(accessor) <= '1';
						
						next_state <= s22;
					
					when s22 =>
						-- check the next access
						next_u_accessor := u_accessor+1;
						if to_integer(next_u_accessor) = MEMORY_ACCESSES then
							u_accessor <= to_unsigned(0, ACESSOR_BUS); -- last one => start again
						else
							u_accessor <= next_u_accessor;
						end if;
						
						next_state <= s0;
			end case;
		end if;
	end process;
	
	process (clk)
	begin
		if (rising_edge(clk)) then
			state <= next_state;
		end if;
	end process;
end behavioral;