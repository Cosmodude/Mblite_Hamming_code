library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

library mblite;
    use mblite.config_Pkg.all;
    use mblite.core_Pkg.all;
    use mblite.std_Pkg.all;

entity mblite_top is
    generic ( 
        CORE_NUM : integer := 0		
    );
    port (
        sys_clk_i    : in std_logic;
        sys_rst_i    : in std_logic;
        
        -- UART
        sys_rx_i     : in std_logic;
        sys_tx_o     : out std_logic
    );			
end mblite_top;

architecture arch of mblite_top is

signal dmem_out : dmem_out_type;
signal dmem_in  : dmem_in_type;
signal imem_out : imem_out_type;
signal imem_in  : imem_in_type;
signal s_dmem_out   : dmem_out_array_type(CFG_NUM_SLAVES - 1 downto 0);
signal s_dmem_in    : dmem_in_array_type(CFG_NUM_SLAVES - 1 downto 0);

signal sys_int  : std_logic; 

begin

-- Peripherals
periph : entity work.Master_peripherals
    port map (
        clk_i           => sys_clk_i,
        rst_i           => sys_rst_i,
    
        dmem_in_o       => s_dmem_in(1),
        dmem_out_i      => s_dmem_out(1),
    
        interrupt_o     => sys_int,
        ext_interrupt_i => '0'
    );

-- Memory
ram : entity work.lram_to_mem 
    generic map (
        MEM_SIZE    => 16
    )    
    port map (
        clk_i               => sys_clk_i,
        rst_i               => sys_rst_i,
        imem_out_i          => imem_out,
        imem_in_o           => imem_in,
        dmem_in_o           => s_dmem_in(0),
        dmem_out_i          => s_dmem_out(0)
    );

-- UART
io : entity work.IO_unit 
    port map (
        clk_i       => sys_clk_i,
        rst_i       => sys_rst_i,
        
        dmem_in_o   => s_dmem_in(2),
        dmem_out_i  => s_dmem_out(2),
        
        int_rx_o    => open,
        txd_pad_o   => sys_tx_o,
        rxd_pad_i   => sys_rx_i
    );       

-- Memory address decoder
decoder : entity mblite.core_address_decoder 
    generic map
    (
        G_NUM_SLAVES => CFG_NUM_SLAVES
    )
    port map
    (
        m_dmem_i => dmem_in,
        s_dmem_o => s_dmem_out,
        m_dmem_o => dmem_out,
        s_dmem_i => s_dmem_in,
        clk_i    => sys_clk_i
    );
    
-- MB-Lite cpu core
cpu : core port map
    (
        imem_o => imem_out,
        dmem_o => dmem_out,
        imem_i => imem_in,
        dmem_i => dmem_in,
        int_i  => sys_int,
        rst_i  => sys_rst_i,
        clk_i  => sys_clk_i
    );

end arch;
