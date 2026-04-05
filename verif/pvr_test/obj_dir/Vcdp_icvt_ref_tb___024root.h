// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vcdp_icvt_ref_tb.h for the primary calling header

#ifndef VERILATED_VCDP_ICVT_REF_TB___024ROOT_H_
#define VERILATED_VCDP_ICVT_REF_TB___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_timing.h"


class Vcdp_icvt_ref_tb__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vcdp_icvt_ref_tb___024root final {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ cdp_icvt_ref_tb__DOT__nvdla_core_clk;
    CData/*0:0*/ cdp_icvt_ref_tb__DOT__nvdla_core_rstn;
    CData/*0:0*/ cdp_icvt_ref_tb__DOT__chn_data_in_vld;
    CData/*0:0*/ cdp_icvt_ref_tb__DOT__chn_data_in_rdy;
    CData/*7:0*/ cdp_icvt_ref_tb__DOT__cfg_truncate;
    CData/*0:0*/ cdp_icvt_ref_tb__DOT__chn_data_out_rdy;
    CData/*7:0*/ cdp_icvt_ref_tb__DOT__dut__DOT__truncate_reg;
    CData/*0:0*/ cdp_icvt_ref_tb__DOT__dut__DOT__valid_q;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __VstlPhaseResult;
    CData/*0:0*/ __Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__cdp_icvt_ref_tb__DOT__nvdla_core_rstn__0;
    CData/*0:0*/ __VactPhaseResult;
    CData/*0:0*/ __VinactPhaseResult;
    CData/*0:0*/ __VnbaPhaseResult;
    SData/*15:0*/ cdp_icvt_ref_tb__DOT__chn_data_in;
    SData/*15:0*/ cdp_icvt_ref_tb__DOT__cfg_alu_in;
    SData/*15:0*/ cdp_icvt_ref_tb__DOT__cfg_mul_in;
    SData/*15:0*/ cdp_icvt_ref_tb__DOT__expected_trt;
    SData/*15:0*/ cdp_icvt_ref_tb__DOT__dut__DOT__data_in_reg;
    SData/*15:0*/ cdp_icvt_ref_tb__DOT__dut__DOT__alu_in_reg;
    SData/*15:0*/ cdp_icvt_ref_tb__DOT__dut__DOT__mul_in_reg;
    IData/*31:0*/ __VactIterCount;
    IData/*31:0*/ __VinactIterCount;
    IData/*31:0*/ __Vi;
    VlUnpacked<QData/*63:0*/, 1> __VstlTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggered;
    VlUnpacked<QData/*63:0*/, 1> __VactTriggeredAcc;
    VlUnpacked<QData/*63:0*/, 1> __VnbaTriggered;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_h8500945d__0;

    // INTERNAL VARIABLES
    Vcdp_icvt_ref_tb__Syms* vlSymsp;
    const char* vlNamep;

    // CONSTRUCTORS
    Vcdp_icvt_ref_tb___024root(Vcdp_icvt_ref_tb__Syms* symsp, const char* namep);
    ~Vcdp_icvt_ref_tb___024root();
    VL_UNCOPYABLE(Vcdp_icvt_ref_tb___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
