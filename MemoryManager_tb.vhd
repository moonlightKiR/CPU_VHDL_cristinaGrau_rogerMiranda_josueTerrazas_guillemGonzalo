library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bus_multiplexer_pkg.all;

entity memory_manager_tb is
	generic (
		MEMORY_ACCESSES				: integer := 2;
		RAM_ADDRESS_BUS				: integer := 32;
		RAM_DATA_BUS				: integer := 32
	);
end entity;

architecture behavioral of memory_manager_tb is
	component memory_manager is
		generic (
			MEMORY_ACCESSES				: integer := MEMORY_ACCESSES;
			RAM_ADDRESS_BUS				: integer := RAM_ADDRESS_BUS;
			RAM_DATA_BUS				: integer := RAM_DATA_BUS
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
	end component;
	
	component memory
        port(
            -- WRITE
            WADDR   : in std_logic_vector(31 downto 0);
            WAVALID : in std_logic;
            WDATA   : in std_logic_vector(31 downto 0);
            WDATAV  : in std_logic;
            WRESP   : out std_logic_vector(1 downto 0);
            WRESPV  : out std_logic;
            -- READ
            RADDR   : in std_logic_vector(31 downto 0);
            RAVALID : in std_logic;
            RDATA   : out std_logic_vector(31 downto 0);
            RDATAV  : out std_logic;
            RRESP   : out std_logic_vector(1 downto 0);
            -- SYSTEM CLOCK
            clock  : in std_logic;
            reset  : in std_logic
        );
    end component;
	
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 1ns;
	
	-- pins memoria
	signal w_addr			: std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
	signal w_addr_valid		: std_logic;
	signal w_data			: std_logic_vector(RAM_DATA_BUS - 1 downto 0);
	signal w_data_valid		: std_logic;
	signal w_resp			: std_logic_vector(1 downto 0);
	signal w_resp_valid		: std_logic;
	signal r_addr			: std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
	signal r_addr_valid		: std_logic;
	signal r_data			: std_logic_vector(RAM_DATA_BUS - 1 downto 0);
	signal r_data_valid		: std_logic;
	signal r_resp			: std_logic_vector(1 downto 0);
	
	-- pins acces memoria
	signal enable			: std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
	signal nread_write		: std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
	signal addr				: bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_ADDRESS_BUS - 1 downto 0);
	signal write_data		: bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_DATA_BUS - 1 downto 0);
	signal read_data		: bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_DATA_BUS - 1 downto 0);
	signal response			: bus_array(MEMORY_ACCESSES - 1 downto 0)(1 downto 0);
	signal done				: std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
	
	signal reset			: std_logic;
begin
	clk <= not clk after CLK_PERIOD/2;
	
	UUT : memory_manager
		port map (
			clk => clk,
			w_addr => w_addr,
			w_addr_valid => w_addr_valid,
			w_data => w_data,
			w_data_valid => w_data_valid,
			w_resp => w_resp,
			w_resp_valid => w_resp_valid,
			r_addr => r_addr,
			r_addr_valid => r_addr_valid,
			r_data => r_data,
			r_data_valid => r_data_valid,
			r_resp => r_resp,
			enable => enable,
			nread_write => nread_write,
			addr => addr,
			write_data => write_data,
			read_data => read_data,
			response => response,
			done => done
		);
	
	UUT_memory : memory
		port map (
			WADDR => w_addr,
			WAVALID => w_addr_valid,
			WDATA => w_data,
			WDATAV => w_data_valid,
			WRESP => w_resp,
			WRESPV => w_resp_valid,
			RADDR => r_addr,
			RAVALID => r_addr_valid,
			RDATA => r_data,
			RDATAV => r_data_valid,
			RRESP => r_resp,
			clock => clk,
			reset => reset
		);
	
	stim_p : process
	begin
		enable <= (others => '0');
		reset <= '0';
		wait for 1ns;
		reset <= '1';
		wait for 1ns;
		reset <= '0';
		
		-- first block read, second block write
		nread_write(0) <= '0';
		nread_write(1) <= '1';
		
		addr(0) <= x"00000001";
		addr(1) <= x"00000001";
		
		-- write
		write_data(1) <= x"FFFF0000";
		wait for 1ns;
		enable(1) <= '1';
		
		wait until done(1) = '1';
		assert (response(1) = "00")
			report "test failed for test 01 [write]" severity error;
		
		-- not updating
		wait until done(1) = '0' for CLK_PERIOD*10;
		assert (done(1) = '1')
			report "test failed for test 02 [hold write]" severity error;
		
		-- read
		enable(1) <= '0';
		enable(0) <= '1';
		
		wait until done(0) = '1';
		assert ((response(0) = "00") and (read_data(0) = x"FFFF0000"))
			report "test failed for test 03 [read]" severity error;
		
		-- write & read
		write_data(1) <= x"FF000000";
		wait for 1ns;
		enable(1) <= '1';
		
		wait until done(1) = '0';
		wait until done(0) = '0';
		wait until done = "11";
		assert ((response(1) = "00") and (response(0) = "00") and (read_data(0) = x"FF000000"))
			report "test failed for test 04 [write & read]" severity error;
		
		-- write 2
		enable(1) <= '0';
		wait for 1ns;
		addr(1) <= x"00000002";
		write_data(1) <= x"F0000000";
		wait for 1ns;
		enable(1) <= '1';
		
		wait until done(1) = '0';
		wait until done(1) = '1';
		assert (response(1) = "00")
			report "test failed for test 05 [write 2]" severity error;
		
		-- read 2
		enable <= "00";
		wait for 1ns;
		addr(0) <= x"00000002";
		wait for 1ns;
		enable(0) <= '1';
		
		wait until done(0) = '0';
		wait until done(0) = '1';
		assert ((response(0) = "00") and (read_data(0) = x"F0000000"))
			report "test failed for test 06 [read 2]" severity error;
		
		wait;
	end process;
end behavioral;