library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
	generic (
		REGISTER_DATA_BUS		: integer := 16; -- bits dels operands & resultat
		PROGRAM_COUNTER_BUS		: integer := 32  -- bits del PC
	);
	port (
		opcode			: in std_logic_vector(3 downto 0);
		oper_1, oper_2 	: in std_logic_vector(REGISTER_DATA_BUS - 1 downto 0);		-- rs&rt, o rs&k, o rs&-
		pc_in			: in std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
		
		pc_out			: out std_logic_vector(PROGRAM_COUNTER_BUS - 1 downto 0);
		result 			: out std_logic_vector(REGISTER_DATA_BUS - 1 downto 0)		-- rd
	);
end entity;

architecture behavioral of alu is
begin
	process(opcode)
		variable pc_out_unsigned : unsigned(PROGRAM_COUNTER_BUS - 1 downto 0);
		variable oper_1_unsigned, oper_2_unsigned, result_unsigned : unsigned(REGISTER_DATA_BUS - 1 downto 0);
		
		constant zero : unsigned(REGISTER_DATA_BUS - 1 downto 0) := to_unsigned(0, REGISTER_DATA_BUS);
	begin
		oper_1_unsigned := unsigned(oper_1);
		oper_2_unsigned := unsigned(oper_2);
		
		-- per defecte, el program counter s'incrementa en 1
		pc_out_unsigned := unsigned(pc_in)+1;
		
		-- en alguns casos (com els reservats, o les instruccions de jump) no es tenen en compte en el case;
		-- per estar segur de que es tindrà un valor ho asigno aquí
		result_unsigned := zero;
		
		case opcode is
			when "0000" | "0001" =>
				result_unsigned := oper_1_unsigned + oper_2_unsigned; -- suma
			when "0010" =>
				result_unsigned := oper_1_unsigned - oper_2_unsigned; -- resta
			when "0011" =>
				result_unsigned := oper_1_unsigned or oper_2_unsigned; -- or
			when "0100" =>
				result_unsigned := oper_1_unsigned xor oper_2_unsigned; -- xor
			when "0101" =>
				result_unsigned := oper_1_unsigned and oper_2_unsigned; -- and
			when "0110" =>
				result_unsigned := not oper_1_unsigned; 				-- not
			when "0111" | "1000" =>
				result_unsigned := oper_1_unsigned;						-- load/store
			when "1001" =>
				-- compare
				if oper_1_unsigned > oper_2_unsigned then
					result_unsigned := to_unsigned(1, REGISTER_DATA_BUS);
				else
					result_unsigned := zero; -- realment no caldria, ja que és el valor per defecte
				end if;
			when "1010" =>
				result_unsigned := shift_left(oper_1_unsigned, to_integer(oper_2_unsigned));  -- <<
			when "1011" =>
				result_unsigned := shift_right(oper_1_unsigned, to_integer(oper_2_unsigned)); -- >>
			when "1100" =>
				pc_out_unsigned := oper_1_unsigned;						-- jump
			when "1101" =>
				if oper_2_unsigned = zero then
					pc_out_unsigned := oper_1_unsigned;					-- conditional jump
				end if;
			when others =>
		end case;
		
		pc_out <= std_logic_vector(pc_out_unsigned);
		result <= std_logic_vector(result_unsigned);
	end process;
end behavioral;