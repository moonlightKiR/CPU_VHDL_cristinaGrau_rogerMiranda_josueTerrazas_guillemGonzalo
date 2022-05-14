library ieee;
use ieee.std_logic_1164.all;

-- https://stackoverflow.com/a/28514135/9178470
package bus_multiplexer_pkg is
        type bus_array is array(natural range <>) of std_logic_vector;
end package;