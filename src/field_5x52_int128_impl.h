/***********************************************************************
 * Copyright (c) 2013, 2014 Pieter Wuille                              *
 * Distributed under the MIT software license, see the accompanying    *
 * file COPYING or https://www.opensource.org/licenses/mit-license.php.*
 ***********************************************************************/

#ifndef SECP256K1_FIELD_INNER5X52_IMPL_H
#define SECP256K1_FIELD_INNER5X52_IMPL_H

#include <stdint.h>

#include "third_party/secp256k1_dettman_64.h"

SECP256K1_INLINE static void
secp256k1_fe_mul_inner(uint64_t *r, const uint64_t *a,
                       const uint64_t *SECP256K1_RESTRICT b) {
  fiat_secp256k1_dettman_mul(r, a, b);
}

SECP256K1_INLINE static void secp256k1_fe_sqr_inner(uint64_t *r,
                                                    const uint64_t *a) {
  fiat_secp256k1_dettman_square(r, a);
}

#endif /* SECP256K1_FIELD_INNER5X52_IMPL_H */
