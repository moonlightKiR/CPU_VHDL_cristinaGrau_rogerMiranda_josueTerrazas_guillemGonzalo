library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity unidad_control is
	generic (
		REGISTER_DATA_BUS	: integer := 6;
		RAM_ADDRESS_BUS		: integer := 32;
		
		PROGRAM_COUNTER_BUS : integer := 32;
		RAM_DATA_BUS		: integer := 32;
		REGISTER_SELECT_BUS	: integer := 6;
		CONSTANT_BUS		: integer := 8
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
end entity;

architecture behavioral of unidad_control is
	component decoder is
	  generic (
		PROGRAM_COUNTER_BITS : integer := PROGRAM_COUNTER_BUS;
		INSTRUCTION_REGISTER_BITS : integer := RAM_DATA_BUS;
		OPCODE_BITS : integer := 4;
		RD_BITS : integer := REGISTER_SELECT_BUS;
		RS_BITS : integer := REGISTER_SELECT_BUS;
		RT_BITS : integer := REGISTER_SELECT_BUS;
		CONSTANT_BITS : integer := CONSTANT_BUS
	  );
	  
	  port(
		done_mux  : in std_logic;
		addr_mux  : out std_logic_vector(PROGRAM_COUNTER_BITS - 1 downto 0);
		pc_in     : in std_logic_vector (PROGRAM_COUNTER_BITS - 1 downto 0);
		inst_reg  : in std_logic_vector (INSTRUCTION_REGISTER_BITS - 1 downto 0);
		pc_out    : out std_logic_vector (PROGRAM_COUNTER_BITS - 1 downto 0);
		done_alu  : in std_logic;
		opcode    : out std_logic_vector (OPCODE_BITS - 1 downto 0);
		rd        : out std_logic_vector (RD_BITS - 1 downto 0);
		rs        : out std_logic_vector (RS_BITS - 1 downto 0);
		rt        : out std_logic_vector (RT_BITS - 1 downto 0);
		const     : out std_logic_vector (CONSTANT_BITS - 1 downto 0);
		clock     : in std_logic;
		reset     : in std_logic
	  );
	end component;
	
	component deco_to_alu is
		generic (
			REGISTER_DATA_BUS		: integer := REGISTER_DATA_BUS;
			PROGRAM_COUNTER_BUS		: integer := PROGRAM_COUNTER_BUS;
			REGISTER_SELECT_BUS		: integer := REGISTER_SELECT_BUS;
			CONSTANT_BUS			: integer := CONSTANT_BUS;
			RAM_ADDRESS_BUS			: integer := RAM_ADDRESS_BUS;
			RAM_DATA_BUS			: integer := RAM_DATA_BUS
		);
		port (
			clk 			: in std_logic;
			pc_in			: in std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			pc_out			: out std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			done			: out std_logic;
			opcode			: in std_logic_vector(3 downto 0);
			rd, rs, rt 		: in std_logic_vector(REGISTER_SELECT_BUS - 1 downto 0);
			const			: in std_logic_vector(CONSTANT_BUS - 1 downto 0);
			opcode_o		: out std_logic_vector(3 downto 0);
			oper_1, oper_2 	: out std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
			oper			: out std_logic;
			alu_pc_in		: out std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			alu_pc_out		: in std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			result 			: in std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
			reg_valueOut 	: in std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
			reg_valueIn		: out std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
			reg_address 	: out std_logic_vector(3 downto 0);
			reg_nread_write : out std_logic;
			mem_enable		: out std_logic;
			mem_nread_write	: out std_logic;
			mem_addr		: out std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
			mem_write_data	: out std_logic_vector(RAM_DATA_BUS - 1 downto 0);
			mem_read_data	: in std_logic_vector(RAM_DATA_BUS - 1 downto 0);
			mem_response	: in std_logic_vector(1 downto 0);
			mem_done		: in std_logic
		);
	end component;
	
	signal pc_in, pc_out			: std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
	signal done_alu					: std_logic;
	signal opcode					: std_logic_vector(3 downto 0);
	signal rd, rs, rt 				: std_logic_vector(REGISTER_SELECT_BUS - 1 downto 0);
	signal const					: std_logic_vector(CONSTANT_BUS - 1 downto 0);
begin
	mem_nread_write_decoder <= '0'; -- decoder always read
	mem_enable_decoder <= '1';
	
	decoder_inst : decoder
		port map (
			clock => clk,
			reset => reset,
			
			-- conexion multiplexor
			done_mux => mem_done_decoder,
			inst_reg => mem_read_data_decoder,
			addr_mux => mem_addr_decoder,
			
			-- conexion DecoToAlu
			pc_in => pc_in,
			pc_out => pc_out,
			done_alu => done_alu,
			opcode => opcode,
			rd => rd,
			rs => rs,
			rt => rt,
			const => const
		);
	
	deco_to_alu_inst : deco_to_alu
		port map (
			clk => clk,
			
			-- conexion decoder
			pc_in => pc_in,
			pc_out => pc_out,
			done => done_alu,
			opcode => opcode,
			rd => rd,
			rs => rs,
			rt => rt,
			const => const,
			
			-- conexion ALU
			opcode_o => opcode_o,
			oper_1 => oper_1,
			oper_2 => oper_2,
			oper => oper,
			alu_pc_in => alu_pc_in,
			alu_pc_out => alu_pc_out,
			result => result,
			
			-- conextion multiplexer
			mem_enable => mem_enable_dta,
			mem_nread_write => mem_nread_write_dta,
			mem_addr => mem_addr_dta,
			mem_write_data => mem_write_data_dta,
			mem_read_data => mem_read_data_dta,
			mem_response => mem_response_dta,
			mem_done => mem_done_dta,
			
			-- conexion register
			reg_valueOut => reg_valueOut,
			reg_valueIn => reg_valueIn,
			reg_address => reg_address,
			reg_nread_write => reg_nread_write
		);
end behavioral;