// Copyright (C) 2023-2025 Intel Corporation
// SPDX-License-Identifier: BSD-3-Clause
//
//vec_string_test.dart
// Tests of Floating Point stuff
//
// April 2025
// Author: Josh Kimmel <joshua1.kimmel@intel.com>

import 'package:rohd/rohd.dart';
import 'package:rohd_hcl/src/crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  test('sbox', () {
    final map1 = {
      0: 1,
      1: 2,
      2: 3,
      3: 4,
    };
    for (var i = 0; i < 4; i++) {
      final val = Const(i, width: 2);
      final sboxVal = sbox(val, map1);
      expect(sboxVal.value, LogicValue.ofInt(map1[i]!, 2));
    }
  });

  test('rotate right', () {
    final val1 = Const(LogicValue.ofString('10000000'), width: 8);
    final rotated1 = ror(val1, 2);
    expect(rotated1.value, LogicValue.ofString('00100000'));
    final rotated2 = ror(val1, 7);
    expect(rotated2.value, LogicValue.ofString('00000001'));
    final rotated3 = ror(val1, 0);
    expect(rotated3.value, LogicValue.ofString('10000000'));

    final val2 = Const(LogicValue.ofString('10001010'), width: 8);
    final rotated4 = ror(val2, 2);
    expect(rotated4.value, LogicValue.ofString('10100010'));
    final rotated5 = ror(val2, 7);
    expect(rotated5.value, LogicValue.ofString('00010101'));
    final rotated6 = ror(val2, 0);
    expect(rotated6.value, LogicValue.ofString('10001010'));
  });

  test('rotate left', () {
    final val1 = Const(LogicValue.ofString('00000001'), width: 8);
    final rotated1 = rol(val1, 2);
    expect(rotated1.value, LogicValue.ofString('00000100'));
    final rotated2 = rol(val1, 7);
    expect(rotated2.value, LogicValue.ofString('10000000'));
    final rotated3 = rol(val1, 0);
    expect(rotated3.value, LogicValue.ofString('00000001'));

    final val2 = Const(LogicValue.ofString('10100001'), width: 8);
    final rotated4 = rol(val2, 2);
    expect(rotated4.value, LogicValue.ofString('10000110'));
    final rotated5 = rol(val2, 7);
    expect(rotated5.value, LogicValue.ofString('11010000'));
    final rotated6 = rol(val2, 0);
    expect(rotated6.value, LogicValue.ofString('10100001'));
  });
}
