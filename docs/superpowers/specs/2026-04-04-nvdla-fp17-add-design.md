# NVDLA fp17_add C-to-Verilog Design Spec

## Function

IEEE 754 half-precision floating-point adder (fp17: 6-bit exponent, 10-bit mantissa, 17-bit total) with 3-stage pipeline and valid/ready handshaking interface. Converts C reference model `FpAdd<6,10>` in `nvdla_float.h` to RTL.

## Interface

| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| `nvdla_core_clk` | 1 | Input | Core clock |
| `nvdla_core_rstn` | 1 | Input | Active-low reset |
| `chn_a_rsc_z` | 17 | Input | Operand A (fp17) |
| `chn_a_rsc_vz` | 1 | Input | Operand A valid |
| `chn_a_rsc_lz` | 1 | Output | Operand A ready |
| `chn_b_rsc_z` | 17 | Input | Operand B (fp17) |
| `chn_b_rsc_vz` | 1 | Input | Operand B valid |
| `chn_b_rsc_lz` | 1 | Output | Operand B ready |
| `chn_o_rsc_z` | 17 | Output | Result (fp17) |
| `chn_o_rsc_vz` | 1 | Output | Result valid |
| `chn_o_rsc_lz` | 1 | Input | Result ready |

## Timing

- **Clock**: 1GHz (1ns period)
- **Pipeline**: 3-stage (matching existing HLS_fp17_add)
- **Latency**: 3 cycles from input valid to output valid

## Architecture

```
Stage 1: Unpack
  - Extract sign[0], exponent[5:0], mantissa[9:0] from 17-bit input
  - Add implied 1 to mantissa (1.frac format)
  - Register unpacked values

Stage 2: Align & Add
  - Compare exponents, compute shift amount
  - Right-shift smaller mantissa to align
  - Add/sub mantissas based on sign
  - Handle sign for result

Stage 3: Normalize & Pack
  - Handle overflow (shift right, increment exponent)
  - Handle underflow (shift left, decrement exponent)
  - RNE rounding (Round to Nearest Even)
  - Pack sign, exponent, mantissa back to 17-bit
```

### Data Path

```
chn_a ──► [Unpack] ──► [Align] ──► [Add] ──► [Normalize] ──► [Pack] ──► chn_o
     │              │           │         │            │            │
     │              ▼           ▼         │            ▼            │
chn_b ──► [Unpack] ─┴───────────┘         │            │            │
                                           │            ▼            │
                                    [Pipeline Registers]      [Output]
```

### Control

- Valid/ready handshaking on all channels
- Back-pressure when pipeline full (`chn_a_rsc_lz = chn_b_rsc_lz = 0`)
- Output valid when pipeline complete

## Hardware Constraints

| Parameter | Value |
|-----------|-------|
| Clock | 1GHz |
| Data width | 17-bit |
| Exponent width | 6-bit |
| Mantissa width | 10-bit |
| Pipeline depth | 3 stages |
| Interface | valid/ready handshaking |

## C Reference

- **File**: `cmod/hls/include/nvdla_float.h`
- **Function**: `FpAdd<6,10>`
- **Lines**: 974-1139
- **Template parameters**: ExpoWidth=6, MantWidth=10

## Verification

- **Method**: DPI-C co-simulation
- **Golden reference**: `FpAdd<6,10>` in C
- **Test vectors**: Random fp17 pairs + edge cases (NaN, Inf, zero, denorm, max/min)
- **Acceptance**: 100% match between C and RTL
- **Lint**: `verilator --lint-only` must pass

## Comparison Target

- **Existing RTL**: `vmod/nvdla/pdp/fp16_4add.v` (uses HLS_fp17_add internally)
- **Goal**: Generate functionally equivalent RTL from C reference
- **Note**: fp16_4add.v is a 4-wide adder; this spec is for single fp17_add

## Phase State

- `current_phase`: brainstorming → complete
- Next phase: planning
