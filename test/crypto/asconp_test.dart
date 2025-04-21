// Copyright (C) 2023-2025 Intel Corporation
// SPDX-License-Identifier: BSD-3-Clause
//
//vec_string_test.dart
// Tests of Floating Point stuff
//
// April 2025
// Author: Josh Kimmel <joshua1.kimmel@intel.com>

import 'dart:math';

import 'package:rohd/rohd.dart';
import 'package:rohd_hcl/src/crypto/crypto.dart';
import 'package:test/test.dart';

void main() {
  final roundAnsMap = {
    0: LogicValue.ofInt(0xf0, 8),
    1: LogicValue.ofInt(0xe1, 8),
    2: LogicValue.ofInt(0xd2, 8),
    3: LogicValue.ofInt(0xc3, 8),
    4: LogicValue.ofInt(0xb4, 8),
    5: LogicValue.ofInt(0xa5, 8),
    6: LogicValue.ofInt(0x96, 8),
    7: LogicValue.ofInt(0x87, 8),
    8: LogicValue.ofInt(0x78, 8),
    9: LogicValue.ofInt(0x69, 8),
    10: LogicValue.ofInt(0x5a, 8),
    11: LogicValue.ofInt(0x4b, 8),
  };

  test('getChunks', () {
    final state = Const(LogicValue.ofString('11110000101001011100'), width: 20);
    final chunks = getChunks(state);
    expect(chunks.length, 5);
    for (var i = 0; i < chunks.length; i++) {
      expect(chunks[i].width, 4);
      switch (i) {
        case 0:
          expect(chunks[i].value, LogicValue.ofString('1100'));
        case 1:
          expect(chunks[i].value, LogicValue.ofString('0101'));
        case 2:
          expect(chunks[i].value, LogicValue.ofString('1010'));
        case 3:
          expect(chunks[i].value, LogicValue.ofString('0000'));
        case 4:
          expect(chunks[i].value, LogicValue.ofString('1111'));
      }
    }
  });

  test('roundConstant', () {
    for (var i = 0; i < 12; i++) {
      expect(roundConstant(i), roundAnsMap[i]);
    }
  });

  test('applyAsconRoundConstant', () {
    final chunks = [
      Const(LogicValue.ofString('111111'), width: 6),
      Const(LogicValue.ofString('111111'), width: 6),
      Const(LogicValue.ofString('000000'), width: 6),
      Const(LogicValue.ofString('111111'), width: 6),
      Const(LogicValue.ofString('111111'), width: 6),
    ];
    for (var i = 0; i < 12; i++) {
      final next = applyAsconRoundConstant(chunks, i);
      for (var j = 0; j < 5; j++) {
        if (j == 2) {
          expect(next[j].value, roundAnsMap[i]!.getRange(0, 6));
        } else {
          expect(next[j].value, LogicValue.ofString('111111'));
        }
      }
      chunks[2] = Const(LogicValue.ofString('000000'), width: 6);
    }
  });
}
