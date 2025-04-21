// Copyright (C) 2023-2025 Intel Corporation
// SPDX-License-Identifier: BSD-3-Clause
//
// crypto_common.dart
// Crypto logic primitives.
//
// April 2025
// Author: Josh Kimmel <joshua1.kimmel@intel.com>,

import 'package:rohd/rohd.dart';

/// Perform the S-Box non-linear function in which an input
/// is mapped to an output using an explicit mapping.
Logic sbox(Logic input, Map<int, int> mapping) {
  final width = input.width;
  final sCases = <Logic, Logic>{};
  for (var i = 0; i < mapping.length; i++) {
    final key = mapping.keys.elementAt(i);
    final value = mapping.values.elementAt(i);
    sCases[Const(key, width: width)] = Const(value, width: width);
  }
  return cases(
      input,
      conditionalType: ConditionalType.unique,
      width: width,
      sCases,
      defaultValue: Const(0, width: width));
}

/// Rotate right the input by the specified amount.
Logic ror(Logic input, int amount) {
  final o1 = input >>> amount;
  final o2 = input << (input.width - amount);
  return o1 | o2;
}

/// Rotate left the input by the specified amount.
Logic rol(Logic input, int amount) {
  final o1 = input << amount;
  final o2 = input >>> (input.width - amount);
  return o1 | o2;
}
