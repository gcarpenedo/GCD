-- -----------------------------------------------------------------------------
--
--  Title      :  FSM controller for the GCD module (Task 4)
--             :
--  Purpose    :  This is the FSM entity referred to in Figure 2 of the
--             :  assignment. It contains only the control logic (the
--             :  Moore-style state register and the combinatorial next-state
--             :  / output logic) and drives the datapath entity (datapath.vhd)
--             :  through ABorALU, LDA, LDB and FN. It is instantiated, together
--             :  with the datapath entity, by the structural architecture in
--             :  gcd_module.vhd.
--             :
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity FSM is
  port (
    clk     : in  std_logic;              -- The clock signal.
    reset   : in  std_logic;              -- Reset the module.
    req     : in  std_logic;              -- Input operand / start computation.
    Z       : in  std_logic;              -- ALU result-is-zero flag.
    N       : in  std_logic;              -- ALU result-is-negative flag.
    ack     : out std_logic;              -- Computation is complete.
    ABorALU : out std_logic;              -- Datapath mux select (0: AB, 1: ALU result).
    LDA     : out std_logic;              -- Load enable for RegA.
    LDB     : out std_logic;              -- Load enable for RegB.
    FN      : out std_logic_vector(1 downto 0)  -- ALU function select.
  );
end FSM;

architecture behaviour of FSM is

  type state_type is (RST, FIRST_HS, A_STORED, WAIT_USER, SECOND_HS, COMPUTE, CHECK_ZERO, POS, NEG, DONE);

  signal state, next_state : state_type;

begin

  -- Combinatorial logic: next state and outputs
  cl_fsm : process (state, req, Z, N)
  begin

    -- Default assignments (avoid inferred latches)
    next_state <= state;
    ack        <= '0';
    ABorALU    <= '0';
    LDA        <= '0';
    LDB        <= '0';
    FN         <= "00";

    case state is
      when RST       => ack <= '0';
                         if req = '1' then
                           next_state <= FIRST_HS;
                         end if;

      when FIRST_HS  => ABorALU <= '0';  -- select AB input
                         LDA <= '1';
                         next_state <= A_STORED;

      when A_STORED  => ack <= '1';
                         if req = '0' then
                           next_state <= WAIT_USER;
                         end if;

      when WAIT_USER => ack <= '0';
                         if req = '1' then
                           next_state <= SECOND_HS;
                         end if;

      when SECOND_HS => ABorALU <= '0';  -- select AB input
                         LDB <= '1';
                         next_state <= COMPUTE;

      when COMPUTE   => ABorALU <= '0';
                         LDA <= '0';
                         LDB <= '0';
                         FN <= "00";
                         next_state <= CHECK_ZERO;

      when CHECK_ZERO => if Z = '1' then
                           next_state <= DONE;
                         elsif N = '1' then
                           next_state <= NEG;
                         else
                           next_state <= POS;
                         end if;

      when POS       => ABorALU <= '1';  -- select ALU result
                         LDA <= '1';
                         FN <= "00"; -- reg_a <= reg_a - reg_b
                         next_state <= COMPUTE;

      when NEG       => ABorALU <= '1';  -- select ALU result
                         LDB <= '1';
                         FN <= "01"; -- reg_b <= reg_b - reg_a
                         next_state <= COMPUTE;

      when DONE      => ack <= '1';
                         ABorALU <= '1';  -- select ALU result so mux_out = reg_a
                         FN <= "10"; -- C <= reg_a
                         if req = '0' then
                           next_state <= RST;
                         end if;

    end case;
  end process cl_fsm;

  -- State register
  seq : process (clk, reset)
  begin
    if reset = '1' then
      state <= RST;
    elsif rising_edge(clk) then
      state <= next_state;
    end if;
  end process seq;

end behaviour;
