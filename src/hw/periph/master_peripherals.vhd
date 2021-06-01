----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Egor
-- 
-- Create Date:    26/10/2011 
-- Design Name:    FMCP
-- Module Name:    Master_peripherals
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: Master peripherals live in this module
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 (26.10.2011) - File Created
-- Revision 0.5  (26.10.2011) - Real Time Clock and Interrupt Controller now reside here
--
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;
    use IEEE.std_logic_unsigned.all;


library mblite;
    use mblite.core_Pkg.all;
    use mblite.config_Pkg.all;

entity Master_peripherals is
    port (
        clk_i : in std_logic;
        rst_i : in std_logic;
    
        dmem_in_o  : out dmem_in_type;
        dmem_out_i : in  dmem_out_type;

        interrupt_o     : out std_logic;
        ext_interrupt_i : in  std_logic
    );
end Master_peripherals;

architecture Behavioral of Master_peripherals is

component control_interrupt is
    Port ( 
        clk_i       : in  std_logic;
        rst_i       : in  std_logic;
        int0_i      : in  std_logic;
        int1_i      : in  std_logic;
        int2_i      : in  std_logic;
        int3_i      : in  std_logic;
        int_ack_i   : in  std_logic;
        int_o       : out std_logic;
        int_num_o   : out std_logic_vector (1 downto 0)
    );
end component;


component RTC_counter is
    generic ( 
        FREQ : integer range 0 to 65535 := 100--frequency in MHz
    );
port (
    Clk_i           : in std_logic;    -- clock
    Reset_i         : in std_logic;  -- reset signal
    Enable_i        : in std_logic; -- chip enable
    Time_Int        : out std_logic;
    Microseconds_o  : out std_logic_vector (31 downto 0) --time in us
    );
end component; 

signal Enable_dmem      : std_logic;

signal Time_interrupt   : std_logic;

signal Interrupt_ack    : std_logic;
signal Interrupt_number : std_logic_vector(1 downto 0);

signal Cur_time         : std_logic_vector(31 downto 0);


begin

RTC_Clock : RTC_counter                 -- Real Time Clock component
	generic map ( FREQ => SYSTEM_FREQ )    -- frequency MHz
	port map (
      Clk_i     => clk_i,
	  Reset_i   => rst_i,
	  Enable_i  => '1',
	  Time_Int  => open,
	  Microseconds_o => Cur_time
    );
   
   
interrupt_controller : control_interrupt
    port map ( 
        clk_i       => clk_i,
        rst_i       => rst_i,
        int0_i      => Time_interrupt,
        int1_i      => ext_interrupt_i,
        int2_i      => '0',
        int3_i      => '0',
        int_ack_i   => Interrupt_ack,
        int_o       => interrupt_o,
        int_num_o   => Interrupt_number
    );

    
Time_interrupt <= '0';    
    
dmem_in_o.ena_i <= Enable_dmem;


REG_CONTROL : process (clk_i, rst_i, dmem_out_i.ena_o)     -- Peripherals registers

begin
    if Falling_Edge(clk_i) then
        if (rst_i = '1') then
            Enable_dmem <= '1';
            Interrupt_ack <= '0';
        else
        
            if Interrupt_ack = '1' then
                Interrupt_ack <= '1';
            end if;  
            
            if (dmem_out_i.ena_o = '1') and (Enable_dmem = '1') then      -- register access
                if dmem_out_i.we_o = '1' then                       -- write to register
                    case dmem_out_i.adr_o(3 downto 2) is
                        when "01" =>
                            Interrupt_ack <= '0';                   -- interrupt acknowlege register
                        when others => null;
                    end case;
                else                                                -- read from register
                    case dmem_out_i.adr_o(3 downto 2) is
                        when "00" =>                                -- current time
                            dmem_in_o.dat_i <= Cur_time;
                        when "01" =>                                -- number of last occured interrupt
                            dmem_in_o.dat_i(1 downto 0) <= Interrupt_number;
                            dmem_in_o.dat_i(31 downto 2) <= (others => '0');
                        when others => null;
                    end case;
                end if;
            end if;
        
        end if;    
    end if;

end process;


end Behavioral;

