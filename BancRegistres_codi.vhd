library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;

entity BitsRegistro is
	port (
		valueOut : out std_logic_vector (15 downto 0);
		valueIn	: in std_logic_vector (15 downto 0);
		Address : in std_logic_vector (3 downto 0);
		reset, clock, readwrite: in std_logic
	);
end entity;

architecture Arch16BitsRegistro of BitsRegistro is
type RegistroFile is array(0 to 15) of std_logic_vector (15 downto 0);
signal Registro : RegistroFile;
begin

	identifier : process (clock)
	begin
		if (rising_edge(clock)) then
			if (readwrite = '1' and Address /= "0000" and reset ='1') then
				Registro(to_integer(unsigned(Address))) <= valueIn;
			end if;
			if (reset = '0' and readwrite = '1') then
				Registro(to_integer(unsigned(Address))) <= "0000000000000000";
			end if;
            valueOut <= Registro(to_integer(unsigned(Address)));
		end if;
	end process;
end architecture;