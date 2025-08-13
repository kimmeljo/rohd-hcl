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
  /// Underlying config object for the provided CSR being represented.
  late final CsrInstanceConfig config;

  final Map<String, LogicValue> _fieldMap = {};
  late LogicValue _noFieldRegVal;

  /// Convenience mechanism for the [CsrValue]'s width.
  int get width => config.width;

  /// Constructor.
  CsrValue({required CsrInstanceConfig config}) {
    this.config = config.clone();
    for (final field in config.fields) {
      final l = LogicValue.ofInt(config.resetValue, config.width)
          .getRange(field.start, field.start + field.width);
      _fieldMap[field.name] = l;
    }
    _noFieldRegVal = LogicValue.ofInt(config.resetValue, config.width);
  }

  /// Set a given field to a given value.
  void setRegisterFieldVal(
      {required String fieldName, required dynamic fieldValue}) {
    if (!_fieldMap.containsKey(fieldName)) {
      throw CsrValidationException('Field $fieldName does not exist '
          'in register ${config.name}');
    }
    _fieldMap[fieldName] =
        LogicValue.of(fieldValue, width: _fieldMap[fieldName]!.width);
  }

  /// Set the entire register to a given value.
  void setRegisterVal({required dynamic value}) {
    final lv = LogicValue.of(value, width: config.width);
    if (config.fields.isEmpty) {
      _noFieldRegVal = lv;
    } else {
      for (final field in config.fields) {
        final l = lv.getRange(field.start, field.start + field.width);
        _fieldMap[field.name] = l;
      }
    }
  }

  /// Retrieve the current value of a given field.
  LogicValue getRegisterFieldVal({required String fieldName}) {
    if (!_fieldMap.containsKey(fieldName)) {
      throw CsrValidationException('Field $fieldName does not exist '
          'in register ${config.name}');
    }
    return _fieldMap[fieldName]!;
  }

  /// Retrieve the current value of the register.
  LogicValue getRegisterVal() {
    if (config.fields.isEmpty) {
      return _noFieldRegVal;
    } else {
      final vals = <LogicValue>[];
      var currIdx = 0;
      for (final field in config.fields) {
        if (currIdx < field.start) {
          vals.add(LogicValue.ofInt(config.resetValue, config.width)
              .getRange(currIdx, field.start));
          currIdx = field.start;
        }
        vals.add(_fieldMap[field.name]!);
        currIdx = field.start + field.width;
      }
      if (currIdx < config.width) {
        vals.add(LogicValue.ofInt(config.resetValue, config.width)
            .getRange(currIdx));
      }
      return vals.rswizzle();
    }
  }
}

/// Method to drive a [CsrValue] through a frontdoor write.
///
/// The write can be either to a [CsrBlock] or a [CsrTop].
/// In the case of [CsrTop], the user should provide
/// the target block's [CsrBlockConfig].
Future<void> driveCsrValue(
    {required CsrValue value,
    required Interface<dynamic> intf,
    required Logic clk,
    CsrBlockConfig? block,
    int? logicalRegisterIncrement}) async {
  if (intf is DataPortInterface) {
    final addr = value.config.addr + (block?.baseAddr ?? 0);
    if (value.width <= intf.dataWidth) {
      await clk.nextNegedge;
      intf.en.put(1);
      intf.addr.put(addr);
      intf.data.put(value.getRegisterVal().zeroExtend(intf.dataWidth));
      await clk.nextNegedge;
      intf.en.put(0);
    } else {
      final wrCnt = (value.width / intf.dataWidth).ceil();
      final addrIncr = logicalRegisterIncrement ?? 1;
      for (var i = 0; i < wrCnt; i++) {
        await clk.nextNegedge;
        intf.en.put(1);
        intf.addr.put(addr + (i * addrIncr));
        final endIdx = (i + 1) * intf.dataWidth > value.width
            ? value.width
            : (i + 1) * intf.dataWidth;
        intf.data
            .put(value.getRegisterVal().getRange(i * intf.dataWidth, endIdx));
      }
      await clk.nextNegedge;
      intf.en.put(0);
    }
  }

  // backdoor access
  else if (intf is CsrBackdoorInterface) {
    if (intf.wrEn == null) {
      throw CsrValidationException('The provided CsrBackdoorInterface is not '
          'backdoor writeable.');
    }
    await clk.nextNegedge;
    intf.wrEn!.put(1);
    intf.wrData!.put(value.getRegisterVal());
    await clk.nextNegedge;
    intf.wrEn!.put(0);
  }

  // invalid input
  else {
    throw CsrValidationException('The provided interface cannot be '
        'used to access a CSR.');
  }
}

/// Method to capture a [CsrValue] through a frontdoor read.
///
/// The read can be either to a [CsrBlock] or a [CsrTop].
/// In the case of [CsrTop], the user should provide
/// the target block's [CsrBlockConfig].
///
/// Note that all reads have a latency of 1 cycle.
Future<void> captureCsrValue(
    {required CsrValue value,
    required Interface<dynamic> intf,
    required Logic clk,
    CsrBlockConfig? block,
    int? logicalRegisterIncrement}) async {
  // frontdoor access
  if (intf is DataPortInterface) {
    final addr = value.config.addr + (block?.baseAddr ?? 0);
    if (value.width <= intf.dataWidth) {
      await clk.nextNegedge;
      intf.en.put(1);
      intf.addr.put(addr);
      await clk.nextNegedge;
      value.setRegisterVal(value: intf.data.value.getRange(0, value.width));
    } else {
      final wrCnt = (value.width / intf.dataWidth).ceil();
      final addrIncr = logicalRegisterIncrement ?? 1;
      final vals = <LogicValue>[];
      for (var i = 0; i < wrCnt; i++) {
        await clk.nextNegedge;
        intf.en.put(1);
        intf.addr.put(addr + (i * addrIncr));
        await clk.nextNegedge;
        final endIdx = (i + 1) * intf.dataWidth > value.width
            ? (i + 1) * intf.dataWidth - value.width
            : intf.dataWidth;
        vals.add(intf.data.value.getRange(0, endIdx));
      }
      value.setRegisterVal(value: vals.rswizzle());
    }
  }

  // backdoor access
  else if (intf is CsrBackdoorInterface) {
    if (intf.rdData == null) {
      throw CsrValidationException('The provided CsrBackdoorInterface is not '
          'backdoor readable.');
    }
    value.setRegisterVal(value: intf.rdData!.value);
  }

  // invalid input
  else {
    throw CsrValidationException('The provided interface cannot be '
        'used to access a CSR.');
  }
}
