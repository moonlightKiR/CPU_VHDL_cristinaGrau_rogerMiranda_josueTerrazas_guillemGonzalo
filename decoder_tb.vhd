library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity decoder_tb is
    generic (
        PROGRAM_COUNTER_BITS : integer := 32;
        INSTRUCTION_REGISTER_BITS : integer := 32;
        OPCODE_BITS : integer := 4;
        RD_BITS : integer := 6;
        RS_BITS : integer := 6;
        RT_BITS : integer := 6;
        CONSTANT_BITS : integer := 8
    );
end;

architecture bench of decoder_tb is

component decoder is
  
    
    
    port(
        --pins mux
        done_mux  : in std_logic;
		addr_mux  : out std_logic_vector(PROGRAM_COUNTER_BITS - 1 downto 0);
        pc_in     : in std_logic_vector (PROGRAM_COUNTER_BITS - 1 downto 0);
        inst_reg  : in std_logic_vector (INSTRUCTION_REGISTER_BITS - 1 downto 0);
        pc_out    : out std_logic_vector (PROGRAM_COUNTER_BITS - 1 downto 0);
        --pins alu
        done_alu  : in std_logic;
        opcode    : out std_logic_vector (OPCODE_BITS - 1 downto 0);
        rd        : out std_logic_vector (RD_BITS - 1 downto 0);
        rs        : out std_logic_vector (RS_BITS - 1 downto 0);
        rt        : out std_logic_vector (RT_BITS - 1 downto 0);
        const     : out std_logic_vector (CONSTANT_BITS - 1 downto 0);
        --pins state machine
        clock     : in std_logic;
        reset     : in std_logic
        );
end component;

    -- Ports
    signal done_mux  :  std_logic;
	signal addr_mux  :  std_logic_vector(PROGRAM_COUNTER_BITS - 1 downto 0);
    signal pc_in     :  std_logic_vector (PROGRAM_COUNTER_BITS - 1 downto 0);
    signal inst_reg  :  std_logic_vector (INSTRUCTION_REGISTER_BITS - 1 downto 0);
    signal pc_out    :  std_logic_vector (PROGRAM_COUNTER_BITS - 1 downto 0);
   
    signal done_alu  :  std_logic;
    signal opcode    :  std_logic_vector (OPCODE_BITS - 1 downto 0);
    signal rd        :  std_logic_vector (RD_BITS - 1 downto 0);
    signal rs        :  std_logic_vector (RS_BITS - 1 downto 0);
    signal rt        :  std_logic_vector (RT_BITS - 1 downto 0);
    signal const     :  std_logic_vector (CONSTANT_BITS - 1 downto 0);
  
    signal clock     :  std_logic;
    signal reset     :  std_logic;

begin

    UUT : decoder
        port map (
            done_mux  => done_mux,
			addr_mux => addr_mux,
            pc_in     => pc_in,
            inst_reg  => inst_reg,
            pc_out    => pc_out,
            done_alu  => done_alu,
            opcode  => opcode,
            rd  => rd,
            rs  => rs,
            rt  => rt,
            const  => const,
            clock  => clock,
            reset  => reset 
            );
 
    clock_p : process
        begin
        clock <= '0';
            wait for 20 ns;
            clock <= '1';
            wait for 20 ns;
    end process;   

  
    -- stimulus generation process
    stim_p : process
    begin
        
        reset <= '1';
        done_mux <= '0';
        done_alu <= '0';
        inst_reg <= "00000000111111000000101010110011";
        wait for 15 ns;
        reset <= '0';
        done_mux <= '1';
        wait for 30 ns;

        wait for 30 ns;
        done_alu <= '1';
        pc_in <= "00000000000000001000000000000000";
        wait for 30 ns;
        done_mux <= '1';
        wait for 30 ns;
        done_mux <= '0';
        wait for 30 ns;
        
        wait for 30 ns;
        done_mux <= '1';
        wait for 30 ns;
        inst_reg <= "00100000111111000000101010110011";
        done_mux <= '0';
        wait for 30 ns;
        done_mux <= '1';
        wait;    
    end process;
end bench;
  
