// Copyright (C) 2024-2025 Intel Corporation SPDX-License-Identifier:
// BSD-3-Clause
//
// csr_val.dart A validation focused representation of the Csr enabling easy
// field manipulation.
//
// 2025 August Author: Josh Kimmel <joshua1.kimmel@intel.com>

import 'package:rohd/rohd.dart';
import 'package:rohd_hcl/rohd_hcl.dart';

/// A class to help facilitate validation's interactions with a Csr.
///
/// Offers simple APIs for getting and setting fields by name.
/// Offers simple APIs for getting and setting the full register.
///
/// The purpose is to use this class to perform reads and writes
/// of HW CSRs without having to derive fields.
class CsrValue {
  late final CsrConfig _config;
  late final int _regWidth;
  final Map<String, LogicValue> _fieldMap = {};

  // /// Helper to translate a dynamic input into a LogicValue.
  // static LogicValue fromInput(dynamic input, {required int width}) {
  //   if (input is LogicValue) {
  //     return input;
  //   } else if (input is int) {
  //     return LogicValue.ofInt(input, width);
  //   } else if (input is BigInt) {
  //     return LogicValue.ofBigInt(input, width);
  //   } else if (input is String) {
  //     return LogicValue.ofString(input);
  //   } else if (input is bool) {
  //     return LogicValue.ofBool(input);
  //   } else {
  //     throw CsrValidationException(
  //         'Unrecognized input format for CsrValue logic $input');
  //   }
  // }

  /// Constructor.
  CsrValue({required CsrConfig config}) {
    _config = config.clone();
    final fields = <LogicValue>[];
    var currIdx = 0;
    for (final field in config.fields) {
      if (currIdx < field.start) {
        fields.add(LogicValue.ofInt(0x0, field.start - currIdx));
        currIdx = field.start;
      }
      final l = LogicValue.ofInt(field.resetValue, field.width);
      fields.add(l);
      _fieldMap[field.name] = l;
      currIdx = field.start + field.width;
    }
    _regWidth = currIdx;
  }

  /// Set a given field to a given value.
  void setRegisterFieldVal(
      {required String fieldName, required LogicValue fieldValue}) {
    if (!_fieldMap.containsKey(fieldName)) {
      throw CsrValidationException('Field $fieldName does not exist '
          'in register ${_config.name}');
    }
    if (_fieldMap[fieldName]!.width != fieldValue.width) {
      throw CsrValidationException(
          'The provided field width ${fieldValue.width} '
          'does not match the given '
          'fields width ${_fieldMap[fieldName]!.width}.');
    }
    _fieldMap[fieldName] = fieldValue;
  }

  /// Set the entire register to a given value.
  void setRegisterVal({required LogicValue value}) {
    if (_regWidth != value.width) {
      throw CsrValidationException('The provided values width ${value.width} '
          'does not match the given '
          'registers width $_regWidth.');
    }
    for (final field in _config.fields) {
      final l = value.getRange(field.start, field.start + field.width);
      _fieldMap[field.name] = l;
    }
  }

  /// Retrieve the current value of a given field.
  LogicValue getRegisterFieldVal({required String fieldName}) {
    if (!_fieldMap.containsKey(fieldName)) {
      throw CsrValidationException('Field $fieldName does not exist '
          'in register ${_config.name}');
    }
    return _fieldMap[fieldName]!;
  }

  /// Retrieve the current value of the register.
  LogicValue getRegisterVal() {
    final vals = <LogicValue>[];
    var currIdx = 0;
    for (final field in _config.fields) {
      if (currIdx < field.start) {
        vals.add(LogicValue.ofInt(0x0, field.start - currIdx));
        currIdx = field.start;
      }
      vals.add(_fieldMap[field.name]!);
      currIdx = field.start + field.width;
    }
    return vals.rswizzle();
  }
}
