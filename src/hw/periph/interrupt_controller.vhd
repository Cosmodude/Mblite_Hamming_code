----------------------------------------------------------------------------------
-- Company: 
-- Engineer:       Tasha
-- 
-- Create Date:    17:49:38 10/01/2011 
-- Design Name: 
-- Module Name:    control_interrupt - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity control_interrupt is
    Port ( clk_i : in  STD_LOGIC;
           rst_i : in  STD_LOGIC;
           int0_i : in  STD_LOGIC;
           int1_i : in  STD_LOGIC;
           int2_i : in  STD_LOGIC;
           int3_i : in  STD_LOGIC;
           int_ack_i : in  STD_LOGIC;
           int_o : out  STD_LOGIC;
           int_num_o : out  STD_LOGIC_VECTOR (1 downto 0));
end control_interrupt;

architecture Behavioral of control_interrupt is

 type state_type is (st0, st1, st_wt); 
   signal state: state_type; 
   signal sig_ack,sig_0,k1i, k2i, k3i, sig_acki, k4i, k1,k2,k3,k4, k11,k22,k33,k44: std_logic;
   signal k : std_logic_vector( 3 downto 0);

begin

k<=k11&k22&k33&k44;


process(clk_i , rst_i)

begin

    if rst_i='1' then
	
        k1i<='0';
        k2i<='0';
        k3i<='0';
        k4i<='0';
        sig_acki<='0';

    elsif( rising_edge(clk_i) ) then
        
	
        sig_acki<=  not int_ack_i;
        k1i<= not int0_i;
        k2i<=not int1_i;
        k3i<=not int2_i;
        k4i<=not int3_i;
		

		

	end if;
	
end process;

sig_ack<=( sig_acki)and( int_ack_i);

k1<=( int0_i)and ( k1i);
k2<=( int1_i) and( k2i);
k3<=( int2_i)and( k3i);
k4<=( int3_i)and  ( k4i);








process(clk_i, rst_i )
begin

    if rst_i='1' then
   
        int_num_o<="00";
        int_o<='0';
        k11<='0';
        k22<='0';
        k33<='0';
        k44<='0';
        state<=st0;

    elsif(rising_edge(clk_i)) then
                
        if k1='1' then k11<='1'; end if;
        if k2='1' then k22<='1'; end if;
        if k3='1' then k33<='1'; end if;
        if k4='1' then k44<='1'; end if;
	

	
        case state is     
			
		    when st0 =>
            
                int_o<='0';   
                int_num_o<="00";
                
                if ((k11)or(k22)or(k33)or(k44))='1' then
                
                    state<=st1;
				
			    end if;	
                    
            when st1=> 
            
                int_o<='1';
			
			    case k is 
			   
                    when "1000"|"1100"|"1010"|"1110"|"1111" =>  int_num_o<="00"; k11<='0';  
                    when "0100"|"0110"|"0101"|"0111"        =>  int_num_o<="01"; k22<='0';
                    when "0010"|"0011"                      =>  int_num_o<="10"; k33<='0';
                    when "0001"                             =>  int_num_o<="11"; k44<='0';
                    when others                             =>  null;
				
			    end case;

			
	            state<=st_wt;
	     
		    when st_wt=>
            
                if sig_ack='1' then
                
                    state<=st0;
                    
                end if;
		
			when others =>
            
                state <= st0;
				
		end case; 
			
	
    end if;
	
end process; 


end Behavioral;

