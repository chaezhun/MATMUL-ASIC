# 16x16 Matrix Multiplication ASIC

A fixed-point matrix multiplication unit that sits behind an SRAM interface.
An external tester writes both operand matrices into on-chip SRAM, pulses a start
signal, and reads the result back when the engine raises `o_done`.

Submitted for the ASIC Design final project, Chung-Ang University (DASH Lab).

[한국어](README.ko.md)

---

## Highlights

| | |
|---|---|
| Throughput | **2 multiply-accumulates per cycle** without extra memory ports |
| Utilisation | **2,048 active cycles out of 2,051** — 99.85%, no pipeline bubbles |
| Accuracy | All **256 golden values** matched |
| Interface | Synchronous SRAM, ownership switched by a single status signal |

## The problem

`O = A x B`, all three 16x16. Inputs are 8-bit two's-complement fixed point with a
fraction length chosen at run time (0 to 7); outputs are 32 bits with the same
fraction length, so the accumulator has to be truncated by a variable amount.

Only the port list was given. Everything inside the module is mine.

The grading had two bonus conditions beyond correctness:

| Condition | Points |
|---|---|
| Read AMEM and BMEM **every clock**, keeping the multipliers busy | +2 |
| Do that **and** put a pipeline register between multiply and accumulate | +5 |

So the target was not "produce the right answer" but "produce it without ever
stalling the datapath".

## Design

**Two MACs per cycle, for free.** The memory map stores two 8-bit values in every
16-bit SRAM word. Reading one word from each memory therefore yields two operand
pairs, so the inner loop runs `k = 0..7` instead of `0..15`. No extra SRAM port,
no extra read — the parallelism was already in the storage format.

```verilog
pipe_reg <= ($signed(amem_dout[15:8]) * $signed(bmem_dout[15:8]))
          + ($signed(amem_dout[7:0])  * $signed(bmem_dout[7:0]));
```

**No bubbles between output elements.** The obvious implementation pauses at the
end of each element to clear the accumulator and store the result — 256 wasted
cycles at one cycle each. Three things happen in the same cycle instead:

- the accumulator is *overwritten* with the new element's first partial product
  rather than cleared first;
- the destination address was captured one loop earlier (`addr_o_reg`), so the
  counters can move on without losing it;
- the previous result is written to OMEM in the very cycle the accumulator is
  overwritten, using the pre-edge value.

**Compensating a two-cycle pipeline.** SRAM read latency is one cycle and the
pipeline register adds another, so the product of the operands requested at k=0
only reaches the accumulator at k=2. Three constants absorb that offset:

| Constant | Why |
|---|---|
| accumulator loads at `cnt_k == 2` | first partial product of the new element arrives |
| write gated by `loop_cnt >= 1` | suppresses garbage during the first warm-up loop |
| finish at `loop_cnt == 256 && cnt_k == 2` | the 256th element's write has actually happened |

Get any one wrong and the whole output shifts by one position.

**Arbitration.** `core_working = !o_done` switches SRAM ownership between the
external tester and the internal core. The two never overlap, so no handshake is
needed. The tester side decodes the upper address bits to select A, B or O.

**Read path.** The SRAM drives X when it is not enabled, and the specification
requires `o_dout` to read zero when the interface is idle and to zero-pad the
upper 16 bits for A and B. A two-stage read (capture the request, then drive the
output) absorbs the read latency and makes both requirements a property of the
datapath rather than a special case.

## Results

| | |
|---|---|
| Functional | **256 / 256 golden outputs match** (fraction length 4) |
| Cycles to `o_done` | **2,051** — 2,048 productive plus 3 drain |
| Multiplier utilisation | **99.85 %** |
| Arithmetic | two 8x8 multipliers, one 16-bit adder, one 32-bit accumulator, one arithmetic shifter |
| State | 129 flip-flops |
| Source | 294 lines, single module |

A scalar implementation reading one operand per word would need 4,096 cycles, so
folding two MACs into each read is a straight 2x.

## Repository structure

```
rtl/custom_matmul16x16.sv    the submitted design
provided/                    SRAM models, top-level testbench, test vectors
homework/hw1/                combinational logic exercises + exhaustive testbenches
homework/hw2/                fixed/floating point conversion, FSM exercises
```

`provided/` came with the assignment and may not be modified. `tb_mm.sv`
instantiates an `mm_tester` module that students write themselves; it is not part
of the submission and is not included here.

## Build and run

Set the design as top in Vivado, add `provided/` to the simulation set, and drive
it from your own `mm_tester`: load `amem.hex` and `bmem.hex` over the tester
interface, pulse `i_matmul_en`, wait for `o_done`, then read OMEM back and compare
against `omem_fl4.hex`.
