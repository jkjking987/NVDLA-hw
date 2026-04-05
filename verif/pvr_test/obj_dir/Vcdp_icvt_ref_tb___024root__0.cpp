// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vcdp_icvt_ref_tb.h for the primary calling header

#include "Vcdp_icvt_ref_tb__pch.h"

VlCoroutine Vcdp_icvt_ref_tb___024root___eval_initial__TOP__Vtiming__0(Vcdp_icvt_ref_tb___024root* vlSelf);
VlCoroutine Vcdp_icvt_ref_tb___024root___eval_initial__TOP__Vtiming__1(Vcdp_icvt_ref_tb___024root* vlSelf);

void Vcdp_icvt_ref_tb___024root___eval_initial(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_initial\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    Vcdp_icvt_ref_tb___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vcdp_icvt_ref_tb___024root___eval_initial__TOP__Vtiming__1(vlSelf);
}

VlCoroutine Vcdp_icvt_ref_tb___024root___eval_initial__TOP__Vtiming__0(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_initial__TOP__Vtiming__0\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_clk = 0U;
    while (true) {
        co_await vlSelfRef.__VdlySched.delay(0x0000000000001388ULL, 
                                             nullptr, 
                                             "cdp_icvt_ref_tb.v", 
                                             58);
        vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_clk 
            = (1U & (~ (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_clk)));
    }
    co_return;
}

void Vcdp_icvt_ref_tb___024root____VbeforeTrig_h8500945d__0(Vcdp_icvt_ref_tb___024root* vlSelf, const char* __VeventDescription);

VlCoroutine Vcdp_icvt_ref_tb___024root___eval_initial__TOP__Vtiming__1(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_initial__TOP__Vtiming__1\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ cdp_icvt_ref_tb__DOT__test_count;
    cdp_icvt_ref_tb__DOT__test_count = 0;
    IData/*31:0*/ cdp_icvt_ref_tb__DOT__pass_count;
    cdp_icvt_ref_tb__DOT__pass_count = 0;
    // Body
    cdp_icvt_ref_tb__DOT__test_count = 0U;
    cdp_icvt_ref_tb__DOT__pass_count = 0U;
    vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_vld = 0U;
    vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_out_rdy = 1U;
    vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_alu_in = 0x000aU;
    vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_mul_in = 2U;
    vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_truncate = 4U;
    vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_rstn = 0U;
    co_await vlSelfRef.__VdlySched.delay(0x00000000000186a0ULL, 
                                         nullptr, "cdp_icvt_ref_tb.v", 
                                         83);
    vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_rstn = 1U;
    co_await vlSelfRef.__VdlySched.delay(0x000000000000c350ULL, 
                                         nullptr, "cdp_icvt_ref_tb.v", 
                                         85);
    cdp_icvt_ref_tb__DOT__test_count = ((IData)(1U) 
                                        + cdp_icvt_ref_tb__DOT__test_count);
    vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in = 0x0064U;
    vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_vld = 1U;
    Vcdp_icvt_ref_tb___024root____VbeforeTrig_h8500945d__0(vlSelf, 
                                                           "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)");
    co_await vlSelfRef.__VtrigSched_h8500945d__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)", 
                                                         "cdp_icvt_ref_tb.v", 
                                                         91);
    while ((1U & (~ (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_rdy)))) {
        Vcdp_icvt_ref_tb___024root____VbeforeTrig_h8500945d__0(vlSelf, 
                                                               "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)");
        co_await vlSelfRef.__VtrigSched_h8500945d__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)", 
                                                             "cdp_icvt_ref_tb.v", 
                                                             92);
    }
    vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_vld = 0U;
    while ((1U & (~ (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q)))) {
        Vcdp_icvt_ref_tb___024root____VbeforeTrig_h8500945d__0(vlSelf, 
                                                               "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)");
        co_await vlSelfRef.__VtrigSched_h8500945d__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)", 
                                                             "cdp_icvt_ref_tb.v", 
                                                             96);
    }
    if ((VL_SHIFTR_III(16,16,8, (0x0000ffffU & ((0x0000ffffU 
                                                 & ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__data_in_reg) 
                                                    - (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__alu_in_reg))) 
                                                * (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__mul_in_reg))), (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__truncate_reg)) 
         == (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__expected_trt))) {
        VL_WRITEF_NX("PASS: Test 1 - ICVT result=%x (expected %x)\n",0,
                     16,VL_SHIFTR_III(16,16,8, (0x0000ffffU 
                                                & ((0x0000ffffU 
                                                    & ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__data_in_reg) 
                                                       - (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__alu_in_reg))) 
                                                   * (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__mul_in_reg))), (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__truncate_reg)),
                     16,(IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__expected_trt));
        cdp_icvt_ref_tb__DOT__pass_count = ((IData)(1U) 
                                            + cdp_icvt_ref_tb__DOT__pass_count);
    } else {
        VL_WRITEF_NX("FAIL: Test 1 - ICVT result=%x (expected %x)\n",0,
                     16,VL_SHIFTR_III(16,16,8, (0x0000ffffU 
                                                & ((0x0000ffffU 
                                                    & ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__data_in_reg) 
                                                       - (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__alu_in_reg))) 
                                                   * (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__mul_in_reg))), (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__truncate_reg)),
                     16,(IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__expected_trt));
    }
    cdp_icvt_ref_tb__DOT__test_count = ((IData)(1U) 
                                        + cdp_icvt_ref_tb__DOT__test_count);
    vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in = 0x00c8U;
    vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_vld = 1U;
    Vcdp_icvt_ref_tb___024root____VbeforeTrig_h8500945d__0(vlSelf, 
                                                           "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)");
    co_await vlSelfRef.__VtrigSched_h8500945d__0.trigger(0U, 
                                                         nullptr, 
                                                         "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)", 
                                                         "cdp_icvt_ref_tb.v", 
                                                         108);
    while ((1U & (~ (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_rdy)))) {
        Vcdp_icvt_ref_tb___024root____VbeforeTrig_h8500945d__0(vlSelf, 
                                                               "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)");
        co_await vlSelfRef.__VtrigSched_h8500945d__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)", 
                                                             "cdp_icvt_ref_tb.v", 
                                                             109);
    }
    vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_vld = 0U;
    while ((1U & (~ (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q)))) {
        Vcdp_icvt_ref_tb___024root____VbeforeTrig_h8500945d__0(vlSelf, 
                                                               "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)");
        co_await vlSelfRef.__VtrigSched_h8500945d__0.trigger(0U, 
                                                             nullptr, 
                                                             "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)", 
                                                             "cdp_icvt_ref_tb.v", 
                                                             113);
    }
    if ((VL_SHIFTR_III(16,16,8, (0x0000ffffU & ((0x0000ffffU 
                                                 & ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__data_in_reg) 
                                                    - (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__alu_in_reg))) 
                                                * (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__mul_in_reg))), (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__truncate_reg)) 
         == (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__expected_trt))) {
        VL_WRITEF_NX("PASS: Test 2 - ICVT result=%x (expected %x)\n",0,
                     16,VL_SHIFTR_III(16,16,8, (0x0000ffffU 
                                                & ((0x0000ffffU 
                                                    & ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__data_in_reg) 
                                                       - (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__alu_in_reg))) 
                                                   * (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__mul_in_reg))), (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__truncate_reg)),
                     16,(IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__expected_trt));
        cdp_icvt_ref_tb__DOT__pass_count = ((IData)(1U) 
                                            + cdp_icvt_ref_tb__DOT__pass_count);
    } else {
        VL_WRITEF_NX("FAIL: Test 2 - ICVT result=%x (expected %x)\n",0,
                     16,VL_SHIFTR_III(16,16,8, (0x0000ffffU 
                                                & ((0x0000ffffU 
                                                    & ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__data_in_reg) 
                                                       - (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__alu_in_reg))) 
                                                   * (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__mul_in_reg))), (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__truncate_reg)),
                     16,(IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__expected_trt));
    }
    VL_WRITEF_NX("========================================\nCDP ICVT Reference Model Test Summary:\n  Total: %0d\n  Pass:  %0d\n  Fail:  %0d\n========================================\n",0,
                 32,cdp_icvt_ref_tb__DOT__test_count,
                 32,cdp_icvt_ref_tb__DOT__pass_count,
                 32,(cdp_icvt_ref_tb__DOT__test_count 
                     - cdp_icvt_ref_tb__DOT__pass_count));
    VL_FINISH_MT("cdp_icvt_ref_tb.v", 128, "");
    co_return;
}

void Vcdp_icvt_ref_tb___024root___eval_triggers_vec__act(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_triggers_vec__act\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VactTriggered[0U] = (QData)((IData)(
                                                    ((vlSelfRef.__VdlySched.awaitingCurrentTime() 
                                                      << 2U) 
                                                     | ((((~ (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_rstn)) 
                                                          & (IData)(vlSelfRef.__Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_rstn__0)) 
                                                         << 1U) 
                                                        | ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_clk) 
                                                           & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_clk__0)))))));
    vlSelfRef.__Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_clk__0 
        = vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_clk;
    vlSelfRef.__Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_rstn__0 
        = vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_rstn;
}

bool Vcdp_icvt_ref_tb___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___trigger_anySet__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        if (in[n]) {
            return (1U);
        }
        n = ((IData)(1U) + n);
    } while ((1U > n));
    return (0U);
}

void Vcdp_icvt_ref_tb___024root___act_comb__TOP__0(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___act_comb__TOP__0\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_rdy 
        = (1U & ((~ (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q)) 
                 | ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_out_rdy) 
                    & (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q))));
    vlSelfRef.cdp_icvt_ref_tb__DOT__expected_trt = 
        VL_SHIFTR_III(16,16,8, (0x0000ffffU & ((0x0000ffffU 
                                                & ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in) 
                                                   - (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_alu_in))) 
                                               * (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_mul_in))), (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_truncate));
}

void Vcdp_icvt_ref_tb___024root___eval_act(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_act\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((5ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_rdy 
            = (1U & ((~ (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q)) 
                     | ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_out_rdy) 
                        & (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q))));
        vlSelfRef.cdp_icvt_ref_tb__DOT__expected_trt 
            = VL_SHIFTR_III(16,16,8, (0x0000ffffU & 
                                      ((0x0000ffffU 
                                        & ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in) 
                                           - (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_alu_in))) 
                                       * (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_mul_in))), (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_truncate));
    }
}

void Vcdp_icvt_ref_tb___024root___nba_sequent__TOP__0(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___nba_sequent__TOP__0\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q;
    __Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q = 0;
    // Body
    __Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q 
        = vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q;
    if (vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_rstn) {
        if (((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_vld) 
             & (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_rdy))) {
            __Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q = 1U;
            vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__mul_in_reg 
                = vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_mul_in;
            vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__data_in_reg 
                = vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in;
            vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__alu_in_reg 
                = vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_alu_in;
            vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__truncate_reg 
                = vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_truncate;
        } else if (((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q) 
                    & (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_out_rdy))) {
            __Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q = 0U;
        }
    } else {
        __Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q = 0U;
    }
    vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q 
        = __Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q;
}

void Vcdp_icvt_ref_tb___024root___nba_comb__TOP__0(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___nba_comb__TOP__0\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.cdp_icvt_ref_tb__DOT__expected_trt = 
        VL_SHIFTR_III(16,16,8, (0x0000ffffU & ((0x0000ffffU 
                                                & ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in) 
                                                   - (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_alu_in))) 
                                               * (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_mul_in))), (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_truncate));
}

void Vcdp_icvt_ref_tb___024root___nba_comb__TOP__1(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___nba_comb__TOP__1\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_rdy 
        = (1U & ((~ (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q)) 
                 | ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_out_rdy) 
                    & (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q))));
}

void Vcdp_icvt_ref_tb___024root___eval_nba(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_nba\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __Vinline__nba_sequent__TOP__0___Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q;
    __Vinline__nba_sequent__TOP__0___Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q = 0;
    // Body
    if ((3ULL & vlSelfRef.__VnbaTriggered[0U])) {
        __Vinline__nba_sequent__TOP__0___Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q 
            = vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q;
        if (vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_rstn) {
            if (((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_vld) 
                 & (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_rdy))) {
                __Vinline__nba_sequent__TOP__0___Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q = 1U;
                vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__mul_in_reg 
                    = vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_mul_in;
                vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__data_in_reg 
                    = vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in;
                vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__alu_in_reg 
                    = vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_alu_in;
                vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__truncate_reg 
                    = vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_truncate;
            } else if (((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q) 
                        & (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_out_rdy))) {
                __Vinline__nba_sequent__TOP__0___Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q = 0U;
            }
        } else {
            __Vinline__nba_sequent__TOP__0___Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q = 0U;
        }
        vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q 
            = __Vinline__nba_sequent__TOP__0___Vdly__cdp_icvt_ref_tb__DOT__dut__DOT__valid_q;
    }
    if ((5ULL & vlSelfRef.__VnbaTriggered[0U])) {
        vlSelfRef.cdp_icvt_ref_tb__DOT__expected_trt 
            = VL_SHIFTR_III(16,16,8, (0x0000ffffU & 
                                      ((0x0000ffffU 
                                        & ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in) 
                                           - (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_alu_in))) 
                                       * (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_mul_in))), (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__cfg_truncate));
    }
    if ((7ULL & vlSelfRef.__VnbaTriggered[0U])) {
        vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_in_rdy 
            = (1U & ((~ (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q)) 
                     | ((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__chn_data_out_rdy) 
                        & (IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__dut__DOT__valid_q))));
    }
}

void Vcdp_icvt_ref_tb___024root___timing_ready(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___timing_ready\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VtrigSched_h8500945d__0.ready("@(posedge cdp_icvt_ref_tb.nvdla_core_clk)");
    }
}

void Vcdp_icvt_ref_tb___024root___timing_resume(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___timing_resume\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VtrigSched_h8500945d__0.moveToResumeQueue(
                                                          "@(posedge cdp_icvt_ref_tb.nvdla_core_clk)");
    vlSelfRef.__VtrigSched_h8500945d__0.resume("@(posedge cdp_icvt_ref_tb.nvdla_core_clk)");
    if ((4ULL & vlSelfRef.__VactTriggered[0U])) {
        vlSelfRef.__VdlySched.resume();
    }
}

void Vcdp_icvt_ref_tb___024root___trigger_orInto__act_vec_vec(VlUnpacked<QData/*63:0*/, 1> &out, const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___trigger_orInto__act_vec_vec\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = (out[n] | in[n]);
        n = ((IData)(1U) + n);
    } while ((0U >= n));
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vcdp_icvt_ref_tb___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG

bool Vcdp_icvt_ref_tb___024root___eval_phase__act(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_phase__act\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VactExecute;
    // Body
    Vcdp_icvt_ref_tb___024root___eval_triggers_vec__act(vlSelf);
    Vcdp_icvt_ref_tb___024root___timing_ready(vlSelf);
    Vcdp_icvt_ref_tb___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VactTriggered, vlSelfRef.__VactTriggeredAcc);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vcdp_icvt_ref_tb___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
    }
#endif
    Vcdp_icvt_ref_tb___024root___trigger_orInto__act_vec_vec(vlSelfRef.__VnbaTriggered, vlSelfRef.__VactTriggered);
    __VactExecute = Vcdp_icvt_ref_tb___024root___trigger_anySet__act(vlSelfRef.__VactTriggered);
    if (__VactExecute) {
        vlSelfRef.__VactTriggeredAcc.fill(0ULL);
        Vcdp_icvt_ref_tb___024root___timing_resume(vlSelf);
        Vcdp_icvt_ref_tb___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vcdp_icvt_ref_tb___024root___eval_phase__inact(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_phase__inact\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VinactExecute;
    // Body
    __VinactExecute = vlSelfRef.__VdlySched.awaitingZeroDelay();
    if (__VinactExecute) {
        VL_FATAL_MT("cdp_icvt_ref_tb.v", 15, "", "ZERODLY: Design Verilated with '--no-sched-zero-delay', but #0 delay executed at runtime");
    }
    return (__VinactExecute);
}

void Vcdp_icvt_ref_tb___024root___trigger_clear__act(VlUnpacked<QData/*63:0*/, 1> &out) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___trigger_clear__act\n"); );
    // Locals
    IData/*31:0*/ n;
    // Body
    n = 0U;
    do {
        out[n] = 0ULL;
        n = ((IData)(1U) + n);
    } while ((1U > n));
}

bool Vcdp_icvt_ref_tb___024root___eval_phase__nba(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_phase__nba\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = Vcdp_icvt_ref_tb___024root___trigger_anySet__act(vlSelfRef.__VnbaTriggered);
    if (__VnbaExecute) {
        Vcdp_icvt_ref_tb___024root___eval_nba(vlSelf);
        Vcdp_icvt_ref_tb___024root___trigger_clear__act(vlSelfRef.__VnbaTriggered);
    }
    return (__VnbaExecute);
}

void Vcdp_icvt_ref_tb___024root___eval(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VnbaIterCount;
    // Body
    __VnbaIterCount = 0U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VnbaIterCount)))) {
#ifdef VL_DEBUG
            Vcdp_icvt_ref_tb___024root___dump_triggers__act(vlSelfRef.__VnbaTriggered, "nba"s);
#endif
            VL_FATAL_MT("cdp_icvt_ref_tb.v", 15, "", "DIDNOTCONVERGE: NBA region did not converge after '--converge-limit' of 100 tries");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        vlSelfRef.__VinactIterCount = 0U;
        do {
            if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VinactIterCount)))) {
                VL_FATAL_MT("cdp_icvt_ref_tb.v", 15, "", "DIDNOTCONVERGE: Inactive region did not converge after '--converge-limit' of 100 tries");
            }
            vlSelfRef.__VinactIterCount = ((IData)(1U) 
                                           + vlSelfRef.__VinactIterCount);
            vlSelfRef.__VactIterCount = 0U;
            do {
                if (VL_UNLIKELY(((0x00000064U < vlSelfRef.__VactIterCount)))) {
#ifdef VL_DEBUG
                    Vcdp_icvt_ref_tb___024root___dump_triggers__act(vlSelfRef.__VactTriggered, "act"s);
#endif
                    VL_FATAL_MT("cdp_icvt_ref_tb.v", 15, "", "DIDNOTCONVERGE: Active region did not converge after '--converge-limit' of 100 tries");
                }
                vlSelfRef.__VactIterCount = ((IData)(1U) 
                                             + vlSelfRef.__VactIterCount);
                vlSelfRef.__VactPhaseResult = Vcdp_icvt_ref_tb___024root___eval_phase__act(vlSelf);
            } while (vlSelfRef.__VactPhaseResult);
            vlSelfRef.__VinactPhaseResult = Vcdp_icvt_ref_tb___024root___eval_phase__inact(vlSelf);
        } while (vlSelfRef.__VinactPhaseResult);
        vlSelfRef.__VnbaPhaseResult = Vcdp_icvt_ref_tb___024root___eval_phase__nba(vlSelf);
    } while (vlSelfRef.__VnbaPhaseResult);
}

void Vcdp_icvt_ref_tb___024root____VbeforeTrig_h8500945d__0(Vcdp_icvt_ref_tb___024root* vlSelf, const char* __VeventDescription) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root____VbeforeTrig_h8500945d__0\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    VlUnpacked<QData/*63:0*/, 1> __VTmp;
    // Body
    __VTmp[0U] = (QData)((IData)(((IData)(vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_clk) 
                                  & (~ (IData)(vlSelfRef.__Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_clk__0)))));
    vlSelfRef.__Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_clk__0 
        = vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_clk;
    if ((1ULL & __VTmp[0U])) {
        vlSelfRef.__VtrigSched_h8500945d__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h8500945d__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h8500945d__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h8500945d__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h8500945d__0.ready(__VeventDescription);
        vlSelfRef.__VtrigSched_h8500945d__0.ready(__VeventDescription);
    }
    vlSelfRef.__VactTriggeredAcc[0U] = (vlSelfRef.__VactTriggeredAcc[0U] 
                                        | __VTmp[0U]);
}

#ifdef VL_DEBUG
void Vcdp_icvt_ref_tb___024root___eval_debug_assertions(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_debug_assertions\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}
#endif  // VL_DEBUG
