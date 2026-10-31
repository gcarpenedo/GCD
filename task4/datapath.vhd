-- -----------------------------------------------------------------------------
--
--  Title      :  Datapath for the GCD module (Task 4)
--             :
--  Purpose    :  This is the datapath entity referred to in Figure 2 of the
--             :  assignment. It is built purely structurally out of the
--             :  components declared/defined in comp.vhd (mux, reg, alu, buf),
--             :  and it is controlled by the FSM entity (fsm.vhd) through
--             :  ABorALU, LDA, LDB and FN. It is instantiated, together with
--             :  the FSM entity, by the structural architecture in
--             :  gcd_module.vhd.
--             :
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity datapath is
  port (
    clk     : in  std_logic;                      -- The clock signal.
    AB      : in  unsigned(15 downto 0);          -- The operand bus (from outside).
    ABorALU : in  std_logic;                      -- Mux select (0: AB, 1: ALU result).
    LDA     : in  std_logic;                      -- Load enable for RegA.
    LDB     : in  std_logic;                      -- Load enable for RegB.
    FN      : in  std_logic_vector(1 downto 0);   -- ALU function select.
    C       : out unsigned(15 downto 0);          -- The result.
    Z       : out std_logic;                      -- ALU result-is-zero flag.
    N       : out std_logic                       -- ALU result-is-negative flag.
  );
end datapath;

architecture structural of datapath is

  signal reg_a, reg_b, mux_out, alu_low, C_mid : unsigned(15 downto 0);
  signal alu_a, alu_b, alu_out : unsigned(17 downto 1);

  component buf is
    generic (N:     natural := 16);
    port (data_in:  in  unsigned(N downto 1);
          data_out: out unsigned(N downto 1));
  end component;

  component mux is
    generic (N:     natural := 16);
    port (data_in1:  in  unsigned(N downto 1);
          data_in2:  in unsigned(N downto 1);
          s       :  in std_logic;
          data_out:  out  unsigned(N downto 1)
          );
  end component;

  component reg is
    generic (N:     natural := 16);
    port (clk:      in  std_logic;
          en:       in  std_logic;
          data_in:  in  unsigned(N downto 1);
          data_out: out unsigned(N downto 1));
  end component;

  component alu is
    generic (W:     natural := 16);
    port (A, B:     in unsigned(w downto 1);
          fn:       in std_logic_vector(1 downto 0);
          C:        out unsigned(W downto 1);
          Z:        out std_logic;
          N:        out std_logic);
  end component;

begin

  alu_a <= '0' & reg_a;
  alu_b <= '0' & reg_b;
  alu_low <= alu_out(16 downto 1);

  u_mux : mux
    port map (data_in1 => AB, data_in2 => alu_low, s => ABorALU, data_out => mux_out);

  u_reg_a : reg
    port map (clk => clk, en => LDA, data_in => mux_out, data_out => reg_a);

  u_reg_b : reg
    port map (clk => clk, en => LDB, data_in => mux_out, data_out => reg_b);

  u_alu : alu
    generic map (W => 17)
    port map (A => alu_a, B => alu_b, fn => FN, C => alu_out, Z => Z, N => N);

  -- Only present the ALU/reg_a result on C once the FSM has selected the
  -- "pass A" function (FN = "10"), i.e. in the DONE state.
  u_Cmux : mux
    port map (data_in1 => (others => '0'), data_in2 => mux_out, s => FN(1), data_out => C_mid);

  u_buf : buf
    port map (data_in => C_mid, data_out => C);

end structural;
