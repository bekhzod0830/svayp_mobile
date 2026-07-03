import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/constants/countries.dart';
import 'package:swipe/shared/widgets/country_code_picker.dart';

/// Custom Text Input Field
class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.body2.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          onTap: onTap,
          validator: validator,
          enabled: enabled,
          readOnly: readOnly,
          maxLines: maxLines,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          autofocus: autofocus,
          textCapitalization: textCapitalization,
          style: AppTypography.body1,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.body1.copyWith(
              color: AppColors.placeholderText,
            ),
            errorText: errorText,
            helperText: helperText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: AppColors.gray600)
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, color: AppColors.gray600),
                    onPressed: onSuffixIconTap,
                  )
                : null,
            filled: true,
            fillColor: enabled ? AppColors.white : AppColors.gray100,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.standardBorder,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.standardBorder,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.black, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: AppColors.gray300,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Phone Number Input Field
///
/// Renders a tappable country flag + dial-code prefix and a national-number
/// field. Tapping the prefix opens [CountryCodePicker]; the chosen [Country] is
/// reported back through [onCountryChanged] so the parent can rebuild and
/// assemble the full E.164 number. Digit grouping and the max input length are
/// driven by the selected [country].
class PhoneTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Currently selected country (drives the prefix, hint and length limit).
  final Country country;

  /// Called with the newly picked country when the user taps the prefix and
  /// selects a different one. When null, the country prefix is not tappable.
  final ValueChanged<Country>? onCountryChanged;

  const PhoneTextField({
    super.key,
    this.controller,
    this.label,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.autofocus = false,
    this.country = Countries.defaultCountry,
    this.onCountryChanged,
  });

  Future<void> _pickCountry(BuildContext context) async {
    if (onCountryChanged == null) return;
    final selected = await CountryCodePicker.show(context, selected: country);
    if (selected != null && selected != country) {
      onCountryChanged!(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPick = onCountryChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.body2.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          onChanged: onChanged,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          autofocus: autofocus,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(country.maxLength),
            _PhoneNumberFormatter(country: country),
          ],
          style: AppTypography.body1.copyWith(
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          decoration: InputDecoration(
            hintText: country.example ?? '',
            hintStyle: AppTypography.body1.copyWith(
              color: isDark
                  ? AppColors.darkPlaceholderText
                  : AppColors.placeholderText,
            ),
            errorText: errorText,
            prefixIcon: InkWell(
              onTap: canPick ? () => _pickCountry(context) : null,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(country.flag, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 6),
                    Text(
                      country.dialCode,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                      ),
                    ),
                    if (canPick)
                      Icon(
                        Icons.arrow_drop_down,
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                      ),
                  ],
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            filled: true,
            fillColor: isDark ? AppColors.darkCardBackground : AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.standardBorder,
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.standardBorder,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Phone Number Formatter
///
/// Inserts spaces so the typed national number reads in the grouping natural to
/// the selected [country] (derived from its example, e.g. "90 123 45 67").
/// Countries without an example fall back to generic groups of three.
class _PhoneNumberFormatter extends TextInputFormatter {
  final Country country;

  _PhoneNumberFormatter({required this.country});

  /// Groups [digits] according to [sizes]; anything beyond the template groups
  /// in threes so long numbers still stay readable.
  String _group(String digits, List<int> sizes) {
    if (digits.isEmpty) return '';
    final buffer = StringBuffer();
    int i = 0;
    int g = 0;
    while (i < digits.length) {
      int size = g < sizes.length ? sizes[g] : 3;
      if (size <= 0) size = 3;
      final end = (i + size) > digits.length ? digits.length : i + size;
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(digits.substring(i, end));
      i = end;
      g++;
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Build formatted string using the country's grouping, e.g. "90 123 45 67".
    final formatted = _group(digitsOnly, country.digitGroupSizes);

    // Calculate cursor position
    int cursorPosition = newValue.selection.baseOffset;
    int newCursorPosition = cursorPosition;

    // If user is typing (text getting longer), place cursor at end
    if (newValue.text.length >= oldValue.text.length) {
      newCursorPosition = formatted.length;
    } else {
      // If user is deleting, adjust cursor position accounting for spaces
      final digitsBeforeCursor = newValue.text
          .substring(0, cursorPosition)
          .replaceAll(RegExp(r'\D'), '')
          .length;

      // Count characters including spaces up to this digit position
      int charCount = 0;
      int digitCount = 0;
      for (
        int i = 0;
        i < formatted.length && digitCount < digitsBeforeCursor;
        i++
      ) {
        charCount++;
        if (formatted[i] != ' ') {
          digitCount++;
        }
      }
      newCursorPosition = charCount;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }
}

/// Test-only accessor for the private country-aware phone formatter.
@visibleForTesting
TextInputFormatter phoneNumberFormatterForTest(Country country) =>
    _PhoneNumberFormatter(country: country);

/// OTP Input Field (4 digits)
class OtpTextField extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final ValueChanged<String>? onCompleted;
  final String? errorText;

  const OtpTextField({
    super.key,
    required this.controllers,
    required this.focusNodes,
    this.onCompleted,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            4,
            (index) => SizedBox(
              width: 60,
              height: 60,
              child: TextFormField(
                controller: controllers[index],
                focusNode: focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: AppTypography.heading2,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.standardBorder,
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.standardBorder,
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.black,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.error,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    if (index < 3) {
                      focusNodes[index + 1].requestFocus();
                    } else {
                      // Last digit entered
                      focusNodes[index].unfocus();
                      if (onCompleted != null) {
                        final otp = controllers
                            .map((controller) => controller.text)
                            .join();
                        onCompleted!(otp);
                      }
                    }
                  } else if (value.isEmpty && index > 0) {
                    focusNodes[index - 1].requestFocus();
                  }
                },
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: AppTypography.caption.copyWith(color: AppColors.error),
          ),
        ],
      ],
    );
  }
}

/// Search Input Field
class SearchTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final FocusNode? focusNode;
  final bool autofocus;

  const SearchTextField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: AppTypography.body1,
      decoration: InputDecoration(
        hintText: hintText ?? 'Search...',
        hintStyle: AppTypography.body1.copyWith(
          color: AppColors.placeholderText,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.gray600,
          size: 20,
        ),
        suffixIcon: controller?.text.isNotEmpty ?? false
            ? IconButton(
                icon: const Icon(
                  Icons.clear,
                  color: AppColors.gray600,
                  size: 20,
                ),
                onPressed: () {
                  controller?.clear();
                  onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.standardBorder,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.standardBorder,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: AppColors.black, width: 2),
        ),
      ),
    );
  }
}
