# NVDLA Core Modules RTL Implementation Plan

> **For agentic workers:** Use wolley-executing-hw to execute this plan task-by-task.

**Goal:** Re-implement all NVDLA core modules from SystemC/C reference models to verified RTL

**Project Scope:**
| Module | RTL Files | C Reference | Estimated Complexity |
|--------|-----------|-------------|---------------------|
| BDMA | 7 files, ~10K lines | cmod/bdma/ | Medium |
| CDMA | ~105K lines | cmod/cdma/ | Very High |
| CSC | ~105K lines | cmod/csc/ | Very High |
| CDP | ~65K lines | cmod/cdp/ | High |
| SDP | ~262K lines | cmod/sdp/ | Very High |
| PDP | ~43K lines | cmod/pdp/ | High |
| CMAC | ~68K lines | cmod/cmac/ | High |
| CACC | ~31K lines | cmod/cacc/ | High |
| **Total** | **~687K lines** | 8 modules | Team-months effort |

**Input:**
- C references: `cmod/*/NV_NVDLA_*.cpp`, `cmod/*/gen/*.cpp`
- Existing RTL: `vmod/nvdla/*/` (for reference only, will be replaced)

**Architecture Overview:**

```
NVDLA Top
├── BDMA (Block Data Memory Access)
│   ├── CSB interface
│   ├── MCIF/CVIF interface
│   ├── Load engine
│   ├── Store engine
│   └── Register file
├── CDMA (Convolution Data Memory Access)
│   ├── Image mode
│   ├── Winograd mode
│   ├── Mean shift
│   └── Register file
├── CSC (Convolution Sequence Controller)
│   ├── Input channel engine
│   ├── Output channel engine
│   ├── Weight compressor
│   └── Register file
├── CDP (Convolution Data Processor)
│   ├── Input format converter (ICVT)
│   ├── Output format converter (OCVT)
│   ├── Squeeze module
│   └── Register file
├── SDP (Second Data Processor)
│   ├── X1 ALU + MUL
│   ├── X2 ALU + MUL
│   ├── Y ALU + MUL + LUT
│   └── Register file
├── PDP (Pooling Data Processor)
│   ├── RDMA (Read DMA)
│   ├── WDMA (Write DMA)
│   ├── Pooling core
│   └── Register file
├── CMAC (Convolution MAC)
│   ├── MAC array
│   ├── Configuration registers
│   └── Output buffers
└── CACC (Convolution Accumulator)
    ├── Calculator
    ├── Assembly buffer
    ├── Delivery buffer
    └── Register file
```

---

## Task 1: BDMA RTL Re-implementation

**C Reference:**
- `cmod/bdma/NV_NVDLA_bdma.cpp` (192 lines)
- `cmod/bdma/NV_NVDLA_bdma.h` (header)
- `cmod/bdma/gen/bdma_reg_model.cpp` (158 lines)
- Sub-module: `cmod/bdma/BdmaCore.h`, `cmod/bdma/BdmaCore.cpp`

**RTL Output:** `vmod/nvdla/bdma/NV_NVDLA_bdma.v` (replace existing)

**Sub-tasks:**
- [ ] **Task 1.1:** BDMA CSB interface
- [ ] **Task 1.2:** BDMA register file
- [ ] **Task 1.3:** BDMA load engine
- [ ] **Task 1.4:** BDMA store engine
- [ ] **Task 1.5:** BDMA MCIF/CVIF interface
- [ ] **Task 1.6:** BDMA integration and handshaking

---

## Task 2: CDMA RTL Re-implementation

**C Reference:**
- `cmod/cdma/NV_NVDLA_cdma.cpp`
- `cmod/cdma/gen/cdma_reg_model.cpp` (265 lines)
- `cmod/hls/cdma_libs/cdma_cvt.cpp`

**RTL Output:** `vmod/nvdla/cdma/NV_NVDLA_cdma.v` (replace existing)

**Sub-tasks:**
- [ ] **Task 2.1:** CDMA CSB interface
- [ ] **Task 2.2:** CDMA register file
- [ ] **Task 2.3:** CDMA image mode engine
- [ ] **Task 2.4:** CDMA winograd engine
- [ ] **Task 2.5:** CDMA mean shift
- [ ] **Task 2.6:** CDMA MCIF/CVIF interface

---

## Task 3: CSC RTL Re-implementation

**C Reference:**
- `cmod/csc/NV_NVDLA_csc.cpp`
- `cmod/csc/gen/csc_reg_model.cpp` (208 lines)
- `cmod/hls/csc_libs/csc_cvt.cpp`

**RTL Output:** `vmod/nvdla/csc/NV_NVDLA_csc.v` (replace existing)

**Sub-tasks:**
- [ ] **Task 3.1:** CSC CSB interface
- [ ] **Task 3.2:** CSC register file
- [ ] **Task 3.3:** CSC input channel engine
- [ ] **Task 3.4:** CSC output channel engine
- [ ] **Task 3.5:** CSC weight compressor
- [ ] **Task 3.6:** CSC data path integration

---

## Task 4: CDP RTL Re-implementation

**C Reference:**
- `cmod/cdp/NV_NVDLA_cdp.cpp`
- `cmod/cdp/gen/cdp_reg_model.cpp` (262 lines)
- `cmod/cdp/gen/cdp_rdma_reg_model.cpp` (185 lines)
- `cmod/hls/cdp_libs/cdp_icvt.cpp`, `cdp_ocvt.cpp`, `cdp_sq.cpp`

**RTL Output:** `vmod/nvdla/cdp/NV_NVDLA_cdp.v` (replace existing)

**Sub-tasks:**
- [ ] **Task 4.1:** CDP CSB interface
- [ ] **Task 4.2:** CDP register file
- [ ] **Task 4.3:** CDP input format converter (ICVT)
- [ ] **Task 4.4:** CDP output format converter (OCVT)
- [ ] **Task 4.5:** CDP squeeze module
- [ ] **Task 4.6:** CDP integration

---

## Task 5: SDP RTL Re-implementation

**C Reference:**
- `cmod/sdp/NV_NVDLA_sdp.cpp` (2247 lines)
- `cmod/sdp/gen/sdp_reg_model.cpp` (305 lines)
- `cmod/sdp/gen/sdp_rdma_reg_model.cpp` (223 lines)
- `cmod/hls/sdp/sdp_x.cpp`, `sdp_y.cpp`, `sdp_y_core.cpp`, `sdp_y_inp.cpp`, `sdp_y_lut.cpp`, `sdp_y_idx.cpp`, `sdp_y_cvt.cpp`

**RTL Output:** `vmod/nvdla/sdp/NV_NVDLA_sdp.v` (replace existing)

**Sub-tasks:**
- [ ] **Task 5.1:** SDP CSB interface
- [ ] **Task 5.2:** SDP register file
- [ ] **Task 5.3:** SDP X1 ALU + MUL
- [ ] **Task 5.4:** SDP X2 ALU + MUL
- [ ] **Task 5.5:** SDP Y ALU + MUL
- [ ] **Task 5.6:** SDP Y LUT
- [ ] **Task 5.7:** SDP integration

---

## Task 6: PDP RTL Re-implementation

**C Reference:**
- `cmod/pdp/NV_NVDLA_pdp.cpp`
- `cmod/pdp/gen/pdp_reg_model.cpp` (220 lines)
- `cmod/pdp/gen/pdp_rdma_reg_model.cpp` (191 lines)
- `cmod/hls_wrapper/pdp_hls_wrapper.cpp`

**RTL Output:** `vmod/nvdla/pdp/NV_NVDLA_pdp.v` (replace existing)

**Sub-tasks:**
- [ ] **Task 6.1:** PDP CSB interface
- [ ] **Task 6.2:** PDP register file
- [ ] **Task 6.3:** PDP RDMA
- [ ] **Task 6.4:** PDP WDMA
- [ ] **Task 6.5:** PDP pooling core (cal1d, cal2d)
- [ ] **Task 6.6:** PDP integration

---

## Task 7: CMAC RTL Re-implementation

**C Reference:**
- `cmod/cmac/NV_NVDLA_cmac.cpp`
- `cmod/cmac/gen/cmac_a_reg_model.cpp` (173 lines)

**RTL Output:** `vmod/nvdla/cmac/NV_NVDLA_cmac.v` (replace existing)

**Sub-tasks:**
- [ ] **Task 7.1:** CMAC CSB interface
- [ ] **Task 7.2:** CMAC register file
- [ ] **Task 7.3:** CMAC MAC array
- [ ] **Task 7.4:** CMAC configuration logic
- [ ] **Task 7.5:** CMAC integration

---

## Task 8: CACC RTL Re-implementation

**C Reference:**
- `cmod/cacc/NV_NVDLA_cacc.cpp`
- `cmod/cacc/gen/cacc_reg_model.cpp` (193 lines)

**RTL Output:** `vmod/nvdla/cacc/NV_NVDLA_cacc.v` (replace existing)

**Sub-tasks:**
- [ ] **Task 8.1:** CACC CSB interface
- [ ] **Task 8.2:** CACC register file
- [ ] **Task 8.3:** CACC calculator
- [ ] **Task 8.4:** CACC assembly buffer
- [ ] **Task 8.5:** CACC delivery buffer
- [ ] **Task 8.6:** CACC integration

---

## Tech Stack

- RTL: Verilog/SystemVerilog (per wolley-rtl-coding-style)
- Lint: `verilator --lint-only` via Docker
- Verification: DPI-C co-simulation against C reference

## Verification Strategy

For each module:
1. Create DPI-C wrapper for C reference
2. Create testbench with random test vectors
3. Run DPI simulation
4. 100% match required

## Implementation Order

Given the dependencies:
1. BDMA first (simplest, ~10K lines)
2. CMAC/CACC (moderate complexity)
3. CSC, CDP, PDP (high complexity)
4. SDP (highest complexity, ~262K lines)
5. CDMA (second highest, ~105K lines)

## Notes

- SystemC TLM models use dynamic processes, SC_THREADs, FIFOs
- RTL must use handshake-based pipeline, not TLM
- MCIF/CVIF interfaces use AXI-like protocol
- CSB is a private 32-bit bus protocol