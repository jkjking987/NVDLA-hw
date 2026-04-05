// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vcdp_icvt_ref_tb.h for the primary calling header

#include "Vcdp_icvt_ref_tb__pch.h"

void Vcdp_icvt_ref_tb___024root___timing_ready(Vcdp_icvt_ref_tb___024root* vlSelf);

VL_ATTR_COLD void Vcdp_icvt_ref_tb___024root___eval_static(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_static\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_clk__0 
        = vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_clk;
    vlSelfRef.__Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_rstn__0 
        = vlSelfRef.cdp_icvt_ref_tb__DOT__nvdla_core_rstn;
    Vcdp_icvt_ref_tb___024root___timing_ready(vlSelf);
    do {
        vlSelfRef.__VactTriggeredAcc[vlSelfRef.__Vi] 
            = vlSelfRef.__VactTriggered[vlSelfRef.__Vi];
        vlSelfRef.__Vi = ((IData)(1U) + vlSelfRef.__Vi);
    } while ((0U >= vlSelfRef.__Vi));
}

VL_ATTR_COLD void Vcdp_icvt_ref_tb___024root___eval_final(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_final\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vcdp_icvt_ref_tb___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vcdp_icvt_ref_tb___024root___eval_phase__stl(Vcdp_icvt_ref_tb___024root* vlSelf);

VL_ATTR_COLD void Vcdp_icvt_ref_tb___024root___eval_settle(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_settle\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    IData/*31:0*/ __VstlIterCount;
    // Body
    __VstlIterCount = 0U;
    vlSelfRef.__VstlFirstIteration = 1U;
    do {
        if (VL_UNLIKELY(((0x00000064U < __VstlIterCount)))) {
#ifdef VL_DEBUG
            Vcdp_icvt_ref_tb___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
#endif
            VL_FATAL_MT("cdp_icvt_ref_tb.v", 15, "", "DIDNOTCONVERGE: Settle region did not converge after '--converge-limit' of 100 tries");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        vlSelfRef.__VstlPhaseResult = Vcdp_icvt_ref_tb___024root___eval_phase__stl(vlSelf);
        vlSelfRef.__VstlFirstIteration = 0U;
    } while (vlSelfRef.__VstlPhaseResult);
}

VL_ATTR_COLD void Vcdp_icvt_ref_tb___024root___eval_triggers_vec__stl(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_triggers_vec__stl\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    vlSelfRef.__VstlTriggered[0U] = ((0xfffffffffffffffeULL 
                                      & vlSelfRef.__VstlTriggered[0U]) 
                                     | (IData)((IData)(vlSelfRef.__VstlFirstIteration)));
}

VL_ATTR_COLD bool Vcdp_icvt_ref_tb___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vcdp_icvt_ref_tb___024root___dump_triggers__stl(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(Vcdp_icvt_ref_tb___024root___trigger_anySet__stl(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD bool Vcdp_icvt_ref_tb___024root___trigger_anySet__stl(const VlUnpacked<QData/*63:0*/, 1> &in) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___trigger_anySet__stl\n"); );
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

VL_ATTR_COLD void Vcdp_icvt_ref_tb___024root___eval_stl(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_stl\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    if ((1ULL & vlSelfRef.__VstlTriggered[0U])) {
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

VL_ATTR_COLD bool Vcdp_icvt_ref_tb___024root___eval_phase__stl(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___eval_phase__stl\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Locals
    CData/*0:0*/ __VstlExecute;
    // Body
    Vcdp_icvt_ref_tb___024root___eval_triggers_vec__stl(vlSelf);
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vcdp_icvt_ref_tb___024root___dump_triggers__stl(vlSelfRef.__VstlTriggered, "stl"s);
    }
#endif
    __VstlExecute = Vcdp_icvt_ref_tb___024root___trigger_anySet__stl(vlSelfRef.__VstlTriggered);
    if (__VstlExecute) {
        Vcdp_icvt_ref_tb___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

bool Vcdp_icvt_ref_tb___024root___trigger_anySet__act(const VlUnpacked<QData/*63:0*/, 1> &in);

#ifdef VL_DEBUG
VL_ATTR_COLD void Vcdp_icvt_ref_tb___024root___dump_triggers__act(const VlUnpacked<QData/*63:0*/, 1> &triggers, const std::string &tag) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(Vcdp_icvt_ref_tb___024root___trigger_anySet__act(triggers))))) {
        VL_DBG_MSGS("         No '" + tag + "' region triggers active\n");
    }
    if ((1U & (IData)(triggers[0U]))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 0 is active: @(posedge cdp_icvt_ref_tb.nvdla_core_clk)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 1U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 1 is active: @(negedge cdp_icvt_ref_tb.nvdla_core_rstn)\n");
    }
    if ((1U & (IData)((triggers[0U] >> 2U)))) {
        VL_DBG_MSGS("         '" + tag + "' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vcdp_icvt_ref_tb___024root___ctor_var_reset(Vcdp_icvt_ref_tb___024root* vlSelf) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vcdp_icvt_ref_tb___024root___ctor_var_reset\n"); );
    Vcdp_icvt_ref_tb__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    auto& vlSelfRef = std::ref(*vlSelf).get();
    // Body
    const uint64_t __VscopeHash = VL_MURMUR64_HASH(vlSelf->vlNamep);
    vlSelf->cdp_icvt_ref_tb__DOT__nvdla_core_clk = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 8822441977570411810ull);
    vlSelf->cdp_icvt_ref_tb__DOT__nvdla_core_rstn = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 6856418245838817859ull);
    vlSelf->cdp_icvt_ref_tb__DOT__chn_data_in_vld = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 15392886072791315998ull);
    vlSelf->cdp_icvt_ref_tb__DOT__chn_data_in_rdy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 7858582469879946835ull);
    vlSelf->cdp_icvt_ref_tb__DOT__chn_data_in = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 7571421537287186670ull);
    vlSelf->cdp_icvt_ref_tb__DOT__cfg_alu_in = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 17747894247139323494ull);
    vlSelf->cdp_icvt_ref_tb__DOT__cfg_mul_in = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 8899188869440327845ull);
    vlSelf->cdp_icvt_ref_tb__DOT__cfg_truncate = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 16829904243201900348ull);
    vlSelf->cdp_icvt_ref_tb__DOT__chn_data_out_rdy = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 12403781123275702782ull);
    vlSelf->cdp_icvt_ref_tb__DOT__expected_trt = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 12494734795977509289ull);
    vlSelf->cdp_icvt_ref_tb__DOT__dut__DOT__data_in_reg = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 11026791050826771293ull);
    vlSelf->cdp_icvt_ref_tb__DOT__dut__DOT__alu_in_reg = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 7098681975172184774ull);
    vlSelf->cdp_icvt_ref_tb__DOT__dut__DOT__mul_in_reg = VL_SCOPED_RAND_RESET_I(16, __VscopeHash, 12127786363328581553ull);
    vlSelf->cdp_icvt_ref_tb__DOT__dut__DOT__truncate_reg = VL_SCOPED_RAND_RESET_I(8, __VscopeHash, 5918994336816487011ull);
    vlSelf->cdp_icvt_ref_tb__DOT__dut__DOT__valid_q = VL_SCOPED_RAND_RESET_I(1, __VscopeHash, 441928347272955195ull);
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VstlTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggered[__Vi0] = 0;
    }
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VactTriggeredAcc[__Vi0] = 0;
    }
    vlSelf->__Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_clk__0 = 0;
    vlSelf->__Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_rstn__0 = 0;
    for (int __Vi0 = 0; __Vi0 < 1; ++__Vi0) {
        vlSelf->__VnbaTriggered[__Vi0] = 0;
    }
    vlSelf->__Vi = 0;
}
