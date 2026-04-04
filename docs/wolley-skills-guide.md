# Wolley Hardware Skills Guide

## NVDLA C-to-Verilog 轉換專案

本專案使用 Wolley hardware 技能系統將 NVDLA 的 C/C++ 程式碼轉換為 Verilog，並與現有 Verilog 比對驗證。

---

## 技能總覽

| 技能 | 用途 | 何时调用 |
|------|------|----------|
| **wolley-brainstorming-hw** | 硬體需求分析、架構設計 | 專案開始、架構不明確 |
| **wolley-writing-plans-hw** | 制定 RTL 實作計劃 | brainstorming 完成後 |
| **wolley-executing-hw** | 執行 RTL 實作計劃 | plan 完成後 |
| **wolley-verification-hw** | DPI 驗證 RTL vs C | execution 完成後 |
| **wolley-systematic-debugging-hw** | 排查 X/Z 值問題 | verification 失敗時 |
| **wolley-rtl-coding-style** | RTL 編碼標準準則 | 寫 RTL 前必讀 |
| **wolley-drawing-hw** | 產生架構/資料流圖表 | brainstorming/planning 時 |
| **wolley-test-driven-development-hw** | C→RTL→DPI TDD 循環 | 有 C model 可用時 |

---

## 專案階段流程

```
┌─────────────────┐
│  BRAINSTORMING │  ← wolley-brainstorming-hw
│   需求分析      │
└────────┬────────┘
         ▼
┌─────────────────┐
│    PLANNING     │  ← wolley-writing-plans-hw
│   制定計劃      │
└────────┬────────┘
         ▼
┌─────────────────┐
│   EXECUTION     │  ← wolley-executing-hw
│   實作 RTL      │
└────────┬────────┘
         ▼
┌─────────────────┐
│  VERIFICATION   │  ← wolley-verification-hw
│   DPI 驗證      │
└────────┬────────┘
         ▼
    ┌────────┐
    │ COMPLETE │  或 ▼
    └────────┘
               ┌─────────────────┐
               │    DEBUGGING    │  ← wolley-systematic-debugging-hw
               │   排查問題      │
               └────────┬────────┘
                       ▼
               回到 VERIFICATION
```

---

## Phase State 管理

每個專案需要在 `docs/superpowers/plans/<project>/.phase-state.json` 追蹤狀態：

```json
{
  "project": "nvdla-c-to-verilog",
  "current_phase": "brainstorming",
  "phases": {
    "brainstorming": "in_progress",
    "planning": "pending",
    "execution": "pending",
    "verification": "pending",
    "debug": "pending"
  },
  "artifacts": {
    "spec": null,
    "c_reference": null,
    "rtl": null,
    "dpi_report": null
  }
}
```

---

## 核心規則

### 1. C 是 Specification
RTL 必須匹配 C，不是 C 匹配 RTL。

### 2. DPI 是最低標準
Lint 通過不代表正確。DPI-C co-simulation 才是驗證標準。

### 3. 100% Match 必要
任何 mismatch 都代表有問題。

### 4. Plan 是合約
執行時嚴格按照 plan，偏差需重新 planning。

### 5. RTL Coding Style 是強制性
寫任何 RTL 前必須閱讀 `wolley-rtl-coding-style`。

---

## NVDLA 模組清單

### 待轉換模組 (cmod/)

| 模組 | C 檔案 | 現有 V 檔案 |
|------|--------|-------------|
| **BDMA** | `cmod/bdma/*.cpp` | `vmod/nvdla/bdma/*.v` |
| **CACC** | `cmod/cacc/*.cpp` | `vmod/nvdla/cacc/*.v` |
| **CBUF** | `cmod/cbuf/*.cpp` | `vmod/nvdla/cbuf/*.v` |
| **CDMA** | `cmod/cdma/*.cpp` | `vmod/nvdla/cdma/*.v` |
| **CDP** | `cmod/cdp/*.cpp` | `vmod/nvdla/cdp/*.v` |
| **CMAC** | `cmod/cmac/*.cpp` | `vmod/nvdla/cmac/*.v` |
| **CSC** | `cmod/csc/*.cpp` | `vmod/nvdla/csc/*.v` |
| **CVIF** | `cmod/cvif/*.cpp` | `vmod/nvdla/cvif/*.v` |
| **GLB** | `cmod/glb/*.cpp` | `vmod/nvdla/glb/*.v` |
| **HLS VLIBS** | `cmod/hls/vlibs/*.cpp` | `vmod/nvdla/*/fp_*.v` |
| **MCIF** | `cmod/mcif/*.cpp` | `vmod/nvdla/mcif/*.v` |
| **PDP** | `cmod/pdp/*.cpp` | `vmod/nvdla/pdp/*.v` |
| **RUBIK** | `cmod/rubik/*.cpp` | `vmod/nvdla/rubik/*.v` |
| **SDP** | `cmod/sdp/*.cpp` | `vmod/nvdla/sdp/*.v` |
| **CSB_MASTER** | `cmod/csb_master/*.cpp` | `vmod/nvdla/csb_master/*.v` |
| **NVDLA_TOP** | `cmod/nvdla_top/*.cpp` | `vmod/nvdla/nvdla.v` |

### HLS VLIBS (優先處理)

這些是基礎浮點運算單元，其他模組依賴它們：

```
cmod/hls/vlibs/
├── fp16_add.cpp      → 現有: vmod/nvdla/pdp/fp16_4add.v
├── fp16_sub.cpp
├── fp16_mul.cpp
├── fp16_max.cpp
├── fp16_min.cpp
├── fp16_to_fp32.cpp
├── fp16_to_fp17.cpp
├── fp17_add.cpp
├── fp17_sub.cpp
├── fp17_mul.cpp
├── fp17_max.cpp
├── fp17_min.cpp
├── fp17_to_fp16.cpp
├── fp17_to_fp32.cpp
├── fp32_add.cpp
├── fp32_mul.cpp
├── fp32_sub.cpp
├── fp32_to_fp16.cpp
├── fp32_to_fp17.cpp
├── uint16_to_fp17.cpp
├── fp16_to_fp32.cpp
├── int17_to_fp16.cpp  (在 vlibs.h 中宣告但無獨立檔案)
└── vlibs.h            (header，含型別定義)
```

---

## 快速開始

### Step 1: 開始 Brainstorming

```
@wolley-brainstorming-hw
```

指定要轉換的模組，例如：
- 「我要先轉換 HLS VLIBS 的 fp16_add」

### Step 2: 制定 Plan

brainstorming 完成後自動過渡到：

```
@wolley-writing-plans-hw
```

### Step 3: 執行

plan 審查通過後：

```
@wolley-executing-hw
```

### Step 4: 驗證

execution 完成後：

```
@wolley-verification-hw
```

---

## 單一模組轉換範例 (fp16_add)

### C 參考 (fp16_add.cpp)
```cpp
void HLS_fp16_add (
     ac_channel<vFp16Type>  & chn_a
    ,ac_channel<vFp16Type>  & chn_b
    ,ac_channel<vFp16Type>  & chn_o
    )
{
    vFp16Type  a = chn_a.read();
    vFp16Type  b = chn_b.read();
    vFp16Type o = FpAdd<vFp16ExpoSize,vFp16MantSize>(a,b);
    chn_o.write(o);
}
```

### 型別定義 (vlibs.h)
- `vFp16Type` = ACINTT(16) = 16-bit integer (IEEE 754 half-precision)
- `vFp16ExpoSize` = 5 (exponent bits)
- `vFp16MantSize` = 10 (mantissa bits)

### 現有 Verilog 參考
- `vmod/nvdla/pdp/fp16_4add.v`
- `vmod/nvdla/pdp/NV_NVDLA_PDP_CORE_cal1d.v`
- `vmod/nvdla/pdp/NV_NVDLA_PDP_CORE_cal2d.v`

### RTL 需求
- 輸入: a[15:0], b[15:0] (IEEE 754 half-precision)
- 輸出: o[15:0]
- 功能: IEEE 754 half-precision addition
- 協定: valid/ready handshaking (如需 pipeline)

### 驗證方法
- DPI-C co-simulation
- 比對 C model 和 RTL 輸出 100% match

---

## RTL Coding Style 快速參考

### 必讀規則
- One module per file
- Explicit signal width: `8'd0` not `8'b0`
- CDC: async signals 需 2-FF synchronizer
- Combinational logic 需完整 else/default
- Wire 在 assign 前宣告

### 模板

```verilog
// +FHDR------------------------------------------------------------
//                 Copyright (c) [YEAR] Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : [filename.v]
// Author        : [Author Name]
// Created On    : [YYYY/MM/DD]
// -----------------------------------------------------------------
// Description: [Brief description]
// +FHDR------------------------------------------------------------

module module_name (
    input  logic        clk,
    input  logic        rst_n,
    // ... signals
);

    // State encoding
    parameter [2:0] ST_IDLE    = 3'd0;
    parameter [2:0] ST_WORKING = 3'd1;

    // Registers with sync reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state_q <= ST_IDLE;
        else
            state_q <= next_state;
    end

    // Combinational logic
    always @* begin
        next_state = state_q;
        case (state_q)
            ST_IDLE:    if (start) next_state = ST_WORKING;
            ST_WORKING: if (done)  next_state = ST_IDLE;
            default:    next_state = ST_IDLE;
        endcase
    end

endmodule
```

---

## 疑難排解

| 問題 | 解決方案 |
|------|----------|
| DPI mismatch | @wolley-systematic-debugging-hw |
| X/Z 值出現 | @wolley-systematic-debugging-hw |
| Timing violation | 優化 C 或增加 pipeline |
| Lint 失敗 | 檢查 coding style |
| Architecture 問題 | 回到 @wolley-brainstorming-hw |

---

## 文件位置

| 文件 | 路徑 |
|------|------|
| Spec 文件 | `docs/superpowers/specs/YYYY-MM-DD-<project>-design.md` |
| Plan 文件 | `docs/superpowers/plans/YYYY-MM-DD-<project>-plan.md` |
| Phase State | `docs/superpowers/plans/<project>/.phase-state.json` |
| Wolley Skills | `C:\Users\jkjki\.claude\skills\wolley-*` |

---

## 調用技能清單 (依序)

1. **`@wolley-brainstorming-hw`** - 需求分析、硬體約束確認 (clock, bit-width, target)
2. **`@wolley-writing-plans-hw`** - 基於 spec 制定 RTL 實作計劃
3. **`@wolley-executing-hw`** - 執行計劃，每個 task 需通過 spec compliance + code quality review
4. **`@wolley-verification-hw`** - 系統級 DPI-C co-simulation
5. **`@wolley-systematic-debugging-hw`** - 如驗證失敗，排查 root cause
6. **`@wolley-rtl-coding-style`** - 寫 RTL 前必讀，強制編碼標準
7. **`@wolley-drawing-hw`** - 產生架構/資料流/狀態機圖表
8. **`@wolley-test-driven-development-hw`** - C→RTL→DPI 循環方法論
