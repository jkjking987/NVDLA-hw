// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VCDP_ICVT_REF_TB__SYMS_H_
#define VERILATED_VCDP_ICVT_REF_TB__SYMS_H_  // guard

#include "verilated.h"

// INCLUDE MODEL CLASS

#include "Vcdp_icvt_ref_tb.h"

// INCLUDE MODULE CLASSES
#include "Vcdp_icvt_ref_tb___024root.h"

// SYMS CLASS (contains all model state)
class alignas(VL_CACHE_LINE_BYTES) Vcdp_icvt_ref_tb__Syms final : public VerilatedSyms {
  public:
    // INTERNAL STATE
    Vcdp_icvt_ref_tb* const __Vm_modelp;
    VlDeleter __Vm_deleter;
    bool __Vm_didInit = false;

    // MODULE INSTANCE STATE
    Vcdp_icvt_ref_tb___024root     TOP;

    // CONSTRUCTORS
    Vcdp_icvt_ref_tb__Syms(VerilatedContext* contextp, const char* namep, Vcdp_icvt_ref_tb* modelp);
    ~Vcdp_icvt_ref_tb__Syms();

    // METHODS
    const char* name() const { return TOP.vlNamep; }
};

#endif  // guard
