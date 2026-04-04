# Wolley Skills Quick Reference

## 技能觸發關鍵字

| 輸入 | 技能 |
|------|------|
| `開始 brainstorming`、`需求`、`架構不明確` | @wolley-brainstorming-hw |
| `制定計劃`、`planning` | @wolley-writing-plans-hw |
| `執行`、`implement`、`RTL`、`開始實作` | @wolley-executing-hw |
| `驗證`、`verify`、`DPI`、`比對` | @wolley-verification-hw |
| `debug`、`X`、`Z`、` mismatch`、`錯誤` | @wolley-systematic-debugging-hw |
| `coding style`、`RTL 規範` | @wolley-rtl-coding-style |
| `畫圖`、`diagram`、`架構圖` | @wolley-drawing-hw |
| `TDD`、`C→RTL→DPI` | @wolley-test-driven-development-hw |

---

## Phase 轉換流程

```
brainstorming → planning → execution → verification
                                    ↘ debug ↗
```

---

## RTL Coding Style 核心規則

### Do ✅
```verilog
// Good: explicit width
wire [7:0] data;
assign data = 8'd0;

// Good: complete else
always @* begin
    if (!rst_n) out = '0;
    else if (en) out = in;
    else out = out;
end

// Good: CDC 2-FF synchronizer
reg sync1, sync2;
always @(posedge clk) sync1 <= async_in;
always @(posedge clk) sync2 <= sync1;

// Good: separate always blocks
always @(posedge clk) state <= next;
always @* case (state) ... endcase
```

### Don't ❌
```verilog
// Bad: implicit width
wire data;
assign data = 1'b0;

// Bad: missing else (latch inferred)
always @* begin
    if (!rst_n) out = '0;
    else if (en) out = in;
end

// Bad: all in one block
always @* begin ... end
always @(posedge clk) begin ... end
```

---

## DPI 驗證流程

```
1. C reference model (golden)
         ↓
2. Generate RTL from C
         ↓
3. Compile C with DPI + RTL with verilator
         ↓
4. Run co-simulation
         ↓
5. 100% match? → COMPLETE
   Mismatch? → DEBUG
```

---

## Debug Backtrack 方法

```
Erroneous signal 發現 X/Z/錯誤值
        ↓
Record cycle number 記錄錯誤時鐘週期
        ↓
Sequential? → Check FF input at n-1
        ↓
Combinational? → Check driver signals
        ↓
Correlate to C model → RTL vs C 在哪個 cycle 開始不同
        ↓
Identify root cause → 不是症狀，是根本原因
        ↓
Fix root cause
```

---

## 常見失敗層級

| Level | 類型 | 徵兆 | 解決 |
|-------|------|------|------|
| 1 | RTL Syntax | DPI 編譯失敗 | 檢查 RTL |
| 2 | DPI Mismatch | C 和 RTL 輸出不一致 | 檢查 C 或 RTL |
| 3 | Timing Violation | STA 負 slack | 優化或加 pipeline |
| 4 | Architecture | 多個 Level 3 失敗 | 回到 brainstorming |

---

## 必問硬體問題

1. Clock domain? (single/multi)
2. Bit-width? (精確位寬)
3. Target frequency?
4. 協定? (AXI/AXI-stream/APB/standalone)
5. Pipeline depth?
6. C reference model?

---

## C→RTL 映射檢查清單

- [ ] Protocol 匹配 spec
- [ ] Bit-width 與 C 一致
- [ ] C logic 完整保留
- [ ] Coding style 遵守
- [ ] `verilator --lint-only` 通過
- [ ] DPI 100% match

---

## 命令速查

```bash
# Lint
verilator --lint-only <file.v>

# DPI 編譯 (範例)
verilator -cc --exe --dpi dpi_wrapper.cpp rtl.v

# Git commit template
git commit -m "[TASK-N] <desc>: protocol=[spec], bitwidth=[checked], style=[rtl_coding_style]"
```

---

## 文件路徑

```
docs/superpowers/
├── specs/
│   └── YYYY-MM-DD-<project>-design.md      # Spec
├── plans/
│   └── <project>/
│       ├── YYYY-MM-DD-<project>-plan.md    # Plan
│       └── .phase-state.json               # State
```

---

## Skill 存放位置

```
C:\Users\jkjki\.claude\skills\
├── wolley-rtl-coding-style/
├── wolley-test-driven-development-hw/
├── wolley-verification-hw/
├── wolley-systematic-debugging-hw/
├── wolley-brainstorming-hw/
├── wolley-drawing-hw/
├── wolley-executing-hw/
└── wolley-writing-plans-hw/
```
