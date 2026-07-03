import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe/core/constants/countries.dart';
import 'package:swipe/core/utils/validators.dart';
import 'package:swipe/shared/widgets/custom_input.dart';

/// Applies [PhoneTextField]'s input formatters (length limit + grouping) the way
/// a TextField would, so we can assert the visible formatting per country.
String formatFor(Country country, String typed) {
  final formatters = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(country.maxLength),
    phoneNumberFormatterForTest(country),
  ];
  // The formatters recompute from the full text each edit, so applying them
  // once to the whole input (as if pasted) yields the final display string.
  var value = TextEditingValue(
    text: typed,
    selection: TextSelection.collapsed(offset: typed.length),
  );
  for (final f in formatters) {
    value = f.formatEditUpdate(TextEditingValue.empty, value);
  }
  return value.text;
}

void main() {
  group('Country catalogue', () {
    test('Uzbekistan is the default and first entry', () {
      expect(Countries.defaultCountry.isoCode, 'UZ');
      expect(Countries.all.first, Countries.uzbekistan);
    });

    test('byDialCode resolves with and without the leading +', () {
      expect(Countries.byDialCode('+998')?.isoCode, 'UZ');
      expect(Countries.byDialCode('998')?.isoCode, 'UZ');
      expect(Countries.byDialCode('+44')?.isoCode, 'GB');
    });

    test('byIsoCode is case-insensitive', () {
      expect(Countries.byIsoCode('us')?.dialCode, '+1');
      expect(Countries.byIsoCode('TR')?.name, 'Turkey');
    });

    test('search matches name, iso code, and dial code digits', () {
      expect(Countries.search('turk').any((c) => c.isoCode == 'TR'), isTrue);
      expect(Countries.search('GB').any((c) => c.isoCode == 'GB'), isTrue);
      expect(Countries.search('+998').any((c) => c.isoCode == 'UZ'), isTrue);
      expect(Countries.search('zzzzz'), isEmpty);
    });

    test('dial codes all start with + and iso codes are two letters', () {
      for (final c in Countries.all) {
        expect(c.dialCode.startsWith('+'), isTrue, reason: c.name);
        expect(c.isoCode.length, 2, reason: c.name);
        expect(c.minLength <= c.maxLength, isTrue, reason: c.name);
      }
    });
  });

  group('Validators.phone is country-aware', () {
    test('Uzbekistan requires exactly 9 national digits', () {
      expect(Validators.phone('90 123 45 67'), isNull); // 9 digits
      expect(Validators.phone('90 123 45'), isNotNull); // 7 digits, too short
      expect(Validators.phone('90 123 45 678'), isNotNull); // 10, too long
    });

    test('empty value is rejected', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone(null), isNotNull);
    });

    test('other countries validate against their own length', () {
      final us = Countries.byIsoCode('US')!; // 10 digits
      expect(Validators.phone('2015550123', country: us), isNull);
      expect(Validators.phone('201555', country: us), isNotNull);

      final tm = Countries.byIsoCode('TM')!; // Turkmenistan, 8 digits
      expect(Validators.phone('61234567', country: tm), isNull);
      expect(Validators.phone('612345678', country: tm), isNotNull);
    });
  });

  group('Phone input formatting', () {
    test('Uzbekistan groups as 2 3 2 2', () {
      expect(formatFor(Countries.uzbekistan, '901234567'), '90 123 45 67');
    });

    test('length is capped at the country max', () {
      // UZ max is 9 — extra digits are dropped by the length limiter.
      expect(formatFor(Countries.uzbekistan, '9012345678999'), '90 123 45 67');
    });

    test('countries without an example fall back to groups of three', () {
      final bg = Countries.byIsoCode('BG')!; // no example defined
      expect(formatFor(bg, '881234567'), '881 234 567');
    });
  });
}
