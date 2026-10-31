library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gcd is
  port (
    clk     : in std_logic;               -- The clock signal.
    reset   : in  std_logic;              -- Reset the module.
    req     : in  std_logic;              -- Input operand / start computation.
    AB      : in  unsigned(15 downto 0);  -- The two operands.
    ack     : out std_logic;              -- Computation is complete.
    C       : out unsigned(15 downto 0)   -- The result.
  );
end gcd;