library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deco_to_alu_tb is
	generic (
		REGISTER_DATA_BUS		: integer := 16; -- bits dels operands & resultat
		PROGRAM_COUNTER_BUS		: integer := 32; -- bits del PC
		REGISTER_SELECT_BUS		: integer := 6;  -- bits per seleccionar el registre
		CONSTANT_BUS			: integer := 8;  -- bits de la constant; ha de ser <= REGISTER_DATA_BUS
		RAM_ADDRESS_BUS			: integer := 32;
		RAM_DATA_BUS			: integer := 32
	);
end entity;

architecture behavioral of deco_to_alu_tb is
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
			-- pins bloc
			clk 			: in std_logic;
			pc_in			: in std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			
			pc_out			: out std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			done			: out std_logic;
			
			-- pins decodificador
			opcode			: in std_logic_vector(3 downto 0);
			rd, rs, rt 		: in std_logic_vector(REGISTER_SELECT_BUS - 1 downto 0);
			const			: in std_logic_vector(CONSTANT_BUS - 1 downto 0);
			
			-- pins alu
			opcode_o		: out std_logic_vector(3 downto 0);
			oper_1, oper_2 	: out std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
			oper			: out std_logic;
			alu_pc_in		: out std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0); -- POV Alu
			
			alu_pc_out		: in std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0); -- POV Alu
			result 			: in std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
			
			-- pins banc de registres
			reg_valueOut 		: in std_logic_vector(REGISTER_DATA_BUS - 1 downto 0); -- POV register
			
			reg_valueIn			: out std_logic_vector(REGISTER_DATA_BUS - 1 downto 0); -- POV register
			reg_address 		: out std_logic_vector(3 downto 0);
			reg_nread_write 	: out std_logic;
			
			-- pins memoria
			mem_enable		: out std_logic;
			mem_nread_write	: out std_logic;
			mem_addr		: out std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
			mem_write_data	: out std_logic_vector(RAM_DATA_BUS - 1 downto 0);
			mem_read_data	: in std_logic_vector(RAM_DATA_BUS - 1 downto 0);
			mem_response	: in std_logic_vector(1 downto 0);
			mem_done		: in std_logic
		);
	end component;
	
	component alu is
		generic (
			REGISTER_DATA_BUS		: integer := REGISTER_DATA_BUS;
			PROGRAM_COUNTER_BUS		: integer := PROGRAM_COUNTER_BUS
		);
		port (
			opcode			: in std_logic_vector(3 downto 0);
			oper_1, oper_2 	: in std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);		-- rs&rt, o rs&k, o rs&-
			pc_in			: in std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			oper, clk		: in std_logic;
			
			pc_out			: out std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
			result 			: out std_logic_vector(REGISTER_DATA_BUS - 1 downto 0)		-- rd
		);
	end component;
	
	component BitsRegistro is
		port (
			valueOut : out std_logic_vector (15 downto 0);
			valueIn	: in std_logic_vector (15 downto 0);
			Address : in std_logic_vector (3 downto 0);
			reset, clock, readwrite: in std_logic
		);
	end component;
	
	signal clk : std_logic := '0';
	constant CLK_PERIOD : time := 1ns;
	
	signal done, oper : std_logic;													-- done?
	signal opcode, alu_opcode : std_logic_vector(3 downto 0);					-- change
	signal oper_1, oper_2 : std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
	signal pc_in, pc_out : std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
	signal alu_pc_in, alu_pc_out : std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
	signal result : std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);			-- check
	signal rd, rs, rt : std_logic_vector(REGISTER_SELECT_BUS - 1 downto 0);		-- change
	signal const : std_logic_vector(CONSTANT_BUS - 1 downto 0);					-- change
	signal reg_valueOut, reg_valueIn : std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
	signal reg_address : std_logic_vector(3 downto 0);
	signal reg_nread_write, reset : std_logic;
	signal mem_enable, mem_nread_write, mem_done : std_logic;
	signal mem_addr : std_logic_vector(RAM_ADDRESS_BUS - 1 downto 0);
	signal mem_write_data, mem_read_data : std_logic_vector(RAM_DATA_BUS - 1 downto 0);
	signal mem_response	: std_logic_vector(1 downto 0);
begin
	clk <= not clk after CLK_PERIOD/2;
	
	UUT_alu : alu
		port map (
			opcode => alu_opcode,
			oper_1 => oper_1,
			oper_2 => oper_2,
			pc_in => alu_pc_in,
			oper => oper,
			clk => clk,
			pc_out => alu_pc_out,
			result => result
		);
	
	UUT_registers : BitsRegistro
		port map (
			valueOut => reg_valueOut,
			valueIn => reg_valueIn,
			Address => reg_address,
			reset => reset,
			clock => clk,
			readwrite => reg_nread_write
		);
		
	UUT_deco_alu : deco_to_alu
		port map (
			clk => clk,
			pc_in => pc_in,
			pc_out => pc_out,
			done => done,
			opcode => opcode,
			rd => rd,
			rs => rs,
			rt => rt,
			const => const,
			opcode_o => alu_opcode,
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
			mem_enable => mem_enable,
			mem_nread_write => mem_nread_write,
			mem_addr => mem_addr,
			mem_write_data => mem_write_data,
			mem_read_data => mem_read_data,
			mem_response => mem_response,
			mem_done => mem_done
		);
	
	stim_p : process
	begin
		-- reset
		reset <= '0';
		wait for CLK_PERIOD*2;
		reset <= '1';
		
		pc_in <= x"00000000";
		
		opcode <= "0001"; -- addi
		rd <= "000001";
		rs <= "000010";
		const <= x"01";
		wait until done = '1';
		assert ((pc_out = x"00000001") and (result = x"0001")) -- es suma 0 i 1 => resultat és 1 i PC incrementat en 1
			report "test failed for test 01 [addi]" severity error;
		wait for 1ns;
		
		opcode <= "0110"; -- not
		rd <= "000010";
		rs <= "000001";
		wait until done = '1';
		assert ((pc_out = x"00000001") and (result = x"FFFE")) -- es nega 1 => resultat és 0xFFFE i PC incrementat en 1
			report "test failed for test 02 [not]" severity error;
		
		wait;
	end process;
end behavioral;