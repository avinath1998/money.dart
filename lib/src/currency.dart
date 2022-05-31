/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2016 - 2019 LitGroup LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the 'Software'), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import 'dart:math';

import 'package:meta/meta.dart';

import 'money.dart';
import 'pattern_decoder.dart';

/// Allows you to create a [Currency] which is then used to construct
/// [Money] instances.
///
/// **NOTE: This is a value type, do not extend or re-implement it.**
///
/// Money2 does not create a default set of currencies instead you need
/// to explicitly create each currency type you want to use.
///
/// Normally you create one global currency instance for each currency type.
/// If you wish you can register each [Currency] instance with the
/// [Currencies] class which then is able to provides a global directory of
/// [Currency] instances.
///
//@sealed
@immutable
class Currency {
  static const String defaultPattern = 'S0.00';

  /// Creates a currency with a given [code] and [scale].
  ///
  /// * [code] - the currency code e.g. USD
  /// * [scale] - the number of digits after the decimal place the
  /// the currency uses. e.g. 2 for USD as it uses cents to 2 digits.
  /// * [pattern] - the default output format used when you call toString
  /// on a Money instance created with this currency. See [Money.format]
  /// for details on the supported patterns.
  /// * [inverSeparator] - normally the decimal separator is '.' and the
  /// group separator is ','. When this value is true (defaults to false)
  /// then the separators are swapped. This is needed for most non English
  /// speaking [Currency]s.
  Currency.create(this.code, this.scale,
      {this.symbol = r'$',
      this.pattern = defaultPattern,
      this.invertSeparators = false,
      this.country = '',
      this.unit = '',
      this.name = ''})
      : scaleFactor = Currency._calcPrecisionFactor(scale),
        decimalSeparator = invertSeparators ? ',' : '.',
        groupSeparator = invertSeparators ? '.' : ',' {
    if (code.isEmpty) {
      throw ArgumentError.value(code, 'code', 'Must be a non-empty string.');
    }
  }

  /// Creates a [Currency] from an existing [Currency] with changes.
  Currency copyWith({
    String? code,
    int? precision,
    String? symbol,
    String? pattern,
    bool? invertSeparators,
  }) {
    return Currency.create(code ?? this.code, precision ?? scale,
        symbol: symbol ?? this.symbol,
        pattern: pattern ?? this.pattern,
        invertSeparators: invertSeparators ?? this.invertSeparators);
  }

  /// Takes a monetary amount encoded as a string
  /// and converts it to a [Money] instance.
  ///
  /// You can pass in a [pattern] to define the
  /// format of the [monetaryAmount].
  /// If you don't pass in a [pattern] then the [Currency]s
  /// default pattern is used.
  ///
  /// If the number of minorUnits in [monetaryAmount]
  /// exceeds the [Currency]s precision then excess digits will be ignored.
  ///
  /// Currency aud = Currency.create('AUD', 2);
  /// Money audAmount = aud.parse('10.50');
  ///
  /// A [MoneyParseException] is thrown if the [monetarAmount]
  /// doesn't match the [pattern].
  ///
  Money parse(String monetaryAmount, {String? pattern}) {
    pattern ??= this.pattern;
    final decoder = PatternDecoder(this, pattern);
    final moneyData = decoder.decode(monetaryAmount);

    return Money.fromFixedWithCurrency(moneyData.amount, this);
  }

  /// The code of the currency (e.g. 'USD').
  final String code;

  /// The currency symbol (e.g. $)
  final String symbol;

  /// The number of decimals for the currency (zero or more).
  final int scale;

  /// The factor of 10 to divide a minor value by to get the intended
  /// currency value.
  ///
  ///  e.g. if [scale] is 2 then this value will be 100.
  final BigInt scaleFactor;

  /// the default pattern used to format and parse monetary amounts for this
  /// currency.
  final String pattern;

  /// Full name of the currency. e.g. Australian Dollar
  final String country;

  /// The major units of the currency. e.g. 'Dollar'
  final String unit;

  /// The name of the currency. e.g. Australian Dollar
  final String name;

  /// Most western currencies use the period as the decimal separator
  /// and comma for formating.
  ///
  // Some other currencies invert the use of periods and commas.
  /// If this value is true then the use of the period and comma is swapped.
  final bool invertSeparators;

  /// The character used for the decimal place
  final String decimalSeparator;

  /// The character used for the group separator.
  final String groupSeparator;

  @override
  int get hashCode => code.hashCode;

  /// Two currencies are considered equivalent if the
  /// [code] and [scale] are the same.
  ///
  /// Are we breaking the semantics of the == operator?
  /// Maybe we need another method that just compares the code?
  @override
  bool operator ==(Object other) {
    if (other is! Currency) {
      return false;
    }
    return identical(this, other) ||
        (code == other.code && scale == other.scale);
  }

  static BigInt _calcPrecisionFactor(int precision) {
    if (precision.isNegative) {
      throw ArgumentError.value(
          precision, 'precision', 'Must be a non-negative value.');
    }
    return BigInt.from(pow(10, precision));
  }

  /// Takes a [majorUnits] and a [minorUnits] and returns
  /// a BigInt which represents the two combined values in
  /// [minorUnits].
  BigInt toMinorUnits(BigInt majorUnits, BigInt minorUnits) {
    return majorUnits * scaleFactor + minorUnits;
  }
}
