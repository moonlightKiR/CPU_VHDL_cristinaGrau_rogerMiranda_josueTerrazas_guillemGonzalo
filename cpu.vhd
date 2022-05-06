library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cpu is
	generic (
		REGISTER_DATA_BUS	: integer := 16;
		RAM_ADDRESS_BUS		: integer := 32;
		
		PROGRAM_COUNTER_BUS : integer := 32;
		RAM_DATA_BUS		: integer := 32;
		REGISTER_SELECT_BUS	: integer := 6;
		CONSTANT_BUS		: integer := 8
	);
	port (
		clk, reset		: in std_logic;
		
		-- RAM multiplexer for the decoder
		mem_enable_decoder			: out std_logic;
		mem_nread_write_decoder		: out std_logic;
		mem_addr_decoder			: out std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
		mem_write_data_decoder		: out std_logic_vector(RAM_DATA_BUS - 1 downto 0);		-- not conected
		mem_read_data_decoder		: in std_logic_vector(RAM_DATA_BUS - 1 downto 0);
		mem_response_decoder		: in std_logic_vector(1 downto 0);						-- not conected
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
end entity;

architecture behavioral of cpu is
	component unidad_control is
		generic (
			REGISTER_DATA_BUS	: integer := REGISTER_DATA_BUS;
			RAM_ADDRESS_BUS		: integer := RAM_ADDRESS_BUS;
			PROGRAM_COUNTER_BUS : integer := PROGRAM_COUNTER_BUS;
			RAM_DATA_BUS		: integer := RAM_DATA_BUS;
			REGISTER_SELECT_BUS	: integer := REGISTER_SELECT_BUS;
			CONSTANT_BUS		: integer := CONSTANT_BUS
		);
		
		port(
			clk, reset 		: in std_logic;
			
			-- to ALU
			opcode_o		: out std_logic_vector(3 downto 0);
			oper_1, oper_2 	: out std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
			oper			: out std_logic;
			alu_pc_in		: out std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			alu_pc_out		: in std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			result 			: in std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
			
			-- to registers
			reg_valueOut 	: in std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
			reg_valueIn		: out std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
			reg_address 	: out std_logic_vector(3 downto 0);
			reg_nread_write : out std_logic;
			
			-- RAM multiplexer for the decoder
			mem_enable_decoder			: out std_logic;
			mem_nread_write_decoder		: out std_logic;
			mem_addr_decoder			: out std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
			mem_write_data_decoder		: out std_logic_vector(RAM_DATA_BUS - 1 downto 0);		-- not conected
			mem_read_data_decoder		: in std_logic_vector(RAM_DATA_BUS - 1 downto 0);
			mem_response_decoder		: in std_logic_vector(1 downto 0);						-- not conected
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
	
	component BitsRegistro is
		port (
			valueOut : out std_logic_vector (REGISTER_DATA_BUS - 1 downto 0);
			valueIn	: in std_logic_vector (REGISTER_DATA_BUS - 1 downto 0);
			Address : in std_logic_vector (3 downto 0);
			reset, clock, readwrite: in std_logic
		);
	end component;
	
	component alu is
		generic (
			REGISTER_DATA_BUS		: integer := REGISTER_DATA_BUS;
			PROGRAM_COUNTER_BUS		: integer := PROGRAM_COUNTER_BUS
		);
		port (
			opcode			: in std_logic_vector(3 downto 0);
			oper_1, oper_2 	: in std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
			pc_in			: in std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			oper, clk		: in std_logic;
			pc_out			: out std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			result 			: out std_logic_vector(REGISTER_DATA_BUS - 1 downto 0)
		);
	end component;
	
	-- UC to Alu connections
	signal opcode					: std_logic_vector(3 downto 0);
	signal oper_1, oper_2, result 	: std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
	signal alu_pc_in, alu_pc_out	: std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
	signal oper						: std_logic;
	
	-- UC to registers connections
	signal reg_valueOut 			: std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
	signal reg_valueIn				: std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
	signal reg_address 				: std_logic_vector(3 downto 0);
	signal reg_nread_write 			: std_logic;
begin
	uc_inst : unidad_control
		port map (
			clk => clk,
			reset => reset,
			
			opcode_o => opcode,
			oper_1 => oper_1,
			oper_2 => oper_2,
			oper => oper,
			alu_pc_in => alu_pc_in,
			alu_pc_out => alu_pc_out,
			result => result,
			
			reg_valueOut => reg_valueOut,
			reg_valueIn => reg_valueIn,
			reg_address => reg_address,
			reg_nread_write => reg_nread_write,
			
			mem_enable_decoder => mem_enable_decoder,
			mem_nread_write_decoder => mem_nread_write_decoder,
			mem_addr_decoder => mem_addr_decoder,
			mem_write_data_decoder => mem_write_data_decoder,
			mem_read_data_decoder => mem_read_data_decoder,
			mem_response_decoder => mem_response_decoder,
			mem_done_decoder => mem_done_decoder,
			
			mem_enable_dta => mem_enable_dta,
			mem_nread_write_dta => mem_nread_write_dta,
			mem_addr_dta => mem_addr_dta,
			mem_write_data_dta => mem_write_data_dta,
			mem_read_data_dta => mem_read_data_dta,
			mem_response_dta => mem_response_dta,
			mem_done_dta => mem_done_dta
		);
	
	alu_inst : alu
		port map (
			clk => clk,
			opcode => opcode,
			oper_1 => oper_1,
			oper_2 => oper_2,
			oper => oper,
			pc_in => alu_pc_in,
			pc_out => alu_pc_out,
			result => result
		);
	
	reg_inst : BitsRegistro
		port map (
			clock => clk,
			reset => reset,
			
			valueOut => reg_valueOut,
			valueIn => reg_valueIn,
			Address => reg_address,
			readwrite => reg_nread_write
		);
end behavioral;