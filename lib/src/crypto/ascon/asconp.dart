// Copyright (C) 2023-2025 Intel Corporation
// SPDX-License-Identifier: BSD-3-Clause
//
// asconp.dart
// ASCON permutation function.
//
// April 2025
// Author: Josh Kimmel <joshua1.kimmel@intel.com>,

import 'package:rohd/rohd.dart';
import 'package:rohd_hcl/rohd_hcl.dart';

/// The S-Box mapping for ASCON permutation function.
Map<int, int> asconSboxMapping = {
  0x00: 0x04,
  0x01: 0x0b,
  0x02: 0x01,
  0x03: 0x00,
  0x04: 0x0c,
  0x05: 0x03,
  0x06: 0x08,
  0x07: 0x0d,
  0x08: 0x06,
  0x09: 0x0f,
  0x0a: 0x05,
  0x0b: 0x09,
  0x0c: 0x0e,
  0x0d: 0x0a,
  0x0e: 0x07,
  0x0f: 0x02,
  0x10: 0x19,
  0x11: 0x1e,
  0x12: 0x13,
  0x13: 0x16,
  0x14: 0x17,
  0x15: 0x1d,
  0x16: 0x10,
  0x17: 0x12,
  0x18: 0x1f,
  0x19: 0x15,
  0x1a: 0x11,
  0x1b: 0x14,
  0x1c: 0x1b,
  0x1d: 0x1a,
  0x1e: 0x18,
  0x1f: 0x1c,
};

/// Mapping of rotation amounts for ASCON permutation function.
Map<int, (int, int)> asconDiffusionMapping = {
  0: (19, 28),
  1: (61, 39),
  2: (1, 6),
  3: (10, 17),
  4: (7, 41),
};

/// Helper method to extract an ASCON state from an arbitrary Logic.
List<Logic> getChunks(Logic state) {
  if ((state.width % 5) != 0) {
    throw RohdHclException('ASCON state input must be evenly divisible by 5.');
  }
  final chunkSize = state.width ~/ 5;
  return List.generate(
      5, (i) => state.getRange(i * chunkSize, (i + 1) * chunkSize));
}

/// Derive the nth round constant from the ASCON permutation function.
LogicValue roundConstant(int round) =>
    ((LogicValue.ofInt(0xf, 8) - LogicValue.ofInt(round, 8)) << 4) |
    LogicValue.ofInt(round, 8);

/// S-Box function for ASCON permutation function.
Logic asconSbox(Logic input) {
  if (input.width != 5) {
    throw RohdHclException('ASCON S-Box input must be 5 bits.');
  }
  return sbox(input, asconSboxMapping);
}

/// Apply the ASCON round constant to the middle chunk of the state.
List<Logic> applyAsconRoundConstant(List<Logic> chunks, int round) {
  final roundConst = roundConstant(round);
  final idx = chunks.length ~/ 2; // middle chunk only
  final out = <Logic>[];
  for (var i = 0; i < chunks.length; i++) {
    if (i == idx) {
      out.add(chunks[i] ^
          Const(roundConst, width: 6).zeroExtend(chunks[idx].width));
    } else {
      out.add(chunks[i]);
    }
  }
  return out;
}

/// S-Box component of the ASCON permutation function for arbitrary input.
List<Logic> applyAsconSbox(List<Logic> chunks) {
  final chunkSize = chunks[0].width;
  final mappedOut = <Logic>[];
  for (var i = 0; i < chunkSize; i++) {
    final sboxInp =
        List.generate(chunks.length, (idx) => chunks[idx][i]).rswizzle();
    mappedOut.add(asconSbox(sboxInp));
  }
  final outChunks = <Logic>[];
  for (var i = 0; i < chunks.length; i++) {
    final chunk = i ~/ chunkSize;
    final index = i % mappedOut.length;
    outChunks.add(mappedOut[index][chunk]);
  }
  return outChunks;
}

/// Linear diffusion function for ASCON permutation function.
List<Logic> applyLinearDiffusion(List<Logic> chunks) {
  final outChunks = <Logic>[];
  for (var i = 0; i < chunks.length; i++) {
    final curr = chunks[i] ^
        (ror(chunks[i], asconDiffusionMapping[i]!.$1) ^
            ror(chunks[i], asconDiffusionMapping[i]!.$2));
    outChunks.add(curr);
  }
  return outChunks;
}

/// ASCON permutation function.
Pipeline asconPermutation(Logic input, Logic clk, Logic rst,
    {int rounds = 12, int pipeStagesPerRound = 1}) {
  // TODO: apply pipeStagesPerRound somewhere??
  final currChunk = Logic(width: input.width);
  return Pipeline(clk,
      reset: rst,
      stages: List.generate(rounds, (index) {
        if (index == 0) {
          final chunks = getChunks(input);
          chunks
            ..setAll(0, applyAsconRoundConstant(chunks, rounds - index - 1))
            ..setAll(0, applyAsconSbox(chunks))
            ..setAll(0, applyLinearDiffusion(chunks));
          return (p) => [
                p.get(currChunk) < chunks.swizzle(),
              ];
        } else {
          final sChunks = Logic(width: input.width);
          final chunks = getChunks(sChunks);
          chunks
            ..setAll(0, applyAsconRoundConstant(chunks, rounds - index - 1))
            ..setAll(0, applyAsconSbox(chunks))
            ..setAll(0, applyLinearDiffusion(chunks));
          return (p) => [
                sChunks < p.get(currChunk),
                p.get(currChunk) < chunks.swizzle(),
              ];
        }
      }));
}
