library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity memory_tb is
end;

architecture bench of memory_tb is
    component memory
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
    end component;

    signal WADDR    : std_logic_vector(31 downto 0);
    signal WAVALID  : std_logic;
    signal WDATA    : std_logic_vector(31 downto 0);
    signal WDATAV   : std_logic;
    signal WRESP    : std_logic_vector(1 downto 0);
    signal WRESPV   : std_logic;

    signal RADDR    : std_logic_vector(31 downto 0);
    signal RAVALID  : std_logic;
    signal RDATA    : std_logic_vector(31 downto 0);
    signal RDATAV   : std_logic;
    signal RRESP    : std_logic_vector(1 downto 0);

    signal clock    : std_logic := '0';
    signal reset    : std_logic;
	
	constant CLK_PERIOD : time := 10ns;

    begin
        memory_inst : memory
            port map (
                
                WADDR => WADDR,
                WAVALID => WAVALID,
                WDATA => WDATA,
                WDATAV => WDATAV,
                WRESP => WRESP,
                WRESPV => WRESPV,

                RADDR => RADDR,
                RAVALID => RAVALID,
                RDATA => RDATA,
                RDATAV => RDATAV,
                RRESP => RRESP,

                clock => clock,
                reset => reset
            );

        clock <= not clock after CLK_PERIOD/2;
        
        stims_process: process
        begin
            reset <= '1';
            wait for 10 ns;
            reset <= '0';
            
            -- Write
            for i in 0 to 4 loop
            
                WADDR <= std_logic_vector(to_unsigned(i,32));
                WDATA <= std_logic_vector(to_unsigned(i+1,32));
                wait for 100 ns;
                WDATAV <= '1';
                WAVALID <= '1';
                wait for 100 ns;
                WDATAV <= '0';
                WAVALID <= '0';
            
            end loop;

            -- Read
            for i in 0 to 4 loop
            
                RADDR <= std_logic_vector(to_unsigned(i,32));
                RDATA <= std_logic_vector(to_unsigned(i+1,32));
                wait for 100 ns;
                RAVALID <= '1';
                wait for 100 ns;
                WAVALID <= '0';
            
            end loop;
			
			wait;
            
        end process;
end;