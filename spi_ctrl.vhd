--------------------------------------------------------------------
--------------------------------------------------------------------
-- Description:
--
-- What does the file contain, what does it do, what is the
-- intention, how to use it, ...
--
--------------------------------------------------------------------
-- VHDL Version: VHDL '93
--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity spi_ctrl is
  port (
    clk_61                      : in  std_logic;        -- 61.44MHz clock
    rst_61                      : in  std_logic;        -- reset signal with 61.44MHz clock
    h_spi_m_clk                 : out std_logic;        -- Output SPI clock pin
    h_spi_m_ss                  : out std_logic;        -- Output SPI slect signal pin
    h_spi_mosi                  : out std_logic;        -- Output MOSI signal pin
    h_spi_miso                  : in  std_logic;        -- Input MISO signal pin
    h_spi_m_dir                 : out std_logic;        -- Output direction signal pin
    h_spi_ctrl_clk_idle         : in  std_logic;        -- Clock idle configuration
    h_spi_ctrl_rate             : in  std_logic_vector(13 downto 0);    -- Rate configurationon
    h_spi_ctrl_ss               : in  std_logic;        -- SPI Slave Select
    h_spi_ctrl_ss_bidir         : in  std_logic;        -- SS mode configuration
    h_spi_ctrl_ss_mode          : in  std_logic;        -- ss mode auto/manual
    h_spi_ctrl_en               : in  std_logic;        -- Enable signal
    h_spi_ctrl_lsbfe            : in  std_logic;        -- LSB first enable configuration
    h_spi_ctrl_cpha             : in  std_logic;        -- Leading/trailing edge
    h_spi_ctrl_cpol             : in  std_logic;        -- Clock polarity bit
    h_spi_ctrl_mode             : in  std_logic_vector(1 downto 0);     -- Mode configuration
    h_spi_length_dir            : in  std_logic_vector(7 downto 0);     -- Read length for BI
    h_spi_length_val            : in  std_logic_vector(7 downto 0);     -- Transaction length
    h_spi_tx_data               : in  std_logic_vector(31 downto 0);    -- TX data
    h_spi_tx_put                : in  std_logic;                        -- TX data control
    h_spi_rx_data               : out std_logic_vector(31 downto 0);    -- RX data
    h_spi_rx_get                : in  std_logic;                        -- RX data control
    h_spi_cmd_reset_cmd         : in  std_logic;        -- Reset command
    h_spi_cmd_reset_ack         : out std_logic;        -- Reset command ack
    h_spi_cmd_strb_cmd          : in  std_logic;        -- Strobe command
    h_spi_cmd_strb_ack          : out std_logic;        -- Strobe command ack
    h_spi_status_done           : out std_logic;        -- Command is done
    h_spi_status_rx_avail       : out std_logic;        -- RX data is available
    h_spi_status_rx_or          : out std_logic;        -- RX data is over-run
    h_spi_status_tx_ur          : out std_logic;        -- TX data is under-run
    h_spi_status_rx_full        : out std_logic;        -- RX data is full
    h_spi_status_act            : out std_logic;        -- Command is processed
    h_spi_status_tx_full        : out std_logic;        -- TX FIFO is full
    h_spi_status_tx_empty       : out std_logic);       -- TX FIFO is empty
end entity spi_ctrl;

architecture rtl of spi_ctrl is
-------------------------------------------------------------------------------
-- Internal Signals
-------------------------------------------------------------------------------
  signal start_strb             : std_logic;
  signal strb_done              : std_logic;
  signal cpol_set               : std_logic;
  signal load_reg               : std_logic;
  signal put_rx_fifo            : std_logic;
  signal tx_en                  : std_logic;
  signal rx_en                  : std_logic;
  signal put_leading_edge       : std_logic;
  signal samp_leading_edge      : std_logic;
  signal put_trailing_edge      : std_logic;
  signal samp_trailing_edge     : std_logic;
  signal dir_en                 : std_logic;
  signal length_val             : std_logic_vector(8 downto 0);
  signal length_dir             : std_logic_vector(8 downto 0);

-------------------------------------------------------------------------------
-- Used module declaration
-------------------------------------------------------------------------------
  component spi_ctrl_clock is
    port (
      clk_61              : in  std_logic;
      rst_61              : in  std_logic;
      start_strb          : in  std_logic;
      strb_done           : out std_logic;
      cpol_set            : out std_logic;
      load_reg            : out std_logic;
      put_rx_fifo         : out std_logic;
      tx_en               : out std_logic;
      rx_en               : out std_logic;
      put_leading_edge    : out std_logic;
      samp_leading_edge   : out std_logic;
      put_trailing_edge   : out std_logic;
      samp_trailing_edge  : out std_logic;
      dir_en              : out std_logic;
      length_val          : out std_logic_vector(8 downto 0);
      length_dir          : out std_logic_vector(8 downto 0);
      h_spi_length_dir    : in  std_logic_vector(7 downto 0);
      h_spi_length_val    : in  std_logic_vector(7 downto 0);
      h_spi_cmd_reset_cmd : in  std_logic;
      h_spi_ctrl_mode     : in  std_logic_vector(1 downto 0);
      h_spi_ctrl_rate     : in  std_logic_vector(13 downto 0);
      h_spi_ctrl_clk_idle : in  std_logic;
      h_spi_ctrl_cpol     : in  std_logic;
      h_spi_ctrl_cpha     : in  std_logic);
  end component spi_ctrl_clock;

  component spi_ctrl_int is
    port (
      clk_61                : in  std_logic;
      rst_61                : in  std_logic;
      h_spi_m_clk           : out std_logic;
      h_spi_m_ss            : out std_logic;
      h_spi_mosi            : out std_logic;
      h_spi_miso            : in  std_logic;
      h_spi_m_dir           : out std_logic;
      start_strb            : out std_logic;
      strb_done             : in  std_logic;
      cpol_set              : in  std_logic;
      load_reg              : in  std_logic;
      put_rx_fifo           : in  std_logic;
      tx_en                 : in  std_logic;
      rx_en                 : in  std_logic;
      dir_en                : in  std_logic;
      put_leading_edge      : in  std_logic;
      samp_leading_edge     : in  std_logic;
      put_trailing_edge     : in  std_logic;
      samp_trailing_edge    : in  std_logic;
      length_dir            : in  std_logic_vector(8 downto 0);
      length_val            : in  std_logic_vector(8 downto 0);
      h_spi_ctrl_ss         : in  std_logic;
      h_spi_ctrl_ss_bidir   : in  std_logic;
      h_spi_ctrl_ss_mode    : in  std_logic;
      h_spi_ctrl_en         : in  std_logic;
      h_spi_ctrl_lsbfe      : in  std_logic;
      h_spi_ctrl_cpha       : in  std_logic;
      h_spi_ctrl_mode       : in  std_logic_vector(1 downto 0);
      h_spi_ctrl_clk_idle   : in  std_logic;
      h_spi_ctrl_rate       : in  std_logic_vector(13 downto 0);
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
  end component spi_ctrl_int;

begin  -- architecture rtl
-------------------------------------------------------------------------------
-- Used Modules
-------------------------------------------------------------------------------
  spi_ctrl_clock_i: spi_ctrl_clock
    port map (
      clk_61              => clk_61,
      rst_61              => rst_61,
      start_strb          => start_strb,
      strb_done           => strb_done,
      cpol_set            => cpol_set,
      load_reg            => load_reg,
      put_rx_fifo         => put_rx_fifo,
      tx_en               => tx_en,
      rx_en               => rx_en,
      put_leading_edge    => put_leading_edge,
      samp_leading_edge   => samp_leading_edge,
      put_trailing_edge   => put_trailing_edge,
      samp_trailing_edge  => samp_trailing_edge,
      dir_en              => dir_en,
      length_val          => length_val,
      length_dir          => length_dir,
      h_spi_length_dir    => h_spi_length_dir,
      h_spi_length_val    => h_spi_length_val,
      h_spi_cmd_reset_cmd => h_spi_cmd_reset_cmd,
      h_spi_ctrl_mode     => h_spi_ctrl_mode,
      h_spi_ctrl_rate     => h_spi_ctrl_rate,
      h_spi_ctrl_clk_idle => h_spi_ctrl_clk_idle,
      h_spi_ctrl_cpol     => h_spi_ctrl_cpol,
      h_spi_ctrl_cpha     => h_spi_ctrl_cpha);

  spi_ctrl_int_i: spi_ctrl_int
    port map (
      clk_61                => clk_61,
      rst_61                => rst_61,
      h_spi_m_clk           => h_spi_m_clk,
      h_spi_m_ss            => h_spi_m_ss,
      h_spi_mosi            => h_spi_mosi,
      h_spi_miso            => h_spi_miso,
      h_spi_m_dir           => h_spi_m_dir,
      start_strb            => start_strb,
      strb_done             => strb_done,
      cpol_set              => cpol_set,
      load_reg              => load_reg,
      put_rx_fifo           => put_rx_fifo,
      tx_en                 => tx_en,
      rx_en                 => rx_en,
      dir_en                => dir_en,
      put_leading_edge      => put_leading_edge,
      samp_leading_edge     => samp_leading_edge,
      put_trailing_edge     => put_trailing_edge,
      samp_trailing_edge    => samp_trailing_edge,
      length_dir            => length_dir,
      length_val            => length_val,
      h_spi_ctrl_ss         => h_spi_ctrl_ss,
      h_spi_ctrl_ss_bidir   => h_spi_ctrl_ss_bidir,
      h_spi_ctrl_ss_mode    => h_spi_ctrl_ss_mode,
      h_spi_ctrl_en         => h_spi_ctrl_en,
      h_spi_ctrl_lsbfe      => h_spi_ctrl_lsbfe,
      h_spi_ctrl_cpha       => h_spi_ctrl_cpha,
      h_spi_ctrl_mode       => h_spi_ctrl_mode,
      h_spi_ctrl_clk_idle   => h_spi_ctrl_clk_idle,
      h_spi_ctrl_rate       => h_spi_ctrl_rate,
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

end architecture rtl;
