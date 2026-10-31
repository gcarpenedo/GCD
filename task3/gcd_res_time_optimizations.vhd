-- -----------------------------------------------------------------------------
--
--  Title      :  FSMD implementation of GCD
--             :
--  Developers :  Jens Sparsø, Rasmus Bo Sørensen and Mathias Møller Bruhn
--           :
--  Purpose    :  This is a FSMD (finite state machine with datapath) 
--             :  implementation the GCD circuit
--             :
--  Revision   :  02203 fall 2019 v.5.0
--
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
--  NOTE: The `gcd` entity itself is declared only once, in task2/gcd.vhd.
--  This file adds an alternative architecture (fsmd_time_optimized) for that
--  same entity, so it must NOT redeclare `entity gcd`. To switch gcd_top to
--  use this architecture, just change the architecture name selected in
--  task2/gcd_top.vhd (u2 : entity work.gcd(<architecture name>)).
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture fsmd_res_time_optimized of gcd is

    type state_type is (RST, FIRST_HS, A_STORED, WAIT_USER, SECOND_HS, COMPUTE, CHECK_ZERO, DONE); -- Input your own state names

    signal reg_a, reg_b, C_int : signed(15 downto 0);
    signal Y : signed(16 downto 0);

    signal state, next_state : state_type;

    signal FN, ctrl_switch_en  : std_logic; -- ALU function select

    signal ABorALU, LDA, LDB, Z, N : std_logic;
    
    -- Switch signals
    signal in1, in2 : signed(15 downto 0);
    signal ctrl_switch : std_logic;
begin
  -- Combinatorial logic for FSM

    cl_fsm : process (state, req, Z, N, C_int, ctrl_switch)
    begin

    -- Default assignments (avoid inferred latches)
        next_state <= state;
        ack        <= '0';
        ABorALU    <= '0';
        LDA        <= '0';
        LDB        <= '0';
        FN         <= '0';
        C          <= (others => '0');
        ctrl_switch_en      <= '0';

        case state is
            when RST      =>  ack <= '0';
            if req = '1' then
                next_state <= FIRST_HS;
            end if;

    when FIRST_HS =>  ABorALU <= '1';
                      LDA <= '1';
                      next_state <= A_STORED;

    when A_STORED =>  ack <= '1';
                      if req = '0' then
                          next_state <= WAIT_USER;
                      end if;

    when WAIT_USER => ack <= '0';
                      if req = '1' then
                          next_state <= SECOND_HS;
                      end if;

    when SECOND_HS => ABorALU <= '1';
                      LDB <= '1';
                      next_state <= COMPUTE;

    when COMPUTE   => ABorALU <= '0';
                      LDA <= '0';
                      LDB <= '0';
                      FN <= '0';
                      next_state <= CHECK_ZERO;
                      ctrl_switch_en <= '1';

    when CHECK_ZERO => if Z = '1' then
                           next_state <= DONE;
                       elsif ctrl_switch = '1' then
                           LDB <= '1';
                           next_state <= COMPUTE;
                       elsif ctrl_switch = '0' then
                           LDA <= '1';
                           next_state <= COMPUTE;
                       else
                           next_state <= COMPUTE;
                       end if;

  when DONE      => ack <= '1';
  FN <= '1'; -- C <= reg_a
  C <= unsigned(C_int);
  if req = '0' then
      next_state <= RST;
  end if;

    end case;
end process cl_fsm;

  -- Combinatorial logic for MUX

cl_mux : process (ABorALU, AB, Y)
begin
    case ABorALU is 
        when '0' => C_int <= Y(15 downto 0);
        when '1' => C_int <= signed(AB);
        when others  => C_int <= (others => '0');
    end case;

end process cl_mux;

  -- Combinatorial logic for calculation

cl_switch : process (ctrl_switch, reg_a, reg_b)
begin 
    case ctrl_switch is 
        when '0' => in1 <= reg_a; in2 <= reg_b;
        when '1' => in1 <= reg_b; in2 <= reg_a;
        when others => in1 <= (others => '0'); in2 <= (others => '0');
    end case;
end process cl_switch;

cl_calc : process (FN, in1, in2)
begin
    case FN is
        when '0' => Y <= ('0' & in1) - ('0' & in2);
        when '1' => Y <= ('0' & in1);
        when others => Y <= (others => '0');
    end case;
end process cl_calc;

N <= Y(16);

  -- Combinatorial logic for evaluation

cl_eval : process (Y)
begin
    if Y = "00000000000000000" then 
        Z <= '1';
    else 
        Z <= '0';
    end if;
end process cl_eval;

  -- Registers

seq : process (clk, reset)
begin

    if reset = '1' then
        state <= RST;
        reg_a <= (others => '0');
        reg_b <= (others => '0');
    elsif rising_edge(clk) then
        state <= next_state;
        if LDA = '1' then 
            reg_a <= C_int;
        else 
            reg_a <= reg_a;
        end if;
        if LDB = '1' then 
            reg_b <= C_int;
        else 
            reg_b <= reg_b;
        end if;
    end if;
end process seq;

seq_switch : process (clk, reset)
begin
    if reset = '1' then
        ctrl_switch <= '0';
    elsif rising_edge(clk) then
        if ctrl_switch_en = '1' then
            ctrl_switch <= N;
        else
            ctrl_switch <= '0';
        end if;
    end if;
end process seq_switch;

end fsmd_res_time_optimized;
