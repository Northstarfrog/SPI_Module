--------------------------------------------------------------------

-- Description:
--
-- Interface part of SPI controller
--
--------------------------------------------------------------------
-- VHDL Version: VHDL '93
--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity spi_ctrl_int is

  port (
    clk_61                : in  std_logic;                      -- 61.44MHz clock
    rst_61                : in  std_logic;                      -- Reset signal with 61.44MHz
    h_spi_m_clk           : out std_logic;                      -- SPI clock towards PIN outside
    h_spi_m_ss            : out std_logic;                      -- SPI chip select towards PIN outside
    h_spi_mosi            : out std_logic;                      -- SPI MOSI towards PIN outside
    h_spi_miso            : in  std_logic;                      -- SPI MISO towards PIN outside
    h_spi_m_dir           : out std_logic;                      -- SPI direction towards PIN outside
    start_strb            : out std_logic;                      -- Start strobe signal from spi_ctrl_clk
    strb_done             : in  std_logic;                      -- end flag for transaction
    cpol_set              : in  std_logic;                      -- Send out SPI clock
    load_reg              : in  std_logic;                      -- Load content need to send out
    put_rx_fifo           : in  std_logic;                      -- Send out recieved data
    tx_en                 : in  std_logic;                      -- TX enable signal
    rx_en                 : in  std_logic;                      -- RX enable signal
    dir_en                : in  std_logic;                      -- Direction enable signal
    put_leading_edge      : in  std_logic;                      -- TX strobe leading edge
    samp_leading_edge     : in  std_logic;                      -- RX strobe leading edge
    put_trailing_edge     : in  std_logic;                      -- TX strobe trailing edge
    samp_trailing_edge    : in  std_logic;                      -- RX strobe trailing edge
    length_dir            : in  std_logic_vector(8 downto 0);   -- TX length for bi-direction
    length_val            : in  std_logic_vector(8 downto 0);   -- Total length for transmission
    h_spi_ctrl_ss         : in  std_logic;                      -- SPI control for chip select
    h_spi_ctrl_ss_bidir   : in  std_logic;                      -- Bidirectional normal/switch mode
    h_spi_ctrl_ss_mode    : in  std_logic;                      -- automatic or not SS generation
    h_spi_ctrl_en         : in  std_logic;                      -- Enable signal for SPI transmission
    h_spi_ctrl_lsbfe      : in  std_logic;                      -- MSB/LSB bit first
    h_spi_ctrl_cpha       : in  std_logic;                      -- sample on leading/trailing edge
    h_spi_ctrl_mode       : in  std_logic_vector(1 downto 0);   -- WR/RD/BIDIR/DUPLEX selection
    h_spi_ctrl_clk_idle   : in  std_logic;                      -- half/one spi clock cycle
    h_spi_ctrl_rate       : in  std_logic_vector(13 downto 0);  -- Configure SPI clock speed
    h_spi_tx_data         : in  std_logic_vector(31 downto 0);  -- Send data
    h_spi_tx_put          : in  std_logic;                      -- Write data command
    h_spi_rx_data         : out std_logic_vector(31 downto 0);  -- Read data
    h_spi_rx_get          : in  std_logic;                      -- Read data command
    h_spi_cmd_reset_cmd   : in  std_logic;                      -- Reset command
    h_spi_cmd_reset_ack   : out std_logic;                      -- Reset command acknowledge
    h_spi_cmd_strb_cmd    : in  std_logic;                      -- Strobe command (active transmission)
    h_spi_cmd_strb_ack    : out std_logic;                      -- Strobe command acknowledge
    h_spi_status_done     : out std_logic;                      -- Done status
    h_spi_status_rx_avail : out std_logic;                      -- RX Availabele status
    h_spi_status_rx_or    : out std_logic;                      -- RX Overrun status
    h_spi_status_tx_ur    : out std_logic;                      -- TX undrrun status
    h_spi_status_rx_full  : out std_logic;                      -- RX full status
    h_spi_status_act      : out std_logic;                      -- SPI command is processed status
    h_spi_status_tx_full  : out std_logic;                      -- TX fifo full status
    h_spi_status_tx_empty : out std_logic);                     -- TX fifo empty status

end entity spi_ctrl_int;

architecture rtl of spi_ctrl_int is
-------------------------------------------------------------------------------
-- Define FSM
-------------------------------------------------------------------------------
  type state_t is (idle_s, init_s, dir_high_s, ss_high_s, data_transaction_s, ss_low_s,dir_low_s);
  signal state                  : state_t;
  signal next_state             : state_t;

-------------------------------------------------------------------------------
-- Define fifo
-------------------------------------------------------------------------------
  type fifo_arr_t is array (7 downto 0) of std_logic_vector(31 downto 0);
  signal tx_fifo                : fifo_arr_t;
  signal rx_fifo                : fifo_arr_t;

  signal tx_rd_ptr              : std_logic_vector(2 downto 0);
  signal tx_wr_ptr              : std_logic_vector(2 downto 0);
  signal num_of_wd_in_tx_fifo   : std_logic_vector(3 downto 0);
  signal rx_rd_ptr              : std_logic_vector(2 downto 0);
  signal rx_wr_ptr              : std_logic_vector(2 downto 0);
  signal num_of_fw_avail        : std_logic_vector(3 downto 0);

-------------------------------------------------------------------------------
-- Internal signals
-------------------------------------------------------------------------------
  signal index                  : std_logic_vector(14 downto 0);
  signal start_strb_s           : std_logic;
  signal rx_fifo_init           : std_logic;
  signal load_reg_init          : std_logic;
  signal tx_shift_reg           : std_logic_vector(31 downto 0);
  signal remaining_tx_data      : std_logic_vector(8 downto 0);
  signal remaining_tx_data_init : std_logic_vector(8 downto 0);
  signal mosi                   : std_logic;
  signal rx_shift_reg           : std_logic_vector(31 downto 0);
  signal s_rx_shift_reg_d       : std_logic_vector(31 downto 0);
  signal h_spi_rx_put           : std_logic;
  signal remaining_rx_data      : std_logic_vector(8 downto 0);
  signal rx_strb                : std_logic;
  signal rx_strb_d              : std_logic_vector(3 downto 0);
  signal put_rx_fifo_d          : std_logic_vector(4 downto 0);
  signal tx_strb                : std_logic;
  signal h_spi_m_ss_fsm         : std_logic;
  signal h_spi_m_ss_mux         : std_logic;
  signal h_spi_m_dir_fsm        : std_logic;
  signal h_spi_status_done_s    : std_logic;
  signal h_spi_status_act_s     : std_logic;
  signal h_spi_status_tx_empty_s: std_logic;
  signal h_spi_status_tx_full_s : std_logic;
  signal h_spi_status_tx_ur_s   : std_logic;
  signal h_spi_status_rx_avail_s: std_logic;
  signal h_spi_status_rx_full_s : std_logic;
  signal h_spi_status_rx_or_s   : std_logic;
  signal h_spi_cmd_reset_ack_s  : std_logic;
  signal h_spi_cmd_strb_ack_s   : std_logic;
  signal h_spi_m_ss_s           : std_logic;
  signal h_spi_m_dir_s          : std_logic;
  signal h_spi_mosi_s           : std_logic;
  signal h_spi_m_clk_s          : std_logic;
  signal miso                   : std_logic;

begin  -- architecture rtl
-------------------------------------------------------------------------------
-- FSM
-------------------------------------------------------------------------------
  -- purpose: Update the state
  -- type   : sequential
  -- inputs : clk_61, rst_61, next_state, h_spi_cmd_reset_cmd
  -- outputs: state
  state_up_p: process (clk_61) is
  begin  -- process state_up_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        state <= idle_s;
      else
        if h_spi_cmd_reset_cmd = '1' then
          state <= idle_s;
        else
          if h_spi_ctrl_en = '1' then
            state <= next_state;
          else
            state <= state;
          end if;
        end if;
      end if;
    end if;
  end process state_up_p;

  -- purpose: Main part of the FSM
  -- type   : combinational
  -- inputs : state
  -- outputs: next_state
  fsm_p: process (h_spi_cmd_strb_cmd, h_spi_ctrl_clk_idle, h_spi_ctrl_rate, index, state, strb_done) is
  begin  -- process fsm_p
    case state is
      when idle_s =>
        if h_spi_cmd_strb_cmd = '1' then
          next_state <= init_s;
        else
          next_state <= idle_s;
        end if;
      when init_s =>
        if index = "000000000000011" then
          next_state <= dir_high_s;
        else
          next_state <= init_s;
        end if;
      when dir_high_s =>
        next_state <= ss_high_s;
      when ss_high_s =>
        if h_spi_ctrl_clk_idle = '1' then
          if index = h_spi_ctrl_rate & '1' then
            next_state <= data_transaction_s;
          else
            next_state <= ss_high_s;
          end if;
        else
          if index = '0' & h_spi_ctrl_rate then
            next_state <= data_transaction_s;
          else
            next_state <= ss_high_s;
          end if;
        end if;
      when data_transaction_s =>
        if strb_done = '1' or index > 0 then
          if h_spi_ctrl_clk_idle = '1' then
            if h_spi_ctrl_rate = "00000000000000" then
              if index = "000000000000001" then
                next_state <= ss_low_s;
              else
                next_state <= data_transaction_s;
              end if;
            else
              if index = (h_spi_ctrl_rate & '1') then
                next_state <= ss_low_s;
              else
                next_state <= data_transaction_s;
              end if;
            end if;
          else
            if h_spi_ctrl_rate = "00000000000000" then
              if index = "000000000000000" then
                next_state <= ss_low_s;
              else
                next_state <= data_transaction_s;
              end if;
            else
              if index = '0' & h_spi_ctrl_rate then
                next_state <= ss_low_s;
              else
                next_state <= data_transaction_s;
              end if;
            end if;
          end if;
        else
          next_state <= data_transaction_s;
        end if;
      when ss_low_s =>
        next_state <= dir_low_s;
      when dir_low_s =>
        next_state <= idle_s;
      when others =>
        next_state <= idle_s;
    end case;
  end process fsm_p;

-------------------------------------------------------------------------------
-- Generate the command ack signal
-------------------------------------------------------------------------------
  -- purpose: Generate the reset ACK signal to acknowledge the reset command from AXI
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd
  -- outputs: h_spi_cmd_reset_ack
  reset_ack_p: process (clk_61) is
  begin  -- process reset_ack_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_cmd_reset_ack_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_cmd_reset_ack_s <= '1';
        else
          h_spi_cmd_reset_ack_s <= '0';
        end if;
      end if;
    end if;
  end process reset_ack_p;

  h_spi_cmd_reset_ack <= h_spi_cmd_reset_ack_s;

  -- purpose: Generate the strobe ack signal to acknowledge the command from AXI
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, state, h_spi_cmd_strb_cmd
  -- outputs: h_spi_cmd_strb_ack
  strobe_ack_p: process (clk_61) is
  begin  -- process strobe_ack_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_cmd_strb_ack_s <= '0';
      else
        if h_spi_cmd_strb_cmd = '1' and state = idle_s then
          h_spi_cmd_strb_ack_s <= '1';
        else
          h_spi_cmd_strb_ack_s <= '0';
        end if;
      end if;
    end if;
  end process strobe_ack_p;

  h_spi_cmd_strb_ack <= h_spi_cmd_strb_ack_s;

-------------------------------------------------------------------------------
-- Generate the counter
-------------------------------------------------------------------------------
  -- purpose: Generate the index works as a counter
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, h_spi_cmd_reset_cmd, h_spi_ctrl_en, h_spi_ctrl_rate
  --          h_spi_ctrl_clk_idle
  -- outputs: index
  index_p: process (clk_61) is
  begin  -- process index_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        index <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          index <= (others => '0');
        else
          if h_spi_ctrl_en = '1' then
            if state = init_s then
              if index = "000000000000011" then
                index <= (others => '0');
              else
                index <= index + '1';
              end if;
            elsif state = ss_high_s then
              if h_spi_ctrl_clk_idle = '1' then
                if index = (h_spi_ctrl_rate & '1') then
                  index <= (others => '0');
                else
                  index <= index + '1';
                end if;
              else
                if index = '0' & h_spi_ctrl_rate then
                  index <= (others => '0');
                else
                  index <= index + '1';
                end if;
              end if;
            elsif state = data_transaction_s then
              if strb_done = '1' or index > 0 then
                if h_spi_ctrl_rate = "00000000000000" then
                  if index(14 downto 1) = "00000000000000" and index(0) = h_spi_ctrl_clk_idle then
                    index <= (others => '0');
                  else
                    index <= index + '1';
                  end if;
                else
                  if h_spi_ctrl_clk_idle = '1' then
                    if index = h_spi_ctrl_rate & '1' then
                      index <= (others => '0');
                    else
                      index <= index + '1';
                    end if;
                  else
                    if index = '0' & h_spi_ctrl_rate then
                      index <= (others => '0');
                    else
                      index <= index + '1';
                    end if;
                  end if;
                end if;
              else
                index <= (others => '0');
              end if;
            else
              index <= (others => '0');
            end if;
          else
            index <= index;
          end if;
        end if;
      end if;
    end if;
  end process index_p;

-------------------------------------------------------------------------------
-- Start strobe trigger
-------------------------------------------------------------------------------
  -- purpose: Generate start strbe in SS_HIGH state
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, index, h_spi_ctrl_rate,
  -- outputs: start_strb
  start_strb_p: process (clk_61) is
  begin  -- process start_strb_ps
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        start_strb_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          start_strb_s <= '0';
        elsif h_spi_ctrl_en = '1' then
          if state = idle_s then
            start_strb_s <= '0';
          elsif state = ss_high_s then
            if h_spi_ctrl_clk_idle = '1' then
              if index = h_spi_ctrl_rate & '1' then
                start_strb_s <= '1';
              else
                start_strb_s <= start_strb_s;
              end if;
            else
              if index = '0' & h_spi_ctrl_rate then
                start_strb_s <= '1';
              else
                start_strb_s <= start_strb_s;
              end if;
            end if;
          elsif state = data_transaction_s then
            start_strb_s <= '0';
          else
            start_strb_s <= start_strb_s;
          end if;
        else
          start_strb_s <= start_strb_s;
        end if;
      end if;
    end if;
  end process start_strb_p;

  start_strb <= start_strb_s;

-------------------------------------------------------------------------------
-- rx_fifo_init
-------------------------------------------------------------------------------
  -- purpose: Generate the intiate RX fifo action
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_en, state, index, h_spi_ctrl_mode
  -- outputs: to_rx_fifo_init
  rx_fifo_init_p: process (clk_61) is
  begin  -- process rx_fifo_init_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        rx_fifo_init <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          rx_fifo_init <= '0';
        elsif h_spi_ctrl_en = '1' then
          if (state = init_s) and (index = "000000000000000") and (h_spi_ctrl_mode /= "00") then
            rx_fifo_init <= '1';
          else
            rx_fifo_init <= '0';
          end if;
        else
          rx_fifo_init <= rx_fifo_init;
        end if;
      end if;
    end if;
  end process rx_fifo_init_p;

-------------------------------------------------------------------------------
-- load_reg_init
-------------------------------------------------------------------------------
  -- purpose: Generate initiate load register signal
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_en, state, index, h_spi_ctrl_mode
  -- outputs: load_reg_init
  load_reg_init_p: process (clk_61) is
  begin  -- process load_reg_init_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        load_reg_init <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          load_reg_init <= '0';
        elsif h_spi_ctrl_en = '1' then
          if (state = init_s) and (index = "000000000000000") and (h_spi_ctrl_mode /= "01") then
            load_reg_init <= '1';
          else
            load_reg_init <= '0';
          end if;
        else
          load_reg_init <= load_reg_init;
        end if;
      end if;
    end if;
  end process load_reg_init_p;

-------------------------------------------------------------------------------
-- TX
-------------------------------------------------------------------------------
  -- purpose: Write FIFO for TX direction
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, tx_en, h_spi_tx_put
  -- outputs: tx_fifo
  fifo_tx_p: process (clk_61) is
  begin  -- process fifo_tx_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        tx_wr_ptr <= (others => '0');
        tx_fifo   <= (others => (others => '0'));
      else
        if h_spi_cmd_reset_cmd = '1' then
          tx_wr_ptr <= (others => '0');
          tx_fifo   <= (others => (others => '0'));
        elsif h_spi_ctrl_mode /= "01" and h_spi_ctrl_en = '1' and tx_en = '1' and h_spi_tx_put = '1' then
          tx_fifo(conv_integer(tx_wr_ptr)) <= h_spi_tx_data;
          if tx_wr_ptr = "111" then
            tx_wr_ptr <= (others => '0');
          else
            tx_wr_ptr <= tx_wr_ptr + '1';
          end if;
        else
          tx_wr_ptr <= tx_wr_ptr;
          tx_fifo   <= tx_fifo;
        end if;
      end if;
    end if;
  end process fifo_tx_p;

  -- purpose: Calculate the depth of TX FIFO
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, tx_en,
  --          h_spi_tx_put, load_reg, load_reg_init
  -- outputs: num_of_wd_in_tx_fifo
  wd_in_tx_p: process (clk_61) is
  begin  -- process wd_in_tx_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        num_of_wd_in_tx_fifo <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          num_of_wd_in_tx_fifo <= (others => '0');
        elsif (h_spi_ctrl_mode /= "01") and (h_spi_ctrl_en = '1') and (tx_en = '1') then
          if (h_spi_tx_put = '1') and (load_reg = '1' or load_reg_init = '1') then
            num_of_wd_in_tx_fifo <= num_of_wd_in_tx_fifo;
          elsif h_spi_tx_put = '1' then
            if num_of_wd_in_tx_fifo = "1000" then
              num_of_wd_in_tx_fifo <= num_of_wd_in_tx_fifo;
            else
              num_of_wd_in_tx_fifo <= num_of_wd_in_tx_fifo + '1';
            end if;
          elsif load_reg = '1' or load_reg_init = '1' then
            if num_of_wd_in_tx_fifo = "0000" then
              num_of_wd_in_tx_fifo <= num_of_wd_in_tx_fifo;
            else
              num_of_wd_in_tx_fifo <= num_of_wd_in_tx_fifo - '1';
            end if;
          else
            num_of_wd_in_tx_fifo <= num_of_wd_in_tx_fifo;
          end if;
        else
          num_of_wd_in_tx_fifo <= num_of_wd_in_tx_fifo;
        end if;
      end if;
    end if;
  end process wd_in_tx_p;

  -- purpose: Generate the read pointer counter for TX FIFO
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, tx_en
  -- outputs: tx_rd_ptr
  rd_ptr_p: process (clk_61) is
  begin  -- process rd_ptr_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        tx_rd_ptr <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          tx_rd_ptr <= (others => '0');
        elsif (h_spi_ctrl_mode /= "01") and (h_spi_ctrl_en = '1') and (tx_en = '1') and
          ((load_reg = '1') or (load_reg_init = '1')) then
          if tx_rd_ptr = "111" then
            tx_rd_ptr <= (others => '0');
          else
            tx_rd_ptr <= tx_rd_ptr + '1';
          end if;
        else
          tx_rd_ptr <= tx_rd_ptr;
        end if;
      end if;
    end if;
  end process rd_ptr_p;

  tx_strb <= put_trailing_edge when h_spi_ctrl_cpha = '0' else
             put_leading_edge;

  -- purpose: Generate TX shift register used to do P -> S
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, tx_en, load_reg,
  --          load_reg_init, h_spi_ctrl_lsbfe, remaining_tx_data_init, remaining_tx_data
  -- outputs: tx_shift_reg
  tx_shift_reg_p: process (clk_61) is
  begin  -- process tx_shift_reg_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        tx_shift_reg <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          tx_shift_reg <= (others => '0');
        elsif (h_spi_ctrl_mode /= "01") and (h_spi_ctrl_en = '1') and (tx_en = '1') then
          if load_reg_init = '1' then
            if h_spi_ctrl_lsbfe = '0' and remaining_tx_data_init >= "100000" then
              for i in 0 to 31 loop
                tx_shift_reg(31-i) <= tx_fifo(conv_integer(tx_rd_ptr))(i);
              end loop;  -- i
            elsif h_spi_ctrl_lsbfe = '0' and remaining_tx_data_init > 0 then
              for i in 0 to 31 loop
                if i <= (remaining_tx_data_init - '1') then
                  tx_shift_reg(i) <= tx_fifo(conv_integer(tx_rd_ptr))
                                     (conv_integer(remaining_tx_data_init)-1 -i);
                else
                  tx_shift_reg(i) <= '0';
                end if;
              end loop;  -- i
            else
              tx_shift_reg <= tx_fifo(conv_integer(tx_rd_ptr));
            end if;
          elsif load_reg = '1' then
            if h_spi_ctrl_lsbfe = '0' and remaining_tx_data >= 32 then
              for i in 0 to 31 loop
                tx_shift_reg(31-i) <= tx_fifo(conv_integer(tx_rd_ptr))(i);
              end loop;  -- i
            elsif h_spi_ctrl_lsbfe = '0' and remaining_tx_data > 0 then
              for i in 0 to 31 loop
                if i <= (remaining_tx_data - '1') then
                  tx_shift_reg(i) <= tx_fifo(conv_integer(tx_rd_ptr))
                                     (conv_integer(remaining_tx_data)-1 -i);
                else
                  tx_shift_reg(i) <= '0';
                end if;
              end loop;  -- i
            else
              tx_shift_reg <= tx_fifo(conv_integer(tx_rd_ptr));
            end if;
          elsif tx_strb = '1' then
            tx_shift_reg <= '0' & tx_shift_reg(31 downto 1);
          else
            tx_shift_reg <= tx_shift_reg;
          end if;
        else
          tx_shift_reg <= tx_shift_reg;
        end if;
      end if;
    end if;
  end process tx_shift_reg_p;

  mosi <= tx_shift_reg(0);

  -- purpose: Genearte the remaining tx init data count
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, tx_en,
  --          load_reg_init, length_val, length_dir
  -- outputs: remaining_tx_data_init
  remain_tx_data_int_p: process (clk_61)
  begin  -- process remain_tx_data_int_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        remaining_tx_data_init <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          remaining_tx_data_init <= (others => '0');
        elsif h_spi_ctrl_mode = "10" then
          remaining_tx_data_init <= length_dir;
        elsif h_spi_ctrl_mode = "00" or h_spi_ctrl_mode = "11" then
          remaining_tx_data_init <= length_val;
        else
          remaining_tx_data_init <= (others => '0');
        end if;
      end if;
    end if;
  end process remain_tx_data_int_p;
  
  -- purpose: Generate remaining tx data count
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, tx_en,
  --          load_reg_init, load_reg, length_val, length_dir
  -- outputs: remaining_tx_data
  remain_tx_data_p: process (clk_61) is
  begin  -- process remain_tx_data_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        remaining_tx_data <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          remaining_tx_data <= (others => '0');
        elsif h_spi_ctrl_mode /= "01" and h_spi_ctrl_en = '1' and tx_en = '1' then
          if load_reg_init = '1' then
            if remaining_tx_data_init > "100000" then
              remaining_tx_data <= remaining_tx_data_init - "100000";
            else
              remaining_tx_data <= (others => '0');
            end if;
          elsif load_reg = '1' then
            if remaining_tx_data > "100000" then
              remaining_tx_data <= remaining_tx_data - "100000";
            else
              remaining_tx_data <= (others => '0');
            end if;
          end if;
        else
          remaining_tx_data <= remaining_tx_data;
        end if;
      end if;
    end if;
  end process remain_tx_data_p;

-------------------------------------------------------------------------------
-- RX
-------------------------------------------------------------------------------
  rx_strb <= samp_leading_edge when h_spi_ctrl_cpha = '0' else
             samp_trailing_edge;

  -- purpose: Delay rx_strb and put_rx_fifo 3 cycles to match MISO data
  --          rx_strb is aligned to the first cycle of clk1_s or clk0_s
  --          The edge of clk_gen is one cycle delay compared to rx_strb
  --          The edge of SPI clock is two cycle delay compared to rx_strb
  --          The sample point of MISO from is aligned with SPI clock
  --          The sample point of pipelined miso is need one more cycle delay
  --          So, total is 3 cycle delay to sample the miso.
  -- type   : sequential
  -- inputs : clk_61, rst_61, rx_strb, put_rx_fifo
  -- outputs: rx_strb_d, put_rx_fifo_d
  rx_delay_p: process (clk_61) is
  begin  -- process rx_delay_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        rx_strb_d     <= (others => '0');
        put_rx_fifo_d <= (others => '0');
      else
        rx_strb_d     <= rx_strb_d(2 downto 0) & rx_strb;
        put_rx_fifo_d <= put_rx_fifo_d(3 downto 0) & put_rx_fifo;
      end if;
    end if;
  end process rx_delay_p;

  -- purpose: Used to store the serial data into 32bit width register
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, rx_strb_d(3), h_spi_ctrl_mode
  --          h_spi_ctrl_en, rx_en
  -- outputs: rx_shift_reg
  shift_reg_p: process (clk_61) is
  begin  -- process shift_reg_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        rx_shift_reg <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          rx_shift_reg <= (others => '0');
        elsif h_spi_ctrl_mode /= "00" and h_spi_ctrl_en = '1' and rx_en = '1'
          and rx_strb_d(3) = '1' then
          rx_shift_reg <= rx_shift_reg(30 downto 0) & miso;
        else
          rx_shift_reg <= rx_shift_reg;
        end if;
      end if;
    end if;
  end process shift_reg_p;

  -- purpose: Used to change the register value between LSB and MSB
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, rx_en,
  --          put_rx_fifo_d, h_spi_ctrl_lsbfe, remaining_rx_data
  -- outputs: s_rx_shift_reg_d
  shift_reg_d_p: process (clk_61) is
  begin  -- process shift_reg_d_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        s_rx_shift_reg_d <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          s_rx_shift_reg_d <= (others => '0');
        elsif (h_spi_ctrl_mode /= "00") and (h_spi_ctrl_en = '1')
          and (put_rx_fifo_d(3) = '1') and (rx_en = '1') then
          if h_spi_ctrl_lsbfe = '1' then
            if remaining_rx_data >= "100000" then
              for i in 0 to 31 loop
                s_rx_shift_reg_d(31-i) <= rx_shift_reg(i);
              end loop;  -- i
            elsif remaining_rx_data > 0 then
              for i in 0 to 31 loop
                if i <= (conv_integer(remaining_rx_data) - 1) then
                  s_rx_shift_reg_d(conv_integer(remaining_rx_data) -1 -i) <= rx_shift_reg(i);
                else
                  s_rx_shift_reg_d(i) <= '0';
                end if;
              end loop;  -- i
            else
              s_rx_shift_reg_d <= s_rx_shift_reg_d;
            end if;
          else
            if remaining_rx_data >= "100000" then
              s_rx_shift_reg_d <= rx_shift_reg;
            elsif remaining_rx_data > "000000" then
              for i in 0 to 31 loop
                if i <= (conv_integer(remaining_rx_data) - 1) then
                  s_rx_shift_reg_d(i) <= rx_shift_reg(i);
                else
                  s_rx_shift_reg_d(i) <= '0';
                end if;
              end loop;  -- i
            else
              s_rx_shift_reg_d <= s_rx_shift_reg_d;
            end if;
          end if;
        else
          s_rx_shift_reg_d <= s_rx_shift_reg_d;
        end if;
      end if;
    end if;
  end process shift_reg_d_p;

  -- purpose: Generate the write pointer towards the RX FIFO
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, rx_en, h_spi_ctrl_en,put_rx_fifo_d
  -- outputs: rx_wr_ptr, rx_fifo
  rx_wr_fifo_p: process (clk_61) is
  begin  -- process rx_wr_ptr_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        rx_wr_ptr <= (others => '0');
        rx_fifo <= (others => (others => '0'));
      else
        if h_spi_cmd_reset_cmd = '1' then
          rx_wr_ptr <= (others => '0');
          rx_fifo <= (others => (others => '0'));
        elsif h_spi_ctrl_mode /= "00" and h_spi_ctrl_en = '1' and
          rx_en = '1' and put_rx_fifo_d(4) = '1' then
          rx_fifo(conv_integer(rx_wr_ptr)) <= s_rx_shift_reg_d;
          if rx_wr_ptr = "111" then
            rx_wr_ptr <= "000";
          else
            rx_wr_ptr <= rx_wr_ptr + '1';
          end if;
        end if;
      end if;
    end if;
  end process rx_wr_fifo_p;

  -- purpose: Generate the avail number for RX FIFO
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, rx_en, h_spi_rx_put
  -- outputs: num_of_fw_avail
  num_of_fw_av_p: process (clk_61) is
  begin  -- process num_of_fw_av_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        num_of_fw_avail <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          num_of_fw_avail <= (others => '0');
        elsif h_spi_ctrl_mode /= "00" and h_spi_ctrl_en = '1' and rx_en = '1' then
          if h_spi_rx_put = '1' and h_spi_rx_get = '1' then
            num_of_fw_avail <= num_of_fw_avail;
          elsif h_spi_rx_put = '1' then
            if num_of_fw_avail = "1000" then
              num_of_fw_avail <= num_of_fw_avail;
            else
              num_of_fw_avail <= num_of_fw_avail + '1';
            end if;
          elsif h_spi_rx_get = '1' then
            if num_of_fw_avail = "0000" then
              num_of_fw_avail <= num_of_fw_avail;
            else
              num_of_fw_avail <= num_of_fw_avail - '1';
            end if;
          else
            num_of_fw_avail <= num_of_fw_avail;
          end if;
        else
          num_of_fw_avail <= num_of_fw_avail;
        end if;
      end if;
    end if;
  end process num_of_fw_av_p;

  -- purpose: Generate the red pointer towards the RX FIFO
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_pi_ctrl_mode, h_spi_ctrl_en, rx_en, h_spi_rx_get, num_of_fw_avail
  -- outputs: rx_rd_ptr, h_spi_rx_data
  rx_rd_fifo_p: process (clk_61) is
  begin  -- process rx_rd_fifo_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        rx_rd_ptr     <= (others => '0');
        h_spi_rx_data <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          rx_rd_ptr     <= (others => '0');
          h_spi_rx_data <= (others => '0');
        elsif h_spi_ctrl_mode /= "00" and h_spi_ctrl_en = '1' and rx_en = '1' then
          h_spi_rx_data <= rx_fifo(conv_integer(rx_rd_ptr));
          if (h_spi_rx_get = '1') and (num_of_fw_avail /= "0000") then
            if rx_rd_ptr = "111" then
              rx_rd_ptr <= (others => '0');
            else
              rx_rd_ptr <= rx_rd_ptr + '1';
            end if;
          else
            rx_rd_ptr <= rx_rd_ptr;
          end if;
        else
          rx_rd_ptr <= rx_rd_ptr;
        end if;
      end if;
    end if;
  end process rx_rd_fifo_p;

  -- purpose: Genearte the signal which is used to generate status signal
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, rx_en, put_rx_fifo_d
  -- outputs: h_spi_rx_put
  rx_put_p: process (clk_61) is
  begin  -- process rx_put_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_rx_put <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_rx_put <= '0';
        elsif h_spi_ctrl_mode /= "00" and h_spi_ctrl_en = '1' and
          rx_en = '1' and put_rx_fifo_d(4) = '1' then
          h_spi_rx_put <= '1';
        else
          h_spi_rx_put <= '0';
        end if;
      end if;
    end if;
  end process rx_put_p;

  -- purpose: Genearte the remained counter for RX
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en,
  --          rx_fifo_init, rx_en, put_rx_fifo_d
  -- outputs: remaining_rx_data
  remain_rx_data_p: process (clk_61) is
  begin  -- process remain_rx_data_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        remaining_rx_data <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          remaining_rx_data <= (others => '0');
        elsif h_spi_ctrl_mode /= "00" and h_spi_ctrl_en = '1' then
          if rx_fifo_init = '1' then
            if h_spi_ctrl_mode = "10" then
              remaining_rx_data <= length_val - length_dir;
            else
              remaining_rx_data <= length_val;
            end if;
          elsif rx_en = '1' and put_rx_fifo_d(4) = '1' then
            if remaining_rx_data > "100000" then
              remaining_rx_data <= remaining_rx_data - "100000";
            else
              remaining_rx_data <= (others => '0');
            end if;
          else
            remaining_rx_data <= remaining_rx_data;
          end if;
        else
          remaining_rx_data <= remaining_rx_data;
        end if;
      end if;
    end if;
  end process remain_rx_data_p;

-------------------------------------------------------------------------------
-- Interface towards PIN
-------------------------------------------------------------------------------
  -- purpose: Generate the chip select siganl out
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_en, h_spi_ctrl_ss_bidir,
  --          h_spi_ctrl_mode, h_spi_m_ss_mux, h_spi_m_dir_fsm, dir_en
  -- outputs: h_spi_m_ss
  pin_ss_p: process (clk_61) is
  begin  -- process pin_ss_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_m_ss_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_m_ss_s <= '0';
        elsif h_spi_ctrl_en = '1' then
          if h_spi_ctrl_ss_bidir = '1' and h_spi_ctrl_mode = "10" then
            h_spi_m_ss_s <= h_spi_m_ss_mux and h_spi_m_dir_fsm and dir_en;
          else
            h_spi_m_ss_s <= h_spi_m_ss_mux;
          end if;
        else
          h_spi_m_ss_s <= '0';
        end if;
      end if;
    end if;
  end process pin_ss_p;

  h_spi_m_ss <= h_spi_m_ss_s;

  -- purpose: Generate the clock signal out
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_en, cpol_set
  -- outputs: h_spi_m_clk_s
  pin_clk_p: process (clk_61) is
  begin  -- process pin_clk_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_m_clk_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_m_clk_s <= '0';
        elsif h_spi_ctrl_en = '1' then
          h_spi_m_clk_s <= cpol_set;
        end if;
      end if;
    end if;
  end process pin_clk_p;

  h_spi_m_clk <= h_spi_m_clk_s;

  -- purpose: Generate the mosi signal out
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_en, mosi
  -- outputs: h_spi_mosi
  pin_mosi_p: process (clk_61) is
  begin  -- process pin_mosi_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_mosi_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_mosi_s <= '0';
        elsif h_spi_ctrl_en = '1' then
          h_spi_mosi_s <= mosi;
        end if;
      end if;
    end if;
  end process pin_mosi_p;

  h_spi_mosi <= h_spi_mosi_s;

  -- purpose: Generate the dir signal out
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_en, h_spi_m_dir_fsm,
  --          dir_en
  -- outputs: h_spi_m_dir
  pin_dir_p: process (clk_61) is
  begin  -- process pin_dir_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_m_dir_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_m_dir_s <= '0';
        elsif h_spi_ctrl_en = '1' then
          h_spi_m_dir_s <= h_spi_m_dir_fsm and dir_en;
        end if;
      end if;
    end if;
  end process pin_dir_p;

  h_spi_m_dir <= h_spi_m_dir_s;

  -- purpose: Generate the MISO signal from PIN in
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_en, h_spi_miso
  -- outputs: miso
  pin_miso_p: process (clk_61) is
  begin  -- process pin_miso_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        miso <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          miso <= '0';
        elsif h_spi_ctrl_en = '1' then
          miso <= h_spi_miso;
        end if;
      end if;
    end if;
  end process pin_miso_p;

-------------------------------------------------------------------------------
-- h_spi_m_ss_fsm and h_spi_m_dir_fsm
-------------------------------------------------------------------------------
  -- purpose: Generate ss signal from FSM
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_en, state
  -- outputs: h_spi_m_ss_fsm
  ss_fsm_p: process (clk_61) is
  begin  -- process ss_fsm_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_m_ss_fsm <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_m_ss_fsm <= '0';
        elsif h_spi_ctrl_en = '1' then
          if state = idle_s then
            h_spi_m_ss_fsm <= '0';
          elsif state = ss_high_s then
            h_spi_m_ss_fsm <= '1';
          elsif state = ss_low_s then
            h_spi_m_ss_fsm <= '0';
          else
            h_spi_m_ss_fsm <= h_spi_m_ss_fsm;
          end if;
        else
          h_spi_m_ss_fsm <= h_spi_m_ss_fsm;
        end if;
      end if;
    end if;
  end process ss_fsm_p;

  h_spi_m_ss_mux <= h_spi_ctrl_ss when h_spi_ctrl_ss_mode = '0' else
                    h_spi_m_ss_fsm;

  -- purpose: Generate dir signal from FSM
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_en, state, h_spi_ctrl_mode
  -- outputs: h_spi_m_dir_fsm
  dir_fsm_p: process (clk_61) is
  begin  -- process dir_fsm_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_m_dir_fsm <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_m_dir_fsm <= '0';
        elsif h_spi_ctrl_en = '1' then
          if state = idle_s then
            h_spi_m_dir_fsm <= '0';
          elsif state = dir_high_s then
            if h_spi_ctrl_mode /= "01" then
              h_spi_m_dir_fsm <= '1';
            else
              h_spi_m_dir_fsm <= '0';
            end if;
          elsif state = dir_low_s then
            h_spi_m_dir_fsm <= '0';
          else
            h_spi_m_dir_fsm <= h_spi_m_dir_fsm;
          end if;
        else
          h_spi_m_dir_fsm <= h_spi_m_dir_fsm;
        end if;
      end if;
    end if;
  end process dir_fsm_p;

-------------------------------------------------------------------------------
-- Status Signals
-------------------------------------------------------------------------------
  -- purpose: Generate done signal status
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_en, state
  -- outputs: h_spi_status_done
  status_done_p: process (clk_61) is
  begin  -- process status_done_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_status_done_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_status_done_s <= '0';
        elsif h_spi_ctrl_en = '1' then
          if state = idle_s then
            h_spi_status_done_s <= '0';
          elsif state = dir_low_s then
            h_spi_status_done_s <= '1';
          else
            h_spi_status_done_s <= h_spi_status_done_s;
          end if;
        else
          h_spi_status_done_s <= h_spi_status_done_s;
        end if;
      end if;
    end if;
  end process status_done_p;

  h_spi_status_done <= h_spi_status_done_s;

  -- purpose: Generate active status signal
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_en, h_spi_cmd_strb_cmd
  -- outputs: h_spi_status_act
  status_act_p: process (clk_61) is
  begin  -- process status_act_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_status_act_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_status_act_s <= '0';
        elsif h_spi_ctrl_en = '1' then
          if (state = idle_s) and h_spi_cmd_strb_cmd = '1' then
            h_spi_status_act_s <= '1';
          else
            h_spi_status_act_s <= '0';
          end if;
        else
          h_spi_status_act_s <= h_spi_status_act_s;
        end if;
      end if;
    end if;
  end process status_act_p;

  h_spi_status_act <= h_spi_status_act_s;

  -- purpose: Generate TX FIFO empty status signal
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, tx_en, load_reg,
  --          load_reg_init, num_of_wd_in_tx_fifo
  -- outputs: h_spi_status_tx_empty
  status_tx_empty_p: process (clk_61) is
  begin  -- process status_tx_empty_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_status_tx_empty_s <= '1';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_status_tx_empty_s <= '1';
        elsif (h_spi_ctrl_mode /= "01") and (h_spi_ctrl_en = '1') and (tx_en = '1') then
          if num_of_wd_in_tx_fifo = x"0" then
            h_spi_status_tx_empty_s <= '1';
          else
            h_spi_status_tx_empty_s <= '0';
          end if;
        else
          h_spi_status_tx_empty_s <= h_spi_status_tx_empty_s;
        end if;
      end if;
    end if;
  end process status_tx_empty_p;

  h_spi_status_tx_empty <= h_spi_status_tx_empty_s;

  -- purpose: Generate TX FIFO full status signal
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, tx_en, num_of_wd_in_tx_fifo
  -- outputs: h_spi_status_tx_full
  status_tx_full_p: process (clk_61) is
  begin  -- process status_tx_full_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_status_tx_full_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_status_tx_full_s <= '0';
        elsif (h_spi_ctrl_mode /= "01") and (h_spi_ctrl_en = '1') and (tx_en = '1') then
          if num_of_wd_in_tx_fifo = "1000" then
            h_spi_status_tx_full_s <= '1';
          else
            h_spi_status_tx_full_s <= '0';
          end if;
        else
          h_spi_status_tx_full_s <= h_spi_status_tx_full_s;
        end if;
      end if;
    end if;
  end process status_tx_full_p;

  h_spi_status_tx_full <= h_spi_status_tx_full_s;

  -- purpose: Generate under flow signal for TX FIFO
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, tx_en, load_reg,
  --          load_reg_init, num_of_wd_in_tx_fifo
  -- outputs: h_spi_status_tx_ur
  status_tx_ur_p: process (clk_61) is
  begin  -- process status_tx_ur_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_status_tx_ur_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_status_tx_ur_s <= '0';
        elsif (h_spi_ctrl_mode /= "01") and (h_spi_ctrl_en = '1') and (tx_en = '1') then
          if (load_reg = '1') or (load_reg_init = '1') then
            if num_of_wd_in_tx_fifo = x"0" then
              h_spi_status_tx_ur_s <= '1';
            else
              h_spi_status_tx_ur_s <= '0';
            end if;
          else
            h_spi_status_tx_ur_s <= h_spi_status_tx_ur_s;
          end if;
        else
          h_spi_status_tx_ur_s <= h_spi_status_tx_ur_s;
        end if;
      end if;
    end if;
  end process status_tx_ur_p;

  h_spi_status_tx_ur <= h_spi_status_tx_ur_s;

  -- purpose: Generate the RX available signal for RX FIFO
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en,
  --          rx_en, num_of_fw_avail
  -- outputs: h_spi_status_rx_avail
  status_rx_av_p: process (clk_61) is
  begin  -- process status_rx_av_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_status_rx_avail_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_status_rx_avail_s <= '0';
        elsif h_spi_ctrl_mode /= "00" and h_spi_ctrl_en = '1' and rx_en = '1' then
          if num_of_fw_avail = "0000" then
            h_spi_status_rx_avail_s <= '0';
          else
            h_spi_status_rx_avail_s <= '1';
          end if;
        else
          h_spi_status_rx_avail_s <= h_spi_status_rx_avail_s;
        end if;
      end if;
    end if;
  end process status_rx_av_p;

  h_spi_status_rx_avail <= h_spi_status_rx_avail_s;

  -- purpose: Generate the RX full signal for RX FIFO
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en,
  --          rx_en, num_of_fw_avail
  -- outputs: h_spi_status_rx_full
  status_rx_fu_p: process (clk_61) is
  begin  -- process status_rx_fu_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_status_rx_full_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_status_rx_full_s <= '0';
        elsif h_spi_ctrl_mode /= "00" and h_spi_ctrl_en = '1' and rx_en = '1' then
          if num_of_fw_avail = "1000" then
            h_spi_status_rx_full_s <= '1';
          else
            h_spi_status_rx_full_s <= '0';
          end if;
        else
          h_spi_status_rx_full_s <= h_spi_status_rx_full_s;
        end if;
      end if;
    end if;
  end process status_rx_fu_p;

  h_spi_status_rx_full <= h_spi_status_rx_full_s;

  -- purpose: Generate the RX overrun signal for RX FIFO
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, h_spi_ctrl_mode, h_spi_ctrl_en, rx_en,
  --          h_spi_rx_get, num_of_fw_avail
  -- outputs: h_spi_status_rx_or_s
  status_rx_ov_p: process (clk_61) is
  begin  -- process status_rx_ov_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        h_spi_status_rx_or_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          h_spi_status_rx_or_s <= '0';
        elsif h_spi_ctrl_mode /= "00" and h_spi_ctrl_en = '1' and rx_en = '1' then
          if (h_spi_rx_get = '1') and (num_of_fw_avail = "0000") then
            h_spi_status_rx_or_s <= '1';
          else
            h_spi_status_rx_or_s <= h_spi_status_rx_or_s;
          end if;
        else
          h_spi_status_rx_or_s <= h_spi_status_rx_or_s;
        end if;
      end if;
    end if;
  end process status_rx_ov_p;

  h_spi_status_rx_or <= h_spi_status_rx_or_s;

end architecture rtl;
