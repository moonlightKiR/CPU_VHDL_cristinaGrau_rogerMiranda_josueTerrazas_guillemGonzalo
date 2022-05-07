library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bus_multiplexer_pkg.all;

entity system is
	generic (
		REGISTER_DATA_BUS	: integer := 16;
		RAM_ADDRESS_BUS		: integer := 32;
		
		PROGRAM_COUNTER_BUS : integer := 32;
		RAM_DATA_BUS		: integer := 32;
		REGISTER_SELECT_BUS	: integer := 6;
		CONSTANT_BUS		: integer := 8;
		
		MEMORY_ACCESSES		: integer := 3
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
end entity;

architecture behavioral of system is
	component cpu is
		generic (
			REGISTER_DATA_BUS	: integer := REGISTER_DATA_BUS;
			RAM_ADDRESS_BUS		: integer := RAM_ADDRESS_BUS;
			PROGRAM_COUNTER_BUS : integer := PROGRAM_COUNTER_BUS;
			RAM_DATA_BUS		: integer := RAM_DATA_BUS;
			REGISTER_SELECT_BUS	: integer := REGISTER_SELECT_BUS;
			CONSTANT_BUS		: integer := CONSTANT_BUS
		);
		port (
			clk, reset		: in std_logic;
			
			-- RAM multiplexer for the decoder
			mem_enable_decoder			: out std_logic;
			mem_nread_write_decoder		: out std_logic;
			mem_addr_decoder			: out std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
			mem_write_data_decoder		: out std_logic_vector(RAM_DATA_BUS - 1 downto 0);
			mem_read_data_decoder		: in std_logic_vector(RAM_DATA_BUS - 1 downto 0);
			mem_response_decoder		: in std_logic_vector(1 downto 0);
			mem_done_decoder			: in std_logic;
			
			-- RAM multiplexer for the DecoToAlu
			mem_enable_dta				: out std_logic;
			mem_nread_write_dta			: out std_logic;
			mem_addr_dta				: out std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
			mem_write_data_dta			: out std_logic_vector(RAM_DATA_BUS - 1 downto 0);
			mem_read_data_dta			: in std_logic_vector(RAM_DATA_BUS - 1 downto 0);
			mem_response_dta			: in std_logic_vector(1 downto 0);
			mem_done_dta				: in std_logic
		);
	end component;
	
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
	
	component memory is
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
	signal mem_enable		: std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
	signal mem_nread_write	: std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
	signal mem_addr			: bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_ADDRESS_BUS - 1 downto 0);
	signal mem_write_data	: bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_DATA_BUS - 1 downto 0);
	signal mem_read_data	: bus_array(MEMORY_ACCESSES - 1 downto 0)(RAM_DATA_BUS - 1 downto 0);
	signal mem_response		: bus_array(MEMORY_ACCESSES - 1 downto 0)(1 downto 0);
	signal mem_done			: std_logic_vector(MEMORY_ACCESSES - 1 downto 0);
begin
	mem_enable(MEMORY_ACCESSES - 1) <= memory_enable;
	mem_nread_write(MEMORY_ACCESSES - 1) <= memory_nread_write;
	mem_addr(MEMORY_ACCESSES - 1) <= memory_addr;
	mem_write_data(MEMORY_ACCESSES - 1) <= memory_write_data;
	memory_read_data <= mem_read_data(MEMORY_ACCESSES - 1);
	memory_response <= mem_response(MEMORY_ACCESSES - 1);
	memory_done <= mem_done(MEMORY_ACCESSES - 1);
	
	memory_inst : memory
		port map (
			clock => clk,
			reset => mem_reset,
			
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
			RRESP => r_resp
		);
		
	memory_mult_inst : memory_manager
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
			
			enable => mem_enable,
			nread_write => mem_nread_write,
			addr => mem_addr,
			write_data => mem_write_data,
			read_data => mem_read_data,
			response => mem_response,
			done => mem_done
		);
	
	cpu_inst : cpu
		port map (
			clk => clk,
			reset => cpu_reset,
			
			mem_enable_decoder => mem_enable(0),
			mem_nread_write_decoder => mem_nread_write(0),
			mem_addr_decoder => mem_addr(0),
			mem_write_data_decoder => mem_write_data(0),
			mem_read_data_decoder => mem_read_data(0),
			mem_response_decoder => mem_response(0),
			mem_done_decoder => mem_done(0),
			
			mem_enable_dta => mem_enable(1),
			mem_nread_write_dta => mem_nread_write(1),
			mem_addr_dta => mem_addr(1),
			mem_write_data_dta => mem_write_data(1),
			mem_read_data_dta => mem_read_data(1),
			mem_response_dta => mem_response(1),
			mem_done_dta => mem_done(1)
		);
end behavioral;