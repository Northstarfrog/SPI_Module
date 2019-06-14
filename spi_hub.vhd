-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Description: SPI HUB
--
-------------------------------------------------------------------------------
-- VHDL Version: VHDL '93
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity spi_hub is
  port (
    clk_61      : in  std_logic;        -- 61.44MHz clock
    rst_61      : in  std_logic;        -- Reset signal with 61.44MHz

    h_spi_m_ss  : in  std_logic;        -- SPI chip select signal from controller
    h_spi_m_clk : in  std_logic;        -- SPI clock signal from controller
    h_spi_mosi  : in  std_logic;        -- SPI MOSI signal from controller
    h_spi_miso  : out std_logic;        -- SPI MISO signal from controller
    h_spi_m_dir : in  std_logic;        -- SPI direction indication signal from controller

    h_spi_ss       : out std_logic_vector(7 downto 0);  -- SPI chip select signal towards PIN
    h_spi_clk      : out std_logic_vector(7 downto 0);  -- SPI clock signal towards PIN
    h_spi_data_out : out std_logic_vector(7 downto 0);  -- SPI MOSI signal towards PIN
    h_spi_data_in  : in  std_logic_vector(7 downto 0);  -- SPI input signal for 3-wire SPI
    h_spi_data_oe  : out std_logic_vector(7 downto 0);  -- SPI output enable signal
    h_spi_miso_in  : in  std_logic_vector(7 downto 0);  -- SPI MISO towards PIN

    -- signals to register h_spi_SS
    h_spi_hub_ss_en      : in std_logic_vector(4 downto 0);     -- Chip select control signal
    -- signals to register h_spi_0
    h_spi_hub_0_port     : in std_logic_vector(2 downto 0);     -- Port number configuration
    h_spi_hub_0_clk_inv  : in std_logic;                        -- Clock polarity configuration
    h_spi_hub_0_ss_high  : in std_logic;                        -- select high/low
    h_spi_hub_0_four_w   : in std_logic;                        -- 3 wire/4 wire
    -- signals to register h_spi_1
    h_spi_hub_1_port     : in std_logic_vector(2 downto 0);     -- Port number configuration
    h_spi_hub_1_clk_inv  : in std_logic;                        -- Clock polarity configuration
    h_spi_hub_1_ss_high  : in std_logic;                        -- select high/low
    h_spi_hub_1_four_w   : in std_logic;                        -- 3 wire/4 wire
    -- signals to register h_spi_2
    h_spi_hub_2_port     : in std_logic_vector(2 downto 0);     -- Port number configuration
    h_spi_hub_2_clk_inv  : in std_logic;                        -- Clock polarity configuration
    h_spi_hub_2_ss_high  : in std_logic;                        -- select high/low
    h_spi_hub_2_four_w   : in std_logic;                        -- 3 wire/4 wire
    -- signals to register h_spi_3
    h_spi_hub_3_port     : in std_logic_vector(2 downto 0);     -- Port number configuration
    h_spi_hub_3_clk_inv  : in std_logic;                        -- Clock polarity configuration
    h_spi_hub_3_ss_high  : in std_logic;                        -- select high/low
    h_spi_hub_3_four_w   : in std_logic;                        -- 3 wire/4 wire
    -- signals to register h_spi_4
    h_spi_hub_4_port     : in std_logic_vector(2 downto 0);     -- Port number configuration
    h_spi_hub_4_clk_inv  : in std_logic;                        -- Clock polarity configuration
    h_spi_hub_4_ss_high  : in std_logic;                        -- select high/low
    h_spi_hub_4_four_w   : in std_logic;                        -- 3 wire/4 wire
    -- signals to register h_spi_5
    h_spi_hub_5_port     : in std_logic_vector(2 downto 0);     -- Port number configuration
    h_spi_hub_5_clk_inv  : in std_logic;                        -- Clock polarity configuration
    h_spi_hub_5_ss_high  : in std_logic;                        -- select high/low
    h_spi_hub_5_four_w   : in std_logic;                        -- 3 wire/4 wire
    -- signals to register h_spi_6
    h_spi_hub_6_port     : in std_logic_vector(2 downto 0);     -- Port number configuration
    h_spi_hub_6_clk_inv  : in std_logic;                        -- Clock polarity configuration
    h_spi_hub_6_ss_high  : in std_logic;                        -- select high/low
    h_spi_hub_6_four_w   : in std_logic;                        -- 3 wire/4 wire
    -- signals to register h_spi_7
    h_spi_hub_7_port     : in std_logic_vector(2 downto 0);     -- Port number configuration
    h_spi_hub_7_clk_inv  : in std_logic;                        -- Clock polarity configuration
    h_spi_hub_7_ss_high  : in std_logic;                        -- select high/low
    h_spi_hub_7_four_w   : in std_logic);                       -- 3 wire/4 wire
end spi_hub;

-------------------------------------------------------------------------------
-- Architecture for SPI HUB
-------------------------------------------------------------------------------

architecture rtl of spi_hub is

  -- Slave Select signals
  signal h_spi_ss_high        : std_logic_vector(7 downto 0);
  signal h_spi_ss_en_one_hot  : std_logic_vector(7 downto 0);
  signal h_spi_ss_active_high : std_logic_vector(7 downto 0);

  -- Enable signals
  signal h_spi_port         : std_logic_vector(2 downto 0);
  signal h_spi_port_one_hot : std_logic_vector(7 downto 0);
  signal h_spi_hub_four_w   : std_logic;

  -- Clock signals
  signal h_spi_clk_inv  : std_logic;
  signal h_spi_m_clk_in : std_logic;
  signal h_spi_miso_en  : std_logic_vector(7 downto 0);

begin  -- rtl

---------------------------------------------------------------
-- SPI slave select
---------------------------------------------------------------
  h_spi_ss_high(0)  <= h_spi_hub_0_ss_high;
  h_spi_ss_high(1)  <= h_spi_hub_1_ss_high;
  h_spi_ss_high(2)  <= h_spi_hub_2_ss_high;
  h_spi_ss_high(3)  <= h_spi_hub_3_ss_high;
  h_spi_ss_high(4)  <= h_spi_hub_4_ss_high;
  h_spi_ss_high(5)  <= h_spi_hub_5_ss_high;
  h_spi_ss_high(6)  <= h_spi_hub_6_ss_high;
  h_spi_ss_high(7)  <= h_spi_hub_7_ss_high;

  h_spi_ss_en_one_hot(0)  <= '1' when (h_spi_hub_ss_en = "00000") else '0';
  h_spi_ss_en_one_hot(1)  <= '1' when (h_spi_hub_ss_en = "00001") else '0';
  h_spi_ss_en_one_hot(2)  <= '1' when (h_spi_hub_ss_en = "00010") else '0';
  h_spi_ss_en_one_hot(3)  <= '1' when (h_spi_hub_ss_en = "00011") else '0';
  h_spi_ss_en_one_hot(4)  <= '1' when (h_spi_hub_ss_en = "00100") else '0';
  h_spi_ss_en_one_hot(5)  <= '1' when (h_spi_hub_ss_en = "00101") else '0';
  h_spi_ss_en_one_hot(6)  <= '1' when (h_spi_hub_ss_en = "00110") else '0';
  h_spi_ss_en_one_hot(7)  <= '1' when (h_spi_hub_ss_en = "00111") else '0';

  h_spi_ss_active_high <= h_spi_ss_en_one_hot when h_spi_m_ss = '1' else (others => '0');

  -- purpose: Generate the chip select signal
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_ss_active_high, h_spi_ss_high
  -- outputs: h_spi_ss
  clock_out_ss_p: process (clk_61)
  begin  -- process clock_out_ss_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_ss <= (others => '0');
      else
        h_spi_ss <= h_spi_ss_active_high xor (not h_spi_ss_high);
      end if;
    end if;
  end process clock_out_ss_p;
---------------------------------------------------------------
-- SPI port enable signal for clock and data
---------------------------------------------------------------
  h_spi_port <= h_spi_hub_0_port when (h_spi_hub_ss_en = "00000") else
                h_spi_hub_1_port when (h_spi_hub_ss_en = "00001") else
                h_spi_hub_2_port when (h_spi_hub_ss_en = "00010") else
                h_spi_hub_3_port when (h_spi_hub_ss_en = "00011") else
                h_spi_hub_4_port when (h_spi_hub_ss_en = "00100") else
                h_spi_hub_5_port when (h_spi_hub_ss_en = "00101") else
                h_spi_hub_6_port when (h_spi_hub_ss_en = "00110") else
                h_spi_hub_7_port when (h_spi_hub_ss_en = "00111") else
                "111";

  h_spi_port_one_hot(0)  <= '1' when (h_spi_port = "000") else '0';
  h_spi_port_one_hot(1)  <= '1' when (h_spi_port = "001") else '0';
  h_spi_port_one_hot(2)  <= '1' when (h_spi_port = "010") else '0';
  h_spi_port_one_hot(3)  <= '1' when (h_spi_port = "011") else '0';
  h_spi_port_one_hot(4)  <= '1' when (h_spi_port = "100") else '0';
  h_spi_port_one_hot(5)  <= '1' when (h_spi_port = "101") else '0';
  h_spi_port_one_hot(6)  <= '1' when (h_spi_port = "110") else '0';
  h_spi_port_one_hot(7)  <= '1' when (h_spi_port = "111") else '0';

--------------------------------------------------------------
-- SPI clock
---------------------------------------------------------------
  h_spi_clk_inv <= h_spi_hub_0_clk_inv when (h_spi_hub_ss_en = "00000") else
                   h_spi_hub_1_clk_inv when (h_spi_hub_ss_en = "00001") else
                   h_spi_hub_2_clk_inv when (h_spi_hub_ss_en = "00010") else
                   h_spi_hub_3_clk_inv when (h_spi_hub_ss_en = "00011") else
                   h_spi_hub_4_clk_inv when (h_spi_hub_ss_en = "00100") else
                   h_spi_hub_5_clk_inv when (h_spi_hub_ss_en = "00101") else
                   h_spi_hub_6_clk_inv when (h_spi_hub_ss_en = "00110") else
                   h_spi_hub_7_clk_inv when (h_spi_hub_ss_en = "00111") else
                   '0';

  h_spi_m_clk_in <= h_spi_clk_inv xor h_spi_m_clk;

  -- purpose: Generate the SPI clock towards PIN
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_port_one_hot, h_spi_m_clk_in
  -- outputs: h_spi_clk
  clock_out_clk_p: process (clk_61)
  begin  -- process clock_out_clk_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_clk <= (others => '0');
      else
        for h_spi_clk_nr_c in h_spi_clk'range loop
          if h_spi_port_one_hot(h_spi_clk_nr_c) = '1' then
            h_spi_clk(h_spi_clk_nr_c) <= h_spi_m_clk_in;
          else
            h_spi_clk(h_spi_clk_nr_c) <= '0';
          end if;
        end loop;  -- h_spi_clk_nr_c
      end if;
    end if;
  end process clock_out_clk_p;

---------------------------------------------------------------
-- SPI data
---------------------------------------------------------------
  -- purpose: Generate the output signal
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_port_one_hot, h_spi_mosi, h_spi_m_dir
  -- outputs: h_spi_data_out, h_spi_data_oe
  clock_out_data_p: process (clk_61)
  begin  -- process clock_out_data_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_data_out <= (others => '0');
        h_spi_data_oe  <= (others => '0');
      else
        for h_spi_port_nr_c in h_spi_data_out'range loop
          if h_spi_port_one_hot(h_spi_port_nr_c) = '1' then
            h_spi_data_out(h_spi_port_nr_c) <= h_spi_mosi;
            h_spi_data_oe(h_spi_port_nr_c)  <= h_spi_m_dir;
          else
            h_spi_data_out(h_spi_port_nr_c) <= '0';
            h_spi_data_oe(h_spi_port_nr_c)  <= '0';
          end if;
        end loop;  -- h_spi_port_nr_c
      end if;
    end if;
  end process clock_out_data_p;

---------------------------------------------------------------
-- 3/4 logic
---------------------------------------------------------------
  h_spi_hub_four_w <= h_spi_hub_0_four_w when (h_spi_hub_ss_en = "00000") else
                      h_spi_hub_1_four_w when (h_spi_hub_ss_en = "00001") else
                      h_spi_hub_2_four_w when (h_spi_hub_ss_en = "00010") else
                      h_spi_hub_3_four_w when (h_spi_hub_ss_en = "00011") else
                      h_spi_hub_4_four_w when (h_spi_hub_ss_en = "00100") else
                      h_spi_hub_5_four_w when (h_spi_hub_ss_en = "00101") else
                      h_spi_hub_6_four_w when (h_spi_hub_ss_en = "00110") else
                      h_spi_hub_7_four_w when (h_spi_hub_ss_en = "00111") else
                      '0';

  -- 3/4-wire logic
  h_spi_miso_en(7 downto 0)  <= h_spi_data_in(7 downto 0) when h_spi_hub_four_w = '0' else h_spi_miso_in;

  h_spi_miso <= h_spi_miso_en(0) when (h_spi_port = "000") else
                h_spi_miso_en(1) when (h_spi_port = "001") else
                h_spi_miso_en(2) when (h_spi_port = "010") else
                h_spi_miso_en(3) when (h_spi_port = "011") else
                h_spi_miso_en(4) when (h_spi_port = "100") else
                h_spi_miso_en(5) when (h_spi_port = "101") else
                h_spi_miso_en(6) when (h_spi_port = "110") else
                h_spi_miso_en(7) when (h_spi_port = "111") else
                '0';

end rtl;
