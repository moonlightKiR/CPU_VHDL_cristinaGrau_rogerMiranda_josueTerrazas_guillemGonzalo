library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bus_multiplexer_pkg.all;

entity memory_multiplexer is
	generic (
		MEMORY_ACCESSES				: integer := 2; -- nº d'accessos a la RAM
		
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
		nread_write		: in std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
		addr			: in bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_ADDRESS_BUS - 1 downto 0);
		write_data		: in bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_DATA_BUS - 1 downto 0);
		read_data		: out bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_DATA_BUS - 1 downto 0);
		done			: out std_logic_vector(MEMORY_ACCESSES - 1 downto 0)
	);
end entity;

architecture behavioral of memory_multiplexer is
begin
	
end behavioral;