----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 		 Egor
-- 
-- Create Date:    15:08:46 03/02/2011 
-- Design Name:    Simple Real Time Clock
-- Module Name:    rtc_counter
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
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;


entity RTC_counter is
generic ( 
		FREQ : integer range 0 to 65535 := 100--frequency in MHz
			);
port (
      Clk_i : in std_logic;    -- clock
	  Reset_i : in std_logic;  -- reset signal
	  Enable_i : in std_logic; -- chip enable
	  Time_Int  : out std_logic;
	  Microseconds_o : out std_logic_vector (31 downto 0) --time in us
	  );
end RTC_counter;

architecture Behavioral of rtc_counter is

  component Counter
  generic(COUNT: INTEGER range 0 to 65535); -- Count revolution
  port (
     Clk      : in  std_logic;  -- Clock
     Reset    : in  std_logic;  -- Reset input
     CE       : in  std_logic;  -- Chip Enable
     O        : out std_logic); -- Output  
  end component;
  
signal Ms_passed : std_logic;  
signal Us_passed : std_logic;
signal Microseconds : std_logic_vector(31 downto 0);
  

begin

clock_count : Counter
	generic map (
		COUNT => FREQ
		)
	port map (
		Clk => Clk_i,
		Reset => Reset_i,
		CE => Enable_i,
		O => Us_passed
		);
		
ms_count : Counter
	generic map (
		COUNT => 1000
		)
	port map (
		Clk => Us_passed,
		Reset => Reset_i,
		CE => Enable_i,
		O => Ms_passed
		);		

--Time_int <= '0';
Microseconds_o <= Microseconds;

process (Ms_passed, Clk_i)
variable int_state : boolean;
begin
 if Reset_i = '1' then
  int_state:=false;
  Time_int <= '0';
 else if rising_edge(Clk_i) then
 
 if (Ms_passed = '1') then
  if (int_state = false) then
   Time_int <= '1';
   int_state:=true;
  else
   Time_int <= '0';
  end if;
 else
  int_state:=false;
 end if;
 end if;
 end if;
end process; 

   
		
tick_tock : process(Clk_i, Us_passed, Reset_i)
begin
    if Reset_i = '1' then
        Microseconds <= (others => '0');
    else
        if Rising_Edge(Clk_i) then
            if Us_passed = '1' then
                Microseconds <= std_logic_vector(unsigned(Microseconds) + 1);
            end if;
		end if;
    end if;
end process;

end Behavioral;

