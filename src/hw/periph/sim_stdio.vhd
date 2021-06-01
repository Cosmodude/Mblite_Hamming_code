----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Egor
--
-- Design Name:    FMCP
-- Module Name:    Sim_StdIO
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    Performs IO in simulator console
--
-- Dependencies: 
--      std.textio
--
-- Revision: 
-- Revision 0.1 (13.11.2011) - Performs output to simulator console
--
----------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library mblite;
    use mblite.config_Pkg.all;
    use mblite.core_Pkg.all;
    use mblite.std_Pkg.all;

library std;
    use std.textio.all;

entity Sim_StdIO is 
    port (
        clk_i           : in  std_logic;
        data_o          : out std_logic_vector(7 downto 0);
        data_i          : in  std_logic_vector(7 downto 0);
        to_output_i     : in  std_logic;
        input_ready_o   : out std_logic
    );
end Sim_StdIO;

architecture arch of Sim_StdIO is

    
begin

input_ready_o <= '0';
data_o <= (others => '0');

-- Character device
stdio: process(clk_i, to_output_i, data_i)
    variable s    : line;
    variable char : character;
begin
    if Rising_edge(clk_i) then
        if to_output_i = '1' then
            char := character'val(my_conv_integer(data_i));
            if data_i = X"0D" then 
                null;                   -- Ignore character 13
            elsif data_i = X"0A" then       
                writeline(output, s);   -- Writeline on character 10 (newline)
            else
                write(s, char);         -- Write to buffer
            end if;
        end if;
    end if;
end process;
    
end arch;
