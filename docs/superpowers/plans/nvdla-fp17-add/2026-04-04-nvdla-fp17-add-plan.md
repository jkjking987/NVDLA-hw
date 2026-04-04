# NVDLA fp17_add RTL Implementation Plan

## Goal

Generate verified RTL from C reference model `FpAdd<6,10>` in `nvdla_float.h`, targeting comparison with existing `vmod/vlibs/HLS_fp17_add.v`.

## Input

- **C reference**: `cmod/hls/include/nvdla_float.h`
  - Main function: `FpAdd<6,10>` (lines 974-1139)
  - Helper functions used:
    - `FpSignedBitsToFloat<6,10>` (lines 116-129) - unpacks 17-bit to sign/expo/mantissa
    - `IsZero<6,10>` (lines 62-65)
    - `IsNaN<6,10>` (lines 36-39)
    - `IsInf<6,10>` (lines 41-44)
    - `SetToInf<6,10>` (lines 92-100)
    - `SetToZero<6,10>` (lines 67-72)
    - `FpNormalize<6,13>` (lines 947-966) - normalize internal 13-bit mantissa
    - `FpMantRNE<13,11>` (lines 219-281) - RNE rounding
    - `FpFloatToSignedBits<6,10>` (lines 193-212) - packs to 17-bit
- **Spec**: `docs/superpowers/specs/2026-04-04-nvdla-fp17-add-design.md`

## Architecture

### C to RTL Mapping

```
C FpAdd<6,10>                    RTL fp17_add (3-stage pipeline)
─────────────────────────────────────────────────────────────────
Stage 1:
  FpSignedBitsToFloat(a)   →  Unpack A: sign_a, expo_a, mant_a
  FpSignedBitsToFloat(b)   →  Unpack B: sign_b, expo_b, mant_b
  Add implied 1 to mantissas

Stage 2:
  Compare exponents         →  Align: shift smaller mantissa right
  is_addition = (a_sign == b_sign)
  Add/sub mantissas        →  Internal mantissa addition

Stage 3:
  Handle overflow          →  Normalize: shift, increment expo
  FpNormalize              →  RNE rounding (FpMantRNE)
  Handle NaN/Inf/Zero      →  Special case handling
  FpFloatToSignedBits      →  Pack to 17-bit output
```

### Bit-Widths (for ExpoWidth=6, MantWidth=10)

| Signal | Width | Description |
|--------|-------|-------------|
| Input | 17 | fp17: 1 sign + 6 expo + 10 mantissa |
| mant_p1 | 11 | mantissa + implied 1 |
| InternalMantWidth | 13 | kMantMoreWidth(12) + MantWidth(10) + 1 |
| int_mant_p1 | 14 | InternalMantType + 1 for overflow check |
| o_mant_p1 | 11 | rounded mantissa |
| Output | 17 | packed fp17 |

## Tech Stack

- RTL: Verilog (per wolley-rtl-coding-style)
- Lint: `verilator --lint-only`
- Verification: DPI-C co-simulation

## Task

### Task 1: Generate fp17_add RTL

**RTL Output**: `vmod/vlibs/fp17_add.v`

**C Reference**: `cmod/hls/include/nvdla_float.h` lines 974-1139 (`FpAdd<6,10>`)

**Verification**:
- Lint: `verilator --lint-only vmod/vlibs/fp17_add.v`
- DPI-C co-simulation against `FpAdd<6,10>`

**Checklist before marking complete**:
- [ ] Protocol matches spec (valid/ready handshaking)?
- [ ] Bit-width correct (17-bit input/output, internal widths per C)?
- [ ] Coding style followed (per RTL_Coding_Style.md)?
- [ ] C logic preserved (same algorithm, same bit-widths)?
- [ ] DPI passes (100% match)?

**Steps**:
- [ ] **Step 1**: Read RTL coding style: `skills/wolley-rtl-coding-style/SKILL.md`
- [ ] **Step 2**: Generate stage 1 - input handshake and unpack logic
- [ ] **Step 3**: Generate stage 2 - exponent compare, align, add
- [ ] **Step 4**: Generate stage 3 - normalize, round, pack, special cases
- [ ] **Step 5**: Add handshaking control logic
- [ ] **Step 6**: Run lint: `verilator --lint-only vmod/vlibs/fp17_add.v`
- [ ] **Step 7**: Write DPI wrapper and run verification
- [ ] **Step 8**: Commit RTL

## Verification Details

### DPI Interface

```c
// C DPI export
void fp17_add_ref(
    uint16_t a,      // 17-bit in lower bits
    uint16_t b,      // 17-bit in lower bits
    uint16_t *out
);
```

### Test Cases

1. Random fp17 pairs (1000 vectors)
2. Edge cases:
   - +0 + +0
   - -0 + -0
   - +0 + -0
   - Max + Max
   - Min + Min
   - Inf + Inf
   - -Inf + +Inf
   - NaN + any
   - any + NaN
   - Denorm + denorm

### Comparison

- Compare RTL output vs C output for each test vector
- 100% match required
- Mismatch = verification failure

## File Outputs

| File | Description |
|------|-------------|
| `vmod/vlibs/fp17_add.v` | Generated RTL |
| `verif/fp17_add_dpi.c` | DPI-C reference wrapper |
| `verif/fp17_add_tb.v` | Testbench |
| `verif/fp17_add_results.txt` | Verification results |
