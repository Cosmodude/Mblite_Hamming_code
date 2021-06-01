----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Design Name: 
-- Module Name:    sim_top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
    use IEEE.STD_LOGIC_1164.ALL;

library mblite;
    use mblite.config_Pkg.all;
    use mblite.core_Pkg.all;
    use mblite.std_Pkg.all;

entity sim_top is
end sim_top;

architecture Behavioral of sim_top is

signal sys_clk  : std_logic := '0';
signal sys_rst  : std_logic := '1';

begin

sys_clk <= not sys_clk after 5 ns;
sys_rst <= '1' after 0 ns, '0' after 1 us;

mb0: entity work.mblite_top
    port map (
        sys_clk_i => sys_clk,
        sys_rst_i => sys_rst,
        sys_rx_i =>  '1',
        sys_tx_o =>  open
    );


end Behavioral;

