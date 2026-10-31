from math import gcd
import random

N_OPS = 10000
MIN_VAL, MAX_VAL = 1, 32767  # 15-bit signed range

a_ops = []
b_ops = []
c_results = []

for _ in range(N_OPS):
    a = random.randint(MIN_VAL, MAX_VAL)
    b = random.randint(MIN_VAL, MAX_VAL)
    a_ops.append(a)
    b_ops.append(b)
    c_results.append(gcd(a, b))

a_str = ", ".join(str(a) for a in a_ops)
b_str = ", ".join(str(b) for b in b_ops)
c_str = ", ".join(str(c) for c in c_results)

output = f"""\tconstant N_OPS : natural := {N_OPS};

\ttype t_ops is array (0 to N_OPS-1) of natural;
\t-- Change numbers here if you what to run different tests
\tvariable a_ops     : t_ops := ({a_str});
\tvariable b_ops     : t_ops := ({b_str});
\tvariable c_results : t_ops := ({c_str});"""

with open("test.txt", "w") as f:
    f.write(output)
