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
class CsrVal {
  late final String _name;
  final Map<String, Logic> _fieldMap = {};
  late final LogicStructure _struct;

  /// Constructor.
  CsrVal({required CsrConfig config}) {
    _name = config.name;
    final fields = <Logic>[];
    var currIdx = 0;
    for (final field in config.fields) {
      if (field.start < currIdx) {
        fields.add(Logic(width: field.start - currIdx));
        currIdx = field.start;
      }
      final l = Logic(width: field.width);
      fields.add(l);
      _fieldMap[field.name] = l;
      currIdx = field.start + field.width;
    }
    _struct = LogicStructure(fields);
  }

  /// Set a given field to a given value.
  void setRegisterFieldVal(
      {required String fieldName, required dynamic fieldValue}) {
    if (!_fieldMap.containsKey(fieldName)) {
      throw CsrValidationException('Field $fieldName does not exist '
          'in register $_name');
    }
    _fieldMap[fieldName]!.put(fieldValue);
  }

  /// Set the entire register to a given value.
  void setRegisterVal({required dynamic value}) {
    _struct.put(value);
  }

  /// Retrieve the current value of a given field.
  LogicValue getFieldVal({required String fieldName}) {
    if (!_fieldMap.containsKey(fieldName)) {
      throw CsrValidationException('Field $fieldName does not exist '
          'in register $_name');
    }
    return _fieldMap[fieldName]!.value;
  }

  /// Retrieve the current value of the register.
  LogicValue getRegisterVal() => _struct.value;
}
