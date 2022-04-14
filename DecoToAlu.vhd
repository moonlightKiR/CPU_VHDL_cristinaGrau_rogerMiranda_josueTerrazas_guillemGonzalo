library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity deco_to_alu is
	generic (
		REGISTER_DATA_BUS		: integer := 16; -- bits dels operands & resultat
		PROGRAM_COUNTER_BUS		: integer := 32; -- bits del PC
		REGISTER_SELECT_BUS		: integer := 6;  -- bits per seleccionar el registre
		CONSTANT_BUS			: integer := 8   -- bits de la constant; ha de ser <= REGISTER_DATA_BUS
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
		alu_pc_in		: out std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0); -- POV Alu
		
		alu_pc_out		: in std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0); -- POV Alu
		result 			: in std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);
		
		-- pins banc de registres
		reg_valueOut 		: in std_logic_vector(REGISTER_DATA_BUS - 1 downto 0); -- POV register
		
		reg_valueIn			: out std_logic_vector(REGISTER_DATA_BUS - 1 downto 0); -- POV register
		reg_address 		: out std_logic_vector(3 downto 0);
		reg_nread_write 	: out std_logic
		
		-- pins memoria
		-- TODO
	);
end entity;

architecture behavioral of deco_to_alu is
	TYPE DECO_TO_ALU_STATE_MACHINE IS (
		e0, e1, e2, e5, e10, e11, e15, e16, e17, e20, e25
	);
	
	signal is_jump : boolean;
	signal state, next_state : DECO_TO_ALU_STATE_MACHINE := e0;
	signal internal_rs : std_logic_vector(REGISTER_SELECT_BUS - 1 downto 0); -- en store rd pasa a ser rs
begin
	is_jump <= (opcode = "1100") or (opcode = "1101");
	
	-- Alu inputs
	opcode_o <= opcode;
	alu_pc_in <= pc_in;
	pc_out <= alu_pc_out;
	process (state,						-- next state
			opcode, rd, rs, rt, const) 	-- reset state machine variables
	begin
		if not state'event then
			-- input changed => start again
			done <= '0';
			reg_nread_write <= '0';
			internal_rs <= rs; -- per defecte a rs
			
			case opcode is
				-- RRR
				when "0000" | "0010" | "0011" | "0100" | "0101" | "1001" | "1010" | "1011" | "1101" => -- TODO comprobar conditional jump (3 registres?)
					next_state <= e1;
					
				-- RRImm
				when "0001" =>
					next_state <= e5;
				
				-- Not/R
				when "0110" =>
					next_state <= e10;
				when "1100" =>
					-- Jump
					internal_rs <= rd;
					next_state <= e10;
				
				--RR
				when "0111" =>
					next_state <= e25;
				when "1000" =>
					-- Store
					internal_rs <= rd;
					next_state <= e25;
					
				when others =>
					next_state <= e0;
			end case;
		else
			case state is
				when e1 =>
					reg_nread_write <= '0';
					reg_address <= rt(3 downto 0);
					next_state <= e2;
					
				when e2 =>
					reg_nread_write <= '0';
					reg_address <= rt(3 downto 0);
					oper_2 <= reg_valueOut;
					next_state <= e10;
				
				when e5 =>
					oper_2 <= "00000000" & const;
					next_state <= e10;
				
				when e10 =>
					reg_nread_write <= '0';
					reg_address <= internal_rs(3 downto 0);
					next_state <= e11;
				
				when e11 =>
					reg_nread_write <= '0';
					reg_address <= internal_rs(3 downto 0);
					oper_1 <= reg_valueOut;
					
					if is_jump then
						next_state <= e20;
					else
						next_state <= e15; -- we need to store the register value
					end if;
				
				when e15 =>
					reg_nread_write <= '0';
					reg_address <= rd(3 downto 0);
					reg_valueIn <= result;
					next_state <= e16;
				
				when e16 =>
					reg_nread_write <= '1';
					reg_address <= rd(3 downto 0);
					reg_valueIn <= result;
					next_state <= e17;
				
				when e17 =>
					reg_nread_write <= '0';
					reg_address <= rd(3 downto 0);
					reg_valueIn <= result;
					next_state <= e20;
				
				when e20 =>
					done <= '1';
				
				when others => -- ?
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