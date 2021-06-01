----------------------------------------------------------------------------------
-- Company:
-- Engineer:        Egor
--
-- Design Name:     MALT
-- Module Name:     core_tb
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:     Testbench for MB-Lite core without memories
--
-- Dependencies:
--
--
----------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library mblite;
    use mblite.core_Pkg.all;
    use mblite.std_Pkg.all;

entity core_tb is
end core_tb;


architecture arch of core_tb is

signal dmem_out         : dmem_out_type;
signal dmem_in          : dmem_in_type;

signal imem_out         : imem_out_type;
signal imem_in          : imem_in_type;

signal sys_clk          : std_logic := '0';
signal sys_rst          : std_logic := '1';

begin


------------------------------------------------------
-- Generate clock and reset
------------------------------------------------------

sys_clk <= not sys_clk after 5 ns;              -- emulate 100 MHz frequency
sys_rst <= '1' after 0 ns, '0' after 100 ns;    -- emulate 100 ns active-high reset

------------------------------------------------------
-- Data memory
------------------------------------------------------

dmem_in.ena_i <= '1';
dmem_in.dat_i <= (others => '0');

-- Process to check for expected dmem behavior from core
process(sys_clk)
    variable cnt : std_logic_vector(31 downto 0);
begin
    if Rising_edge(sys_clk) then
        if (sys_rst = '1') then
            cnt := (others => '0');
        else
            if (dmem_out.ena_o = '1') and (dmem_out.we_o = '1') then
            
                if (dmem_out.adr_o = cnt) and (dmem_out.dat_o = cnt) then
                    report "Core dmem write OK";
                    cnt := cnt + 4;
                else
                    report "Core dmem write error!";
                end if;
            
            end if;
        end if;
    end if;
end process;

------------------------------------------------------
-- Instruction memory
------------------------------------------------------

imem_in.ena_i <= '1';

process(sys_clk)
begin
    if Rising_edge(sys_clk) then
        
        case imem_out.adr_o is
        
            when X"00000000" =>
                imem_in.dat_i <= X"01400000";   -- add	r10, r0, r0
            when X"00000004" =>
                imem_in.dat_i <= X"21600004";   -- addi	r11, r0, 4
            when X"00000008" =>
                imem_in.dat_i <= X"d94a0000";   -- sw	r10, r10, r0
            when X"0000000C" =>
                imem_in.dat_i <= X"b810fffc";   -- brid	-4
            when X"00000010" =>
                imem_in.dat_i <= X"014a5800";   -- add	r10, r10, r11
            when others =>
                imem_in.dat_i <= X"80000000";   -- nop
                
        end case;
        
    end if;
end process;

------------------------------------------------------
-- MB-Lite core
------------------------------------------------------

mbl_core : core
    port map (
        imem_o      => imem_out,
        dmem_o      => dmem_out,
        imem_i      => imem_in,
        dmem_i      => dmem_in,
        int_i       => '0',
        int_ack_o   => open,
        rst_i       => sys_rst,
        clk_i       => sys_clk
    );


end arch;
