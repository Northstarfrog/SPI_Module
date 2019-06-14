--------------------------------------------------------------------
-- Description:
--
-- spi_top module
--
--------------------------------------------------------------------
-- VHDL Version: VHDL '93
--
--------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity spi is
  port (
    -- clock and reset
    clk_61      : in std_logic;                         -- 61.44MHz clock
    rst_61      : in std_logic;                         -- Reset signal with 61.44MHz clock

    -- AXI4-Lite bus Signals
    awaddr      : in  std_logic_vector(31 downto 0);    -- Write address for AXI-lite
    awvalid     : in  std_logic;                        -- Write address valid for AXI-lite
    awready     : out std_logic;                        -- Write address ready for AXI-lite
    wdata       : in  std_logic_vector(31 downto 0);    -- Write data for AXI-lite
    wstrb       : in  std_logic_vector( 3 downto 0);    -- Write data byte mask for AXI-lite
    wvalid      : in  std_logic;                        -- Write data valid for AXI-lite
    wready      : out std_logic;                        -- Write data ready for AXI-lite
    bready      : in  std_logic;                        -- Response ready for AXI-lite
    bresp       : out std_logic_vector( 1 downto 0);    -- Response for AXI-lite
    bvalid      : out std_logic;                        -- Response valid for AXI-lite
    araddr      : in  std_logic_vector(31 downto 0);    -- Read address for AXI-lite
    arvalid     : in  std_logic;                        -- Read address valid for AXI-lite
    arready     : out std_logic;                        -- Read address ready for AXI-lite
    rready      : in  std_logic;                        -- Read ready for AXI-lite
    rdata       : out std_logic_vector(31 downto 0);    -- Read data for AXI-lite
    rresp       : out std_logic_vector( 1 downto 0);    -- Read response for AXI-lite
    rvalid      : out std_logic;                        -- Read valid for AXI-lite

    -- Interrupt Signal
    irq_spi     : out std_logic;                        -- Interrupt signal

    --SPI pins 8 X device
    fpga_tokelau0_spi_miso : in  std_logic;             -- Tokelau0 SPI configuration
    fpga_tokelau0_spi_mosi : out std_logic;             -- Tokelau0 SPI configuration
    fpga_tokelau0_spi_cs_n : out std_logic;             -- Tokelau0 SPI configuration
    fpga_tokelau0_spi_clk  : out std_logic;             -- Tokelau0 SPI configuration

    fpga_tokelau1_spi_miso : in  std_logic;             -- Tokelau1 SPI configuration
    fpga_tokelau1_spi_mosi : out std_logic;             -- Tokelau1 SPI configuration
    fpga_tokelau1_spi_cs_n : out std_logic;             -- Tokelau1 SPI configuration
    fpga_tokelau1_spi_clk  : out std_logic;             -- Tokelau1 SPI configuration

    fpga_tokelau2_spi_miso : in  std_logic;             -- Tokelau2 SPI configuration
    fpga_tokelau2_spi_mosi : out std_logic;             -- Tokelau2 SPI configuration
    fpga_tokelau2_spi_cs_n : out std_logic;             -- Tokelau2 SPI configuration
    fpga_tokelau2_spi_clk  : out std_logic;             -- Tokelau2 SPI configuration

    fpga_tokelau3_spi_miso : in  std_logic;             -- Tokelau3 SPI configuration
    fpga_tokelau3_spi_mosi : out std_logic;             -- Tokelau3 SPI configuration
    fpga_tokelau3_spi_cs_n : out std_logic;             -- Tokelau3 SPI configuration
    fpga_tokelau3_spi_clk  : out std_logic;             -- Tokelau3 SPI configuration

    fpga_pacc0_spi_miso    : in  std_logic;             -- PACC0 SPI configuration
    fpga_pacc0_spi_mosi    : out std_logic;             -- PACC0 SPI configuration
    fpga_pacc0_spi_cs_n    : out std_logic;             -- PACC0 SPI configuration
    fpga_pacc0_spi_clk     : out std_logic;             -- PACC0 SPI configuration

    fpga_pacc1_spi_miso    : in  std_logic;             -- PACC1 SPI configuration
    fpga_pacc1_spi_mosi    : out std_logic;             -- PACC1 SPI configuration
    fpga_pacc1_spi_cs_n    : out std_logic;             -- PACC1 SPI configuration
    fpga_pacc1_spi_clk     : out std_logic;             -- PACC1 SPI configuration

    fpga_dcadc_spi_miso    : in  std_logic;             -- PACC2 SPI configuration
    fpga_dcadc_spi_mosi    : out std_logic;             -- PACC2 SPI configuration
    fpga_dcadc_spi_cs_n    : out std_logic;             -- PACC2 SPI configuration
    fpga_dcadc_spi_clk     : out std_logic;             -- PACC2 SPI configuration

    fpga_dcpavdd_spi_miso  : in  std_logic;             -- PACC3 SPI configuration
    fpga_dcpavdd_spi_mosi  : out std_logic;             -- PACC3 SPI configuration
    fpga_dcpavdd_spi_cs_n  : out std_logic;             -- PACC3 SPI configuration
    fpga_dcpavdd_spi_clk   : out std_logic);            -- PACC3 SPI configuration
end spi;

architecture rtl of spi is

------------------------------------------------------------------------------------------
-- Signals
------------------------------------------------------------------------------------------
  signal h_spi_ss         : std_logic_vector(7 downto 0);
  signal h_spi_clk        : std_logic_vector(7 downto 0);
  signal h_spi_data_out   : std_logic_vector(7 downto 0);
  signal h_spi_data_in    : std_logic_vector(7 downto 0);
  --signal h_spi_data_oe    : std_logic_vector(7 downto 0);
  signal h_spi_miso_in    : std_logic_vector(7 downto 0);

  component spi_wrapper
    port (
      -- clock and reset
      clk_61      : in std_logic;
      rst_61      : in std_logic;

      -- AXI4-Lite bus signals
      awaddr      : in  std_logic_vector(31 downto 0);
      awvalid     : in  std_logic;
      awready     : out std_logic;
      wdata       : in  std_logic_vector(31 downto 0);
      wstrb       : in  std_logic_vector( 3 downto 0);
      wvalid      : in  std_logic;
      wready      : out std_logic;
      bready      : in  std_logic;
      bresp       : out std_logic_vector( 1 downto 0);
      bvalid      : out std_logic;
      araddr      : in  std_logic_vector(31 downto 0);
      arvalid     : in  std_logic;
      arready     : out std_logic;
      rready      : in  std_logic;
      rdata       : out std_logic_vector(31 downto 0);
      rresp       : out std_logic_vector( 1 downto 0);
      rvalid      : out std_logic;

      -- Interrupt signal
      irq_h_spi_status : out std_logic;

      -- SPI HUB signals
      h_spi_ss       : out std_logic_vector(7 downto 0);
      h_spi_clk      : out std_logic_vector(7 downto 0);
      h_spi_data_out : out std_logic_vector(7 downto 0);
      h_spi_data_in  : in  std_logic_vector(7 downto 0);
      h_spi_data_oe  : out std_logic_vector(7 downto 0);
      h_spi_miso_in  : in  std_logic_vector(7 downto 0));
  end component;

begin  --  rtl
-------------------------------------------------------
-- SPI INST
-------------------------------------------------------
  spi_wrapper_i : spi_wrapper
    port map (
      clk_61           => clk_61,
      rst_61           => rst_61,
      awaddr           => awaddr,
      awvalid          => awvalid,
      awready          => awready,
      wdata            => wdata,
      wstrb            => wstrb,
      wvalid           => wvalid,
      wready           => wready,
      bready           => bready,
      bresp            => bresp,
      bvalid           => bvalid,
      araddr           => araddr,
      arvalid          => arvalid,
      arready          => arready,
      rready           => rready,
      rdata            => rdata,
      rresp            => rresp,
      rvalid           => rvalid,
      irq_h_spi_status => irq_spi,
      h_spi_ss         => h_spi_ss,
      h_spi_clk        => h_spi_clk,
      h_spi_data_out   => h_spi_data_out,
      h_spi_data_in    => h_spi_data_in,
      h_spi_data_oe    => open,
      h_spi_miso_in    => h_spi_miso_in);

-----------------------------------------------------------------------
-- PIN cnnection for SPI
-----------------------------------------------------------------------
  h_spi_miso_in(0)       <= fpga_tokelau0_spi_miso;
  fpga_tokelau0_spi_mosi <= h_spi_data_out(0);
  fpga_tokelau0_spi_cs_n <= h_spi_ss(0);
  fpga_tokelau0_spi_clk  <= h_spi_clk(0);

  h_spi_miso_in(1)       <= fpga_tokelau1_spi_miso;
  fpga_tokelau1_spi_mosi <= h_spi_data_out(1);
  fpga_tokelau1_spi_cs_n <= h_spi_ss(1);
  fpga_tokelau1_spi_clk  <= h_spi_clk(1);

  h_spi_miso_in(2)       <= fpga_tokelau2_spi_miso;
  fpga_tokelau2_spi_mosi <= h_spi_data_out(2);
  fpga_tokelau2_spi_cs_n <= h_spi_ss(2);
  fpga_tokelau2_spi_clk  <= h_spi_clk(2);

  h_spi_miso_in(3)       <= fpga_tokelau3_spi_miso;
  fpga_tokelau3_spi_mosi <= h_spi_data_out(3);
  fpga_tokelau3_spi_cs_n <= h_spi_ss(3);
  fpga_tokelau3_spi_clk  <= h_spi_clk(3);

  h_spi_miso_in(4)       <= fpga_pacc0_spi_miso;
  fpga_pacc0_spi_mosi    <= h_spi_data_out(4);
  fpga_pacc0_spi_cs_n    <= h_spi_ss(4);
  fpga_pacc0_spi_clk     <= h_spi_clk(4);

  h_spi_miso_in(5)       <= fpga_pacc1_spi_miso;
  fpga_pacc1_spi_mosi    <= h_spi_data_out(5);
  fpga_pacc1_spi_cs_n    <= h_spi_ss(5);
  fpga_pacc1_spi_clk     <= h_spi_clk(5);

  h_spi_miso_in(6)       <= fpga_dcadc_spi_miso;
  fpga_dcadc_spi_mosi    <= h_spi_data_out(6);
  fpga_dcadc_spi_cs_n    <= h_spi_ss(6);
  fpga_dcadc_spi_clk     <= h_spi_clk(6);

  h_spi_miso_in(7)       <= fpga_dcpavdd_spi_miso;
  fpga_dcpavdd_spi_mosi  <= h_spi_data_out(7);
  fpga_dcpavdd_spi_cs_n  <= h_spi_ss(7);
  fpga_dcpavdd_spi_clk   <= h_spi_clk(7);

  -- There all no 3-wire in this module
  h_spi_data_in          <= x"00";
  -- h_spi_data_oe <= "0";

end rtl;
