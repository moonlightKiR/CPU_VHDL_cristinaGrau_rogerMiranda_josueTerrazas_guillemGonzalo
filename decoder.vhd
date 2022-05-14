library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity decoder is
  
  generic (
    PROGRAM_COUNTER_BITS : integer := 32;
    INSTRUCTION_REGISTER_BITS : integer := 32;
    OPCODE_BITS : integer := 4;
    RD_BITS : integer := 6;
    RS_BITS : integer := 6;
    RT_BITS : integer := 6;
    CONSTANT_BITS : integer := 8
  );
  
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
end entity;

architecture behavioral of decoder is
    type state_type is (STATE0, 
                        STATE1, 
                        STATE2, 
                        STATE3,
                        STATE4, 
                        STATE5);

    signal current_state, next_state : state_type;
	signal pc : std_logic_vector (PROGRAM_COUNTER_BITS - 1 downto 0);
begin
	pc_out <= pc;
	addr_mux <= pc;
	
    state_p : process (clock, reset)
        begin
            if (reset = '1') then
				current_state <= STATE0;
            elsif (clock'event and clock = '1') then
				current_state <= next_state;
            end if;
        end process;
        
    nxt_state_logic : process (done_alu, done_mux, current_state)
        begin
            case (current_state) is
                when STATE0 =>
                    if ( done_mux = '1') then
                        next_state <= STATE1;
                    else
                        next_state <= STATE0;
                    end if;           
                when STATE1 =>
                    next_state <= STATE2;
                when STATE2 =>
                    if ( done_alu = '1') then
                        next_state <= STATE3;
                    else 
                        next_state <= STATE2;
                    end if;
                when STATE3 =>
                    next_state <= STATE4;
                when STATE4 =>
                    if (done_mux = '0') then
                        next_state <= STATE5;
                    else 
                        next_state <= STATE4;
                    end if;
                when STATE5 =>
                    if (done_mux = '1') then
                        next_state <= STATE1;
                    else 
                        next_state <= STATE5;
                    end if;
                when others =>
                    next_state <= STATE0;
                end case;
        end process;
    
    output_logic : process (done_alu, done_mux, current_state, inst_reg)
    begin
        case (current_state) is
            when STATE0 => -- first-time configuration
				pc <= (others => '0');

            when STATE1 => -- decode what you've read
                opcode <= inst_reg(31 downto 28);
                rd <= inst_reg(23 downto 18);
                if (inst_reg(31 downto 28) = "1100") then
                    --R
                elsif ((inst_reg(31 downto 28) = "0110" OR inst_reg(31 downto 28) = "0111") OR inst_reg(31 downto 28) = "1000") then
                    --RR
                    rs <= inst_reg(11 downto 6);
                elsif (inst_reg(31 downto 28) = "0001") then
                    --RRImm
                    rs <= inst_reg(17 downto 12);
                    const <= inst_reg(7 downto 0);
                else
                    --RRR
                    rs <= inst_reg(11 downto 6);
                    rt <= inst_reg(5 downto 0);
                end if;    
				
            when STATE2 => -- wait the ALU to finish
                  
            when STATE3 => -- copy the next PC
                pc <= pc_in;
				
            when STATE4 => -- read signal not notified yet
			
            when STATE5 => -- wait for the next instruction

            when others =>
                
            end case;
    end process;

end behavioral;