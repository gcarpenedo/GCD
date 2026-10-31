# VHDL GCD Hardware Core

A modular VHDL implementation of Euclid's algorithm computing the Greatest Common Divisor (GCD) of two 16-bit unsigned integers. The core operates as a Synchronous Locally Timed (SLT) block using a 4-phase fully interlocked `req`/`ack` handshake protocol across two consecutive operand transfers ($A$ then $B$) and presents the valid result on output $C$.

Targeted, synthesized, and verified on the **Digilent Nexys A7-100T / Nexys 4 DDR (Xilinx Artix-7)** FPGA platform.

---

## Architectural Variants & Synthesis Results

All architectures share the common interface in [`task2/gcd_entity.vhd`](task2/gcd_entity.vhd) and are swappable in [`task2/gcd_top.vhd`](task2/gcd_top.vhd). Results from Xilinx Vivado synthesis and simulation over 10,000 random vectors (20 ns clock):

| Architecture | Description | LUTs | FFs | Cycles / GCD | Sim Time |
|:---|:---|:---:|:---:|:---:|:---:|
| `fsmd` ([`task2/gcd.vhd`](task2/gcd.vhd)) | Baseline 10-state FSMD, 17-bit ALU, 2 subtractors | 69 | 36 | $3k+2$ | 47.72 ms |
| `fsmd_resource_optimized` ([`task3/`](task3/)) | Single shared subtractor with operand swapping (-23% area) | **53** | 36 | $3k+2$ | 47.72 ms |
| `fsmd_time_optimized` ([`task3/`](task3/)) | Dual parallel subtractors, 2-state loop (-28.9% latency) | 75 | **35** | **$2k+2$** | **33.95 ms** |
| `fsmd_res_time_optimized` ([`task3/`](task3/)) | Single subtractor + 1-bit registered sign across cycles | 66 | 36 | **$2k+2$** | **33.95 ms** |
| `structural` ([`task4/`](task4/)) | Structural netlist using generic primitives (`reg`, `mux`, `alu`, `buf`) | 67 | 36 | $3k+2$ | 47.72 ms |

*($k$ is the number of subtraction iterations).*

---

## How to Run

### Simulation
The testbench [`task2/gcd_tb.vhd`](task2/gcd_tb.vhd) runs a self-checking test suite of 10,000 randomized test pairs.

1. **Select Architecture:** In [`task2/gcd_top.vhd`](task2/gcd_top.vhd#L62), specify the desired architecture in the entity instantiation:
   ```vhdl
   u2 : entity work.gcd(fsmd); -- Or fsmd_resource_optimized, fsmd_time_optimized, fsmd_res_time_optimized, structural
   ```
2. **Compile & Simulate:** Compile the common files (`gcd_entity.vhd`, `debounce.vhd`, `gcd_top.vhd`, `gcd_tb.vhd`) and the selected `gcd` architecture file.
3. *(Optional)* Regenerate test vectors: `python3 test/test_generator.py` (outputs to `test.txt`).

### FPGA Deployment (Nexys A7 / Nexys 4 DDR)
- **Top Entity & Constraints:** `gcd_top` with [`task2/Nexys4DDR_gcd.xdc`](task2/Nexys4DDR_gcd.xdc).
- **I/O Mapping:** `BTNU` = Reset, `BTNR` = `req`, `SW[15:0]` = Input `AB`, `LED[15:0]` = Result `C`, `LED16_B` (Blue LED) = `ack`.

**Operation:**
1. Set operand $A$ on `SW[15:0]`, press and release `BTNR` (blue `ack` LED pulses when stored).
2. Set operand $B$ on `SW[15:0]`, press `BTNR`.
3. The GCD result is displayed on `LED[15:0]` while `ack` is held high. Release `BTNR` to return to ready.

---

## Documentation
- [docs/assignment_1.pdf](docs/assignment_1.pdf) — Project specification
- [docs/main.tex](docs/main.tex) — Technical report

---

## Authors
Technical University of Denmark (DTU):
- **Giovanni Carpenedo**
- **Francesco Danese**
- **Bertram Fink-Jakobsen**
- **Filippo Battisti**
- **Alessandro Porcheddu**