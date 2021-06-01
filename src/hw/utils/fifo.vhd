library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.std_logic_unsigned.all;
    

entity FIFO_LOGIC is
    generic (N: integer := 3);
    port (
        CLK, PUSH, POP, INIT    : in std_logic;
        ADD                     : out std_logic_vector(N-1 downto 0);
        FULL, EMPTY, WE, NOPUSH, NOPOP: out std_logic
    );
end entity FIFO_LOGIC;

architecture RTL of FIFO_LOGIC is

signal WPTR, RPTR: std_logic_vector(N-1 downto 0);
signal LASTOP: std_logic;
signal FULL_t, EMPTY_t : std_logic;

begin

FULL <= FULL_t;
EMPTY <= EMPTY_t;

SYNC: process (CLK) begin
    if (CLK'event and CLK = '1') then
        if (INIT = '1') then
            -- initialization --
            WPTR <= (others => '0');
            RPTR <= (others => '0');
            LASTOP <= '0';
        elsif (POP = '1' and EMPTY_t = '0') then -- pop --
            RPTR <= RPTR + 1;
            LASTOP <= '0';
        elsif (PUSH = '1' and FULL_t = '0') then -- push --
            WPTR <= WPTR + 1;
            LASTOP <= '1';
        end if;
    -- otherwise all Fs hold their value --
    end if;
end process SYNC;


COMB: process (PUSH, POP, WPTR, RPTR, LASTOP, FULL_t, EMPTY_t) 
begin
    -- full and empty flags --
    if (RPTR = WPTR) then
        if (LASTOP = '1') then
            FULL_t <= '1';
            EMPTY_t <= '0';
        else
            FULL_t <= '0';
            EMPTY_t <= '1';
        end if;
    else
        FULL_t <= '0';
        EMPTY_t <= '0';
    end if;

    -- address, write enable and nopush/nopop logic --
    if (POP = '0' and PUSH = '0') then -- no operation --
        ADD <= RPTR;
        WE <= '0';
        NOPUSH <= '0';
        NOPOP <= '0';
    elsif (POP = '0' and PUSH = '1') then -- push only --
        ADD <= WPTR;
        NOPOP <= '0';
        if (FULL_t = '0') then -- valid write condition --
            WE <= '1';
            NOPUSH <= '0';
        else
            -- no write condition --
            WE <= '0';
            NOPUSH <= '1';
        end if;
    elsif (POP = '1' and PUSH = '0') then -- pop only --
        ADD <= RPTR;
        NOPUSH <= '0';
        WE <= '0';
        if (EMPTY_t = '0') then -- valid read condition --
            NOPOP <= '0';
        else
            NOPOP <= '1';
            -- no red condition --
        end if;
    else
        -- push and pop at same time –
        if (EMPTY_t = '0') then
            -- valid pop --
            ADD <= RPTR;
            WE <= '0';
            NOPUSH <= '1';
            NOPOP <= '0';
        else
            ADD <= wptr;
            WE <= '1';
            NOPUSH <= '0';
            NOPOP <= '1';
        end if;
    end if;
    
end process COMB;


end architecture RTL;


library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;
    
library mblite;
    use mblite.std_pkg.all;

entity FIFO is
    generic(
        N: integer := 3;    -- number of address bits for 2**N address locations
        M: integer := 5     -- number of data bits to/from FIFO
    ); 
    port (
        CLK     : in std_logic; 
        PUSH    : in std_logic;
        POP     : in std_logic; 
        INIT    : in std_logic;
        DIN     : in std_logic_vector(M-1 downto 0);
        DOUT    : out std_logic_vector(M-1 downto 0);
        FULL    : out std_logic; 
        EMPTY   : out std_logic; 
        NOPUSH  : out std_logic; 
        NOPOP   : out std_logic
    );
end entity FIFO;

architecture FIFO_TOP of FIFO is
signal WE: std_logic;
signal A: std_logic_vector(N-1 downto 0);

component FIFO_LOGIC is
    generic (N: integer); -- number of address bits
    port (
        CLK, PUSH, POP, INIT: in std_logic;
        ADD: out std_logic_vector(N-1 downto 0);
        FULL, EMPTY, WE, NOPUSH, NOPOP: out std_logic
    );
end component FIFO_LOGIC;

component sram is 
generic
(
    WIDTH : positive := 32;
    SIZE  : positive := 16
);
port
(
    dat_o : out std_logic_vector(WIDTH - 1 downto 0);
    dat_i : in std_logic_vector(WIDTH - 1 downto 0);
    adr_i : in std_logic_vector(SIZE - 1 downto 0);
    wre_i : in std_logic;
    ena_i : in std_logic;
    clk_i : in std_logic
);
end component;

begin

FL: FIFO_LOGIC generic map (N)
port map (CLK, PUSH, POP, INIT, A, FULL, EMPTY, WE, NOPUSH, NOPOP);


FIFO_RAM : sram 
    generic map(
        WIDTH => M, 
        SIZE  => N
    )
    port map(
        clk_i => clk,
        ena_i => '1',
        dat_i => DIN, 
        adr_i => A, 
        wre_i => WE, 
        dat_o => DOUT
    );

    
end architecture FIFO_TOP;


