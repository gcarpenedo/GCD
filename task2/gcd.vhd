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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture fsmd of gcd is

  type state_type is (RST, FIRST_HS, A_STORED, WAIT_USER, SECOND_HS, COMPUTE, CHECK_ZERO, POS, NEG, DONE); -- Input your own state names

  signal reg_a, reg_b, C_int : signed(15 downto 0);
  signal Y : signed(16 downto 0);

  signal state, next_state : state_type;

  signal FN  : std_logic_vector(1 downto 0); -- ALU function select

  signal ABorALU, LDA, LDB, z, n : std_logic;

begin
  -- Combinatorial logic for FSM

  cl_fsm : process (state, req, Z, N, C_int)
  begin

    -- Default assignments (avoid inferred latches)
    next_state <= state;
    ack        <= '0';
    ABorALU    <= '0';
    LDA        <= '0';
    LDB        <= '0';
    FN         <= "00";
    C          <= (others => '0');

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
                        FN <= "00";
                        next_state <= CHECK_ZERO;

      when CHECK_ZERO => if Z = '1' then
                          next_state <= DONE;
                        elsif N = '1' then
                          next_state <= NEG;
                        else
                          next_state <= POS;
                        end if;

      when POS       => LDA <= '1';
                        FN <= "00"; -- reg_a <= reg_a - reg_b
                        next_state <= COMPUTE;

      when NEG       => LDB <= '1';
                        FN <= "01"; -- reg_b <= reg_b - reg_a
                        next_state <= COMPUTE;


      when DONE      => ack <= '1';
                        FN <= "10"; -- C <= reg_a
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

  cl_calc : process (FN, reg_a, reg_b)
  begin
    case FN is 
        when "00" => Y <= ('0' & reg_a) - ('0' & reg_b);    
        when "01" => Y <= ('0' & reg_b) - ('0' & reg_a);
        when "10" => Y <= ('0' & reg_a);
        when "11" => Y <= ('0' & reg_b);
        when others => Y <= (others => '0');
    end case;
  end process cl_calc;

  -- Combinatorial logic for evaluation

  cl_eval : process (Y)
  begin
    n <= Y(16);
    if Y = "00000000000000000" then 
        z <= '1';
    else 
        z <= '0';
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

end fsmd;
