-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Description: Inside wrapper of SPI module
--
-------------------------------------------------------------------------------
-- VHDL Version: VHDL '93
--
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- Entity for h_spi
-------------------------------------------------------------------------------

entity spi_wrapper is
  port (
    -- clock and reset
    clk_61      : in std_logic;                         -- 61.44MHz clock
    rst_61      : in std_logic;                         -- Reset signal with 61.44MHz clock

    -- AXI4-Lite bus signals
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

    -- Interrupt signal
    irq_h_spi_status : out std_logic;                   -- Interrupt signal

    -- SPI HUB signals
    h_spi_ss       : out std_logic_vector(7 downto 0);  -- Chip select signal towards PIN
    h_spi_clk      : out std_logic_vector(7 downto 0);  -- Clock signal towards PIN
    h_spi_data_out : out std_logic_vector(7 downto 0);  -- Output signal towards PIN
    h_spi_data_in  : in  std_logic_vector(7 downto 0);  -- Input signal for bidir usage
    h_spi_data_oe  : out std_logic_vector(7 downto 0);  -- Output signal enable signal
    h_spi_miso_in  : in  std_logic_vector(7 downto 0)); -- Input signal for 4-wire
end spi_wrapper;

------------------------------------------------------------------------------
-- Architecture for spi_top
-------------------------------------------------------------------------------
architecture str of spi_wrapper is
  --signals between SPI_CTRL & SPI_HUB
  signal h_spi_m_clk : std_logic;
  signal h_spi_m_ss  : std_logic;
  signal h_spi_mosi  : std_logic;
  signal h_spi_m_dir : std_logic;
  signal h_spi_miso  : std_logic;

  -- Signals for register SPI_CTRL
  signal h_spi_ctrl_clk_idle : std_logic;
  signal h_spi_ctrl_rate     : std_logic_vector(13 downto 0);
  signal h_spi_ctrl_ss       : std_logic;
  signal h_spi_ctrl_ss_bidir : std_logic;
  signal h_spi_ctrl_ss_mode  : std_logic;
  signal h_spi_ctrl_en       : std_logic;
  signal h_spi_ctrl_lsbfe    : std_logic;
  signal h_spi_ctrl_cpha     : std_logic;
  signal h_spi_ctrl_cpol     : std_logic;
  signal h_spi_ctrl_mode     : std_logic_vector(1 downto 0);

  -- Signals for register SPI_LENGTH
  signal h_spi_length_dir : std_logic_vector(7 downto 0);
  signal h_spi_length_val : std_logic_vector(7 downto 0);

  -- Signals for register SPI_TX
  signal h_spi_tx_data : std_logic_vector(31 downto 0);
  signal h_spi_tx_put  : std_logic;
  -- Signals for register SPI_RX
  signal h_spi_rx_data : std_logic_vector(31 downto 0);
  signal h_spi_rx_get  : std_logic;
  -- Signals for register SPI_CMD
  signal h_spi_cmd_reset_cmd : std_logic;
  signal h_spi_cmd_reset_ack : std_logic;
  signal h_spi_cmd_strb_cmd  : std_logic;
  signal h_spi_cmd_strb_ack  : std_logic;

  -- Signals for register SPI_STATUS
  signal h_spi_status_done     : std_logic;
  signal h_spi_status_rx_avail : std_logic;
  signal h_spi_status_rx_full  : std_logic;
  signal h_spi_status_act      : std_logic;
  signal h_spi_status_tx_full  : std_logic;
  signal h_spi_status_tx_empty : std_logic;
  signal h_spi_status_rx_or    : std_logic;
  signal h_spi_status_tx_ur    : std_logic;

  -- Signals for register SPI_HUB_SS
  signal h_spi_hub_ss_en : std_logic_vector(4 downto 0);

  -- Signals for register SPI_HUB_0
  signal h_spi_hub_0_port    : std_logic_vector(2 downto 0);
  signal h_spi_hub_0_four_w  : std_logic;
  signal h_spi_hub_0_clk_inv : std_logic;
  signal h_spi_hub_0_ss_high : std_logic;

  -- Signals for register SPI_HUB_1
  signal h_spi_hub_1_port    : std_logic_vector(2 downto 0);
  signal h_spi_hub_1_four_w  : std_logic;
  signal h_spi_hub_1_clk_inv : std_logic;
  signal h_spi_hub_1_ss_high : std_logic;

  -- Signals for register SPI_HUB_2
  signal h_spi_hub_2_port    : std_logic_vector(2 downto 0);
  signal h_spi_hub_2_four_w  : std_logic;
  signal h_spi_hub_2_clk_inv : std_logic;
  signal h_spi_hub_2_ss_high : std_logic;

  -- Signals for register SPI_HUB_3
  signal h_spi_hub_3_port    : std_logic_vector(2 downto 0);
  signal h_spi_hub_3_four_w  : std_logic;
  signal h_spi_hub_3_clk_inv : std_logic;
  signal h_spi_hub_3_ss_high : std_logic;

  -- Signals for register SPI_HUB_4
  signal h_spi_hub_4_port    : std_logic_vector(2 downto 0);
  signal h_spi_hub_4_four_w  : std_logic;
  signal h_spi_hub_4_clk_inv : std_logic;
  signal h_spi_hub_4_ss_high : std_logic;

  -- Signals for register SPI_HUB_5
  signal h_spi_hub_5_port    : std_logic_vector(2 downto 0);
  signal h_spi_hub_5_four_w  : std_logic;
  signal h_spi_hub_5_clk_inv : std_logic;
  signal h_spi_hub_5_ss_high : std_logic;

  -- Signals for register SPI_HUB_6
  signal h_spi_hub_6_port    : std_logic_vector(2 downto 0);
  signal h_spi_hub_6_four_w  : std_logic;
  signal h_spi_hub_6_clk_inv : std_logic;
  signal h_spi_hub_6_ss_high : std_logic;

  -- Signals for register SPI_HUB_7
  signal h_spi_hub_7_port    : std_logic_vector(2 downto 0);
  signal h_spi_hub_7_four_w  : std_logic;
  signal h_spi_hub_7_clk_inv : std_logic;
  signal h_spi_hub_7_ss_high : std_logic;



-------------------------------------------------------------------------------
-- SPI_CTRL
-------------------------------------------------------------------------------
  component spi_ctrl is
    port (
      clk_61                : in  std_logic;
      rst_61                : in  std_logic;
      h_spi_m_clk           : out std_logic;
      h_spi_m_ss            : out std_logic;
      h_spi_mosi            : out std_logic;
      h_spi_miso            : in  std_logic;
      h_spi_m_dir           : out std_logic;
      h_spi_ctrl_clk_idle   : in  std_logic;
      h_spi_ctrl_rate       : in  std_logic_vector(13 downto 0);
      h_spi_ctrl_ss         : in  std_logic;
      h_spi_ctrl_ss_bidir   : in  std_logic;
      h_spi_ctrl_ss_mode    : in  std_logic;
      h_spi_ctrl_en         : in  std_logic;
      h_spi_ctrl_lsbfe      : in  std_logic;
      h_spi_ctrl_cpha       : in  std_logic;
      h_spi_ctrl_cpol       : in  std_logic;
      h_spi_ctrl_mode       : in  std_logic_vector(1 downto 0);
      h_spi_length_dir      : in  std_logic_vector(7 downto 0);
      h_spi_length_val      : in  std_logic_vector(7 downto 0);
      h_spi_tx_data         : in  std_logic_vector(31 downto 0);
      h_spi_tx_put          : in  std_logic;
      h_spi_rx_data         : out std_logic_vector(31 downto 0);
      h_spi_rx_get          : in  std_logic;
      h_spi_cmd_reset_cmd   : in  std_logic;
      h_spi_cmd_reset_ack   : out std_logic;
      h_spi_cmd_strb_cmd    : in  std_logic;
      h_spi_cmd_strb_ack    : out std_logic;
      h_spi_status_done     : out std_logic;
      h_spi_status_rx_avail : out std_logic;
      h_spi_status_rx_or    : out std_logic;
      h_spi_status_tx_ur    : out std_logic;
      h_spi_status_rx_full  : out std_logic;
      h_spi_status_act      : out std_logic;
      h_spi_status_tx_full  : out std_logic;
      h_spi_status_tx_empty : out std_logic);
  end component spi_ctrl;

-------------------------------------------------------------------------------
-- SPI_OPB
-------------------------------------------------------------------------------
  component spi_axi_slv is
    port (
      clk_axi             : in  std_logic;
      rst_axi             : in  std_logic;
      awaddr              : in  std_logic_vector(31 downto 0);
      awvalid             : in  std_logic;
      awready             : out std_logic;
      wdata               : in  std_logic_vector(31 downto 0);
      wstrb               : in  std_logic_vector(3 downto 0);
      wvalid              : in  std_logic;
      wready              : out std_logic;
      bready              : in  std_logic;
      bresp               : out std_logic_vector(1 downto 0);
      bvalid              : out std_logic;
      araddr              : in  std_logic_vector(31 downto 0);
      arvalid             : in  std_logic;
      arready             : out std_logic;
      rready              : in  std_logic;
      rdata               : out std_logic_vector(31 downto 0);
      rresp               : out std_logic_vector(1 downto 0);
      rvalid              : out std_logic;
      irq_spi_status      : out std_logic;
      spi_status_act      : in  std_logic;
      spi_status_rx_or    : in  std_logic;
      spi_status_rx_avail : in  std_logic;
      spi_status_rx_full  : in  std_logic;
      spi_status_tx_ur    : in  std_logic;
      spi_status_tx_full  : in  std_logic;
      spi_status_tx_empty : in  std_logic;
      spi_status_done     : in  std_logic;
      spi_ctrl_rate       : out std_logic_vector(13 downto 0);
      spi_ctrl_clk_idle   : out std_logic;
      spi_ctrl_ss         : out std_logic;
      spi_ctrl_ss_bidir   : out std_logic;
      spi_ctrl_ss_mode    : out std_logic;
      spi_ctrl_en         : out std_logic;
      spi_ctrl_lsbfe      : out std_logic;
      spi_ctrl_cpha       : out std_logic;
      spi_ctrl_cpol       : out std_logic;
      spi_ctrl_mode       : out std_logic_vector(1 downto 0);
      spi_length_dir      : out std_logic_vector(7 downto 0);
      spi_length_val      : out std_logic_vector(7 downto 0);
      spi_cmd_reset_cmd   : out std_logic;
      spi_cmd_reset_ack   : in  std_logic;
      spi_cmd_strb_cmd    : out std_logic;
      spi_cmd_strb_ack    : in  std_logic;
      spi_tx_data         : out std_logic_vector(31 downto 0);
      spi_tx_put          : out std_logic;
      spi_tx_be           : out std_logic_vector(3 downto 0);
      spi_rx_data         : in  std_logic_vector(31 downto 0);
      spi_rx_get          : out std_logic;
      spi_rx_be           : out std_logic_vector(3 downto 0);
      spi_hub_ss_en       : out std_logic_vector(4 downto 0);           -- should switch to 2
      spi_hub_0_port      : out std_logic_vector(2 downto 0);
      spi_hub_0_four_w    : out std_logic;
      spi_hub_0_clk_inv   : out std_logic;
      spi_hub_0_ss_high   : out std_logic;
      spi_hub_1_port      : out std_logic_vector(2 downto 0);
      spi_hub_1_four_w    : out std_logic;
      spi_hub_1_clk_inv   : out std_logic;
      spi_hub_1_ss_high   : out std_logic;
      spi_hub_2_port      : out std_logic_vector(2 downto 0);
      spi_hub_2_four_w    : out std_logic;
      spi_hub_2_clk_inv   : out std_logic;
      spi_hub_2_ss_high   : out std_logic;
      spi_hub_3_port      : out std_logic_vector(2 downto 0);
      spi_hub_3_four_w    : out std_logic;
      spi_hub_3_clk_inv   : out std_logic;
      spi_hub_3_ss_high   : out std_logic;
      spi_hub_4_port      : out std_logic_vector(2 downto 0);
      spi_hub_4_four_w    : out std_logic;
      spi_hub_4_clk_inv   : out std_logic;
      spi_hub_4_ss_high   : out std_logic;
      spi_hub_5_port      : out std_logic_vector(2 downto 0);
      spi_hub_5_four_w    : out std_logic;
      spi_hub_5_clk_inv   : out std_logic;
      spi_hub_5_ss_high   : out std_logic;
      spi_hub_6_port      : out std_logic_vector(2 downto 0);
      spi_hub_6_four_w    : out std_logic;
      spi_hub_6_clk_inv   : out std_logic;
      spi_hub_6_ss_high   : out std_logic;
      spi_hub_7_port      : out std_logic_vector(2 downto 0);
      spi_hub_7_four_w    : out std_logic;
      spi_hub_7_clk_inv   : out std_logic;
      spi_hub_7_ss_high   : out std_logic
      );
  end component spi_axi_slv;

-------------------------------------------------------------------------------
-- SPI_HUB
-------------------------------------------------------------------------------
  component spi_hub is
    port (
      clk_61               : in  std_logic;
      rst_61               : in  std_logic;
      h_spi_m_ss           : in  std_logic;
      h_spi_m_clk          : in  std_logic;
      h_spi_mosi           : in  std_logic;
      h_spi_miso           : out std_logic;
      h_spi_m_dir          : in  std_logic;
      h_spi_ss             : out std_logic_vector(7 downto 0);
      h_spi_clk            : out std_logic_vector(7 downto 0);
      h_spi_data_out       : out std_logic_vector(7 downto 0);
      h_spi_data_in        : in  std_logic_vector(7 downto 0);
      h_spi_data_oe        : out std_logic_vector(7 downto 0);
      h_spi_miso_in        : in  std_logic_vector(7 downto 0);
      h_spi_hub_ss_en      : in  std_logic_vector(4 downto 0);
      h_spi_hub_0_port     : in  std_logic_vector(2 downto 0);
      h_spi_hub_0_clk_inv  : in  std_logic;
      h_spi_hub_0_ss_high  : in  std_logic;
      h_spi_hub_0_four_w   : in  std_logic;
      h_spi_hub_1_port     : in  std_logic_vector(2 downto 0);
      h_spi_hub_1_clk_inv  : in  std_logic;
      h_spi_hub_1_ss_high  : in  std_logic;
      h_spi_hub_1_four_w   : in  std_logic;
      h_spi_hub_2_port     : in  std_logic_vector(2 downto 0);
      h_spi_hub_2_clk_inv  : in  std_logic;
      h_spi_hub_2_ss_high  : in  std_logic;
      h_spi_hub_2_four_w   : in  std_logic;
      h_spi_hub_3_port     : in  std_logic_vector(2 downto 0);
      h_spi_hub_3_clk_inv  : in  std_logic;
      h_spi_hub_3_ss_high  : in  std_logic;
      h_spi_hub_3_four_w   : in  std_logic;
      h_spi_hub_4_port     : in  std_logic_vector(2 downto 0);
      h_spi_hub_4_clk_inv  : in  std_logic;
      h_spi_hub_4_ss_high  : in  std_logic;
      h_spi_hub_4_four_w   : in  std_logic;
      h_spi_hub_5_port     : in  std_logic_vector(2 downto 0);
      h_spi_hub_5_clk_inv  : in  std_logic;
      h_spi_hub_5_ss_high  : in  std_logic;
      h_spi_hub_5_four_w   : in  std_logic;
      h_spi_hub_6_port     : in  std_logic_vector(2 downto 0);
      h_spi_hub_6_clk_inv  : in  std_logic;
      h_spi_hub_6_ss_high  : in  std_logic;
      h_spi_hub_6_four_w   : in  std_logic;
      h_spi_hub_7_port     : in  std_logic_vector(2 downto 0);
      h_spi_hub_7_clk_inv  : in  std_logic;
      h_spi_hub_7_ss_high  : in  std_logic;
      h_spi_hub_7_four_w   : in  std_logic
     );
  end component spi_hub;

begin
-------------------------------------------------------------------------
-- SPI_CTRL_I0
-------------------------------------------------------------------------
  spi_ctrl_i: spi_ctrl
    port map (
      clk_61                => clk_61,
      rst_61                => rst_61,
      h_spi_m_clk           => h_spi_m_clk,
      h_spi_m_ss            => h_spi_m_ss,
      h_spi_mosi            => h_spi_mosi,
      h_spi_miso            => h_spi_miso,
      h_spi_m_dir           => h_spi_m_dir,
      h_spi_ctrl_clk_idle   => h_spi_ctrl_clk_idle,
      h_spi_ctrl_rate       => h_spi_ctrl_rate,
      h_spi_ctrl_ss         => h_spi_ctrl_ss,
      h_spi_ctrl_ss_bidir   => h_spi_ctrl_ss_bidir,
      h_spi_ctrl_ss_mode    => h_spi_ctrl_ss_mode,
      h_spi_ctrl_en         => h_spi_ctrl_en,
      h_spi_ctrl_lsbfe      => h_spi_ctrl_lsbfe,
      h_spi_ctrl_cpha       => h_spi_ctrl_cpha,
      h_spi_ctrl_cpol       => h_spi_ctrl_cpol,
      h_spi_ctrl_mode       => h_spi_ctrl_mode,
      h_spi_length_dir      => h_spi_length_dir,
      h_spi_length_val      => h_spi_length_val,
      h_spi_tx_data         => h_spi_tx_data,
      h_spi_tx_put          => h_spi_tx_put,
      h_spi_rx_data         => h_spi_rx_data,
      h_spi_rx_get          => h_spi_rx_get,
      h_spi_cmd_reset_cmd   => h_spi_cmd_reset_cmd,
      h_spi_cmd_reset_ack   => h_spi_cmd_reset_ack,
      h_spi_cmd_strb_cmd    => h_spi_cmd_strb_cmd,
      h_spi_cmd_strb_ack    => h_spi_cmd_strb_ack,
      h_spi_status_done     => h_spi_status_done,
      h_spi_status_rx_avail => h_spi_status_rx_avail,
      h_spi_status_rx_or    => h_spi_status_rx_or,
      h_spi_status_tx_ur    => h_spi_status_tx_ur,
      h_spi_status_rx_full  => h_spi_status_rx_full,
      h_spi_status_act      => h_spi_status_act,
      h_spi_status_tx_full  => h_spi_status_tx_full,
      h_spi_status_tx_empty => h_spi_status_tx_empty);

-------------------------------------------------------------------------------
-- SPI_OPB_I0
-------------------------------------------------------------------------------
  spi_axi_slv_i: spi_axi_slv
    port map (
      clk_axi             => clk_61,
      rst_axi             => rst_61,
      awaddr              => awaddr,
      awvalid             => awvalid,
      awready             => awready,
      wdata               => wdata,
      wstrb               => wstrb,
      wvalid              => wvalid,
      wready              => wready,
      bready              => bready,
      bresp               => bresp,
      bvalid              => bvalid,
      araddr              => araddr,
      arvalid             => arvalid,
      arready             => arready,
      rready              => rready,
      rdata               => rdata,
      rresp               => rresp,
      rvalid              => rvalid,
      irq_spi_status      => irq_h_spi_status,
      spi_status_act      => h_spi_status_act,
      spi_status_rx_or    => h_spi_status_rx_or,
      spi_status_rx_avail => h_spi_status_rx_avail,
      spi_status_rx_full  => h_spi_status_rx_full,
      spi_status_tx_ur    => h_spi_status_tx_ur,
      spi_status_tx_full  => h_spi_status_tx_full,
      spi_status_tx_empty => h_spi_status_tx_empty,
      spi_status_done     => h_spi_status_done,
      spi_ctrl_rate       => h_spi_ctrl_rate,
      spi_ctrl_clk_idle   => h_spi_ctrl_clk_idle,
      spi_ctrl_ss         => h_spi_ctrl_ss,
      spi_ctrl_ss_bidir   => h_spi_ctrl_ss_bidir,
      spi_ctrl_ss_mode    => h_spi_ctrl_ss_mode,
      spi_ctrl_en         => h_spi_ctrl_en,
      spi_ctrl_lsbfe      => h_spi_ctrl_lsbfe,
      spi_ctrl_cpha       => h_spi_ctrl_cpha,
      spi_ctrl_cpol       => h_spi_ctrl_cpol,
      spi_ctrl_mode       => h_spi_ctrl_mode,
      spi_length_dir      => h_spi_length_dir,
      spi_length_val      => h_spi_length_val,
      spi_cmd_reset_cmd   => h_spi_cmd_reset_cmd,
      spi_cmd_reset_ack   => h_spi_cmd_reset_ack,
      spi_cmd_strb_cmd    => h_spi_cmd_strb_cmd,
      spi_cmd_strb_ack    => h_spi_cmd_strb_ack,
      spi_tx_data         => h_spi_tx_data,
      spi_tx_put          => h_spi_tx_put,
      spi_tx_be           => open,
      spi_rx_data         => h_spi_rx_data,
      spi_rx_get          => h_spi_rx_get,
      spi_rx_be           => open,
      spi_hub_ss_en       => h_spi_hub_ss_en,
      spi_hub_0_port      => h_spi_hub_0_port,
      spi_hub_0_four_w    => h_spi_hub_0_four_w,
      spi_hub_0_clk_inv   => h_spi_hub_0_clk_inv,
      spi_hub_0_ss_high   => h_spi_hub_0_ss_high,
      spi_hub_1_port      => h_spi_hub_1_port,
      spi_hub_1_four_w    => h_spi_hub_1_four_w,
      spi_hub_1_clk_inv   => h_spi_hub_1_clk_inv,
      spi_hub_1_ss_high   => h_spi_hub_1_ss_high,
      spi_hub_2_port      => h_spi_hub_2_port,
      spi_hub_2_four_w    => h_spi_hub_2_four_w,
      spi_hub_2_clk_inv   => h_spi_hub_2_clk_inv,
      spi_hub_2_ss_high   => h_spi_hub_2_ss_high,
      spi_hub_3_port      => h_spi_hub_3_port,
      spi_hub_3_four_w    => h_spi_hub_3_four_w,
      spi_hub_3_clk_inv   => h_spi_hub_3_clk_inv,
      spi_hub_3_ss_high   => h_spi_hub_3_ss_high,
      spi_hub_4_port      => h_spi_hub_4_port,
      spi_hub_4_four_w    => h_spi_hub_4_four_w,
      spi_hub_4_clk_inv   => h_spi_hub_4_clk_inv,
      spi_hub_4_ss_high   => h_spi_hub_4_ss_high,
      spi_hub_5_port      => h_spi_hub_5_port,
      spi_hub_5_four_w    => h_spi_hub_5_four_w,
      spi_hub_5_clk_inv   => h_spi_hub_5_clk_inv,
      spi_hub_5_ss_high   => h_spi_hub_5_ss_high,
      spi_hub_6_port      => h_spi_hub_6_port,
      spi_hub_6_four_w    => h_spi_hub_6_four_w,
      spi_hub_6_clk_inv   => h_spi_hub_6_clk_inv,
      spi_hub_6_ss_high   => h_spi_hub_6_ss_high,
      spi_hub_7_port      => h_spi_hub_7_port,
      spi_hub_7_four_w    => h_spi_hub_7_four_w,
      spi_hub_7_clk_inv   => h_spi_hub_7_clk_inv,
      spi_hub_7_ss_high   => h_spi_hub_7_ss_high
     );

-------------------------------------------------------------------------------
-- SPI_HUB_I0
-------------------------------------------------------------------------------
  spi_hub_i: spi_hub
    port map (
      clk_61               => clk_61,
      rst_61               => rst_61,
      h_spi_m_ss           => h_spi_m_ss,
      h_spi_m_clk          => h_spi_m_clk,
      h_spi_mosi           => h_spi_mosi,
      h_spi_miso           => h_spi_miso,
      h_spi_m_dir          => h_spi_m_dir,
      h_spi_ss             => h_spi_ss,
      h_spi_clk            => h_spi_clk,
      h_spi_data_out       => h_spi_data_out,
      h_spi_data_in        => h_spi_data_in,
      h_spi_data_oe        => h_spi_data_oe,
      h_spi_miso_in        => h_spi_miso_in,
      h_spi_hub_ss_en      => h_spi_hub_ss_en,
      h_spi_hub_0_port     => h_spi_hub_0_port,
      h_spi_hub_0_clk_inv  => h_spi_hub_0_clk_inv,
      h_spi_hub_0_ss_high  => h_spi_hub_0_ss_high,
      h_spi_hub_0_four_w   => h_spi_hub_0_four_w,
      h_spi_hub_1_port     => h_spi_hub_1_port,
      h_spi_hub_1_clk_inv  => h_spi_hub_1_clk_inv,
      h_spi_hub_1_ss_high  => h_spi_hub_1_ss_high,
      h_spi_hub_1_four_w   => h_spi_hub_1_four_w,
      h_spi_hub_2_port     => h_spi_hub_2_port,
      h_spi_hub_2_clk_inv  => h_spi_hub_2_clk_inv,
      h_spi_hub_2_ss_high  => h_spi_hub_2_ss_high,
      h_spi_hub_2_four_w   => h_spi_hub_2_four_w,
      h_spi_hub_3_port     => h_spi_hub_3_port,
      h_spi_hub_3_clk_inv  => h_spi_hub_3_clk_inv,
      h_spi_hub_3_ss_high  => h_spi_hub_3_ss_high,
      h_spi_hub_3_four_w   => h_spi_hub_3_four_w,
      h_spi_hub_4_port     => h_spi_hub_4_port,
      h_spi_hub_4_clk_inv  => h_spi_hub_4_clk_inv,
      h_spi_hub_4_ss_high  => h_spi_hub_4_ss_high,
      h_spi_hub_4_four_w   => h_spi_hub_4_four_w,
      h_spi_hub_5_port     => h_spi_hub_5_port,
      h_spi_hub_5_clk_inv  => h_spi_hub_5_clk_inv,
      h_spi_hub_5_ss_high  => h_spi_hub_5_ss_high,
      h_spi_hub_5_four_w   => h_spi_hub_5_four_w,
      h_spi_hub_6_port     => h_spi_hub_6_port,
      h_spi_hub_6_clk_inv  => h_spi_hub_6_clk_inv,
      h_spi_hub_6_ss_high  => h_spi_hub_6_ss_high,
      h_spi_hub_6_four_w   => h_spi_hub_6_four_w,
      h_spi_hub_7_port     => h_spi_hub_7_port,
      h_spi_hub_7_clk_inv  => h_spi_hub_7_clk_inv,
      h_spi_hub_7_ss_high  => h_spi_hub_7_ss_high,
      h_spi_hub_7_four_w   => h_spi_hub_7_four_w
  );
end str;
