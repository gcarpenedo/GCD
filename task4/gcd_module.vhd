-- -----------------------------------------------------------------------------
--
--  Title      :  Structural (component-based) implementation of GCD (Task 4)
--             :
--  Purpose    :  Task 4 asks for a structural architecture body for the GCD
--             :  module made up of exactly two entities/components, FSM and
--             :  datapath, as shown in Figure 2 of the assignment. This file
--             :  contains that top-level structural architecture: it declares
--             :  the FSM and datapath components (defined in fsm.vhd and
--             :  datapath.vhd) and wires them together.
--             :
--             :  This is a separate architecture of the same "gcd" entity
--             :  used throughout the assignment, so it can be selected in
--             :  gcd_top.vhd the same way as the other architectures
--             :  (u2 : entity work.gcd(structural)).
--             :
-- -----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture structural of gcd is

  signal ABorALU, LDA, LDB, Z, N : std_logic;
  signal FN : std_logic_vector(1 downto 0);

  component FSM is
    port (
      clk     : in  std_logic;
      reset   : in  std_logic;
      req     : in  std_logic;
      Z       : in  std_logic;
      N       : in  std_logic;
      ack     : out std_logic;
      ABorALU : out std_logic;
      LDA     : out std_logic;
      LDB     : out std_logic;
      FN      : out std_logic_vector(1 downto 0)
    );
  end component;

  component datapath is
    port (
      clk     : in  std_logic;
      AB      : in  unsigned(15 downto 0);
      ABorALU : in  std_logic;
      LDA     : in  std_logic;
      LDB     : in  std_logic;
      FN      : in  std_logic_vector(1 downto 0);
      C       : out unsigned(15 downto 0);
      Z       : out std_logic;
      N       : out std_logic
    );
  end component;

begin

  u_fsm : FSM
    port map (
      clk => clk, reset => reset, req => req, Z => Z, N => N,
      ack => ack, ABorALU => ABorALU, LDA => LDA, LDB => LDB, FN => FN
    );

  u_datapath : datapath
    port map (
      clk => clk, AB => AB, ABorALU => ABorALU, LDA => LDA, LDB => LDB, FN => FN,
      C => C, Z => Z, N => N
    );

end structural;
