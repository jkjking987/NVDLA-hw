# NVDLA C-to-Verilog 轉換框架

## 專案概述

**目標:** 將 NVDLA 的 C/C++ 參考模型轉換為 Verilog RTL，與現有 Verilog 比對驗證

**範圍:**
- C code: `cmod/` (含 hls, 各子模組)
- 現有 V code: `vmod/nvdla/`
- 目標: 產生符合 Wolley coding standard 的新 RTL

---

## 模組優先級

### P0 - 基礎單元 (其他模組依賴)

| 優先 | 模組 | C 檔案 | 說明 |
|------|------|--------|------|
| 1 | **VLIBS (fp*)** | `cmod/hls/vlibs/*.cpp` | 浮點運算單元 |
| 2 | **HLS wrappers** | `cmod/hls_wrapper/*.cpp` | HLS 包裝層 |
| 3 | **REG models** | `cmod/*/gen/*_reg_model.cpp` | 暫存器模型 |

### P1 - 核心運算單元

| 模組 | C 檔案 | 現有 V |
|------|--------|--------|
| BDMA | `cmod/bdma/*.cpp` | `vmod/nvdla/bdma/*.v` |
| CDMA | `cmod/cdma/*.cpp` | `vmod/nvdla/cdma/*.v` |
| CSC | `cmod/csc/*.cpp` | `vmod/nvdla/csc/*.v` |
| CMAC | `cmod/cmac/*.cpp` | `vmod/nvdla/cmac/*.v` |
| CACC | `cmod/cacc/*.cpp` | `vmod/nvdla/cacc/*.v` |
| SDP | `cmod/sdp/*.cpp` | `vmod/nvdla/sdp/*.v` |
| CDP | `cmod/cdp/*.cpp` | `vmod/nvdla/cdp/*.v` |
| PDP | `cmod/pdp/*.cpp` | `vmod/nvdla/pdp/*.v` |

### P2 - 記憶體/介面單元

| 模組 | C 檔案 | 現有 V |
|------|--------|--------|
| CBUF | `cmod/cbuf/*.cpp` | `vmod/nvdla/cbuf/*.v` |
| CVIF | `cmod/cvif/*.cpp` | `vmod/nvdla/cvif/*.v` |
| MCIF | `cmod/mcif/*.cpp` | `vmod/nvdla/mcif/*.v` |
| RUBIK | `cmod/rubik/*.cpp` | `vmod/nvdla/rubik/*.v` |
| GLB | `cmod/glb/*.cpp` | `vmod/nvdla/glb/*.v` |

### P3 - 頂層/系統整合

| 模組 | C 檔案 | 現有 V |
|------|--------|--------|
| CSB_MASTER | `cmod/csb_master/*.cpp` | `vmod/nvdla/csb_master/*.v` |
| NVDLA_TOP | `cmod/nvdla_top/*.cpp` | `vmod/nvdla/nvdla.v` |
| CORE | `cmod/nvdla_core/*.cpp` | `vmod/nvdla/car/*.v` |

---

## VLIBS 詳細分解 (P0)

VLIBS 是基礎中的基礎。建議優先順序：

```
1. fp16_* (半精度浮點)
   ├── fp16_add.cpp
   ├── fp16_sub.cpp
   ├── fp16_mul.cpp
   ├── fp16_max.cpp
   ├── fp16_min.cpp
   ├── fp16_to_fp32.cpp
   └── fp16_to_fp17.cpp

2. fp17_* (擴充半精度)
   ├── fp17_add.cpp
   ├── fp17_sub.cpp
   ├── fp17_mul.cpp
   ├── fp17_max.cpp
   ├── fp17_min.cpp
   ├── fp17_to_fp16.cpp
   └── fp17_to_fp32.cpp

3. fp32_* (單精度浮點)
   ├── fp32_add.cpp
   ├── fp32_sub.cpp
   ├── fp32_mul.cpp
   ├── fp32_to_fp16.cpp
   └── fp32_to_fp17.cpp

4. 格式轉換
   ├── uint16_to_fp17.cpp
   └── int17_to_fp16.cpp (header only)
```

### VLIBS 型別定義

```cpp
// vlibs.h
#define vFp16ExpoSize  5
#define vFp16MantSize  10
#define vFp16Size      16
typedef ACINTT(vFp16Size) vFp16Type;  // IEEE 754 half-precision

#define vFp17ExpoSize  6
#define vFp17MantSize  10
#define vFp17Size      17
typedef ACINTT(vFp17Size) vFp17Type;

#define vFp32ExpoSize  8
#define vFp32MantSize  23
#define vFp32Size      32
typedef ACINTT(vFp32Size) vFp32Type;
```

---

## 轉換工作流程

### Phase 1: Brainstorming (每模組)

```
@wolley-brainstorming-hw

問題清單:
1. Clock domain? (NVDLA typically single clock)
2. Bit-width? (from C type definitions)
3. Target frequency? (check existing V for hints)
4. Protocol? (valid/ready handshaking common in NVDLA)
5. Existing V reference? (compare vs generate)
```

### Phase 2: Planning (每模組)

```
@wolley-writing-plans-hw

Plan 結構:
- C reference location
- RTL output location
- DPI verification plan
- Per-module task breakdown
```

### Phase 3: Execution (per task)

```
@wolley-executing-hw

Each task needs:
1. C reference analysis
2. RTL generation
3. Spec compliance review
4. Code quality review
5. Lint (verilator --lint-only)
6. Auto-commit
```

### Phase 4: Verification (per module group)

```
@wolley-verification-hw

DPI verification:
- Compile C reference with DPI
- Compile RTL with verilator
- Run co-simulation
- 100% match required
```

### Phase 5: Debug (if needed)

```
@wolley-systematic-debugging-hw

Debug approach:
- Find erroneous signal on waveform
- Backtrack through clock cycles
- Correlate to C model
- Fix root cause, not symptom
```

---

## 現有 V 比對策略

NVDLA 已經有 Verilog 實作。轉換目標不是取代，而是：

1. **驗證現有 V**: 用 C model 產生 test vector，驗證現有 V
2. **找出差異**: 如果行為不同，分析是 C 正確還是 V 正確
3. **填空**: 如果某個 C function 沒有對應 V，則生成

### 比對方法

```
C reference (golden)
       ↓
  Test vectors
       ↓
┌──────┴──────┐
↓             ↓
Existing V   New Generated V
       ↓             ↓
    Compare ←─────── Compare
```

---

## 檔案對照表

### cmod/ → vmod/ 對照

| C 目錄 | V 目錄 | 備註 |
|--------|--------|------|
| `cmod/bdma/` | `vmod/nvdla/bdma/` | |
| `cmod/cacc/` | `vmod/nvdla/cacc/` | |
| `cmod/cbuf/` | `vmod/nvdla/cbuf/` | |
| `cmod/cdma/` | `vmod/nvdla/cdma/` | |
| `cmod/cdp/` | `vmod/nvdla/cdp/` | |
| `cmod/cmac/` | `vmod/nvdla/cmac/` | |
| `cmod/csc/` | `vmod/nvdla/csc/` | |
| `cmod/cvif/` | `vmod/nvdla/cvif/` | |
| `cmod/glb/` | `vmod/nvdla/glb/` | |
| `cmod/hls/vlibs/` | `vmod/nvdla/*/fp_*.v` | 多處參照 |
| `cmod/mcif/` | `vmod/nvdla/mcif/` | |
| `cmod/pdp/` | `vmod/nvdla/pdp/` | |
| `cmod/rubik/` | `vmod/nvdla/rubik/` | |
| `cmod/sdp/` | `vmod/nvdla/sdp/` | |
| `cmod/csb_master/` | `vmod/nvdla/csb_master/` | |
| `cmod/nvdla_top/` | `vmod/nvdla/` | 頂層 |

---

## 建議第一個模組

**建議從 `fp16_add` 開始** (最簡單):

1. C 只有一個 function: `FpAdd<vFp16ExpoSize,vFp16MantSize>(a,b)`
2. 現有 V 有參考: `vmod/nvdla/pdp/fp16_4add.v`
3. 輸入輸出都是 16-bit
4. 容易做 DPI 驗證

---

## 預期產出

### 文件
- [ ] `docs/superpowers/specs/nvdla-vlibs-fp16-add-design.md`
- [ ] `docs/superpowers/plans/nvdla-vlibs-fp16-add-plan.md`
- [ ] `docs/superpowers/plans/nvdla-vlibs-fp16-add/.phase-state.json`

### RTL
- [ ] 新 Verilog 檔案 (每個轉換的 module)

### 驗證
- [ ] DPI 驗證報告 (100% match)

---

## 風險與注意事項

1. **C 使用 ACINT (Arbitrary Precision Integer)**: 轉換時需注意具體 bit-width
2. **HLS 特有的 `#pragma`**: 這些是 synthesis hint，轉換時要理解
3. **記憶體模型**: C 中的陣列 vs V 中的 RAM/FIFO 映射
4. **時序**: C 是 functional，V 需要 pipeline/registers
5. **現有 V 已經最佳化**: 可能有不同的 micro-optimization

---

## 啟動建議

要開始這個專案，請說：

```
@wolley-brainstorming-hw

我要開始轉換 fp16_add，先從 VLIBS 開始
```
