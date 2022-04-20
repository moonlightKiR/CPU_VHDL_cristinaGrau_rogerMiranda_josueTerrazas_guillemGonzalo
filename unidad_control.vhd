library ieee;
use ieee.std_logic_1164.all; 
use ieee.numeric_std.all;

entity unidad_control is
  
  generic (
    PROGRAM_COUNTER_BITS : integer := 32;
    INSTRUCTION_REGISTER_BITS : integer : 32;
    OPCODE_BITS : integer := 4;
    REGISTER_BITS : integer := 16
  );
  
  port(
    
    --pins mux
    done_mux  : in std_logic;
    pc_in     : in std_logic_vector (PROGRAM_COUNTER_BITS - 1 downto 0);
    inst_reg  : in std_logic_vector (INSTRUCTION_REGISTER_BITS - 1 downto 0);
    pc_out    : out std_logic_vector (PROGRAM_COUNTER_BITS - 1 downto 0);

    --pins alu
    done_alu  : in std_logic;
    opcode    : out std_logic_vector (OPCODE_BITS - 1 downto 0);
    rd        : out std_logic_vector (REGISTER_BITS - 1 downto 0);
    rs        : out std_logic_vector (REGISTER_BITS - 1 downto 0);
    rt        : out std_logic_vector (REGISTER_BITS - 1 downto 0);
    const     : out std_logic_vector (REGISTER_BITS - 1 downto 0);
    --pins state machine
    clock     : in std_logic;
    reset     : in std_logic
  );
end entity;

architecture behavioral of unidad_control is
    type state_type is (STATE0, 
                        STATE1, 
                        STATE2, 
                        STATE3,
                        STATE4, 
                        STATE5, 
                        STATE6);

    signal current_state, next_state : state_type;

begin
    state_p : process (clock, reset)
        begin
            if (reset = '0') then
            current_state <= STATE0;
            elsif (clock'event and clock = '1') then
            current_state <= next_state;
            end if;
        end process;
        
    nxt_state_logic : process (done_alu, done_mux, current_state)
    begin
        case (current_state) is
            when STATE0 =>
                
            when STATE1 =>
        
            when STATE2 =>
                   
            when STATE3 =>

            when STATE4 =>
                
            when STATE5 =>
                
            when STATE6 =>
                
            when others =>
                next_state <= STATE0;
            end case;
    end process;
    
    output_logic : process (done_alu, done_mux, current_state)
    begin
        case (current_state) is
            when STATE0 =>
                    
            when STATE1 =>
                
            when STATE2 =>
                  
            when STATE3 =>
                
            when STATE4 =>
                   
            when STATE5 =>
               
            when STATE6 =>
               
            when others =>
                
            end case;
    end process;

end behavioral;