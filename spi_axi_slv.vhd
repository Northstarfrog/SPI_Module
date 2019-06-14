-------------------------------------------------------------------------------

-- Description: AXI4-Lite slave for SPI
--   
--   Read and Write registers takes 2 cycles,
--   Write MEM takes 5 cycles, Read MEM takes 5 cycles (TBC /Max)
--   Write MIRI takes 4+nr_ws cycles, Read MIRI takes 4+nr_ws cycles
-------------------------------------------------------------------------------
-- VHDL Version: VHDL '93
--
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Libraries
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ****************************************************************************
-- ****************************************************************************
-- ****                                                                    ****
-- ****   DO NOT MAKE CHANGES IN THIS FILE!!                               ****
-- ****                                                                    ****
-- ****************************************************************************
-- ****************************************************************************

-------------------------------------------------------------------------------
-- Entity declaration for AXI-IF for SPI
-------------------------------------------------------------------------------
entity spi_axi_slv is
  port (
    -- AXI clock and reset
    clk_axi   : in  std_logic;                          -- AXI clock
    rst_axi  : in  std_logic;                          -- AXI reset
    -- AXI4-Lite bus signals
    awaddr    : in    std_logic_vector(31 downto 0);    -- Write address
    awvalid   : in    std_logic;                        -- Write address valid
    awready   : out   std_logic;                        -- Write address ready

    wdata     : in    std_logic_vector(31 downto 0);    -- Write data
    wstrb     : in    std_logic_vector( 3 downto 0);    -- Write data strobe
    wvalid    : in    std_logic;                        -- Write data valid
    wready    : out   std_logic;                        -- Write data ready

    bready    : in    std_logic;                        -- Response ready
    bresp     : out   std_logic_vector( 1 downto 0);    -- Response
    bvalid    : out   std_logic;                        -- Response valid

    araddr    : in    std_logic_vector(31 downto 0);    -- Read address
    arvalid   : in    std_logic;                        -- Read address valid
    arready   : out   std_logic;                        -- Read address ready

    rready    : in    std_logic;                        -- Read data ready
    rdata     : out   std_logic_vector(31 downto 0);    -- Read data
    rresp     : out   std_logic_vector( 1 downto 0);    -- Read response
    rvalid    : out   std_logic;                        -- Read data valid

    -- Interrupt set in SPI_STATUS trap register
    irq_spi_status                 : out    std_logic;

    -- Signals for register SPI_STATUS
    --R_REG_CLR/R_BIT_CLR
    spi_status_act         : in     std_logic;
    --R_REG_CLR/R_BIT_CLR
    spi_status_rx_or       : in     std_logic;
    --R_REG_CLR/R_BIT_CLR
    spi_status_rx_avail    : in     std_logic;
    --R_REG_CLR/R_BIT_CLR
    spi_status_rx_full     : in     std_logic;
    --R_REG_CLR/R_BIT_CLR
    spi_status_tx_ur       : in     std_logic;
    --R_REG_CLR/R_BIT_CLR
    spi_status_tx_full     : in     std_logic;
    --R_REG_CLR/R_BIT_CLR
    spi_status_tx_empty    : in     std_logic;
    --R_REG_CLR/R_BIT_CLR
    spi_status_done        : in     std_logic;
    -- Signals for register SPI_CTRL
    --RW/W/PUT
    spi_ctrl_rate          : out    std_logic_vector(13 downto 0);
    --RW/W/PUT
    spi_ctrl_clk_idle      : out    std_logic;
    --RW/W/PUT
    spi_ctrl_ss            : out    std_logic;
    --RW/W/PUT
    spi_ctrl_ss_bidir      : out    std_logic;
    --RW/W/PUT
    spi_ctrl_ss_mode       : out    std_logic;
    --RW/W/PUT
    spi_ctrl_en            : out    std_logic;
    --RW/W/PUT
    spi_ctrl_lsbfe         : out    std_logic;
    --RW/W/PUT
    spi_ctrl_cpha          : out    std_logic;
    --RW/W/PUT
    spi_ctrl_cpol          : out    std_logic;
    --RW/W/PUT
    spi_ctrl_mode          : out    std_logic_vector(1 downto 0);
    -- Signals for register SPI_LENGTH
    --RW/W/PUT
    spi_length_dir         : out    std_logic_vector(7 downto 0);
    --RW/W/PUT
    spi_length_val         : out    std_logic_vector(7 downto 0);
    -- Signals for register SPI_CMD
    --CMD
    spi_cmd_reset_cmd         : out    std_logic;
    --ACK
    spi_cmd_reset_ack         : in     std_logic;
    --CMD
    spi_cmd_strb_cmd          : out    std_logic;
    --ACK
    spi_cmd_strb_ack          : in     std_logic;
    -- Signals for register SPI_TX
    --RW/W/PUT
    spi_tx_data            : out    std_logic_vector(31 downto 0);
    --PUT
    spi_tx_put               : out    std_logic;
    --PUT byte enable
    spi_tx_be                : out    std_logic_vector(3 downto 0);
    -- Signals for register SPI_RX
    --R_REG_CLR/R_BIT_CLR
    spi_rx_data            : in     std_logic_vector(31 downto 0);
    --GET
    spi_rx_get               : out    std_logic;
    --GET byte enable
    spi_rx_be                : out    std_logic_vector(3 downto 0);
    -- Signals for register SPI_HUB_SS
    --RW/W/PUT
    spi_hub_ss_en          : out    std_logic_vector(4 downto 0);
    -- Signals for register SPI_HUB_0
    --RW/W/PUT
    spi_hub_0_port         : out    std_logic_vector(2 downto 0);
    --RW/W/PUT
    spi_hub_0_four_w       : out    std_logic;
    --RW/W/PUT
    spi_hub_0_clk_inv      : out    std_logic;
    --RW/W/PUT
    spi_hub_0_ss_high      : out    std_logic;
    -- Signals for register SPI_HUB_1
    --RW/W/PUT
    spi_hub_1_port         : out    std_logic_vector(2 downto 0);
    --RW/W/PUT
    spi_hub_1_four_w       : out    std_logic;
    --RW/W/PUT
    spi_hub_1_clk_inv      : out    std_logic;
    --RW/W/PUT
    spi_hub_1_ss_high      : out    std_logic;
    -- Signals for register SPI_HUB_2
    --RW/W/PUT
    spi_hub_2_port         : out    std_logic_vector(2 downto 0);
    --RW/W/PUT
    spi_hub_2_four_w       : out    std_logic;
    --RW/W/PUT
    spi_hub_2_clk_inv      : out    std_logic;
    --RW/W/PUT
    spi_hub_2_ss_high      : out    std_logic;
    -- Signals for register SPI_HUB_3
    --RW/W/PUT
    spi_hub_3_port         : out    std_logic_vector(2 downto 0);
    --RW/W/PUT
    spi_hub_3_four_w       : out    std_logic;
    --RW/W/PUT
    spi_hub_3_clk_inv      : out    std_logic;
    --RW/W/PUT
    spi_hub_3_ss_high      : out    std_logic;
    -- Signals for register SPI_HUB_4
    --RW/W/PUT
    spi_hub_4_port         : out    std_logic_vector(2 downto 0);
    --RW/W/PUT
    spi_hub_4_four_w       : out    std_logic;
    --RW/W/PUT
    spi_hub_4_clk_inv      : out    std_logic;
    --RW/W/PUT
    spi_hub_4_ss_high      : out    std_logic;
    -- Signals for register SPI_HUB_5
    --RW/W/PUT
    spi_hub_5_port         : out    std_logic_vector(2 downto 0);
    --RW/W/PUT
    spi_hub_5_four_w       : out    std_logic;
    --RW/W/PUT
    spi_hub_5_clk_inv      : out    std_logic;
    --RW/W/PUT
    spi_hub_5_ss_high      : out    std_logic;
    -- Signals for register SPI_HUB_6
    --RW/W/PUT
    spi_hub_6_port         : out    std_logic_vector(2 downto 0);
    --RW/W/PUT
    spi_hub_6_four_w       : out    std_logic;
    --RW/W/PUT
    spi_hub_6_clk_inv      : out    std_logic;
    --RW/W/PUT
    spi_hub_6_ss_high      : out    std_logic;
    -- Signals for register SPI_HUB_7
    --RW/W/PUT
    spi_hub_7_port         : out    std_logic_vector(2 downto 0);
    --RW/W/PUT
    spi_hub_7_four_w       : out    std_logic;
    --RW/W/PUT
    spi_hub_7_clk_inv      : out    std_logic;
    --RW/W/PUT
    spi_hub_7_ss_high      : out    std_logic
  );

end entity spi_axi_slv;

architecture rtl of spi_axi_slv is

  signal spi_status_act_set         : std_logic;
  signal spi_status_act_trap        : std_logic;
  signal spi_status_act_mask        : std_logic;
  signal spi_status_act_force       : std_logic;
  signal spi_status_act_db          : std_logic;
  signal spi_status_act_trig        : std_logic;
  signal spi_status_act_d           : std_logic;
  signal spi_status_act_edge        : std_logic;
  signal spi_status_rx_or_set         : std_logic;
  signal spi_status_rx_or_trap        : std_logic;
  signal spi_status_rx_or_mask        : std_logic;
  signal spi_status_rx_or_force       : std_logic;
  signal spi_status_rx_or_db          : std_logic;
  signal spi_status_rx_or_trig        : std_logic;
  signal spi_status_rx_or_d           : std_logic;
  signal spi_status_rx_or_edge        : std_logic;
  signal spi_status_rx_avail_set         : std_logic;
  signal spi_status_rx_avail_trap        : std_logic;
  signal spi_status_rx_avail_mask        : std_logic;
  signal spi_status_rx_avail_force       : std_logic;
  signal spi_status_rx_avail_db          : std_logic;
  signal spi_status_rx_avail_trig        : std_logic;
  signal spi_status_rx_avail_d           : std_logic;
  signal spi_status_rx_avail_edge        : std_logic;
  signal spi_status_rx_full_set         : std_logic;
  signal spi_status_rx_full_trap        : std_logic;
  signal spi_status_rx_full_mask        : std_logic;
  signal spi_status_rx_full_force       : std_logic;
  signal spi_status_rx_full_db          : std_logic;
  signal spi_status_rx_full_trig        : std_logic;
  signal spi_status_rx_full_d           : std_logic;
  signal spi_status_rx_full_edge        : std_logic;
  signal spi_status_tx_ur_set         : std_logic;
  signal spi_status_tx_ur_trap        : std_logic;
  signal spi_status_tx_ur_mask        : std_logic;
  signal spi_status_tx_ur_force       : std_logic;
  signal spi_status_tx_ur_db          : std_logic;
  signal spi_status_tx_ur_trig        : std_logic;
  signal spi_status_tx_ur_d           : std_logic;
  signal spi_status_tx_ur_edge        : std_logic;
  signal spi_status_tx_full_set         : std_logic;
  signal spi_status_tx_full_trap        : std_logic;
  signal spi_status_tx_full_mask        : std_logic;
  signal spi_status_tx_full_force       : std_logic;
  signal spi_status_tx_full_db          : std_logic;
  signal spi_status_tx_full_trig        : std_logic;
  signal spi_status_tx_full_d           : std_logic;
  signal spi_status_tx_full_edge        : std_logic;
  signal spi_status_tx_empty_set         : std_logic;
  signal spi_status_tx_empty_trap        : std_logic;
  signal spi_status_tx_empty_mask        : std_logic;
  signal spi_status_tx_empty_force       : std_logic;
  signal spi_status_tx_empty_db          : std_logic;
  signal spi_status_tx_empty_trig        : std_logic;
  signal spi_status_tx_empty_d           : std_logic;
  signal spi_status_tx_empty_edge        : std_logic;
  signal spi_status_done_set         : std_logic;
  signal spi_status_done_trap        : std_logic;
  signal spi_status_done_mask        : std_logic;
  signal spi_status_done_force       : std_logic;
  signal spi_status_done_db          : std_logic;
  signal spi_status_done_trig        : std_logic;
  signal spi_status_done_d           : std_logic;
  signal spi_status_done_edge        : std_logic;
  signal spi_ctrl_rate_int         : std_logic_vector(13 downto 0);
  signal spi_ctrl_clk_idle_int         : std_logic;
  signal spi_ctrl_ss_int         : std_logic;
  signal spi_ctrl_ss_bidir_int         : std_logic;
  signal spi_ctrl_ss_mode_int         : std_logic;
  signal spi_ctrl_en_int         : std_logic;
  signal spi_ctrl_lsbfe_int         : std_logic;
  signal spi_ctrl_cpha_int         : std_logic;
  signal spi_ctrl_cpol_int         : std_logic;
  signal spi_ctrl_mode_int         : std_logic_vector(1 downto 0);
  signal spi_length_dir_int         : std_logic_vector(7 downto 0);
  signal spi_length_val_int         : std_logic_vector(7 downto 0);
  signal spi_cmd_reset_cmd_int     : std_logic;
  signal spi_cmd_strb_cmd_int     : std_logic;
  signal spi_tx_data_int         : std_logic_vector(31 downto 0);
  signal spi_hub_ss_en_int         : std_logic_vector(4 downto 0);
  signal spi_hub_0_port_int         : std_logic_vector(2 downto 0);
  signal spi_hub_0_four_w_int         : std_logic;
  signal spi_hub_0_clk_inv_int         : std_logic;
  signal spi_hub_0_ss_high_int         : std_logic;
  signal spi_hub_1_port_int         : std_logic_vector(2 downto 0);
  signal spi_hub_1_four_w_int         : std_logic;
  signal spi_hub_1_clk_inv_int         : std_logic;
  signal spi_hub_1_ss_high_int         : std_logic;
  signal spi_hub_2_port_int         : std_logic_vector(2 downto 0);
  signal spi_hub_2_four_w_int         : std_logic;
  signal spi_hub_2_clk_inv_int         : std_logic;
  signal spi_hub_2_ss_high_int         : std_logic;
  signal spi_hub_3_port_int         : std_logic_vector(2 downto 0);
  signal spi_hub_3_four_w_int         : std_logic;
  signal spi_hub_3_clk_inv_int         : std_logic;
  signal spi_hub_3_ss_high_int         : std_logic;
  signal spi_hub_4_port_int         : std_logic_vector(2 downto 0);
  signal spi_hub_4_four_w_int         : std_logic;
  signal spi_hub_4_clk_inv_int         : std_logic;
  signal spi_hub_4_ss_high_int         : std_logic;
  signal spi_hub_5_port_int         : std_logic_vector(2 downto 0);
  signal spi_hub_5_four_w_int         : std_logic;
  signal spi_hub_5_clk_inv_int         : std_logic;
  signal spi_hub_5_ss_high_int         : std_logic;
  signal spi_hub_6_port_int         : std_logic_vector(2 downto 0);
  signal spi_hub_6_four_w_int         : std_logic;
  signal spi_hub_6_clk_inv_int         : std_logic;
  signal spi_hub_6_ss_high_int         : std_logic;
  signal spi_hub_7_port_int         : std_logic_vector(2 downto 0);
  signal spi_hub_7_four_w_int         : std_logic;
  signal spi_hub_7_clk_inv_int         : std_logic;
  signal spi_hub_7_ss_high_int         : std_logic;

  -- AXI constants
  -- SLVERR will be generated whenever a read is done from a empty FIFO or
  -- write only register, or write is done to a full FIFO or read only register
  constant resp_okay_c   : std_logic_vector(1 downto 0) := "00";  -- Normal access OK response
  constant resp_exokay_c : std_logic_vector(1 downto 0) := "01";  -- Exclusive access OK response
  constant resp_slverr_c : std_logic_vector(1 downto 0) := "10";  -- Slave error
  constant resp_decerr_c : std_logic_vector(1 downto 0) := "11";  -- Decode error (not used)

  constant miri_timeout_c : natural := 64; -- Maximum number of cycles for a MIRI access.

  -- Register type for current access
  type reg_type_t is (none, unmapped, std_wr, mem_wr, miri_wr, std_rd, mem_rd, miri_rd);

  -- Internal AXI registers
  signal awaddr_reg_s  : std_logic_vector(31 downto 0);
  signal araddr_reg_s  : std_logic_vector(31 downto 0);
  signal awready_s     : std_logic;
  signal wready_s      : std_logic;
  signal arready_s     : std_logic;
  signal bvalid_s      : std_logic;
  signal rvalid_s      : std_logic;
  signal wdata_reg_s   : std_logic_vector(31 downto 0);
  signal wstrb_reg_s   : std_logic_vector( 3 downto 0);

  -- AXI 'command' capture control
  signal aw_captured_s : std_logic;    -- Signals when AWADDR has been captured
  signal w_captured_s  : std_logic;    -- Signals when WDATA and WSTRB has been captured
  signal ar_captured_s : std_logic;    -- Signals when AWADDR has been captured
  signal wr_valid_i    : std_logic;    -- AWADDR and WDATA captured
  signal rd_valid_i    : std_logic;    -- ARADDR captured
  signal bready_wait_s : std_logic;    -- Wait states for BREADY
  signal rready_wait_s : std_logic;    -- Wait states for RREADY

  -- Read/Write arbitration control
  signal rd_nwr_prio_s : std_logic;    -- Next priority ('1' = Read, '0' = Write)
  signal wr_ongoing_s  : std_logic;    -- Write access ongoing
  signal rd_ongoing_s  : std_logic;    -- Read access ongoing

begin

  -----------------------------------------------------------------------------
  -- Signal assignments
  -----------------------------------------------------------------------------
  awready <= awready_s;
  wready  <= wready_s;
  arready <= arready_s;
  bvalid  <= bvalid_s;
  rvalid  <= rvalid_s;

  wr_valid_i <= '1' when aw_captured_s = '1' and w_captured_s = '1' else '0';
  rd_valid_i <= '1' when ar_captured_s = '1' else '0';

  spi_ctrl_rate             <= spi_ctrl_rate_int;
  spi_ctrl_clk_idle             <= spi_ctrl_clk_idle_int;
  spi_ctrl_ss             <= spi_ctrl_ss_int;
  spi_ctrl_ss_bidir             <= spi_ctrl_ss_bidir_int;
  spi_ctrl_ss_mode             <= spi_ctrl_ss_mode_int;
  spi_ctrl_en             <= spi_ctrl_en_int;
  spi_ctrl_lsbfe             <= spi_ctrl_lsbfe_int;
  spi_ctrl_cpha             <= spi_ctrl_cpha_int;
  spi_ctrl_cpol             <= spi_ctrl_cpol_int;
  spi_ctrl_mode             <= spi_ctrl_mode_int;
  spi_length_dir             <= spi_length_dir_int;
  spi_length_val             <= spi_length_val_int;
  spi_cmd_reset_cmd         <= spi_cmd_reset_cmd_int;
  spi_cmd_strb_cmd         <= spi_cmd_strb_cmd_int;
  spi_tx_data             <= spi_tx_data_int;
  spi_hub_ss_en             <= spi_hub_ss_en_int;
  spi_hub_0_port             <= spi_hub_0_port_int;
  spi_hub_0_four_w             <= spi_hub_0_four_w_int;
  spi_hub_0_clk_inv             <= spi_hub_0_clk_inv_int;
  spi_hub_0_ss_high             <= spi_hub_0_ss_high_int;
  spi_hub_1_port             <= spi_hub_1_port_int;
  spi_hub_1_four_w             <= spi_hub_1_four_w_int;
  spi_hub_1_clk_inv             <= spi_hub_1_clk_inv_int;
  spi_hub_1_ss_high             <= spi_hub_1_ss_high_int;
  spi_hub_2_port             <= spi_hub_2_port_int;
  spi_hub_2_four_w             <= spi_hub_2_four_w_int;
  spi_hub_2_clk_inv             <= spi_hub_2_clk_inv_int;
  spi_hub_2_ss_high             <= spi_hub_2_ss_high_int;
  spi_hub_3_port             <= spi_hub_3_port_int;
  spi_hub_3_four_w             <= spi_hub_3_four_w_int;
  spi_hub_3_clk_inv             <= spi_hub_3_clk_inv_int;
  spi_hub_3_ss_high             <= spi_hub_3_ss_high_int;
  spi_hub_4_port             <= spi_hub_4_port_int;
  spi_hub_4_four_w             <= spi_hub_4_four_w_int;
  spi_hub_4_clk_inv             <= spi_hub_4_clk_inv_int;
  spi_hub_4_ss_high             <= spi_hub_4_ss_high_int;
  spi_hub_5_port             <= spi_hub_5_port_int;
  spi_hub_5_four_w             <= spi_hub_5_four_w_int;
  spi_hub_5_clk_inv             <= spi_hub_5_clk_inv_int;
  spi_hub_5_ss_high             <= spi_hub_5_ss_high_int;
  spi_hub_6_port             <= spi_hub_6_port_int;
  spi_hub_6_four_w             <= spi_hub_6_four_w_int;
  spi_hub_6_clk_inv             <= spi_hub_6_clk_inv_int;
  spi_hub_6_ss_high             <= spi_hub_6_ss_high_int;
  spi_hub_7_port             <= spi_hub_7_port_int;
  spi_hub_7_four_w             <= spi_hub_7_four_w_int;
  spi_hub_7_clk_inv             <= spi_hub_7_clk_inv_int;
  spi_hub_7_ss_high             <= spi_hub_7_ss_high_int;

  -----------------------------------------------------------------------------
  -- Read or Write to the SPI registers
  -----------------------------------------------------------------------------
  read_write_spi_registers: process (clk_axi)
    variable wr_reg_type_v  : reg_type_t;  -- Current register access type
    variable rd_reg_type_v  : reg_type_t;  -- Current register access type
  begin
    if clk_axi'event and clk_axi = '1' then
      if rst_axi = '1' then
        bresp           <= resp_okay_c;
        bvalid_s        <= '0';
        bready_wait_s   <= '0';
        rready_wait_s   <= '0';
        rresp           <= resp_okay_c;
        rdata           <= (others => '0');
        rvalid_s        <= '0';
        awready_s       <= '1';
        wready_s        <= '1';
        arready_s       <= '1';
        aw_captured_s   <= '0';
        w_captured_s    <= '0';
        ar_captured_s   <= '0';
        rd_nwr_prio_s   <= '0';           -- Start with write priority
        wr_ongoing_s    <= '0';
        rd_ongoing_s    <= '0';
  
        spi_status_act_set         <= '0';
        spi_status_act_trap        <= '0';
        spi_status_act_mask        <= '0';
        spi_status_act_force       <= '0';
        spi_status_act_trig        <= '0';
        spi_status_act_db          <= '0';
        spi_status_rx_or_set         <= '0';
        spi_status_rx_or_trap        <= '0';
        spi_status_rx_or_mask        <= '0';
        spi_status_rx_or_force       <= '0';
        spi_status_rx_or_trig        <= '0';
        spi_status_rx_or_db          <= '0';
        spi_status_rx_avail_set         <= '0';
        spi_status_rx_avail_trap        <= '0';
        spi_status_rx_avail_mask        <= '0';
        spi_status_rx_avail_force       <= '0';
        spi_status_rx_avail_trig        <= '0';
        spi_status_rx_avail_db          <= '0';
        spi_status_rx_full_set         <= '0';
        spi_status_rx_full_trap        <= '0';
        spi_status_rx_full_mask        <= '0';
        spi_status_rx_full_force       <= '0';
        spi_status_rx_full_trig        <= '0';
        spi_status_rx_full_db          <= '0';
        spi_status_tx_ur_set         <= '0';
        spi_status_tx_ur_trap        <= '0';
        spi_status_tx_ur_mask        <= '0';
        spi_status_tx_ur_force       <= '0';
        spi_status_tx_ur_trig        <= '0';
        spi_status_tx_ur_db          <= '0';
        spi_status_tx_full_set         <= '0';
        spi_status_tx_full_trap        <= '0';
        spi_status_tx_full_mask        <= '0';
        spi_status_tx_full_force       <= '0';
        spi_status_tx_full_trig        <= '0';
        spi_status_tx_full_db          <= '0';
        spi_status_tx_empty_set         <= '0';
        spi_status_tx_empty_trap        <= '0';
        spi_status_tx_empty_mask        <= '0';
        spi_status_tx_empty_force       <= '0';
        spi_status_tx_empty_trig        <= '0';
        spi_status_tx_empty_db          <= '0';
        spi_status_done_set         <= '0';
        spi_status_done_trap        <= '0';
        spi_status_done_mask        <= '0';
        spi_status_done_force       <= '0';
        spi_status_done_trig        <= '0';
        spi_status_done_db          <= '0';
        spi_ctrl_rate_int         <= "11111111111111";
        spi_ctrl_clk_idle_int         <= '0';
        spi_ctrl_ss_int         <= '0';
        spi_ctrl_ss_bidir_int         <= '0';
        spi_ctrl_ss_mode_int         <= '0';
        spi_ctrl_en_int         <= '1';
        spi_ctrl_lsbfe_int         <= '0';
        spi_ctrl_cpha_int         <= '0';
        spi_ctrl_cpol_int         <= '0';
        spi_ctrl_mode_int         <= "00";
        spi_length_dir_int         <= "00000000";
        spi_length_val_int         <= "00001000";
        spi_cmd_reset_cmd_int     <= '0';
        spi_cmd_strb_cmd_int     <= '0';
        spi_tx_put     <= '0';
        spi_tx_be      <= "0000";
        spi_tx_data_int         <= "00000000000000000000000000000000";
        spi_rx_get        <= '0';
        spi_rx_be         <= "0000";
        spi_hub_ss_en_int         <= "11111";
        spi_hub_0_port_int         <= "000";
        spi_hub_0_four_w_int         <= '0';
        spi_hub_0_clk_inv_int         <= '0';
        spi_hub_0_ss_high_int         <= '0';
        spi_hub_1_port_int         <= "000";
        spi_hub_1_four_w_int         <= '0';
        spi_hub_1_clk_inv_int         <= '0';
        spi_hub_1_ss_high_int         <= '0';
        spi_hub_2_port_int         <= "000";
        spi_hub_2_four_w_int         <= '0';
        spi_hub_2_clk_inv_int         <= '0';
        spi_hub_2_ss_high_int         <= '0';
        spi_hub_3_port_int         <= "000";
        spi_hub_3_four_w_int         <= '0';
        spi_hub_3_clk_inv_int         <= '0';
        spi_hub_3_ss_high_int         <= '0';
        spi_hub_4_port_int         <= "000";
        spi_hub_4_four_w_int         <= '0';
        spi_hub_4_clk_inv_int         <= '0';
        spi_hub_4_ss_high_int         <= '0';
        spi_hub_5_port_int         <= "000";
        spi_hub_5_four_w_int         <= '0';
        spi_hub_5_clk_inv_int         <= '0';
        spi_hub_5_ss_high_int         <= '0';
        spi_hub_6_port_int         <= "000";
        spi_hub_6_four_w_int         <= '0';
        spi_hub_6_clk_inv_int         <= '0';
        spi_hub_6_ss_high_int         <= '0';
        spi_hub_7_port_int         <= "000";
        spi_hub_7_four_w_int         <= '0';
        spi_hub_7_clk_inv_int         <= '0';
        spi_hub_7_ss_high_int         <= '0';

      else
        -- Default local variable values
        wr_reg_type_v  := none;
        rd_reg_type_v  := none;

        -- Default register values
        wr_ongoing_s    <= '0';
        rd_ongoing_s    <= '0';
  
        spi_status_act_set       <= ((not spi_status_act_trig) and
                                                     spi_status_act) OR
                                                     (spi_status_act_trig and
                                                     spi_status_act_edge) OR
                                                     spi_status_act_force;
        spi_status_act_trap      <= spi_status_act_set OR
                                                     spi_status_act_trap;
        spi_status_act_force     <= '0';
        spi_status_act_db        <= ((not spi_status_act_trig) and
                                                     spi_status_act) OR
                                                     (spi_status_act_trig and
                                                     spi_status_act_edge) OR
                                                     spi_status_act_force OR
                                                     spi_status_act_db;
        spi_status_rx_or_set       <= ((not spi_status_rx_or_trig) and
                                                     spi_status_rx_or) OR
                                                     (spi_status_rx_or_trig and
                                                     spi_status_rx_or_edge) OR
                                                     spi_status_rx_or_force;
        spi_status_rx_or_trap      <= spi_status_rx_or_set OR
                                                     spi_status_rx_or_trap;
        spi_status_rx_or_force     <= '0';
        spi_status_rx_or_db        <= ((not spi_status_rx_or_trig) and
                                                     spi_status_rx_or) OR
                                                     (spi_status_rx_or_trig and
                                                     spi_status_rx_or_edge) OR
                                                     spi_status_rx_or_force OR
                                                     spi_status_rx_or_db;
        spi_status_rx_avail_set       <= ((not spi_status_rx_avail_trig) and
                                                     spi_status_rx_avail) OR
                                                     (spi_status_rx_avail_trig and
                                                     spi_status_rx_avail_edge) OR
                                                     spi_status_rx_avail_force;
        spi_status_rx_avail_trap      <= spi_status_rx_avail_set OR
                                                     spi_status_rx_avail_trap;
        spi_status_rx_avail_force     <= '0';
        spi_status_rx_avail_db        <= ((not spi_status_rx_avail_trig) and
                                                     spi_status_rx_avail) OR
                                                     (spi_status_rx_avail_trig and
                                                     spi_status_rx_avail_edge) OR
                                                     spi_status_rx_avail_force OR
                                                     spi_status_rx_avail_db;
        spi_status_rx_full_set       <= ((not spi_status_rx_full_trig) and
                                                     spi_status_rx_full) OR
                                                     (spi_status_rx_full_trig and
                                                     spi_status_rx_full_edge) OR
                                                     spi_status_rx_full_force;
        spi_status_rx_full_trap      <= spi_status_rx_full_set OR
                                                     spi_status_rx_full_trap;
        spi_status_rx_full_force     <= '0';
        spi_status_rx_full_db        <= ((not spi_status_rx_full_trig) and
                                                     spi_status_rx_full) OR
                                                     (spi_status_rx_full_trig and
                                                     spi_status_rx_full_edge) OR
                                                     spi_status_rx_full_force OR
                                                     spi_status_rx_full_db;
        spi_status_tx_ur_set       <= ((not spi_status_tx_ur_trig) and
                                                     spi_status_tx_ur) OR
                                                     (spi_status_tx_ur_trig and
                                                     spi_status_tx_ur_edge) OR
                                                     spi_status_tx_ur_force;
        spi_status_tx_ur_trap      <= spi_status_tx_ur_set OR
                                                     spi_status_tx_ur_trap;
        spi_status_tx_ur_force     <= '0';
        spi_status_tx_ur_db        <= ((not spi_status_tx_ur_trig) and
                                                     spi_status_tx_ur) OR
                                                     (spi_status_tx_ur_trig and
                                                     spi_status_tx_ur_edge) OR
                                                     spi_status_tx_ur_force OR
                                                     spi_status_tx_ur_db;
        spi_status_tx_full_set       <= ((not spi_status_tx_full_trig) and
                                                     spi_status_tx_full) OR
                                                     (spi_status_tx_full_trig and
                                                     spi_status_tx_full_edge) OR
                                                     spi_status_tx_full_force;
        spi_status_tx_full_trap      <= spi_status_tx_full_set OR
                                                     spi_status_tx_full_trap;
        spi_status_tx_full_force     <= '0';
        spi_status_tx_full_db        <= ((not spi_status_tx_full_trig) and
                                                     spi_status_tx_full) OR
                                                     (spi_status_tx_full_trig and
                                                     spi_status_tx_full_edge) OR
                                                     spi_status_tx_full_force OR
                                                     spi_status_tx_full_db;
        spi_status_tx_empty_set       <= ((not spi_status_tx_empty_trig) and
                                                     spi_status_tx_empty) OR
                                                     (spi_status_tx_empty_trig and
                                                     spi_status_tx_empty_edge) OR
                                                     spi_status_tx_empty_force;
        spi_status_tx_empty_trap      <= spi_status_tx_empty_set OR
                                                     spi_status_tx_empty_trap;
        spi_status_tx_empty_force     <= '0';
        spi_status_tx_empty_db        <= ((not spi_status_tx_empty_trig) and
                                                     spi_status_tx_empty) OR
                                                     (spi_status_tx_empty_trig and
                                                     spi_status_tx_empty_edge) OR
                                                     spi_status_tx_empty_force OR
                                                     spi_status_tx_empty_db;
        spi_status_done_set       <= ((not spi_status_done_trig) and
                                                     spi_status_done) OR
                                                     (spi_status_done_trig and
                                                     spi_status_done_edge) OR
                                                     spi_status_done_force;
        spi_status_done_trap      <= spi_status_done_set OR
                                                     spi_status_done_trap;
        spi_status_done_force     <= '0';
        spi_status_done_db        <= ((not spi_status_done_trig) and
                                                     spi_status_done) OR
                                                     (spi_status_done_trig and
                                                     spi_status_done_edge) OR
                                                     spi_status_done_force OR
                                                     spi_status_done_db;
        spi_cmd_reset_cmd_int     <= spi_cmd_reset_cmd_int and
                                                       (not spi_cmd_reset_ack);
        spi_cmd_strb_cmd_int     <= spi_cmd_strb_cmd_int and
                                                       (not spi_cmd_strb_ack);
        spi_tx_put     <= '0';
        spi_tx_be      <= "0000";
        spi_rx_get         <= '0';
        spi_rx_be          <= "0000";

        -------------------------------------------------------------------------
        -------------------------------------------------------------------------
        -- Write access
        -------------------------------------------------------------------------
        -------------------------------------------------------------------------

        if bready = '1' and bvalid_s = '1' then
          bvalid_s      <= '0';
          bready_wait_s <= '0';
        end if;

        if awvalid = '1' and aw_captured_s = '0' then
          awready_s     <= '0';
          aw_captured_s <= '1';
        end if;

        if wvalid = '1' and w_captured_s = '0' then
          wready_s     <= '0';
          w_captured_s <= '1';
        end if;

        -------------------------------------------------------------------------
        -- Write access
        -------------------------------------------------------------------------
        if wr_valid_i = '1' and bready_wait_s = '0' and rd_ongoing_s = '0' and
          ((rd_valid_i = '1' and rd_nwr_prio_s = '0') or rd_valid_i = '0' or wr_ongoing_s = '1') then
          wr_reg_type_v := unmapped;
          bresp         <= resp_okay_c; -- Assume that transaction is okay
          rd_nwr_prio_s <= '1';

          -------------------------------------------------------------------------
          -- Write address decoder for standard registers
          -------------------------------------------------------------------------
          case awaddr_reg_s(12 downto 2) is
            when "00000000000" => -- Register SPI_STATUS is on HEX Address 0x00000000
              wr_reg_type_v := std_wr;
              bresp <= resp_slverr_c;     -- Write access to read only register

          when "00000000001" => -- Register SPI_STATUS_TRAP is on HEX Address 0x00000004
            wr_reg_type_v := std_wr;
            if wstrb_reg_s(0) = '1' then
              spi_status_act_trap <= ((not wdata_reg_s(7)) and
              spi_status_act_trap) or spi_status_act_set;
              spi_status_rx_or_trap <= ((not wdata_reg_s(6)) and
              spi_status_rx_or_trap) or spi_status_rx_or_set;
              spi_status_rx_avail_trap <= ((not wdata_reg_s(5)) and
              spi_status_rx_avail_trap) or spi_status_rx_avail_set;
              spi_status_rx_full_trap <= ((not wdata_reg_s(4)) and
              spi_status_rx_full_trap) or spi_status_rx_full_set;
              spi_status_tx_ur_trap <= ((not wdata_reg_s(3)) and
              spi_status_tx_ur_trap) or spi_status_tx_ur_set;
              spi_status_tx_full_trap <= ((not wdata_reg_s(2)) and
              spi_status_tx_full_trap) or spi_status_tx_full_set;
              spi_status_tx_empty_trap <= ((not wdata_reg_s(1)) and
              spi_status_tx_empty_trap) or spi_status_tx_empty_set;
              spi_status_done_trap <= ((not wdata_reg_s(0)) and
              spi_status_done_trap) or spi_status_done_set;
            end if;

          when "00000000010" => -- Register SPI_STATUS_MASK is on HEX Address 0x00000008
            wr_reg_type_v := std_wr;
            if wstrb_reg_s(0) = '1' then
              spi_status_act_mask <= wdata_reg_s(7);
              spi_status_rx_or_mask <= wdata_reg_s(6);
              spi_status_rx_avail_mask <= wdata_reg_s(5);
              spi_status_rx_full_mask <= wdata_reg_s(4);
              spi_status_tx_ur_mask <= wdata_reg_s(3);
              spi_status_tx_full_mask <= wdata_reg_s(2);
              spi_status_tx_empty_mask <= wdata_reg_s(1);
              spi_status_done_mask <= wdata_reg_s(0);
            end if;

          when "00000000011" => -- Register SPI_STATUS_FORCE is on HEX Address 0x0000000c
            wr_reg_type_v := std_wr;
            if wstrb_reg_s(0) = '1' then
              spi_status_act_force <= wdata_reg_s(7);
              spi_status_rx_or_force <= wdata_reg_s(6);
              spi_status_rx_avail_force <= wdata_reg_s(5);
              spi_status_rx_full_force <= wdata_reg_s(4);
              spi_status_tx_ur_force <= wdata_reg_s(3);
              spi_status_tx_full_force <= wdata_reg_s(2);
              spi_status_tx_empty_force <= wdata_reg_s(1);
              spi_status_done_force <= wdata_reg_s(0);
            end if;

            when "00000000100" => -- Register SPI_STATUS_DB is on HEX Address 0x00000010
              wr_reg_type_v := std_wr;
              -- Write access to READ ONLY position
              bresp <= resp_slverr_c;     -- Write access to read only register

          when "00000000101" => -- Register SPI_STATUS_TRIG is on HEX Address 0x00000014
            wr_reg_type_v := std_wr;
            if wstrb_reg_s(0) = '1' then
              spi_status_act_trig <= wdata_reg_s(7);
              spi_status_rx_or_trig <= wdata_reg_s(6);
              spi_status_rx_avail_trig <= wdata_reg_s(5);
              spi_status_rx_full_trig <= wdata_reg_s(4);
              spi_status_tx_ur_trig <= wdata_reg_s(3);
              spi_status_tx_full_trig <= wdata_reg_s(2);
              spi_status_tx_empty_trig <= wdata_reg_s(1);
              spi_status_done_trig <= wdata_reg_s(0);
            end if;
            when "00000000110" => -- Register SPI_CTRL is on HEX Address 0x00000018
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(3) = '1' then
              spi_ctrl_rate_int(13 downto 8) <= wdata_reg_s(29 downto 24);
              end if;
              if wstrb_reg_s(2) = '1' then
              spi_ctrl_rate_int(7 downto 0) <= wdata_reg_s(23 downto 16);
              end if;
              if wstrb_reg_s(1) = '1' then
              spi_ctrl_clk_idle_int <= wdata_reg_s(12);
              spi_ctrl_ss_int <= wdata_reg_s(9);
              spi_ctrl_ss_bidir_int <= wdata_reg_s(8);
              end if;
              if wstrb_reg_s(0) = '1' then
              spi_ctrl_ss_mode_int <= wdata_reg_s(7);
              spi_ctrl_en_int <= wdata_reg_s(5);
              spi_ctrl_lsbfe_int <= wdata_reg_s(4);
              spi_ctrl_cpha_int <= wdata_reg_s(3);
              spi_ctrl_cpol_int <= wdata_reg_s(2);
              spi_ctrl_mode_int(1 downto 0) <= wdata_reg_s(1 downto 0);
              end if;

            when "00000000111" => -- Register SPI_LENGTH is on HEX Address 0x0000001c
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(2) = '1' then
              spi_length_dir_int(7 downto 0) <= wdata_reg_s(23 downto 16);
              end if;
              if wstrb_reg_s(0) = '1' then
              spi_length_val_int(7 downto 0) <= wdata_reg_s(7 downto 0);
              end if;

            when "00000001000" => -- Register SPI_CMD is on HEX Address 0x00000020
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(0) = '1' then
              spi_cmd_reset_cmd_int <= wdata_reg_s(1);
              spi_cmd_strb_cmd_int <= wdata_reg_s(0);
              end if;

            when "00000001001" => -- Register SPI_TX is on HEX Address 0x00000024
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(3) = '1' then
                spi_tx_put   <= '1';
                spi_tx_be(3) <= '1';
              spi_tx_data_int(31 downto 24)     <= wdata_reg_s(31 downto 24);
              end if;
              if wstrb_reg_s(2) = '1' then
                spi_tx_put   <= '1';
                spi_tx_be(2) <= '1';
              spi_tx_data_int(23 downto 16)     <= wdata_reg_s(23 downto 16);
              end if;
              if wstrb_reg_s(1) = '1' then
                spi_tx_put   <= '1';
                spi_tx_be(1) <= '1';
              spi_tx_data_int(15 downto 8)     <= wdata_reg_s(15 downto 8);
              end if;
              if wstrb_reg_s(0) = '1' then
                spi_tx_put   <= '1';
                spi_tx_be(0) <= '1';
              spi_tx_data_int(7 downto 0)     <= wdata_reg_s(7 downto 0);
              end if;

            when "00000001010" => -- Register SPI_RX is on HEX Address 0x00000028
              wr_reg_type_v := std_wr;
              bresp <= resp_slverr_c;     -- Write access to read only register
            when "00000001011" => -- Register SPI_HUB_SS is on HEX Address 0x0000002c
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(0) = '1' then
              spi_hub_ss_en_int(4 downto 0) <= wdata_reg_s(4 downto 0);
              end if;

            when "00000001100" => -- Register SPI_HUB_0 is on HEX Address 0x00000030
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(0) = '1' then
              spi_hub_0_port_int(2 downto 0) <= wdata_reg_s(6 downto 4);
              spi_hub_0_four_w_int <= wdata_reg_s(2);
              spi_hub_0_clk_inv_int <= wdata_reg_s(1);
              spi_hub_0_ss_high_int <= wdata_reg_s(0);
              end if;

            when "00000001101" => -- Register SPI_HUB_1 is on HEX Address 0x00000034
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(0) = '1' then
              spi_hub_1_port_int(2 downto 0) <= wdata_reg_s(6 downto 4);
              spi_hub_1_four_w_int <= wdata_reg_s(2);
              spi_hub_1_clk_inv_int <= wdata_reg_s(1);
              spi_hub_1_ss_high_int <= wdata_reg_s(0);
              end if;

            when "00000001110" => -- Register SPI_HUB_2 is on HEX Address 0x00000038
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(0) = '1' then
              spi_hub_2_port_int(2 downto 0) <= wdata_reg_s(6 downto 4);
              spi_hub_2_four_w_int <= wdata_reg_s(2);
              spi_hub_2_clk_inv_int <= wdata_reg_s(1);
              spi_hub_2_ss_high_int <= wdata_reg_s(0);
              end if;

            when "00000001111" => -- Register SPI_HUB_3 is on HEX Address 0x0000003c
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(0) = '1' then
              spi_hub_3_port_int(2 downto 0) <= wdata_reg_s(6 downto 4);
              spi_hub_3_four_w_int <= wdata_reg_s(2);
              spi_hub_3_clk_inv_int <= wdata_reg_s(1);
              spi_hub_3_ss_high_int <= wdata_reg_s(0);
              end if;

            when "00000010000" => -- Register SPI_HUB_4 is on HEX Address 0x00000040
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(0) = '1' then
              spi_hub_4_port_int(2 downto 0) <= wdata_reg_s(6 downto 4);
              spi_hub_4_four_w_int <= wdata_reg_s(2);
              spi_hub_4_clk_inv_int <= wdata_reg_s(1);
              spi_hub_4_ss_high_int <= wdata_reg_s(0);
              end if;

            when "00000010001" => -- Register SPI_HUB_5 is on HEX Address 0x00000044
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(0) = '1' then
              spi_hub_5_port_int(2 downto 0) <= wdata_reg_s(6 downto 4);
              spi_hub_5_four_w_int <= wdata_reg_s(2);
              spi_hub_5_clk_inv_int <= wdata_reg_s(1);
              spi_hub_5_ss_high_int <= wdata_reg_s(0);
              end if;

            when "00000010010" => -- Register SPI_HUB_6 is on HEX Address 0x00000048
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(0) = '1' then
              spi_hub_6_port_int(2 downto 0) <= wdata_reg_s(6 downto 4);
              spi_hub_6_four_w_int <= wdata_reg_s(2);
              spi_hub_6_clk_inv_int <= wdata_reg_s(1);
              spi_hub_6_ss_high_int <= wdata_reg_s(0);
              end if;

            when "00000010011" => -- Register SPI_HUB_7 is on HEX Address 0x0000004c
              wr_reg_type_v := std_wr;
              if wstrb_reg_s(0) = '1' then
              spi_hub_7_port_int(2 downto 0) <= wdata_reg_s(6 downto 4);
              spi_hub_7_four_w_int <= wdata_reg_s(2);
              spi_hub_7_clk_inv_int <= wdata_reg_s(1);
              spi_hub_7_ss_high_int <= wdata_reg_s(0);
              end if;

             -- OUTSIDE OF MEMORY MAP or EXTERNAL MEMORY/MIRI
             when others => null;          -- Do nothing if wrong address
          end case;

        end if;


        -------------------------------------------------------------------------
        -- Write channel handshake control
        -------------------------------------------------------------------------
        -- AXI signaling for std_wr type accesses
        if wr_reg_type_v = std_wr or wr_reg_type_v = unmapped then
          wr_ongoing_s    <= '1';
          awready_s       <= '1';
          wready_s        <= '1';
          bvalid_s        <= '1';
          aw_captured_s   <= '0';
          w_captured_s    <= '0';
          if bready = '1' then
            bready_wait_s <= '0';
          else
            bready_wait_s <= '1';
          end if;

        end if;


        -------------------------------------------------------------------------
        -------------------------------------------------------------------------
        -- Read access
        -------------------------------------------------------------------------
        -------------------------------------------------------------------------

        if rready = '1' and rvalid_s = '1' then
          rvalid_s      <= '0';
          rready_wait_s <= '0';
        end if;

        if arvalid = '1' and ar_captured_s = '0' then
          arready_s     <= '0';
          ar_captured_s <= '1';
        end if;

        -------------------------------------------------------------------------
        -- Read access
        -------------------------------------------------------------------------
        if rd_valid_i = '1' and rready_wait_s = '0' and wr_ongoing_s = '0' and
          ((wr_valid_i = '1' and rd_nwr_prio_s = '1') or wr_valid_i = '0' or rd_ongoing_s = '1') then
          -- Default values
          rd_reg_type_v := unmapped;
          rresp         <= resp_okay_c;       -- Assume that transaction is okay
          rdata         <= x"00000000";
          rd_nwr_prio_s <= '0';

          -------------------------------------------------------------------------
          -- Read address decoder for standard registers
          -------------------------------------------------------------------------
          case araddr_reg_s(12 downto 2) is

            when "00000000000" => -- Register SPI_STATUS is on HEX Address 0x00000000
            rd_reg_type_v := std_rd;
              rdata(7)  <= spi_status_act;
              rdata(6)  <= spi_status_rx_or;
              rdata(5)  <= spi_status_rx_avail;
              rdata(4)  <= spi_status_rx_full;
              rdata(3)  <= spi_status_tx_ur;
              rdata(2)  <= spi_status_tx_full;
              rdata(1)  <= spi_status_tx_empty;
              rdata(0)  <= spi_status_done;

          when "00000000001" => -- Register SPI_STATUS_TRAP is on HEX Address 0x00000004
            rd_reg_type_v := std_rd;
            rdata(7)  <= spi_status_act_trap;
            rdata(6)  <= spi_status_rx_or_trap;
            rdata(5)  <= spi_status_rx_avail_trap;
            rdata(4)  <= spi_status_rx_full_trap;
            rdata(3)  <= spi_status_tx_ur_trap;
            rdata(2)  <= spi_status_tx_full_trap;
            rdata(1)  <= spi_status_tx_empty_trap;
            rdata(0)  <= spi_status_done_trap;

          when "00000000010" => -- Register SPI_STATUS_MASK is on HEX Address 0x00000008
            rd_reg_type_v := std_rd;
            rdata(7)  <= spi_status_act_mask;
            rdata(6)  <= spi_status_rx_or_mask;
            rdata(5)  <= spi_status_rx_avail_mask;
            rdata(4)  <= spi_status_rx_full_mask;
            rdata(3)  <= spi_status_tx_ur_mask;
            rdata(2)  <= spi_status_tx_full_mask;
            rdata(1)  <= spi_status_tx_empty_mask;
            rdata(0)  <= spi_status_done_mask;

            when "00000000011" => -- Register SPI_STATUS_FORCE is on HEX Address 0x0000000c
              rd_reg_type_v := std_rd;
              rresp <= resp_slverr_c;           -- Read access to WRITE ONLY position

            when "00000000100" => -- Register SPI_STATUS_DB is on HEX Address 0x00000010
              rd_reg_type_v := std_rd;
              rdata(7)  <= spi_status_act_db;
              spi_status_act_db  <= '0';
              rdata(6)  <= spi_status_rx_or_db;
              spi_status_rx_or_db  <= '0';
              rdata(5)  <= spi_status_rx_avail_db;
              spi_status_rx_avail_db  <= '0';
              rdata(4)  <= spi_status_rx_full_db;
              spi_status_rx_full_db  <= '0';
              rdata(3)  <= spi_status_tx_ur_db;
              spi_status_tx_ur_db  <= '0';
              rdata(2)  <= spi_status_tx_full_db;
              spi_status_tx_full_db  <= '0';
              rdata(1)  <= spi_status_tx_empty_db;
              spi_status_tx_empty_db  <= '0';
              rdata(0)  <= spi_status_done_db;
              spi_status_done_db  <= '0';

          when "00000000101" => -- Register SPI_STATUS_TRIG is on HEX Address 0x00000014
            rd_reg_type_v := std_rd;
            rdata(7)  <= spi_status_act_trig;
            rdata(6)  <= spi_status_rx_or_trig;
            rdata(5)  <= spi_status_rx_avail_trig;
            rdata(4)  <= spi_status_rx_full_trig;
            rdata(3)  <= spi_status_tx_ur_trig;
            rdata(2)  <= spi_status_tx_full_trig;
            rdata(1)  <= spi_status_tx_empty_trig;
            rdata(0)  <= spi_status_done_trig;

            when "00000000110" => -- Register SPI_CTRL is on HEX Address 0x00000018
            rd_reg_type_v := std_rd;
              rdata(29 downto 16)  <= spi_ctrl_rate_int;
              rdata(12)  <= spi_ctrl_clk_idle_int;
              rdata(9)  <= spi_ctrl_ss_int;
              rdata(8)  <= spi_ctrl_ss_bidir_int;
              rdata(7)  <= spi_ctrl_ss_mode_int;
              rdata(5)  <= spi_ctrl_en_int;
              rdata(4)  <= spi_ctrl_lsbfe_int;
              rdata(3)  <= spi_ctrl_cpha_int;
              rdata(2)  <= spi_ctrl_cpol_int;
              rdata(1 downto 0)  <= spi_ctrl_mode_int;

            when "00000000111" => -- Register SPI_LENGTH is on HEX Address 0x0000001c
            rd_reg_type_v := std_rd;
              rdata(23 downto 16)  <= spi_length_dir_int;
              rdata(7 downto 0)  <= spi_length_val_int;

            when "00000001000" => -- Register SPI_CMD is on HEX Address 0x00000020
            rd_reg_type_v := std_rd;
              rdata(1)  <= spi_cmd_reset_cmd_int;
              rdata(0)  <= spi_cmd_strb_cmd_int;

            when "00000001001" => -- Register SPI_TX is on HEX Address 0x00000024
            rd_reg_type_v := std_rd;
              rresp <= resp_slverr_c;           -- Read access to WRITE ONLY position

            when "00000001010" => -- Register SPI_RX is on HEX Address 0x00000028
            rd_reg_type_v := std_rd;
              spi_rx_get                    <= '1';
              spi_rx_be                     <= "1111";
              rdata(31 downto 0)  <= spi_rx_data;

            when "00000001011" => -- Register SPI_HUB_SS is on HEX Address 0x0000002c
            rd_reg_type_v := std_rd;
              rdata(4 downto 0)  <= spi_hub_ss_en_int;

            when "00000001100" => -- Register SPI_HUB_0 is on HEX Address 0x00000030
            rd_reg_type_v := std_rd;
              rdata(6 downto 4)  <= spi_hub_0_port_int;
              rdata(2)  <= spi_hub_0_four_w_int;
              rdata(1)  <= spi_hub_0_clk_inv_int;
              rdata(0)  <= spi_hub_0_ss_high_int;

            when "00000001101" => -- Register SPI_HUB_1 is on HEX Address 0x00000034
            rd_reg_type_v := std_rd;
              rdata(6 downto 4)  <= spi_hub_1_port_int;
              rdata(2)  <= spi_hub_1_four_w_int;
              rdata(1)  <= spi_hub_1_clk_inv_int;
              rdata(0)  <= spi_hub_1_ss_high_int;

            when "00000001110" => -- Register SPI_HUB_2 is on HEX Address 0x00000038
            rd_reg_type_v := std_rd;
              rdata(6 downto 4)  <= spi_hub_2_port_int;
              rdata(2)  <= spi_hub_2_four_w_int;
              rdata(1)  <= spi_hub_2_clk_inv_int;
              rdata(0)  <= spi_hub_2_ss_high_int;

            when "00000001111" => -- Register SPI_HUB_3 is on HEX Address 0x0000003c
            rd_reg_type_v := std_rd;
              rdata(6 downto 4)  <= spi_hub_3_port_int;
              rdata(2)  <= spi_hub_3_four_w_int;
              rdata(1)  <= spi_hub_3_clk_inv_int;
              rdata(0)  <= spi_hub_3_ss_high_int;

            when "00000010000" => -- Register SPI_HUB_4 is on HEX Address 0x00000040
            rd_reg_type_v := std_rd;
              rdata(6 downto 4)  <= spi_hub_4_port_int;
              rdata(2)  <= spi_hub_4_four_w_int;
              rdata(1)  <= spi_hub_4_clk_inv_int;
              rdata(0)  <= spi_hub_4_ss_high_int;

            when "00000010001" => -- Register SPI_HUB_5 is on HEX Address 0x00000044
            rd_reg_type_v := std_rd;
              rdata(6 downto 4)  <= spi_hub_5_port_int;
              rdata(2)  <= spi_hub_5_four_w_int;
              rdata(1)  <= spi_hub_5_clk_inv_int;
              rdata(0)  <= spi_hub_5_ss_high_int;

            when "00000010010" => -- Register SPI_HUB_6 is on HEX Address 0x00000048
            rd_reg_type_v := std_rd;
              rdata(6 downto 4)  <= spi_hub_6_port_int;
              rdata(2)  <= spi_hub_6_four_w_int;
              rdata(1)  <= spi_hub_6_clk_inv_int;
              rdata(0)  <= spi_hub_6_ss_high_int;

            when "00000010011" => -- Register SPI_HUB_7 is on HEX Address 0x0000004c
            rd_reg_type_v := std_rd;
              rdata(6 downto 4)  <= spi_hub_7_port_int;
              rdata(2)  <= spi_hub_7_four_w_int;
              rdata(1)  <= spi_hub_7_clk_inv_int;
              rdata(0)  <= spi_hub_7_ss_high_int;

            when others => -- Unmapped register address
              rdata <= x"DEADDEAD";

          end case;

        end if;

        -------------------------------------------------------------------------
        -- Read channel handshake control
        -------------------------------------------------------------------------
        -- AXI signaling for std_rd type accesses
        if rd_reg_type_v = std_rd  or rd_reg_type_v = unmapped then
          rd_ongoing_s    <= '1';
          arready_s       <= '1';
          rvalid_s        <= '1';
          ar_captured_s   <= '0';
          if rready = '1' then
            rready_wait_s <= '0';
          else
            rready_wait_s <= '1';
          end if;

        end if;
      end if;
    end if;
  end process read_write_spi_registers;


  -----------------------------------------------------------------------------
  -- Interrupt trig logic
  --
  -- Interrupt can be level or edge triggered.
  -- This process creates the edge signal.
  -----------------------------------------------------------------------------
  irq_trig_process : process(clk_axi)
  begin
    if clk_axi'event and clk_axi = '1' then
      if rst_axi = '1' then
        spi_status_act_d     <= '0';
        spi_status_act_edge  <= '0';
        spi_status_rx_or_d     <= '0';
        spi_status_rx_or_edge  <= '0';
        spi_status_rx_avail_d     <= '0';
        spi_status_rx_avail_edge  <= '0';
        spi_status_rx_full_d     <= '0';
        spi_status_rx_full_edge  <= '0';
        spi_status_tx_ur_d     <= '0';
        spi_status_tx_ur_edge  <= '0';
        spi_status_tx_full_d     <= '0';
        spi_status_tx_full_edge  <= '0';
        spi_status_tx_empty_d     <= '0';
        spi_status_tx_empty_edge  <= '0';
        spi_status_done_d     <= '0';
        spi_status_done_edge  <= '0';
      else
        spi_status_act_d     <= spi_status_act;
        spi_status_act_edge  <= (not spi_status_act_d) and
                                                 spi_status_act;
        spi_status_rx_or_d     <= spi_status_rx_or;
        spi_status_rx_or_edge  <= (not spi_status_rx_or_d) and
                                                 spi_status_rx_or;
        spi_status_rx_avail_d     <= spi_status_rx_avail;
        spi_status_rx_avail_edge  <= (not spi_status_rx_avail_d) and
                                                 spi_status_rx_avail;
        spi_status_rx_full_d     <= spi_status_rx_full;
        spi_status_rx_full_edge  <= (not spi_status_rx_full_d) and
                                                 spi_status_rx_full;
        spi_status_tx_ur_d     <= spi_status_tx_ur;
        spi_status_tx_ur_edge  <= (not spi_status_tx_ur_d) and
                                                 spi_status_tx_ur;
        spi_status_tx_full_d     <= spi_status_tx_full;
        spi_status_tx_full_edge  <= (not spi_status_tx_full_d) and
                                                 spi_status_tx_full;
        spi_status_tx_empty_d     <= spi_status_tx_empty;
        spi_status_tx_empty_edge  <= (not spi_status_tx_empty_d) and
                                                 spi_status_tx_empty;
        spi_status_done_d     <= spi_status_done;
        spi_status_done_edge  <= (not spi_status_done_d) and
                                                 spi_status_done;
      end if;
    end if;
  end process irq_trig_process;

  -----------------------------------------------------------------------------
  -- Interrupt logic
  --
  -- Interrupt will be generated if not all unmasked bits in
  -- the trap register is zero.
  -----------------------------------------------------------------------------
  irq_generation_process : process(clk_axi)
  begin
    if clk_axi'event and clk_axi = '1' then
      if rst_axi = '1' then
        irq_spi_status      <= '0';
      else
        --Default value is 0
        irq_spi_status      <= '0';
        if (spi_status_act_trap and spi_status_act_mask) = '1' then
          irq_spi_status    <= '1';
        end if;
        if (spi_status_rx_or_trap and spi_status_rx_or_mask) = '1' then
          irq_spi_status    <= '1';
        end if;
        if (spi_status_rx_avail_trap and spi_status_rx_avail_mask) = '1' then
          irq_spi_status    <= '1';
        end if;
        if (spi_status_rx_full_trap and spi_status_rx_full_mask) = '1' then
          irq_spi_status    <= '1';
        end if;
        if (spi_status_tx_ur_trap and spi_status_tx_ur_mask) = '1' then
          irq_spi_status    <= '1';
        end if;
        if (spi_status_tx_full_trap and spi_status_tx_full_mask) = '1' then
          irq_spi_status    <= '1';
        end if;
        if (spi_status_tx_empty_trap and spi_status_tx_empty_mask) = '1' then
          irq_spi_status    <= '1';
        end if;
        if (spi_status_done_trap and spi_status_done_mask) = '1' then
          irq_spi_status    <= '1';
        end if;
      end if;
    end if;
  end process irq_generation_process;


  -----------------------------------------------------------------------------
  -- AW/W/AR-channel capture registers
  -----------------------------------------------------------------------------
  axi_capt_reg_p : process (clk_axi) is
  begin  -- process axi_capt_reg_p
    if clk_axi'event and clk_axi = '1' then
      if rst_axi = '1' then
        awaddr_reg_s <= (others => '0');
        wdata_reg_s  <= (others => '0');
        wstrb_reg_s  <= (others => '0');
        araddr_reg_s <= (others => '0');
      else

        -- Capture AWADDR
        if awvalid = '1' and aw_captured_s = '0' then
          awaddr_reg_s  <= awaddr;
        end if;

        -- Capture WDATA
        if wvalid = '1' and w_captured_s = '0' then
          wdata_reg_s <= wdata;
          wstrb_reg_s <= wstrb;
        end if;

        -- Capture ARADDR
        if arvalid = '1' and ar_captured_s = '0' then
          araddr_reg_s  <= araddr;
        end if;
      end if;
    end if;
  end process axi_capt_reg_p;

end architecture rtl;
