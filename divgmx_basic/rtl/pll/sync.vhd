library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sync_with_edge_detect is
    port
    ( 
        clock               : in std_logic;
        async_in            : in std_logic;
        
        sync_out            : out std_logic;
        rising_edge_tick    : out std_logic;
        falling_edge_tick   : out std_logic
    );
end sync_with_edge_detect;

architecture Behavioral of sync_with_edge_detect is
    
    -- *** SYNCHRONIZER FLIPFLOPS ***
    signal sync_ffs : std_logic_vector(1 downto 0) := (others => '0');
    
    --attribute ASYNC_REG : string;
    --attribute ASYNC_REG of sync_ffs : signal is "true";
    
    -- *** EDGE DETECT FLIPFLOP ***
    signal edge_detect_ff : std_logic := '0';
    
begin

    process (clock)
    begin
        if rising_edge(clock) then
            sync_ffs(0) <= async_in;
            sync_ffs(1) <= sync_ffs(0);
        end if;
    end process;

    sync_out <= sync_ffs(1);
    
    process (clock)
    begin
        if rising_edge(clock) then
            edge_detect_ff <= sync_ffs(1);
        end if;
    end process;
    
    -- edge detect
    rising_edge_tick <= (not edge_detect_ff) and sync_ffs(1);
    falling_edge_tick <= edge_detect_ff and (not sync_ffs(1));
    
end Behavioral;