library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bus_multiplexer_pkg.all;

entity system_tb is
	generic (
		REGISTER_DATA_BUS	: integer := 16;
		RAM_ADDRESS_BUS		: integer := 32;
		
		PROGRAM_COUNTER_BUS : integer := 32;
		RAM_DATA_BUS		: integer := 32;
		REGISTER_SELECT_BUS	: integer := 6;
		CONSTANT_BUS		: integer := 8;
		
		MEMORY_ACCESSES		: integer := 3
	);
end entity;

architecture behavioral of system_tb is
	component system is
		generic (
			REGISTER_DATA_BUS	: integer := REGISTER_DATA_BUS;
			RAM_ADDRESS_BUS		: integer := RAM_ADDRESS_BUS;
			PROGRAM_COUNTER_BUS : integer := PROGRAM_COUNTER_BUS;
			RAM_DATA_BUS		: integer := RAM_DATA_BUS;
			REGISTER_SELECT_BUS	: integer := REGISTER_SELECT_BUS;
			CONSTANT_BUS		: integer := CONSTANT_BUS;
			MEMORY_ACCESSES		: integer := MEMORY_ACCESSES
		);
		port (
			clk, cpu_reset, mem_reset : in std_logic;
			
			-- RAM multiplexer if you want to write/read to check
			memory_enable		: in std_logic;
			memory_nread_write	: in std_logic;
			memory_addr			: in std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
			memory_write_data	: in std_logic_vector(RAM_DATA_BUS - 1 downto 0);
			memory_read_data	: out std_logic_vector(RAM_DATA_BUS - 1 downto 0);
			memory_response		: out std_logic_vector(1 downto 0);
			memory_done			: out std_logic
		);
	end component;
	
	constant CLK_PERIOD : time := 1ns;
	
	signal clk					: std_logic := '0';
	signal cpu_reset, mem_reset	: std_logic;
	
	signal memory_enable		: std_logic;
	signal memory_nread_write	: std_logic;
	signal memory_addr			: std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
	signal memory_write_data	: std_logic_vector(RAM_DATA_BUS - 1 downto 0);
	signal memory_read_data		: std_logic_vector(RAM_DATA_BUS - 1 downto 0);
	signal memory_done			: std_logic;
begin
	clk <= not clk after CLK_PERIOD/2;
	
	testUnit : system
		port map(
			clk => clk,
			cpu_reset => cpu_reset,
			mem_reset => mem_reset,
			memory_enable => memory_enable,
			memory_nread_write => memory_nread_write,
            memory_addr => memory_addr,
            memory_write_data => memory_write_data,
            memory_read_data => memory_read_data,
            memory_response => open,
            memory_done => memory_done
		);
	
	stim_p : process
	begin
		cpu_reset <= '0';
		mem_reset <= '0';
		memory_enable <= '0';
		memory_nread_write <= '0';
		
		-- reset rising edge
		wait for 1ns;
		cpu_reset <= '1';
		mem_reset <= '1';
		
		wait for 1ns;
		memory_enable <= '1';
		mem_reset <= '0';
		memory_addr <= x"00000000";
		memory_write_data <= "0001" & "0000" & "000001" & "000000" & "0000" & "00000100"; -- addi 1, 0, 4 (carrega al registre 1 el valor 0+4)
		
		wait for 1ns;
		memory_nread_write <= '1';
		
		--wait until memory_done = '0';
		wait until memory_done = '1';
		memory_nread_write <= '0';
		
		wait for 1ns;
		memory_addr <= x"00000001";
		memory_write_data <= "1000" & "0000" & "000001" & "000000" & "000001" & "000000"; -- st 1, 1 -- Memory[4] = 4
		
		wait for 1ns;
		memory_nread_write <= '1';
		
		wait until memory_done = '0';
		wait until memory_done = '1';
		memory_nread_write <= '0';
		cpu_reset <= '0';
		
		wait for 1ns;
		memory_addr <= x"00000004";
		
		wait until memory_done = '0';
		wait until (memory_done = '1' and memory_read_data = x"00000004") for CLK_PERIOD*100;
		assert (memory_read_data = x"00000004")
			report "test failed for test 01 [addi+store]" severity error;
		
		wait;
	end process;
end behavioral;