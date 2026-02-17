import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/address/data/models/address_model.dart';
import 'package:swipe/features/address/data/services/address_service.dart';

/// Add/Edit Address Screen - Form to create or update delivery address
class AddEditAddressScreen extends StatefulWidget {
  final AddressModel? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final AddressService _addressService = AddressService();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _apartmentController;
  late TextEditingController _landmarkController;
  late TextEditingController _postalCodeController;

  String _selectedCity = 'Tashkent';
  String _selectedRegion = 'Tashkent';
  bool _isDefault = false;
  bool _isSaving = false;

  final List<String> _cities = [
    'Tashkent',
    'Samarkand',
    'Bukhara',
    'Andijan',
    'Fergana',
    'Namangan',
    'Nukus',
    'Qarshi',
    'Termez',
    'Urgench',
    'Jizzakh',
    'Guliston',
  ];

  final Map<String, List<String>> _regionsByCity = {
    'Tashkent': [
      'Tashkent',
      'Chilanzar',
      'Yunusabad',
      'Mirzo Ulugbek',
      'Yakkasaray',
      'Shaykhontohur',
    ],
    'Samarkand': ['Samarkand City', 'Samarkand Region'],
    'Bukhara': ['Bukhara City', 'Bukhara Region'],
    'Andijan': ['Andijan City', 'Andijan Region'],
    'Fergana': ['Fergana City', 'Fergana Region'],
    'Namangan': ['Namangan City', 'Namangan Region'],
    'Nukus': ['Nukus City', 'Karakalpakstan'],
    'Qarshi': ['Qarshi City', 'Kashkadarya'],
    'Termez': ['Termez City', 'Surxondaryo'],
    'Urgench': ['Urgench City', 'Khorezm'],
    'Jizzakh': ['Jizzakh City', 'Jizzakh Region'],
    'Guliston': ['Guliston City', 'Sirdaryo'],
  };

  @override
  void initState() {
    super.initState();
    _addressService.init();

    // Initialize controllers with existing data or empty
    _fullNameController = TextEditingController(
      text: widget.address?.fullName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.address?.phoneNumber ?? '',
    );
    _streetController = TextEditingController(
      text: widget.address?.street ?? '',
    );
    _apartmentController = TextEditingController(
      text: widget.address?.apartmentNumber ?? '',
    );
    _landmarkController = TextEditingController(
      text: widget.address?.landmark ?? '',
    );
    _postalCodeController = TextEditingController(
      text: widget.address?.postalCode ?? '',
    );

    if (widget.address != null) {
      _selectedCity = widget.address!.city;
      _selectedRegion = widget.address!.region;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _apartmentController.dispose();
    _landmarkController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final address = AddressModel(
        id:
            widget.address?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        street: _streetController.text.trim(),
        city: _selectedCity,
        region: _selectedRegion,
        postalCode: _postalCodeController.text.trim(),
        apartmentNumber: _apartmentController.text.trim().isEmpty
            ? null
            : _apartmentController.text.trim(),
        landmark: _landmarkController.text.trim().isEmpty
            ? null
            : _landmarkController.text.trim(),
        isDefault: _isDefault,
        createdAt: widget.address?.createdAt,
        updatedAt: DateTime.now(),
      );

      if (widget.address == null) {
        await _addressService.addAddress(address);
      } else {
        await _addressService.updateAddress(address);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorSavingAddress(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.address != null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkMainBackground
          : AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkMainBackground
            : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? l10n.editAddress : l10n.addNewAddress,
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Contact Information Section
            _buildSectionTitle(l10n.contactInformation),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _fullNameController,
              label: l10n.fullName,
              hint: l10n.enterYourFullName,
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterFullName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _phoneController,
              label: l10n.phoneNumberLabel,
              hint: l10n.phoneNumberHint,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterPhoneNumber;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Address Information Section
            _buildSectionTitle(l10n.addressInformation),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _streetController,
              label: l10n.streetAddress,
              hint: l10n.houseNumberAndStreetName,
              icon: Icons.home_outlined,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterStreetAddress;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _apartmentController,
              label: l10n.apartmentUnitOptional,
              hint: l10n.aptSuiteUnitBuilding,
              icon: Icons.apartment_outlined,
            ),
            const SizedBox(height: 16),

            // City Dropdown
            _buildDropdown(
              label: l10n.city,
              value: _selectedCity,
              items: _cities,
              onChanged: (value) {
                setState(() {
                  _selectedCity = value!;
                  // Reset region to first option when city changes
                  _selectedRegion = _regionsByCity[value]!.first;
                });
              },
            ),
            const SizedBox(height: 16),

            // Region Dropdown
            _buildDropdown(
              label: l10n.regionDistrict,
              value: _selectedRegion,
              items: _regionsByCity[_selectedCity] ?? [],
              onChanged: (value) {
                setState(() {
                  _selectedRegion = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _postalCodeController,
              label: l10n.postalCode,
              hint: l10n.postalCodeHint,
              icon: Icons.markunread_mailbox_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterPostalCode;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _landmarkController,
              label: l10n.landmarkOptional,
              hint: l10n.nearbyLandmarkForDelivery,
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 24),

            // Set as default checkbox
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCardBackground : AppColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: _isDefault,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
                title: Text(
                  l10n.setAsDefault,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  l10n.setAsDefaultAddressDescription,
                  style: AppTypography.caption.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                ),
                activeColor: isDark ? AppColors.white : AppColors.black,
                checkColor: isDark ? AppColors.black : AppColors.white,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.white : AppColors.black,
                  foregroundColor: isDark ? AppColors.black : AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: AppColors.gray400,
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? AppColors.black : AppColors.white,
                        ),
                      )
                    : Text(
                        isEditing ? l10n.updateAddress : l10n.saveAddress,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.black : AppColors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: AppTypography.heading4.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body2.copyWith(
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: TextStyle(color: theme.colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? AppColors.darkTertiaryText : AppColors.gray600,
            ),
            prefixIcon: Icon(
              icon,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkCardBackground : AppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark
                    ? AppColors.darkStandardBorder
                    : AppColors.gray300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: isDark ? AppColors.white : AppColors.black,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body2.copyWith(
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkSecondaryText : AppColors.gray700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBackground : AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.darkStandardBorder : AppColors.gray300,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: Icon(
                Icons.location_city_outlined,
                color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
              ),
            ),
            dropdownColor: isDark
                ? AppColors.darkCardBackground
                : AppColors.white,
          ),
        ),
      ],
    );
  }
}
