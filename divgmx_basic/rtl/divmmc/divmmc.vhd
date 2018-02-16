-------------------------------------------------------------------------------
-- DivMMC
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity divmmc is
port (
	I_CLK			: in std_logic;
	I_CS 			: in std_logic;
	I_RESET			: in std_logic;
	I_ADDR			: in std_logic_vector(15 downto 0);
	I_DATA			: in std_logic_vector(7 downto 0);
	O_DATA			: out std_logic_vector(7 downto 0);
	I_WR_N			: in std_logic;
	I_RD_N			: in std_logic;
	I_IORQ_N		: in std_logic;
	I_MREQ_N		: in std_logic;
	I_M1_N			: in std_logic;
	I_RFSH_N		: in std_logic;

	-- divmmc related
	O_E3REG			: out std_logic_vector(7 downto 0);
	O_BANK         : out std_logic_vector(5 downto 0);
	O_AMAP			: out std_logic;
	O_CONMEM       : out std_logic;
	
	-- SD
	O_CS_N			: out std_logic;
	O_SCLK			: out std_logic;
	O_MOSI			: out std_logic;
	I_MISO			: in std_logic);
end divmmc;

architecture rtl of divmmc is

 signal BANK         : std_logic_vector(5 downto 0) := "000000";
 signal CONMEM       : std_logic := '0';
 signal MAPRAM       : std_logic := '0';
 signal MAPCOND      : std_logic := '0';
 signal AUTOMAP      : std_logic := '0';
 
 signal counter		:	unsigned(3 downto 0) := "1111";
 -- Shift register has an extra bit because we write on the
 -- falling edge and read on the rising edge
 signal shift_reg	:	std_logic_vector(8 downto 0) := "111111111";
 signal in_reg		:	std_logic_vector(7 downto 0) := "11111111";
 signal reg_e3    : std_logic_vector(7 downto 0) := "00000000";
	
begin

process(I_CLK, I_RESET, I_CS, I_MREQ_N, I_M1_N, I_ADDR, MAPCOND, I_IORQ_N, I_WR_N)
begin
        if I_RESET = '1' then
            O_CS_N <= '1';
		  elsif (I_CS = '0') then
				O_CS_N <= '1';
				MAPCOND <= '0';
				MAPRAM <= '0';
				AUTOMAP <= '0';
				BANK <= (others => '0');
				reg_e3 <= (others => '0');
        elsif rising_edge(I_CLK) then
				if I_MREQ_N = '0' then
                if I_M1_N = '0' and I_ADDR(15 downto 3) = "0001111111111" then
                    MAPCOND <= '0';
                elsif (I_M1_N = '0' and (I_ADDR = X"0000" or I_ADDR = X"0008" or I_ADDR = X"0038" or I_ADDR = X"0066" or I_ADDR = X"04C6" or I_ADDR = X"0562")) or (I_M1_N = '0' and I_ADDR(15 downto 8) = X"3D") then
                    MAPCOND <= '1';
                end if;
                if MAPCOND = '1' or (I_M1_N = '0' and I_ADDR(15 downto 8) = X"3D") then
                    AUTOMAP <= '1';
                else
                    AUTOMAP <= '0';
                end if;
            end if;
				
            if I_IORQ_N = '0' and I_WR_N = '0' then
                if I_ADDR(7 downto 0) = X"E7" then               -- Port #E7
                    O_CS_N <= I_DATA(0);
                elsif I_ADDR(7 downto 0) = X"E3" then            -- Port #E3
                    BANK <= I_DATA(5 downto 0);
                    CONMEM <= I_DATA(7);
                    MAPRAM <= I_DATA(6) or MAPRAM;
						  reg_e3 <= I_DATA;
					 end if;
            end if;
        end if;
end process;

sd_card : process(I_CLK, I_RESET, I_CS, counter, I_IORQ_N, I_ADDR, I_WR_N)
begin
        if I_RESET = '1' or I_CS = '0' then
            shift_reg <= (others => '1');
            in_reg <= (others => '1');
            counter <= "1111"; -- Idle
        elsif rising_edge(I_CLK) then
            if counter = "1111" then
                in_reg <= shift_reg(7 downto 0);
                if I_IORQ_N = '0' and I_ADDR(7 downto 0) = X"EB" then
                    if I_WR_N = '1' then
                        shift_reg <= (others => '1');
                    else
                        shift_reg <= I_DATA & '1';
                    end if;
                    counter <= "0000";
                end if;
            else
                counter <= counter + 1;
                if counter(0) = '0' then
                    shift_reg(0) <= I_MISO;
                else
                    shift_reg <= shift_reg(7 downto 0) & '1';
                end if;
            end if;
        end if;
end process;

O_SCLK <= counter(0);
O_MOSI <= shift_reg(8);
O_DATA <= in_reg;

O_AMAP <= AUTOMAP;
O_E3REG <= reg_e3;
O_BANK <= BANK;
O_CONMEM <= CONMEM;

end rtl;