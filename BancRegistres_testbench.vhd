library IEEE;
use IEEE.std_logic_1164.all;

entity BitsRegistro_tb is
end BitsRegistro_tb;

architecture Arch16BitsRegistro_tb of BitsRegistro_tb is

	component BitsRegistro is
		port (
		valueOut : out std_logic_vector (15 downto 0);
		valueIn	: in std_logic_vector (15 downto 0);
		Address : in std_logic_vector (3 downto 0);
		reset, clock, readwrite : in std_logic
		);
	end component;
	
	signal testReset, testClock, testReadWrite : std_logic := '0';
	signal testValueOut, testValueIn : std_logic_vector (15 downto 0);
	signal testAddress : std_logic_vector (3 downto 0);
	signal testTime : integer := 0;
	
	begin
		testUnit : BitsRegistro port map(
			valueOut => testValueOut,
			valueIn => testValueIn,
			reset => testReset,
			clock => testClock,
			Address => testAddress,
            readwrite => testReadWrite
		);
		
		generate_100MHz : process
		begin
			testClock <= not testClock;
			wait for 5 ns;
			
			if testClock = '1' then
				testTime <= testTime + 1;
			end if;
			if testTime > 20 then
				wait;
			end if;
		end process;
		
		generate_Signal : process
		begin
        	         	
       		wait for 5 ns;
			testReset <= '1';
            testAddress <= "1010";
			testValueIn <= "1010101010101010"; --aaaa
			testReadWrite <= '1';
            wait for 10 ns;
            testReadWrite <= '0';
            wait for 10 ns;
            testAddress <= "0101";
			testValueIn <= "0101010101010101"; --5555
            testReadWrite <= '1';
			wait for 10 ns;
            testReadWrite <= '0';
            wait for 10 ns;
			testAddress <= "1010";
			wait for 10 ns;
			testReset <= '0';
			testReadWrite <= '1';
            wait for 10 ns;
			testReset <= '1';
            testReadWrite <= '0';
			wait for 10 ns;
            testAddress <= "0101";
			testValueIn <= "0011010100110011"; --3533
            testReadWrite <= '1';
			wait for 10 ns;
			testReadWrite <= '0';
			wait;
            
		end process;
		
end architecture;