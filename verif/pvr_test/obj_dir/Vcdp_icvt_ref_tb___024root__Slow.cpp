// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vcdp_icvt_ref_tb.h for the primary calling header

#include "Vcdp_icvt_ref_tb__pch.h"

void Vcdp_icvt_ref_tb___024root___ctor_var_reset(Vcdp_icvt_ref_tb___024root* vlSelf);

Vcdp_icvt_ref_tb___024root::Vcdp_icvt_ref_tb___024root(Vcdp_icvt_ref_tb__Syms* symsp, const char* namep)
    : __VdlySched{*symsp->_vm_contextp__}
 {
    vlSymsp = symsp;
    vlNamep = strdup(namep);
    // Reset structure values
    Vcdp_icvt_ref_tb___024root___ctor_var_reset(this);
}

void Vcdp_icvt_ref_tb___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

Vcdp_icvt_ref_tb___024root::~Vcdp_icvt_ref_tb___024root() {
    VL_DO_DANGLING(std::free(const_cast<char*>(vlNamep)), vlNamep);
}
