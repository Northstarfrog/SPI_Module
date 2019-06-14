--------------------------------------------------------------------

-- Description:
--
-- The main controller for SPI which is used to handle SPI send and
-- receive.
--
--------------------------------------------------------------------
-- VHDL Version: VHDL '93
--
--------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity spi_ctrl_clock is

  port (
    clk_61                : in  std_logic;                      -- 61.44MHz clock
    rst_61                : in  std_logic;                      -- reset signal with 61.44MHz clock
    start_strb            : in  std_logic;                      -- start flag from interface FSM
    strb_done             : out std_logic;                      -- end flag for transaction
    cpol_set              : out std_logic;                      -- Send out SPI clock
    load_reg              : out std_logic;                      -- Load content need to send out
    put_rx_fifo           : out std_logic;                      -- Send out recieved data
    tx_en                 : out std_logic;                      -- TX enable signal
    rx_en                 : out std_logic;                      -- RX enable signal
    put_leading_edge      : out std_logic;                      -- TX strobe leading edge
    samp_leading_edge     : out std_logic;                      -- RX strobe leading edge
    put_trailing_edge     : out std_logic;                      -- TX strobe trailing edge
    samp_trailing_edge    : out std_logic;                      -- RX strobe trailing edge
    dir_en                : out std_logic;                      -- Direction enable signal
    length_val            : out std_logic_vector(8 downto 0);   -- The value of length
    length_dir            : out std_logic_vector(8 downto 0);   -- The value of dir length
    h_spi_length_dir      : in  std_logic_vector(7 downto 0);   -- SPI length
    h_spi_length_val      : in  std_logic_vector(7 downto 0);   -- SPI length
    h_spi_cmd_reset_cmd   : in  std_logic;                      -- reset command
    h_spi_ctrl_mode       : in  std_logic_vector(1 downto 0);   -- Mode selection
    h_spi_ctrl_rate       : in  std_logic_vector(13 downto 0);  -- rate control from AXI
    h_spi_ctrl_clk_idle   : in  std_logic;                      -- clock idle from AXI configuration
    h_spi_ctrl_cpol       : in  std_logic;                      -- SPI clock polarity bit
    h_spi_ctrl_cpha       : in  std_logic);                     -- SPI clock phase bit
end entity spi_ctrl_clock;

architecture rtl of spi_ctrl_clock is
-------------------------------------------------------------------------------
-- Signal used by FSM
-------------------------------------------------------------------------------
  type state_t is (idle_s, clk1_s, clk0_s, clk_done_s, last_put_rx_fifo_s, rx_strb_samp_lead_s,
                   bidir_clk_idle_s, bidir_clk_idle0_s);
  signal state      : state_t;
  signal next_state : state_t;

-------------------------------------------------------------------------------
-- Internal Signals
-------------------------------------------------------------------------------
  signal cnt                            : std_logic_vector(14 downto 0);
  signal strb_cnt                       : std_logic_vector(8 downto 0);
  signal i_length_val                   : std_logic_vector(8 downto 0);
  signal i_length_dir                   : std_logic_vector(8 downto 0);
  signal num_of_strbs                   : std_logic_vector(8 downto 0);
  signal num_of_tx_strbs                : std_logic_vector(8 downto 0);
  signal rx_cnt                         : std_logic_vector(9 downto 0);
  signal tx_strb_put_leading_edge       : std_logic;
  signal tx_strb_put_trailing_edge      : std_logic;
  signal rx_strb_samp_trailing_edge     : std_logic;
  signal rx_strb_samp_leading_edge      : std_logic;
  signal strb_done_s                    : std_logic;
  signal clk_gen                        : std_logic;
  signal load_reg_s                     : std_logic;
  signal put_rx_fifo_s                  : std_logic;
  signal tx_en_s                        : std_logic;
  signal rx_en_s                        : std_logic;
  signal dir_en_s                       : std_logic;

begin  -- architecture rtl
-------------------------------------------------------------------------------
-- FSM
-------------------------------------------------------------------------------
  -- purpose: Update the FSM state
  -- type   : sequential
  -- inputs : clk_61, rst_61, nextstate
  -- outputs: state
  state_up_p : process (clk_61) is
  begin  -- process state_up_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        state <= idle_s;
      elsif h_spi_cmd_reset_cmd = '1' then
        state <= idle_s;
      else
        state <= next_state;
      end if;
    end if;
  end process state_up_p;

  -- purpose: Main body of FSM
  -- type   : combinational
  -- inputs : h_spi_cmd_reset_cmd
  -- outputs: next_state
  fsm_p: process (cnt, h_spi_ctrl_clk_idle, h_spi_ctrl_mode, h_spi_ctrl_rate, num_of_strbs,
                  num_of_tx_strbs,rx_en_s, start_strb, state, strb_cnt) is
  begin  -- process fsm_p
    case state is
      when idle_s =>
        --Start condition
        if start_strb = '1' then
          --Handle Bidirectional
          if h_spi_ctrl_mode = "10" then
            next_state <= clk1_s;
          else
            next_state <= rx_strb_samp_lead_s;
          end if;
        else
          next_state <= idle_s;
        end if;
      --SPI clock high
      when clk1_s =>
        --Reach SPI clock speed
        if cnt = '0' & h_spi_ctrl_rate then
          --Transmit part is done for bidirection mode
          if strb_cnt = num_of_tx_strbs-1 and h_spi_ctrl_mode = "10" and rx_en_s = '0' then
            next_state <= bidir_clk_idle_s;
          else
            next_state <= clk0_s;
          end if;
        else
          next_state <= clk1_s;
        end if;
      --SPI clock low
      when clk0_s =>
        --Reach SPI clock speed
        if cnt = '0' & h_spi_ctrl_rate then
          --Still have some data need transmit or receive
          if strb_cnt < num_of_strbs then
            next_state <= clk1_s;
          --Done
          else
            next_state <= clk_done_s;
          end if;
        else
          next_state <= clk0_s;
        end if;
      when clk_done_s =>
        --Write RX data
        next_state <= last_put_rx_fifo_s;
      when last_put_rx_fifo_s =>
        --clk_idle = '0' half cycle advance for ss, dir before first clock toggling for bidirection mode
        --               half cycle delay for ss after last clock toggling for bidirection mode
        --               half cycle delay between T -> R for bidireciton mode
        --clk_idle = '1' One cycle advance for ss, dir before first clock toggling for bidirection mode
        --               One cycle delay for ss after last clock toggling for bidirection mode
        --               One cycle delay between T -> R for bidireciton mode
        if h_spi_ctrl_mode = "10" and h_spi_ctrl_clk_idle = '1' then
          --Wait extra half clock cycle at the end
          if cnt = '0' & h_spi_ctrl_rate then
            next_state <= idle_s;
          else
            next_state <= last_put_rx_fifo_s;
          end if;
        else
          next_state <= idle_s;
        end if;
      when rx_strb_samp_lead_s =>
        --Only one cycle
        next_state <= clk1_s;
      when bidir_clk_idle_s =>
        --Add one cycle or half cycle delay between T -> R for bidirection mode
        if h_spi_ctrl_rate /= 0 then
          if h_spi_ctrl_clk_idle = '1' then
            if cnt = (h_spi_ctrl_rate & '1') then
              next_state <= bidir_clk_idle0_s;
            else
              next_state <= bidir_clk_idle_s;
            end if;
          else
            if cnt = '0' & h_spi_ctrl_rate then
              next_state <= bidir_clk_idle0_s;
            else
              next_state <= bidir_clk_idle_s;
            end if;
          end if;
        --Handle rate setting is 0
        elsif (cnt = "00000000000000" & h_spi_ctrl_clk_idle and h_spi_ctrl_rate = 0) then
          next_state <= bidir_clk_idle0_s;
        else
          next_state <= bidir_clk_idle_s;
        end if;
      when bidir_clk_idle0_s =>
        --Recieve part of bidirection
        if cnt = '0' & h_spi_ctrl_rate then
          next_state <= rx_strb_samp_lead_s;
        else
          next_state <= bidir_clk_idle0_s;
        end if;
      when others =>
        next_state <= idle_s;
    end case;
  end process fsm_p;

-------------------------------------------------------------------------------
-- Handle signals from AXI
-------------------------------------------------------------------------------
  -- purpose: get the counter from AXI
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_ctrl_rate, h_spi_length_val, h_spi_length_dir,
  --          h_spi_ctrl_clk_idle
  -- outputs: i_length_val, i_length_dir, num_of_strbs, num_of_tx_strbs,
  --          i_hc_idle
  axi_cnt_p: process (clk_61) is
  begin  -- process axi_cnt_p
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        i_length_val    <= "00000000" & '1';
        i_length_dir    <= (others => '0');
        num_of_strbs    <= (others => '0');
        num_of_tx_strbs <= (others => '0');
      else
        i_length_val    <= '0' & h_spi_length_val + '1';
        i_length_dir    <= '0' & h_spi_length_dir + '1';
        num_of_strbs    <= h_spi_length_val & '1';
        num_of_tx_strbs <= h_spi_length_dir & '1';
      end if;
    end if;
  end process axi_cnt_p;

  length_val <= i_length_val;
  length_dir <= i_length_dir;

-------------------------------------------------------------------------------
-- Handle clock counter
-------------------------------------------------------------------------------
  -- purpose: Handle the coutner which is used to genereate SPI clock as rate setting
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, h_spi_ctrl_rate, h_spi_cmd_reset_cmd, h_spi_ctrl_clk_idle
  --          h_spi_ctrl_mode
  -- outputs: cnt
  cnt_proc: process (clk_61) is
  begin  -- process cnt_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        cnt <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          cnt <= (others => '0');
        else
          case state is
            when idle_s =>
              cnt <= (others => '0');
            when clk1_s =>
              if cnt = '0' & h_spi_ctrl_rate then
                cnt <= (others => '0');
              else
                cnt <= cnt + '1';
              end if;
            when clk0_s =>
              if cnt = '0' & h_spi_ctrl_rate then
                cnt <= (others => '0');
              else
                cnt <= cnt + '1';
              end if;
            when clk_done_s =>
              cnt <= (others => '0');
            when last_put_rx_fifo_s =>
              --Add extra half clock cycle
              if h_spi_ctrl_mode = "10" and h_spi_ctrl_clk_idle = '1' then
                if cnt = '0' & h_spi_ctrl_rate then
                  cnt <= (others => '0');
                else
                  cnt <= cnt + '1';
                end if;
              end if;
            when rx_strb_samp_lead_s =>
              cnt <= (others => '0');
            when bidir_clk_idle_s =>
              --Setting for 30.72MHz SPI clock
              if h_spi_ctrl_rate = 0 then
                if cnt = "00000000000000" & h_spi_ctrl_clk_idle then
                  cnt <= (others => '0');
                else
                  cnt <= cnt + '1';
                end if;
              else
                if h_spi_ctrl_clk_idle = '0' then
                  if cnt = '0' & h_spi_ctrl_rate then
                    cnt <= (others => '0');
                  else
                    cnt <= cnt + '1';
                  end if;
                else
                  if cnt = h_spi_ctrl_rate & '1' then
                    cnt <= (others => '0');
                  else
                    cnt <= cnt + '1';
                  end if;
                end if;
              end if;
            when bidir_clk_idle0_s =>
              if cnt = '0' & h_spi_ctrl_rate then
                cnt <= (others => '0');
              else
                cnt <= cnt + '1';
              end if;
            when others =>
              cnt <= (others => '0');
          end case;
        end if;
      end if;
    end if;
  end process cnt_proc;

-------------------------------------------------------------------------------
-- Count clock toggling
-------------------------------------------------------------------------------
  -- purpose: Count the toggoling of clock signal
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, cnt. h_spi_ctrl_rate
  -- outputs: strb_cnt
  strb_cnt_proc: process (clk_61) is
  begin  -- process strb_cnt_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        strb_cnt <= (others => '0');
      else
        if h_spi_cmd_reset_cmd = '1' then
          strb_cnt <= (others => '0');
        else
          case state is
            when idle_s =>
              strb_cnt <= (others => '0');
            when rx_strb_samp_lead_s =>
              -- Add one more for bi-direction
              if h_spi_ctrl_mode = "10" then
                strb_cnt <= strb_cnt + '1';
              else
                strb_cnt <= strb_cnt;
              end if;
            when clk1_s =>
              if cnt = '0' & h_spi_ctrl_rate then
                strb_cnt <= strb_cnt + '1';
              else
                strb_cnt <= strb_cnt;
              end if;
            when clk0_s =>
              if cnt = '0' & h_spi_ctrl_rate then
                if strb_cnt = num_of_strbs then
                  strb_cnt <= num_of_strbs;
                else
                  strb_cnt <= strb_cnt + '1';
                end if;
              else
                strb_cnt <= strb_cnt;
              end if;
            when others =>
              strb_cnt <= strb_cnt;
          end case;
        end if;
      end if;
    end if;
  end process strb_cnt_proc;

-------------------------------------------------------------------------------
-- Strobe signal for TX and RX
-------------------------------------------------------------------------------
  -- purpose: Generate strobe signal for TX leading edge
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, cnt, h_spi_ctrl_rate
  -- outputs: tx_strb_put_leading_edge
  tx_lead_strb_proc: process (clk_61) is
  begin  -- process tx_lead_strb_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        tx_strb_put_leading_edge <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          tx_strb_put_leading_edge <= '0';
        elsif state = clk0_s and cnt = '0' & h_spi_ctrl_rate and strb_cnt < num_of_strbs then
          tx_strb_put_leading_edge <= '1';
        else
          tx_strb_put_leading_edge <= '0';
        end if;
      end if;
    end if;
  end process tx_lead_strb_proc;

  -- purpose: Generate strobe signal for RX leading edge
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, cnt, h_spi_ctrl_rate
  -- outputs: rx_strb_samp_leading_edge
  rx_lead_strb_proc: process (clk_61) is
  begin  -- process rx_lead_strb_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        rx_strb_samp_leading_edge <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          rx_strb_samp_leading_edge <= '0';
        elsif (state = clk0_s and cnt = '0' & h_spi_ctrl_rate and strb_cnt < num_of_strbs) or
          (state = rx_strb_samp_lead_s) then
          rx_strb_samp_leading_edge <= '1';
        else
          rx_strb_samp_leading_edge <= '0';
        end if;
      end if;
    end if;
  end process rx_lead_strb_proc;

  -- purpose: Generate strobe signal for TX trailing edge
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, cnt, h_spi_ctrl_rate
  -- outputs: tx_strb_put_trailing_edge
  tx_trail_strb_proc: process (clk_61) is
  begin  -- process tx_trail_strb_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        tx_strb_put_trailing_edge <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          tx_strb_put_trailing_edge <= '0';
        elsif state = clk1_s and cnt = '0' & h_spi_ctrl_rate and strb_cnt < num_of_strbs - 1 then
          tx_strb_put_trailing_edge <= '1';
        else
          tx_strb_put_trailing_edge <= '0';
        end if;
      end if;
    end if;
  end process tx_trail_strb_proc;

  -- purpose: Generate strobe signal for RX trailing edge
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, cnt, h_spi_ctrl_rate
  -- outputs: rx_strb_samp_trailing_edge
  rx_trail_strb_proc: process (clk_61) is
  begin  -- process rx_trail_strb_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        rx_strb_samp_trailing_edge <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          rx_strb_samp_trailing_edge <= '0';
        elsif state = clk1_s and cnt = '0' & h_spi_ctrl_rate then
          rx_strb_samp_trailing_edge <= '1';
        else
          rx_strb_samp_trailing_edge <= '0';
        end if;
      end if;
    end if;
  end process rx_trail_strb_proc;

  put_leading_edge <= tx_strb_put_leading_edge;
  samp_leading_edge <= rx_strb_samp_leading_edge;
  put_trailing_edge <= tx_strb_put_trailing_edge;
  samp_trailing_edge <= rx_strb_samp_trailing_edge;

-------------------------------------------------------------------------------
-- Strobe done signal
-------------------------------------------------------------------------------
  -- purpose: Generate strobe done signal indication transaction done
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, strobe_cnt, num_of_strbs
  -- outputs: strb_done
  strb_done_proc: process (clk_61) is
  begin  -- process strb_done_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        strb_done_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          strb_done_s <= '0';
        elsif state = idle_s then
          strb_done_s <= '0';
        elsif state = clk1_s and cnt = '0' & h_spi_ctrl_rate and strb_cnt = num_of_strbs - 1 then
          strb_done_s <= '1';
        else
          strb_done_s <= strb_done_s;
        end if;
      end if;
    end if;
  end process strb_done_proc;

  strb_done <= strb_done_s;

-------------------------------------------------------------------------------
-- Generate SPI clock signal
-------------------------------------------------------------------------------
  -- purpose: Generate clock siganl for SPI
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, h_spi_cmd_reset_cmd
  -- outputs: clk_gen
  clk_gen_ps: process (clk_61) is
  begin  -- process clk_gen_ps
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        clk_gen <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          clk_gen <= h_spi_ctrl_cpol;
        elsif state = clk1_s then
          clk_gen <= not h_spi_ctrl_cpol;
        elsif state = bidir_clk_idle_s then
          if h_spi_ctrl_cpha = '1' then
            clk_gen <= h_spi_ctrl_cpol;
          else
            clk_gen <= clk_gen;
          end if;
        else
          clk_gen <= h_spi_ctrl_cpol;
        end if;
      end if;
    end if;
  end process clk_gen_ps;

  cpol_set <= clk_gen;

-------------------------------------------------------------------------------
-- Load Register Value used to send out
-------------------------------------------------------------------------------
  -- purpose: Generate the load register signal used to load content
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, state, strb_cnt, num_of_strbs,
  --          num_of_tx_strbs, h_spi_ctrl_cpha
  -- outputs: load_reg_s
  load_reg_proc: process (clk_61) is
  begin  -- process load_reg_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        load_reg_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          load_reg_s <= '0';
        else
          if (state = clk1_s) and (cnt = '0' & h_spi_ctrl_rate) then
            if strb_cnt < num_of_strbs - 1 then
              if h_spi_ctrl_mode = "10" then
                if strb_cnt < num_of_tx_strbs - '1' and strb_cnt(5 downto 0) = "111110" and
                  h_spi_ctrl_cpha = '0' then
                  load_reg_s <= '1';
                else
                  load_reg_s <= '0';
                end if;
              else
                if (strb_cnt(5 downto 0) = "111110" or strb_cnt(5 downto 0) = "111101") and
                  h_spi_ctrl_cpha = '0' then
                  load_reg_s <= '1';
                else
                  load_reg_s <= '0';
                end if;
              end if;
            else
              load_reg_s <= '0';
            end if;
          elsif (state = clk0_s) and (cnt = '0' & h_spi_ctrl_rate) then
            if strb_cnt < num_of_strbs and h_spi_ctrl_cpha = '1' and strb_cnt > 0 then
              if h_spi_ctrl_mode = "10" then
                if (strb_cnt < num_of_tx_strbs - 1) and (strb_cnt(5 downto 0) = "111111") then
                  load_reg_s <= '1';
                else
                  load_reg_s <= '0';
                end if;
              else
                if strb_cnt(5 downto 0) = "111111" or strb_cnt(5 downto 0) = "000000" then
                  load_reg_s <= '1';
                else
                  load_reg_s <= '0';
                end if;
              end if;
            else
              load_reg_s <= '0';
            end if;
          else
            load_reg_s <= '0';
          end if;
        end if;

      end if;
    end if;
  end process load_reg_proc;

  load_reg <= load_reg_s;

-------------------------------------------------------------------------------
-- Store register value recieved from SPI
-------------------------------------------------------------------------------
  -- purpose: Generate put_Rx_fifo control signal used to store RX data
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, h_spi_cmd_reset_cmd, strb_cnt, num_of_tx_strbs,
  --          num_of_strbs, h_spi_ctrl_cpha
  -- outputs: put_rx_fifo
  put_fifo_proc: process (clk_61) is
  begin  -- process put_fifo_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        put_rx_fifo_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          put_rx_fifo_s <= '0';
        else
          if (state = clk1_s) and (cnt = '0' & h_spi_ctrl_rate) then
            if strb_cnt < num_of_strbs - 1 then
              if h_spi_ctrl_mode = "10" then
                if rx_cnt(9) = '0' and rx_cnt(5 downto 0) = "111111" and h_spi_ctrl_cpha = '0' then
                  put_rx_fifo_s <= '1';
                else
                  put_rx_fifo_s <= '0';
                end if;
              else
                if (strb_cnt(5 downto 0) = "111110" or strb_cnt(5 downto 0) = "111101") and
                  h_spi_ctrl_cpha = '0' then
                  put_rx_fifo_s <= '1';
                else
                  put_rx_fifo_s <= '0';
                end if;
              end if;
            else
              put_rx_fifo_s <= '0';
            end if;
          elsif (state = clk0_s) and (cnt = '0' & h_spi_ctrl_rate) then
            if (strb_cnt < num_of_strbs) and (h_spi_ctrl_cpha = '1') then
              if h_spi_ctrl_mode = "10" then
                if rx_cnt(5 downto 0) = "000000" and rx_cnt(9) = '0' then
                  put_rx_fifo_s <= '1';
                else
                  put_rx_fifo_s <= '0';
                end if;
              else
                if (strb_cnt(5 downto 0) = "111111" or strb_cnt(5 downto 0) = "000000") then
                  put_rx_fifo_s <= '1';
                else
                  put_rx_fifo_s <= '0';
                end if;
              end if;
            else
              put_rx_fifo_s <= '0';
            end if;
          elsif (state = last_put_rx_fifo_s) and cnt = 0 then
            put_rx_fifo_s <= '1';
          else
            put_rx_fifo_s <= '0';
          end if;
        end if;
      end if;
    end if;
  end process put_fifo_proc;

  rx_cnt <= '0' & (strb_cnt - num_of_tx_strbs) when strb_cnt > num_of_tx_strbs else
            "1000000000";

  put_rx_fifo <= put_rx_fifo_s;

-------------------------------------------------------------------------------
-- TX enable signal
-------------------------------------------------------------------------------
  -- purpose: Generate TX signal
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, h_spi_cmd_reset_cmd, h_spi_ctrl_mode
  -- outputs: tx_en
  tx_en_proc: process (clk_61) is
  begin  -- process tx_en_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        tx_en_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          tx_en_s <= '0';
        elsif state = idle_s then
          tx_en_s <= '1';
        elsif (state = rx_strb_samp_lead_s) and h_spi_ctrl_mode = "10" then
          tx_en_s <= '0';
        else
          tx_en_s <= tx_en_s;
        end if;
      end if;
    end if;
  end process tx_en_proc;

  tx_en <= tx_en_s;

-------------------------------------------------------------------------------
-- RX enable signal
-------------------------------------------------------------------------------
  -- purpose: Generate RX signal
  -- type   : sequential
  -- inputs : clk_61, rst_61, state, h_spi_cmd_reset_cmd, start_strb, h_spi_ctrl_mode
  -- outputs: rx_en
  rx_en_proc: process (clk_61) is
  begin  -- process rx_en_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        rx_en_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          rx_en_s <= '0';
        elsif state = idle_s then
          if start_strb = '1' and h_spi_ctrl_mode = "10" then
            rx_en_s <= '0';
          else
            rx_en_s <= '1';
          end if;
        elsif state = rx_strb_samp_lead_s then
          rx_en_s <= '1';
        else
          rx_en_s <= rx_en_s;
        end if;
      end if;
    end if;
  end process rx_en_proc;

  rx_en <= rx_en_s;

-------------------------------------------------------------------------------
-- Direction signal
-------------------------------------------------------------------------------
  -- purpose: Generate direction enable signal
  -- type   : sequential
  -- inputs : clk_61, rst_61, h_spi_cmd_reset_cmd, state, h_spi_ctrl_cpha, cnt, clk_div
  -- outputs: dir_en
  dir_en_proc: process (clk_61) is
  begin  -- process dir_en_proc
    if rising_edge(clk_61) then         -- rising clock edge
      if rst_61 = '1' then              -- synchronous reset (active high)
        dir_en_s <= '0';
      else
        if h_spi_cmd_reset_cmd = '1' then
          dir_en_s <= '0';
        elsif state = idle_s then
          dir_en_s <= '1';
        elsif state = bidir_clk_idle_s then
          if (h_spi_ctrl_cpha = '0') or (cnt = ('0' & h_spi_ctrl_rate) + '1') then
            dir_en_s <= '0';
          else
            dir_en_s <= dir_en_s;
          end if;
        elsif state = bidir_clk_idle0_s then
          dir_en_s <= '0';
        else
          dir_en_s <= dir_en_s;
        end if;
      end if;
    end if;
  end process dir_en_proc;

  dir_en <= dir_en_s;


end architecture rtl;
