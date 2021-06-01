----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Egor
--
-- Design Name:    
-- Module Name:    IO_unit
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:    Module for IO (UART)
--
-- Dependencies: 
--      fifo.vhd
--
--      rs232-rx.vhd
--      rs232-tx.vhd
--      periph_utils.vhd
--      !OR!
--      sim_stdio.vhd
----------------------------------------------------------------------------------
library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;
    
library mblite;	
	use mblite.core_Pkg.all;	
	use mblite.config_Pkg.all;	

entity IO_unit is
    generic (
        UART_BAUDRATE   : integer := 19200;         -- Baud rate of UART-port
        FREQ            : integer := SYSTEM_FREQ    -- Frequency of br_clk_i in MHz
    );
    port (
        clk_i       : in  std_logic;        -- Main clock
        rst_i       : in  std_logic;        -- Reset signal
        
        dmem_in_o   : out dmem_in_type;     -- MB-Lite memory in interface
        dmem_out_i  : in  dmem_out_type;    -- MB-Lite memory out interface
        
        int_rx_o    : out std_logic;        -- Receive interrupt - byte received
        txd_pad_o   : out std_logic;        -- Tx RS-232 Line
        rxd_pad_i   : in  std_logic         -- Rx RS-232 Line 
    );       
end IO_unit;


architecture Behaviour of IO_unit is

component Counter
    generic(COUNT: INTEGER range 0 to 65535); -- Count revolution
    port (
        Clk      : in  std_logic;  -- Clock
        Reset    : in  std_logic;  -- Reset input
        CE       : in  std_logic;  -- Chip Enable
        O        : out std_logic   -- Output
    );   
end component;

component RxUnit
    port (
        Clk    : in  std_logic;  -- system clock signal
        Reset  : in  std_logic;  -- Reset input
        Enable : in  std_logic;  -- Enable input
        ReadA  : in  Std_logic;  -- Async Read Received Byte
        RxD    : in  std_logic;  -- RS-232 data input
        RxAv   : out std_logic;  -- Byte available
        DataO  : out std_logic_vector(7 downto 0) -- Byte received
    ); 
end component;

component TxUnit
    port (
        Clk    : in  std_logic;  -- Clock signal
        Reset  : in  std_logic;  -- Reset input
        Enable : in  std_logic;  -- Enable input
        LoadA  : in  std_logic;  -- Asynchronous Load
        TxD    : out std_logic;  -- RS-232 data output
        Busy   : out std_logic;  -- Tx Busy
        DataI  : in  std_logic_vector(7 downto 0) -- Byte to transmit
    ); 
end component;


component Sim_StdIO is 
    port (
        clk_i           : in  std_logic;
        data_o          : out std_logic_vector(7 downto 0);
        data_i          : in  std_logic_vector(7 downto 0);
        to_output_i     : in  std_logic;
        input_ready_o   : out std_logic
    );
end component;



component FIFO is
    generic(
        N: integer := 3;    -- number of address bits for 2**N address locations
        M: integer := 5     -- number of data bits to/from FIFO
    ); 
    port (
        clk     : in std_logic; 
        push    : in std_logic;
        pop     : in std_logic; 
        init    : in std_logic;
        din     : in std_logic_vector(N-1 downto 0);
        dout    : out std_logic_vector(N-1 downto 0);
        full    : out std_logic; 
        empty   : out std_logic; 
        nopush  : out std_logic; 
        nopop   : out std_logic
    );
end component;

signal RxData : std_logic_vector(7 downto 0);   -- Last Byte received
signal TxData : std_logic_vector(7 downto 0);   -- Last bytes transmitted
signal SReg   : std_logic_vector(7 downto 0);   -- Status register
signal EnabRx : std_logic;                      -- Enable Rx unit
signal EnabTx : std_logic;                      -- Enable Tx unit
signal RxAv   : std_logic;                      -- Data Received
signal TxBusy : std_logic;                      -- Transmiter Busy
signal ReadA  : std_logic;                      -- Async Read receive buffer
signal LoadA  : std_logic;                      -- Async Load transmit buffer

constant BRDIVISOR : integer := FREQ * 1000000 / 4 / UART_BAUDRATE;

signal Enable_dmem : std_logic;                                 -- Core enable signal

constant FIFO_SIZE          : positive := 8;                    -- Size of Tx FIFO
signal tx_fifo_i_data       : std_logic_vector(7 downto 0);     -- Tx FIFO input data
signal tx_fifo_o_data       : std_logic_vector(7 downto 0);     -- Tx FIFO output data
signal tx_fifo_we           : std_logic;                        -- Tx FIFO write enable
signal tx_fifo_re           : std_logic;                        -- Tx FIFO read enable
signal tx_fifo_empty        : std_logic;                        -- Tx FIFO empty
signal tx_fifo_full         : std_logic;                        -- Tx FIFO full
signal fifo_4byte_write     : std_logic_vector(2 downto 0);     -- State of 4-byte write to FIFO
 
 
begin

RS232_IO : if SIMULATION = False generate

    Uart_Rxrate : Counter -- Baud Rate adjust
        generic map (COUNT => BRDIVISOR) 
        port map (
            Clk     => clk_i, 
            Reset   => '0', 
            CE      => '1', 
            O       => EnabRx
        ); 
        
        
    Uart_Txrate : Counter -- 4 Divider for Tx
        generic map (COUNT => 4)  
        port map (
            Clk     => clk_i, 
            Reset   => '0', 
            CE      => EnabRx,
            O       => EnabTx
        );
  
  
    Uart_TxUnit : TxUnit 
        port map (
            Clk     => clk_i, 
            Reset   => rst_i, 
            Enable  => EnabTX, 
            LoadA   => LoadA, 
            TxD     => txd_pad_o, 
            Busy    => TxBusy, 
            DataI   => TxData
        );
 
 
    Uart_RxUnit : RxUnit 
        port map (
            Clk     => clk_i, 
            Reset   => rst_i, 
            Enable  => EnabRX, 
            ReadA   => ReadA, 
            RxD     => rxd_pad_i, 
            RxAv    => RxAv, 
            DataO   => RxData
        );
        
end generate;   
    
SIMULATION_IO : if SIMULATION = True generate

    TxBusy <= '0';
    txd_pad_o <= '1';
    
    Sim_console : Sim_StdIO 
        port map (
            clk_i           => clk_i,
            data_o          => RxData,
            data_i          => TxData,
            to_output_i     => LoadA,
            input_ready_o   => RxAv
        );
        
end generate;    


Tx_FIFO : FIFO
    generic map(
        N => FIFO_SIZE, -- number of address bits for 2**N address locations
        M => 8          -- number of data bits to/from FIFO
    ) 
    port map(
        clk     => clk_i,
        push    => tx_fifo_we,
        pop     => tx_fifo_re, 
        init    => rst_i,
        din     => tx_fifo_i_data,
        dout    => tx_fifo_o_data,
        full    => tx_fifo_full,
        empty   => tx_fifo_empty,
        nopush  => open,
        nopop   => open
    );
    
    
         
int_rx_o <= RxAv;

SReg <= (2 => tx_fifo_full, 1 => RxAv, 0 => (not TxBusy), others => '0');

dmem_in_o.ena_i <= Enable_dmem;


-- Implements MB-Lite dmem service registers.
REG_CONTROL: process(clk_i, rst_i, dmem_out_i.ena_o)
begin
    if Falling_Edge(clk_i) then
        if (rst_i = '1') then
            ReadA <= '0';
            LoadA <= '0';
            Enable_dmem <= '1';                 -- core enabled
            tx_fifo_we <= '0';
            tx_fifo_re <= '0'; 
            fifo_4byte_write <= "000";
        else
        
            LoadA <= '0';
            ReadA <= '0';
            tx_fifo_we <= '0';
            
            if tx_fifo_re = '1' then
                TxData <= tx_fifo_o_data;
                LoadA <= '1';               -- if smth is read from FIFO - write it to Tx
                tx_fifo_re <= '0';
            elsif (dmem_out_i.ena_o or TxBusy or tx_fifo_empty ) = '0' then 
                tx_fifo_re <= '1';          -- if transmitter is free - read FIFO for data
            end if;  

            if (dmem_out_i.ena_o and Enable_dmem) = '1' then        -- register access 
                if dmem_out_i.we_o = '1' then                       -- write to register
                    case dmem_out_i.adr_o(3 downto 2) is
                        when "00" =>                                -- write byte to Tx FIFO
                            tx_fifo_i_data <= dmem_out_i.dat_o(7 downto 0);
                            tx_fifo_we <= '1';                      -- write data to be transmitted to Tx FIFO
                        when others => null;
                    end case;
                else                                                -- read from register
                    case dmem_out_i.adr_o(3 downto 2) is
                        when "00" =>                                -- read from Rx register
                            dmem_in_o.dat_i(7 downto 0) <= RxData;
                            dmem_in_o.dat_i(31 downto 8) <= (others => '0');
                            ReadA <= '1';
                        when "01" =>                                -- read from UART status register
                            dmem_in_o.dat_i(7 downto 0) <= SReg;
                            dmem_in_o.dat_i(31 downto 8) <= (others => '0');
                        when others => null;
                    end case;
                end if;         
            end if;
        end if;
    end if; 
end process;

  
end Behaviour;
