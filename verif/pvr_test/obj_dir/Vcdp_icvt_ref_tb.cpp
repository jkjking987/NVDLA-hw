// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vcdp_icvt_ref_tb__pch.h"

//============================================================
// Constructors

Vcdp_icvt_ref_tb::Vcdp_icvt_ref_tb(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vcdp_icvt_ref_tb__Syms(contextp(), _vcname__, this)}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vcdp_icvt_ref_tb::Vcdp_icvt_ref_tb(const char* _vcname__)
    : Vcdp_icvt_ref_tb(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vcdp_icvt_ref_tb::~Vcdp_icvt_ref_tb() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vcdp_icvt_ref_tb___024root___eval_debug_assertions(Vcdp_icvt_ref_tb___024root* vlSelf);
#endif  // VL_DEBUG
void Vcdp_icvt_ref_tb___024root___eval_static(Vcdp_icvt_ref_tb___024root* vlSelf);
void Vcdp_icvt_ref_tb___024root___eval_initial(Vcdp_icvt_ref_tb___024root* vlSelf);
void Vcdp_icvt_ref_tb___024root___eval_settle(Vcdp_icvt_ref_tb___024root* vlSelf);
void Vcdp_icvt_ref_tb___024root___eval(Vcdp_icvt_ref_tb___024root* vlSelf);

void Vcdp_icvt_ref_tb::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vcdp_icvt_ref_tb::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vcdp_icvt_ref_tb___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vcdp_icvt_ref_tb___024root___eval_static(&(vlSymsp->TOP));
        Vcdp_icvt_ref_tb___024root___eval_initial(&(vlSymsp->TOP));
        Vcdp_icvt_ref_tb___024root___eval_settle(&(vlSymsp->TOP));
        vlSymsp->__Vm_didInit = true;
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vcdp_icvt_ref_tb___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vcdp_icvt_ref_tb::eventsPending() { return !vlSymsp->TOP.__VdlySched.empty() && !contextp()->gotFinish(); }

uint64_t Vcdp_icvt_ref_tb::nextTimeSlot() { return vlSymsp->TOP.__VdlySched.nextTimeSlot(); }

//============================================================
// Utilities

const char* Vcdp_icvt_ref_tb::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vcdp_icvt_ref_tb___024root___eval_final(Vcdp_icvt_ref_tb___024root* vlSelf);

VL_ATTR_COLD void Vcdp_icvt_ref_tb::final() {
    Vcdp_icvt_ref_tb___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vcdp_icvt_ref_tb::hierName() const { return vlSymsp->name(); }
const char* Vcdp_icvt_ref_tb::modelName() const { return "Vcdp_icvt_ref_tb"; }
unsigned Vcdp_icvt_ref_tb::threads() const { return 1; }
void Vcdp_icvt_ref_tb::prepareClone() const { contextp()->prepareClone(); }
void Vcdp_icvt_ref_tb::atClone() const {
    contextp()->threadPoolpOnClone();
}
