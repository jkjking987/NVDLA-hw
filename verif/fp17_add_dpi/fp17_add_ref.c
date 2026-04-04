// +FHDR------------------------------------------------------------
//                 Copyright (c) 2026 Wolley Inc.
//                       ALL RIGHTS RESERVED
// -----------------------------------------------------------------
// Filename      : fp17_add_ref.c
// Author        : Wolley Hardware Team
// Created On    : 2026/04/04
// -----------------------------------------------------------------
// Description:
//   C reference model for fp17_add DPI verification
//   Implements FpAdd<6,10> from nvdla_float.h
// +FHDR------------------------------------------------------------

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

// Helper functions from nvdla_float.h
static inline int IsNaN(int expo_width, int mant_width, int expo, int mant) {
    int expo_max = (1 << expo_width) - 1;
    return (expo == expo_max) && (mant != 0);
}

static inline int IsInf(int expo_width, int mant_width, int expo, int mant) {
    int expo_max = (1 << expo_width) - 1;
    return (expo == expo_max) && (mant == 0);
}

static inline int IsZero(int expo_width, int mant_width, int expo, int mant) {
    return (expo == 0) && (mant == 0);
}

// Count leading zeros
static inline int CountLeadingZeros(uint32_t val, int width) {
    int count = 0;
    for (int i = width - 1; i >= 0; i--) {
        if (val & (1 << i))
            break;
        count++;
    }
    return count;
}

// FpAdd<6,10> reference implementation
uint16_t FpAdd_fp17(uint16_t a, uint16_t b) {
    const int ExpoWidth = 6;
    const int MantWidth = 10;
    const int FPWidth = 17;
    const int ExpoMax = (1 << ExpoWidth) - 1;  // 63
    const int ExpoBias = (1 << (ExpoWidth - 1)) - 1;  // 31
    const int KMantMoreWidth = MantWidth + 2;  // 12
    const int InternalMantWidth = KMantMoreWidth + MantWidth + 1;  // 23

    // Unpack
    int a_sign = (a >> (ExpoWidth + MantWidth)) & 1;
    int a_expo = (a >> MantWidth) & ((1 << ExpoWidth) - 1);
    int a_mant = a & ((1 << MantWidth) - 1);

    int b_sign = (b >> (ExpoWidth + MantWidth)) & 1;
    int b_expo = (b >> MantWidth) & ((1 << ExpoWidth) - 1);
    int b_mant = b & ((1 << MantWidth) - 1);

    // Special case handling
    if (IsNaN(ExpoWidth, MantWidth, a_expo, a_mant))
        return a;
    if (IsNaN(ExpoWidth, MantWidth, b_expo, b_mant))
        return b;
    if (IsInf(ExpoWidth, MantWidth, a_expo, a_mant) &&
        IsInf(ExpoWidth, MantWidth, b_expo, b_mant) &&
        a_sign != b_sign)
        return (63 << MantWidth) | 0;  // NaN
    if (IsInf(ExpoWidth, MantWidth, a_expo, a_mant))
        return a;
    if (IsInf(ExpoWidth, MantWidth, b_expo, b_mant))
        return b;
    if (IsZero(ExpoWidth, MantWidth, a_expo, a_mant) &&
        IsZero(ExpoWidth, MantWidth, b_expo, b_mant))
        return (b_sign << (ExpoWidth + MantWidth)) | (0 << MantWidth) | 0;

    // Add implied 1 to mantissas
    int a_mant_p1 = (a_expo == 0 && a_mant == 0) ? 0 : (1 << MantWidth) | a_mant;
    int b_mant_p1 = (b_expo == 0 && b_mant == 0) ? 0 : (1 << MantWidth) | b_mant;

    // Determine which is larger
    int a_greater = (a_expo > b_expo) ||
        ((a_expo == b_expo) && (a_mant >= b_mant));

    int o_expo = a_greater ? a_expo : b_expo;
    int o_sign = a_greater ? a_sign : b_sign;
    int is_addition = (a_sign == b_sign);

    // Align mantissas
    int a_right_shift = a_greater ? 0 : (b_expo - a_expo);
    int b_right_shift = a_greater ? (a_expo - b_expo) : 0;

    int left_shift_a = KMantMoreWidth - a_right_shift;
    int left_shift_b = KMantMoreWidth - b_right_shift;

    // Extended mantissas
    uint32_t a_ext = a_mant_p1;
    uint32_t b_ext = b_mant_p1;

    uint32_t a_int = a_ext << left_shift_a;
    uint32_t b_int = b_ext << left_shift_b;

    uint32_t add_larger = a_greater ? a_int : b_int;
    uint32_t add_smaller = a_greater ? b_int : a_int;

    // Add or subtract
    uint32_t result_int;
    int overflow = 0;
    if (is_addition) {
        uint32_t sum = add_larger + add_smaller;
        overflow = (sum >> InternalMantWidth) & 1;
        result_int = overflow ? (sum >> 1) : sum;
    } else {
        uint32_t diff = add_larger - add_smaller;
        result_int = diff;
    }

    // Normalize
    int lead_zeros = CountLeadingZeros(result_int >> (MantWidth + 1), InternalMantWidth);
    if (overflow)
        lead_zeros = 0;

    int shift_amount = (result_int == 0) ? 0 : lead_zeros;
    uint32_t norm_mant = (result_int == 0) ? 0 : (result_int << shift_amount);
    int norm_expo = overflow ? (o_expo + 1) : (o_expo - shift_amount);

    // Round to nearest even
    uint32_t mant_top = norm_mant >> MantWidth;
    int guard_bit = (norm_mant >> (MantWidth - 1)) & 1;
    int sticky_bit = (norm_mant & ((1 << (MantWidth - 1)) - 1)) != 0;
    int lsb_bit = mant_top & 1;
    int round_up = guard_bit && (sticky_bit || lsb_bit);

    uint32_t final_mant = mant_top + (round_up ? 1 : 0);
    int rounding_overflow = (final_mant >> (MantWidth + 1)) & 1;
    final_mant = final_mant & ((1 << MantWidth) - 1);

    int final_expo = rounding_overflow ? (norm_expo + 1) : norm_expo;

    // Clamp exponent
    if (final_expo > ExpoMax)
        final_expo = ExpoMax;
    if (final_expo < 0)
        final_expo = 0;

    // Handle zero
    if (result_int == 0) {
        final_expo = 0;
        final_mant = 0;
    }

    // Pack result
    uint16_t result = (o_sign << (ExpoWidth + MantWidth)) |
                      (final_expo << MantWidth) |
                      final_mant;

    return result;
}

// DPI export function
void fp17_add_ref(int a, int b, int *out) {
    *out = (int)FpAdd_fp17((uint16_t)a, (uint16_t)b);
}
