#include <iostream>
#include <verilated.h>
int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    cdp_icvt_ref_tb* top = new cdp_icvt_ref_tb;
    while(!Verilated::gotFinish()) { top->eval(); }
    delete top;
    return 0;
}
