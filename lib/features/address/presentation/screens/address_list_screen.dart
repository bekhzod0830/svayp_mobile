import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/features/address/data/models/address_model.dart';
import 'package:swipe/features/address/data/services/address_service.dart';
import 'package:swipe/features/address/presentation/screens/add_edit_address_screen.dart';

/// Address List Screen - Manage delivery addresses
class AddressListScreen extends StatefulWidget {
  final bool isSelectionMode;
  final String? selectedAddressId;

  const AddressListScreen({
    super.key,
    this.isSelectionMode = false,
    this.selectedAddressId,
  });

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  final AddressService _addressService = AddressService();
  List<AddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _isLoading = true;
    });

    await _addressService.init();

    setState(() {
      _addresses = _addressService.getAddresses();
      _isLoading = false;
    });
  }

  Future<void> _addNewAddress() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddEditAddressScreen()),
    );

    if (result == true) {
      await _loadAddresses();
    }
  }

  Future<void> _editAddress(AddressModel address) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditAddressScreen(address: address),
      ),
    );

    if (result == true) {
      await _loadAddresses();
    }
  }

  Future<void> _deleteAddress(AddressModel address) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAddress),
        content: Text(l10n.deleteAddressMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _addressService.deleteAddress(address.id);
      await _loadAddresses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.addressDeleted),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _setDefaultAddress(AddressModel address) async {
    await _addressService.setDefaultAddress(address.id);
    await _loadAddresses();

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.defaultAddressUpdated),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _selectAddress(AddressModel address) {
    if (widget.isSelectionMode) {
      Navigator.pop(context, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
          widget.isSelectionMode ? l10n.selectAddress : l10n.myAddresses,
          style: AppTypography.heading3.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.white : AppColors.black,
              ),
            )
          : _addresses.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final address = _addresses[index];
                return _AddressCard(
                  address: address,
                  isSelected: widget.selectedAddressId == address.id,
                  isSelectionMode: widget.isSelectionMode,
                  onTap: () => _selectAddress(address),
                  onEdit: () => _editAddress(address),
                  onDelete: () => _deleteAddress(address),
                  onSetDefault: () => _setDefaultAddress(address),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewAddress,
        backgroundColor: isDark ? AppColors.white : AppColors.black,
        foregroundColor: isDark ? AppColors.black : AppColors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.addAddress),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 80,
              color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noAddresses,
              style: AppTypography.heading4.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.addDeliveryAddressToContinue,
              style: AppTypography.body2.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.gray600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Address Card Widget
class _AddressCard extends StatelessWidget {
  final AddressModel address;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? (isDark ? AppColors.white : AppColors.black)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.white : AppColors.black).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: isSelectionMode ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and default badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      address.fullName,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (address.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.white : AppColors.black,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.defaultAddress.toUpperCase(),
                        style: AppTypography.caption.copyWith(
                          color: isDark ? AppColors.black : AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Phone number
              Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    address.phoneNumber,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.gray600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address.formattedAddress,
                      style: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.gray700,
                      ),
                    ),
                  ),
                ],
              ),

              if (!isSelectionMode) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 4),

                // Action buttons
                Row(
                  children: [
                    if (!address.isDefault)
                      TextButton.icon(
                        onPressed: onSetDefault,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(l10n.setDefault),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      color: theme.colorScheme.onSurface,
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
