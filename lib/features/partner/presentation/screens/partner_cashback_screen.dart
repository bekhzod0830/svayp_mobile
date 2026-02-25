import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/di/service_locator.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/core/models/product.dart';
import 'package:swipe/core/network/api_client.dart';
import 'package:swipe/features/auth/data/models/auth_models.dart';
import 'package:swipe/features/partner/data/services/partner_service.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/shared/widgets/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:swipe/core/cache/image_cache_manager.dart';

/// Partner Cashback Screen
/// Partners scan a customer's unique QR code, verify the user,
/// select products, and apply cashback/discount before submitting.
class PartnerCashbackScreen extends StatefulWidget {
  const PartnerCashbackScreen({super.key});

  @override
  State<PartnerCashbackScreen> createState() => _PartnerCashbackScreenState();
}

class _PartnerCashbackScreenState extends State<PartnerCashbackScreen> {
  void _openScanner() async {
    final result = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const _QrScannerPage()));
    if (result != null && result.isNotEmpty) {
      _proceedWithUserId(result);
    }
  }

  void _proceedWithUserId(String userId) {
    // Create a basic user object with the scanned ID
    final user = UserResponse(
      id: userId,
      phoneNumber: '', // Will be filled later or from backend
      email: '', // Will be filled later
      fullName: '', // Will be filled later
      isActive: true,
      isVerified: true,
      createdAt: DateTime.now(),
      hasProfile: false,
      cashbackBalance: 0.0,
    );

    // Navigate directly to product selection
    _openProductSelection(user);
  }

  void _openProductSelection(UserResponse user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ProductSelectionScreen(user: user)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkMainBackground : AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Title - Left aligned at top
              Text(
                l10n.partnerCashbackTitle,
                style: AppTypography.heading1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  fontSize: 34,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                l10n.partnerCashbackSubtitle,
                style: AppTypography.body1.copyWith(
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.gray700,
                  fontSize: 17,
                  height: 1.4,
                ),
              ),

              const Spacer(),

              // Scan Button - At bottom
              GestureDetector(
                onTap: _openScanner,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.white : AppColors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 28,
                        color: isDark ? AppColors.black : AppColors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.partnerScanQr,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.black : AppColors.white,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── QR Scanner Page ────────────────────────────────────────────────────────

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  bool _hasScanned = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    // Start camera after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _controller.start();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Stop camera before disposing
    _controller
        .stop()
        .then((_) {
          _controller.dispose();
        })
        .catchError((error) {
          _controller.dispose();
        });
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned || _isDisposed) return;
    final barcode = capture.barcodes.firstOrNull;
    final value = barcode?.rawValue;
    if (value != null && value.isNotEmpty && mounted) {
      _hasScanned = true;
      HapticFeedback.mediumImpact();
      // Stop camera before popping
      _controller.stop().then((_) {
        if (mounted) {
          Navigator.of(context).pop(value);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Stop camera before navigating back
        await _controller.stop();
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            MobileScanner(controller: _controller, onDetect: _onDetect),

            // Overlay with cutout
            CustomPaint(
              painter: _ScannerOverlayPainter(),
              child: const SizedBox.expand(),
            ),

            // Top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        // Stop camera before popping
                        await _controller.stop();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const Spacer(),
                    // Torch toggle
                    IconButton(
                      icon: ValueListenableBuilder(
                        valueListenable: _controller,
                        builder: (_, value, __) => Icon(
                          value.torchState == TorchState.on
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () => _controller.toggleTorch(),
                    ),
                  ],
                ),
              ),
            ),

            // Instruction label
            Align(
              alignment: const Alignment(0, 0.55),
              child: Builder(
                builder: (ctx) => Text(
                  AppLocalizations.of(ctx)!.partnerPointCamera,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a dark overlay with a transparent square cutout in the center.
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cutSize = 260.0;
    final cx = size.width / 2;
    final cy = size.height / 2 - 30;
    final rect = Rect.fromCenter(
      center: Offset(cx, cy),
      width: cutSize,
      height: cutSize,
    );

    final paint = Paint()..color = Colors.black.withOpacity(0.6);
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()
      ..addRect(full)
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Corner brackets
    final bracket = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const bLen = 24.0;
    final r = rect;
    // TL
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(bLen, 0), bracket);
    canvas.drawLine(r.topLeft, r.topLeft + const Offset(0, bLen), bracket);
    // TR
    canvas.drawLine(r.topRight, r.topRight + const Offset(-bLen, 0), bracket);
    canvas.drawLine(r.topRight, r.topRight + const Offset(0, bLen), bracket);
    // BL
    canvas.drawLine(
      r.bottomLeft,
      r.bottomLeft + const Offset(bLen, 0),
      bracket,
    );
    canvas.drawLine(
      r.bottomLeft,
      r.bottomLeft + const Offset(0, -bLen),
      bracket,
    );
    // BR
    canvas.drawLine(
      r.bottomRight,
      r.bottomRight + const Offset(-bLen, 0),
      bracket,
    );
    canvas.drawLine(
      r.bottomRight,
      r.bottomRight + const Offset(0, -bLen),
      bracket,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Product Selection Screen ───────────────────────────────────────────────

class _ProductSelectionScreen extends StatefulWidget {
  final UserResponse user;
  const _ProductSelectionScreen({required this.user});

  @override
  State<_ProductSelectionScreen> createState() =>
      _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<_ProductSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<Product> _selectedProducts = {};
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = getIt<ApiClient>();
      final partnerService = PartnerService(apiClient);

      final response = await partnerService.getSellerProducts(limit: 500);

      if (!mounted) return;

      setState(() {
        _allProducts = response.products;
        _filteredProducts = _allProducts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allProducts;
      } else {
        _filteredProducts = _allProducts.where((product) {
          return product.title.toLowerCase().contains(query) ||
              product.brand.toLowerCase().contains(query) ||
              (product.description?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  void _toggleProduct(Product product) {
    setState(() {
      if (_selectedProducts.contains(product)) {
        _selectedProducts.remove(product);
      } else {
        _selectedProducts.add(product);
      }
    });
  }

  void _continueToCheckout() {
    final l10n = AppLocalizations.of(context)!;

    if (_selectedProducts.isEmpty) {
      SnackBarHelper.showError(context, l10n.partnerSelectAtLeastOne);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CashbackFormScreen(
          user: widget.user,
          selectedProducts: _selectedProducts.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkMainBackground : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkCardBackground
            : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.partnerSelectProducts,
              style: AppTypography.heading4.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
            ),
            Text(
              widget.user.fullName ?? widget.user.phoneNumber,
              style: AppTypography.caption.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: AppTypography.body1.copyWith(
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
              decoration: InputDecoration(
                hintText: l10n.partnerSearchProducts,
                hintStyle: AppTypography.body1.copyWith(
                  color: isDark
                      ? AppColors.darkTertiaryText
                      : AppColors.tertiaryText,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark
                      ? AppColors.darkSecondaryText
                      : AppColors.secondaryText,
                ),
                filled: true,
                fillColor: isDark
                    ? AppColors.darkCardBackground
                    : AppColors.gray50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Selected count badge
          if (_selectedProducts.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_selectedProducts.length} ${l10n.partnerProductsSelected}',
                    style: AppTypography.body2.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Products list
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.partnerLoadingProducts,
                          style: AppTypography.body1.copyWith(
                            color: isDark
                                ? AppColors.darkSecondaryText
                                : AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  )
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: AppTypography.body1.copyWith(
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _loadProducts,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                : _filteredProducts.isEmpty
                ? Center(
                    child: Text(
                      l10n.partnerNoProducts,
                      style: AppTypography.body1.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      final isSelected = _selectedProducts.contains(product);

                      return _ProductListItem(
                        product: product,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () => _toggleProduct(product),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedProducts.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PrimaryButton(
                  text: l10n.partnerContinue,
                  onPressed: _continueToCheckout,
                  isFullWidth: true,
                ),
              ),
            ),
    );
  }
}

// ─── Product List Item ──────────────────────────────────────────────────────

class _ProductListItem extends StatelessWidget {
  final Product product;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _ProductListItem({
    required this.product,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? Colors.green.shade900.withOpacity(0.3)
                    : Colors.green.shade50)
              : (isDark ? AppColors.darkCardBackground : AppColors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.green.shade400
                : (isDark
                      ? AppColors.darkSecondaryText.withOpacity(0.2)
                      : AppColors.gray200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.images.first,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      cacheManager: ImageCacheManager.instance,
                      memCacheWidth: 120,
                      memCacheHeight: 120,
                      errorWidget: (_, __, ___) => const _PlaceholderImage(),
                    )
                  : const _PlaceholderImage(),
            ),
            const SizedBox(width: 12),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.brand,
                    style: AppTypography.caption.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${product.price} ${product.currency}',
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Checkbox
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected
                  ? Colors.green.shade600
                  : (isDark ? AppColors.darkSecondaryText : AppColors.gray400),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 60,
      height: 60,
      color: isDark ? AppColors.darkCardBackground : AppColors.gray100,
      child: Icon(
        Icons.image_outlined,
        color: isDark ? AppColors.darkSecondaryText : AppColors.gray400,
        size: 24,
      ),
    );
  }
}

// ─── Cashback Form Screen (Multiple Products) ──────────────────────────────

class _CashbackFormScreen extends StatefulWidget {
  final UserResponse user;
  final List<Product> selectedProducts;

  const _CashbackFormScreen({
    required this.user,
    required this.selectedProducts,
  });

  @override
  State<_CashbackFormScreen> createState() => _CashbackFormScreenState();
}

class _CashbackFormScreenState extends State<_CashbackFormScreen> {
  final Map<String, _ProductFormData> _productForms = {};
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize form data for each product
    for (final product in widget.selectedProducts) {
      _productForms[product.id] = _ProductFormData(product: product);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final form in _productForms.values) {
      form.dispose();
    }
    super.dispose();
  }

  double get _totalAmount {
    return _productForms.values.fold(0.0, (sum, form) => sum + form.finalPrice);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;

    // Validate all products have required data
    for (final form in _productForms.values) {
      if (form.originalPriceController.text.trim().isEmpty) {
        SnackBarHelper.showError(
          context,
          '${l10n.partnerEnterPrice}: ${form.product.title}',
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = getIt<ApiClient>();
      final partnerService = PartnerService(apiClient);

      // Build cashback items
      final items = _productForms.values.map((form) {
        return CashbackProductItem(
          productId: form.product.id,
          productName: form.product.title,
          size: form.selectedSize,
          color: form.selectedColor,
          quantity: form.quantity,
          originalPrice: double.parse(form.originalPriceController.text),
          discount: double.tryParse(form.discountController.text) ?? 0,
          discountType: form.isPercent ? 'percent' : 'flat',
          finalPrice: form.finalPrice,
        );
      }).toList();

      await partnerService.recordCashback(
        customerId: widget.user.id,
        products: items,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (!mounted) return;

      // Success! Navigate back to main screen
      Navigator.of(context).popUntil((route) => route.isFirst);
      SnackBarHelper.showSuccess(
        context,
        '${l10n.partnerCashbackSuccess} ${l10n.partnerTotal}: ${_totalAmount.toStringAsFixed(0)} UZS',
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, l10n.partnerCashbackFailed);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkMainBackground : AppColors.white,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkCardBackground
            : AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.partnerRecordCashback,
              style: AppTypography.heading4.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimaryText : AppColors.black,
              ),
            ),
            Text(
              widget.user.fullName ?? widget.user.phoneNumber,
              style: AppTypography.caption.copyWith(
                color: isDark
                    ? AppColors.darkSecondaryText
                    : AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Products forms
          ..._productForms.values.map((form) {
            return _ProductFormCard(
              form: form,
              isDark: isDark,
              onChanged: () => setState(() {}),
            );
          }),

          const SizedBox(height: 16),

          // Total display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isDark ? Colors.green.shade900 : Colors.green.shade50)
                  .withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade400, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.partnerTotal,
                  style: AppTypography.heading4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkPrimaryText : AppColors.black,
                  ),
                ),
                Text(
                  '${_totalAmount.toStringAsFixed(0)} UZS',
                  style: AppTypography.heading3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notes
          _SectionLabel(l10n.partnerNotesLabel, isDark: isDark),
          const SizedBox(height: 8),
          _FormField(
            controller: _notesController,
            hint: l10n.partnerNotesHint,
            prefix: Icons.notes_rounded,
            isDark: isDark,
            maxLines: 3,
          ),

          const SizedBox(height: 32),

          // Submit button
          PrimaryButton(
            text: l10n.partnerRecordCashback,
            onPressed: _submit,
            isLoading: _isLoading,
            isFullWidth: true,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Product Form Data ──────────────────────────────────────────────────────

class _ProductFormData {
  final Product product;
  final TextEditingController originalPriceController;
  final TextEditingController discountController;
  int quantity = 1;

  String? selectedSize;
  String? selectedColor;
  bool isPercent = true;

  _ProductFormData({required this.product})
    : originalPriceController = TextEditingController(
        text: product.price.toString(),
      ),
      discountController = TextEditingController(text: '0');

  double get finalPrice {
    final original = double.tryParse(originalPriceController.text) ?? 0;
    final discount = double.tryParse(discountController.text) ?? 0;
    double pricePerItem;
    if (isPercent) {
      pricePerItem = original - (original * discount / 100);
    } else {
      pricePerItem = (original - discount).clamp(0, double.infinity);
    }
    return pricePerItem * quantity;
  }

  void incrementQuantity() {
    if (quantity < 99) {
      quantity++;
    }
  }

  void decrementQuantity() {
    if (quantity > 1) {
      quantity--;
    }
  }

  void dispose() {
    originalPriceController.dispose();
    discountController.dispose();
  }
}

// ─── Product Form Card ──────────────────────────────────────────────────────

class _ProductFormCard extends StatelessWidget {
  final _ProductFormData form;
  final bool isDark;
  final VoidCallback onChanged;

  const _ProductFormCard({
    required this.form,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final product = form.product;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.darkSecondaryText.withOpacity(0.2)
              : AppColors.gray200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.images.first,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        cacheManager: ImageCacheManager.instance,
                        memCacheWidth: 100,
                        memCacheHeight: 100,
                        errorWidget: (_, __, ___) => const _PlaceholderImage(),
                      )
                    : const _PlaceholderImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkPrimaryText
                            : AppColors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      product.brand,
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkSecondaryText
                            : AppColors.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Size selection (if product has sizes)
          if (product.sizes != null && product.sizes!.isNotEmpty) ...[
            _SectionLabel(l10n.partnerSizeLabel, isDark: isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: product.sizes!.map((sizeEnum) {
                final size = sizeEnum.toString().split('.').last.toUpperCase();
                final selected = form.selectedSize == size;
                return GestureDetector(
                  onTap: () {
                    form.selectedSize = selected ? null : size;
                    onChanged();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? (isDark ? AppColors.white : AppColors.black)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected
                            ? (isDark ? AppColors.white : AppColors.black)
                            : (isDark
                                  ? AppColors.darkSecondaryText.withOpacity(0.3)
                                  : AppColors.gray300),
                      ),
                    ),
                    child: Text(
                      size,
                      style: AppTypography.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? (isDark ? AppColors.black : AppColors.white)
                            : (isDark
                                  ? AppColors.darkPrimaryText
                                  : AppColors.black),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Color selection (if product has colors)
          if (product.colors != null && product.colors!.isNotEmpty) ...[
            _SectionLabel(l10n.partnerColorLabel, isDark: isDark),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: product.colors!.map((colorHex) {
                final isSelected = form.selectedColor == colorHex;
                final color = _parseColor(colorHex);

                return GestureDetector(
                  onTap: () {
                    form.selectedColor = isSelected ? null : colorHex;
                    onChanged();
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.blue
                            : (isDark
                                  ? AppColors.darkSecondaryText.withOpacity(0.4)
                                  : AppColors.gray300),
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: _isLightColor(color)
                                ? Colors.black
                                : Colors.white,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Quantity
          _SectionLabel(l10n.quantity, isDark: isDark),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark
                    ? AppColors.darkSecondaryText.withOpacity(0.3)
                    : AppColors.gray300,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.quantity,
                  style: AppTypography.body2.copyWith(
                    color: isDark
                        ? AppColors.darkSecondaryText
                        : AppColors.secondaryText,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.gray300,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          form.decrementQuantity();
                          onChanged();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${form.quantity}',
                          style: AppTypography.body2.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          form.incrementQuantity();
                          onChanged();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: isDark
                                ? AppColors.darkPrimaryText
                                : AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pricing
          _SectionLabel(l10n.partnerPricingLabel, isDark: isDark),
          const SizedBox(height: 8),
          _FormField(
            controller: form.originalPriceController,
            hint: l10n.partnerOriginalPriceHint,
            prefix: Icons.price_change_outlined,
            isDark: isDark,
            keyboardType: TextInputType.number,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),

          // Discount row
          Row(
            children: [
              Expanded(
                child: _FormField(
                  controller: form.discountController,
                  hint: form.isPercent
                      ? l10n.partnerDiscountPercent
                      : l10n.partnerDiscountAmount,
                  prefix: Icons.discount_outlined,
                  isDark: isDark,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  form.isPercent = !form.isPercent;
                  onChanged();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCardBackground
                        : AppColors.gray100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkSecondaryText.withOpacity(0.3)
                          : AppColors.gray200,
                    ),
                  ),
                  child: Text(
                    form.isPercent ? '%' : 'UZS',
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.darkPrimaryText
                          : AppColors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Final price display
          if (form.originalPriceController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.white : AppColors.black).withOpacity(
                  0.05,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.partnerFinalPriceLabel,
                    style: AppTypography.body2.copyWith(
                      color: isDark
                          ? AppColors.darkSecondaryText
                          : AppColors.secondaryText,
                    ),
                  ),
                  Text(
                    '${form.finalPrice.toStringAsFixed(0)} UZS',
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _parseColor(String colorHex) {
    try {
      if (colorHex.startsWith('#')) {
        return Color(int.parse(colorHex.substring(1), radix: 16) + 0xFF000000);
      }
      return Color(int.parse(colorHex, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  bool _isLightColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5;
  }
}

// ─── Helper Widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.body2.copyWith(
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.darkPrimaryText : AppColors.black,
    ),
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefix;
  final bool isDark;
  final TextInputType keyboardType;
  final int maxLines;
  final void Function(String)? onChanged;

  const _FormField({
    required this.controller,
    required this.hint,
    required this.prefix,
    required this.isDark,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      style: AppTypography.body1.copyWith(
        color: isDark ? AppColors.darkPrimaryText : AppColors.black,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTypography.body1.copyWith(
          color: isDark ? AppColors.darkTertiaryText : AppColors.gray400,
        ),
        prefixIcon: Icon(
          prefix,
          size: 20,
          color: isDark ? AppColors.darkSecondaryText : AppColors.secondaryText,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkCardBackground : AppColors.gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.darkSecondaryText.withOpacity(0.3)
                : AppColors.gray200,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? AppColors.darkSecondaryText.withOpacity(0.3)
                : AppColors.gray200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkPrimaryText : AppColors.black,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
