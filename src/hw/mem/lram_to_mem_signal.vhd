----------------------------------------------------------------------------------
-- Company:
-- Engineer:        Egor
--
-- Design Name:     MALT
-- Module Name:     lram_to_mem
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:     Memory residing on core without memory controler iface
--
-- Dependencies:
--
--
----------------------------------------------------------------------------------

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    use ieee.numeric_std.all;
    
library std;
    use std.textio.all;
    
library work;
    use work.std_logic_1164_additions.all;

library mblite;
    use mblite.core_pkg.all;
    use mblite.config_pkg.all;

library extras;
use extras.secded_edac.all;
use extras.hamming_edac.all;

entity lram_to_mem is
    generic (
        MEM_SIZE            : integer := 16
    );
    port (
        clk_i               : in  std_logic;
        rst_i               : in  std_logic;
        imem_out_i          : in  imem_out_type;
        imem_in_o           : out imem_in_type;
        dmem_in_o           : out dmem_in_type;
        dmem_out_i          : in  dmem_out_type
    );
end lram_to_mem;


architecture arch of lram_to_mem is

constant ABITS_g    : integer := MEM_SIZE-2;
constant WORD_WIDTH : integer := CFG_DMEM_SIZE;
 
signal rst_i_reg    : std_logic := '1'; 
signal local_we     : std_logic_vector(3 downto 0);

-------------------------------------------------------------------------Mine-------------------------------------------------------------------------------------------
constant WORD_MSG_SIZE : positive := secded_message_size(8);
type Ham_type is array (0 TO (2**ABITS_g)-1) of ecc_vector(7 downto -secded_parity_size(WORD_MSG_SIZE));
signal ham0, ham1, ham2, ham3 : Ham_type;
------------------------------------------------------------------------------------------------------------------------------------------------------------------



-- pragma translate_off
-- Init from txt file procedure
procedure read_from_file (file_name : string) IS

file data_file      : text open read_mode is file_name;
variable L          : line;
variable index_m    : natural := 0;
variable ok         : boolean;
variable data       : std_logic_vector(31 downto 0);

begin

    report "Simulation memory: starting read from init file..."
    severity note;
    
    while not endfile(data_file) loop
    
        readline(data_file, L);
        
        HREAD(L, data, ok);
        
        assert ok = True
        report "Error during LRAM initialization from file " & file_name
        severity failure;
        
        ham0(index_m) <= secded_encode(std_ulogic_vector(data(7 downto 0)));
        ham1(index_m) <= secded_encode(std_ulogic_vector(data(15 downto 8)));
        ham2(index_m) <= secded_encode(std_ulogic_vector(data(23 downto 16)));
        ham3(index_m) <= secded_encode(std_ulogic_vector(data(31 downto 24)));
        
        deallocate(L);

        index_m := index_m + 1;
        
    end loop;
    
    -- fill rest with zero value
    while index_m < (2**(MEM_SIZE))/4 loop
        ham0(index_m) <= (others => '0');
        ham1(index_m) <= (others => '0');
        ham2(index_m) <= (others => '0');
        ham3(index_m) <= (others => '0');
        
        index_m := index_m + 1;
    end loop;
    
    report "Simulation memory: init completed"
    severity note;

end read_from_file;
-- pragma translate_on


begin 


dmem_in_o.ena_i <= not rst_i_reg; -- Always on
imem_in_o.ena_i <= not rst_i_reg;


REG_PROC : process(clk_i)
begin
    if Rising_edge(clk_i) then
        
            rst_i_reg <= rst_i;
    end if;
end process;

DMEM_PROC : process(clk_i)
-- pragma translate_off
    variable inited : std_logic := '0';
-- pragma translate_on
begin
    if Falling_edge(clk_i) then
        if (rst_i = '1') then
            -- pragma translate_off
            if (inited = '0') then
                read_from_file(MEMINIT_PATH);
                inited := '1';
            end if;
            -- pragma translate_on
            null;
        else
            if (dmem_out_i.ena_o = '1') then
                if (dmem_out_i.we_o and dmem_out_i.sel_o(0)) = '1' then
                    ham0(to_integer(unsigned(dmem_out_i.adr_o(ABITS_g+1 downto 2)))) <= secded_encode(std_ulogic_vector(dmem_out_i.dat_o(7 downto 0)));
                end if;
                if (dmem_out_i.we_o and dmem_out_i.sel_o(1)) = '1' then
                    ham1(to_integer(unsigned(dmem_out_i.adr_o(ABITS_g+1 downto 2)))) <= secded_encode(std_ulogic_vector(dmem_out_i.dat_o(15 downto 8)));
                end if;
                if (dmem_out_i.we_o and dmem_out_i.sel_o(2)) = '1' then
                    ham2(to_integer(unsigned(dmem_out_i.adr_o(ABITS_g+1 downto 2)))) <= secded_encode(std_ulogic_vector(dmem_out_i.dat_o(23 downto 16)));
                end if;
                if (dmem_out_i.we_o and dmem_out_i.sel_o(3)) = '1' then
                    ham3(to_integer(unsigned(dmem_out_i.adr_o(ABITS_g+1 downto 2)))) <= secded_encode(std_ulogic_vector(dmem_out_i.dat_o(31 downto 24)));
                end if;
                dmem_in_o.dat_i <=  std_logic_vector(secded_decode(ham3(to_integer(unsigned(dmem_out_i.adr_o(ABITS_g+1 downto 2)))))) &
                                    std_logic_vector(secded_decode(ham2(to_integer(unsigned(dmem_out_i.adr_o(ABITS_g+1 downto 2)))))) &
                                    std_logic_vector(secded_decode(ham1(to_integer(unsigned(dmem_out_i.adr_o(ABITS_g+1 downto 2)))))) &
                                    std_logic_vector(secded_decode(ham0(to_integer(unsigned(dmem_out_i.adr_o(ABITS_g+1 downto 2))))));
            end if;
        end if;
    end if;
end process;


IMEM_PROC : process(clk_i)
begin
    if Rising_edge(clk_i) then
        if (rst_i = '0') then
            imem_in_o.dat_i <=  std_logic_vector(secded_decode(ham3(to_integer(unsigned(imem_out_i.adr_o(ABITS_g+1 downto 2)))))) &
                                std_logic_vector(secded_decode(ham2(to_integer(unsigned(imem_out_i.adr_o(ABITS_g+1 downto 2)))))) &
                                std_logic_vector(secded_decode(ham1(to_integer(unsigned(imem_out_i.adr_o(ABITS_g+1 downto 2)))))) &
                                std_logic_vector(secded_decode(ham0(to_integer(unsigned(imem_out_i.adr_o(ABITS_g+1 downto 2))))));
       end if;
    end if;
end process;

end architecture arch;
