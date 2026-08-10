# 16x16 Matrix Multiplication ASIC

> A fixed-point matrix multiply engine whose datapath never stalls for a cycle.

A 16×16 fixed-point matrix multiplier sitting behind an SRAM interface. An external
tester writes both input matrices into on-chip SRAM, pulses start once, and reads the
result back when the engine raises `o_done`. The design extracts **two MACs per cycle**
without adding memory ports, and keeps the multipliers busy for 2,048 of 2,051 cycles
with no pipeline bubbles.

[한국어](README.ko.md)

---

## Background

`O = A × B`, all three matrices 16×16. Inputs are 8-bit two's-complement fixed point
with a fraction length chosen at run time (0–7). The output is 32 bits with the same
fraction length, so the accumulated result has to be truncated by a different amount
on every run.

Only the port list was given; everything inside the module was written from scratch.
Beyond correctness there were two bonus conditions.

| Condition | Points |
|---|---|
| Read AMEM and BMEM every clock so the multipliers **never idle** | +2 |
| Do the above **with a pipeline register between multiply and accumulate** | +5 |

So the target was not "produce the right answer" but "produce the right answer without
ever stalling the datapath".

## System

| | |
|---|---|
| Operation | `O = A × B`, 16×16 by 16×16 |
| Data format | 8-bit two's complement in, 32-bit out, fraction length 0–7 set at run time |
| Memory | three synchronous SRAMs (AMEM, BMEM, OMEM), 16-bit words |
| Arbitration | one status signal (`core_working`) switches ownership between tester and core |
| Pipeline | one SRAM read stage plus one register between multiply and accumulate |
| Size | single module, 294 lines, 129 flip-flops |

```
      external tester                       internal core
            |                                   |
            +-------- core_working = !o_done ---+
            |                                   |
      +-----v-----+   +-----------+   +---------v----------+
      | AMEM/BMEM |-->| 2 multipl |-->| pipe_reg -> accum  |--> OMEM
      +-----------+   +-----------+   +--------------------+
```

## Design

### Two MACs per cycle, for free

The memory map packs two 8-bit values into one 16-bit SRAM word. Reading one word from
each memory yields two operand pairs, so the inner loop runs `k = 0..7` instead of
`0..15`. No extra SRAM ports, no extra reads. The parallelism was already sitting in the
storage format.

```verilog
pipe_reg <= ($signed(amem_dout[15:8]) * $signed(bmem_dout[15:8]))
          + ($signed(amem_dout[7:0])  * $signed(bmem_dout[7:0]));
```

### No bubble between output elements

The common implementation stalls at the end of every element to clear the accumulator
and store the result. Even one idle cycle per element throws away 256 cycles. Instead
three things overlap in the same cycle:

- rather than clearing the accumulator and then adding, the first partial product of the
  new element **overwrites** it
- the destination address was latched a loop early into `addr_o_reg`, so the write target
  survives the counter rolling over first
- in the very cycle the accumulator is overwritten, its pre-overwrite value is written to
  OMEM

### Two-cycle pipeline compensation

The SRAM read costs one cycle and the pipeline register adds another, so the product of
operands requested at k=0 only reaches the accumulator at k=2. Three constants absorb
that skew.

| Constant | Reason |
|---|---|
| assign the accumulator at `cnt_k == 2` | when the new element's first partial product arrives |
| block writes until `loop_cnt >= 1` | suppresses garbage from the warm-up loop |
| finish at `loop_cnt == 256 && cnt_k == 2` | when the 256th element's write actually completes |

Get any one of them wrong and the entire output shifts by one position.

### Arbitration and the read path

A single `core_working = !o_done` switches SRAM ownership between the external tester and
the internal core. Their active windows never overlap, so no handshake is needed. The
tester-side path has a decoder that selects A/B/O from the upper address bits.

The SRAM drives X while inactive, but the specification requires `o_dout` to be 0 when the
interface is unused and the upper 16 bits to be 0 when reading A or B. A two-stage read
that separates request capture from output drive absorbs the read latency while satisfying
both requirements **as a property of the datapath rather than as conditional logic**.

## Repository structure

```
rtl/custom_matmul16x16.sv    the submitted design
provided/                    SRAM model, top-level testbench, test vectors
homework/hw1/                combinational logic exercise + exhaustive testbench
homework/hw2/                fixed/floating point conversion, FSM exercise
```

## Results

| | |
|---|---|
| Function | **256 / 256 golden values match** (fraction length 4) |
| Cycles to `o_done` | **2,051** — 2,048 useful + 3 drain |
| Multiplier utilisation | **99.85 %** |
| Arithmetic resources | two 8×8 multipliers, one 16-bit adder, one 32-bit accumulator, one arithmetic shifter |
| State | 129 flip-flops |
| Code | 294 lines, single module |

A scalar implementation pulling one 8-bit value at a time out of each word would need
4,096 cycles, so folding two MACs into a single read is exactly a 2× gain.

## Build and run

In Vivado, set the design as top, add `provided/` to the simulation set, and drive it with
your own `mm_tester`. Load `amem.hex` and `bmem.hex` through the tester interface, pulse
`i_matmul_en` once, wait for `o_done`, then read OMEM back and compare against
`omem_fl4.hex`.

## Notes

**Not included** — `provided/` is distributed material and must not be modified. The
`mm_tester` instantiated by `tb_mm.sv` is written separately, is not part of the
submission, and is not included here.
