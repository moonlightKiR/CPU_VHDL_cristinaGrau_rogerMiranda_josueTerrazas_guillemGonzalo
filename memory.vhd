library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory is
    port(
        -- WRITE
        WADDR   : in std_logic_vector(31 downto 0);
        WAVALID : in std_logic;
        WDATA   : in std_logic_vector(31 downto 0);
        WDATAV  : in std_logic;
        WRESP   : out std_logic_vector(1 downto 0);
        WRESPV  : out std_logic;
        -- READ
        RADDR   : in std_logic_vector(31 downto 0);
        RAVALID : in std_logic;
        RDATA   : out std_logic_vector(31 downto 0);
        RDATAV  : out std_logic;
        RRESP   : out std_logic_vector(1 downto 0);
        -- SYSTEM CLOCK
        clock  : in std_logic;
        reset  : in std_logic
    );
end entity;

architecture ararc_memory of memory is
    type state_type_write is (SW0, SW1, SW2, SW3);
    signal current_state_write, next_state_write : state_type_write;
	
    type state_type_read is (SR0, SR1, SR2, SR3);
    signal current_state_read, next_state_read : state_type_read;
	
    type memory_type is array (0 to 63) of std_logic_vector(31 downto 0);
    signal memory_system : memory_type;
    
  begin

    clock_p : process (clock, reset)
    begin
        if (reset = '1') then
            current_state_write <= SW0;
            current_state_read <= SR0;
        elsif (clock'event and clock = '1') then
            current_state_write <= next_state_write;
            current_state_read <= next_state_read;
        end if; 
    end process;
	
    write_process : process (current_state_write, WAVALID, WDATAV)
    begin
        case( current_state_write ) is
            when SW0 =>
                WRESPV <= '0';
                WRESP <= "00";
				
                if WAVALID = '1' and WDATAV = '1' then
                    next_state_write <= SW1;
                else
		            next_state_write <= SW0;
                end if;
            when SW1 => -- aqui miro si hay error de @
                
                if WADDR >= "00000000000000000000000001000000" then
                    WRESP <= "01";
					if WAVALID = '0' and WDATAV = '0' then
						next_state_write <= SW0;
					end if;
                else 
                    -- Aqui meter el dato en la RAM
                    memory_system(to_integer(unsigned(WADDR))) <= WDATA;
                    WRESP <= "00";
                    next_state_write <= SW2;
                end if;

            when SW2 =>
                WRESP <= "00";
                WRESPV <= '1';
				
                if WAVALID = '0' and WDATAV = '0' then
                    next_state_write <= SW0;
                end if;
                
            when others =>
                
        end case;
    end process;
	
    read_process : process ( current_state_read, RAVALID )
    begin
        case( current_state_read ) is
        
            when SR0 =>
                RDATAV <= '0';
				RRESP <= "00";
                
				if RAVALID = '1' then
                    next_state_read <= SR1;
                else
		            next_state_read <= SR0;
		        end if;
                
            when SR1 =>
                if RADDR >= "00000000000000000000000001000000" then
                    RRESP <= "01";
					if RAVALID = '0' then
						next_state_read <= SR0;
					end if;
                else   
                    -- Aqui meter el dato en la RAM
                    RDATA <= memory_system(to_integer(unsigned(RADDR)));
                    RRESP <= "00";
                    next_state_read <= SR2;
                end if;

            when SR2 =>
				RRESP <= "00";
                RDATAV <= '1';
				
				if RAVALID = '0' then
					next_state_read <= SR0;
				end if;
            
            when others =>
        
        end case;
    end process;
end ararc_memory;