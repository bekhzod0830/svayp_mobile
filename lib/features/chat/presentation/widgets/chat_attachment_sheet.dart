import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart' hide LatLng;
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/l10n/app_localizations.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Public result type
// ──────────────────────────────────────────────────────────────────────────────

/// Sealed result from the attachment bottom sheet.
sealed class AttachmentResult {
  const AttachmentResult();
}

class ImageAttachment extends AttachmentResult {
  final List<File> files;
  const ImageAttachment(this.files);
}

class LocationAttachment extends AttachmentResult {
  final LatLng latLng;
  const LocationAttachment(this.latLng);
}

// ──────────────────────────────────────────────────────────────────────────────
// Entry point
// ──────────────────────────────────────────────────────────────────────────────

/// Opens the SVAYP-styled attachment bottom sheet.
/// Returns an [AttachmentResult] when the user taps Send, or null on dismiss.
Future<AttachmentResult?> showChatAttachmentSheet(BuildContext context) {
  return showModalBottomSheet<AttachmentResult>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => const _AttachmentSheetContent(),
  );
}

// ──────────────────────────────────────────────────────────────────────────────
// Internal sheet widget
// ──────────────────────────────────────────────────────────────────────────────

enum _Tab { gallery, location }

class _AttachmentSheetContent extends StatefulWidget {
  const _AttachmentSheetContent();

  @override
  State<_AttachmentSheetContent> createState() =>
      _AttachmentSheetContentState();
}

class _AttachmentSheetContentState extends State<_AttachmentSheetContent> {
  _Tab _activeTab = _Tab.gallery;
  final List<File> _selectedImages = [];
  File? _cameraCapture;
  LatLng? _selectedLocation;
  bool _loadingLocation = false;
  bool _mapEverOpened = false;

  GoogleMapController? _mapController;

  // Default to Tashkent if location is unavailable
  LatLng _mapCenter = const LatLng(41.2995, 69.2401);

  @override
  void dispose() {
    // GoogleMapController is managed by GoogleMap widget
    super.dispose();
  }

  // ── Location helpers ──────────────────────────────────────────────────────

  Future<void> _fetchCurrentLocation() async {
    if (!mounted) return;
    setState(() => _loadingLocation = true);
    try {
      // 1. Check location services are on
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }

      // 2. Permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) setState(() => _loadingLocation = false);
        return;
      }

      // 3. Last-known as instant preview
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted) {
        final latLng = LatLng(last.latitude, last.longitude);
        setState(() {
          _mapCenter = latLng;
          _selectedLocation = latLng;
          _loadingLocation = true;
        });
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: latLng, zoom: 15),
            ),
          ),
        );
      }

      // 4. Fresh fix via Fused Location Provider (most accurate)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _mapCenter = latLng;
        _selectedLocation = latLng;
        _loadingLocation = false;
      });
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 15),
          ),
        ),
      );
    } catch (e, st) {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  // ── Image helpers ─────────────────────────────────────────────────────────

  Future<void> _captureFromCamera() async {
    final img = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (img != null && mounted) {
      final file = File(img.path);
      setState(() {
        _cameraCapture = file;
        if (!_selectedImages.any((f) => f.path == file.path)) {
          _selectedImages.add(file);
        }
      });
    }
  }

  void _toggleGalleryFile(File file) {
    setState(() {
      final idx = _selectedImages.indexWhere((f) => f.path == file.path);
      if (idx >= 0) {
        _selectedImages.removeAt(idx);
      } else {
        _selectedImages.add(file);
      }
    });
  }

  // ── Tab switching ─────────────────────────────────────────────────────────

  void _switchTab(_Tab tab) {
    if (_activeTab == tab) return;
    setState(() {
      _activeTab = tab;
      if (tab == _Tab.location && !_mapEverOpened) {
        _mapEverOpened = true;
        // Fetch location as soon as the tab is first opened
        _fetchCurrentLocation();
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final sheetHeight = MediaQuery.of(context).size.height * 0.72;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPadding + 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: sheetHeight,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : AppColors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                // ── Drag handle ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 2),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Header row ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
                  child: Row(
                    children: [
                      Text(
                        _activeTab == _Tab.gallery
                            ? l10n.chatAttachPhoto
                            : l10n.chatAttachLocation,
                        style: AppTypography.heading4.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      // ── Close button ──────────────────────────────
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? Colors.white60
                              : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Main content area ─────────────────────────────
                Expanded(
                  child: _activeTab == _Tab.gallery
                      ? _GalleryGrid(
                          isDark: isDark,
                          selectedImages: _selectedImages,
                          cameraCapture: _cameraCapture,
                          onCapture: _captureFromCamera,
                          onToggle: _toggleGalleryFile,
                        )
                      : _LocationContent(
                          isDark: isDark,
                          mapCenter: _mapCenter,
                          loadingLocation: _loadingLocation,
                          selectedLocation: _selectedLocation,
                          onCenterChanged: (latLng) =>
                              setState(() => _selectedLocation = latLng),
                          onMyLocation: _fetchCurrentLocation,
                          onMapCreated: (controller) =>
                              _mapController = controller,
                        ),
                ),

                // ── Send button (full-width, above tab bar) ───────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _canSend
                      ? Padding(
                          key: const ValueKey('send-btn'),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: GestureDetector(
                              onTap: _onSend,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Text(
                                  _activeTab == _Tab.gallery && _selectedImages.length > 1
                                      ? '${l10n.chatAttachButton} (${_selectedImages.length})'
                                      : l10n.chatAttachButton,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body2.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-send-btn')),
                ),

                // ── Bottom tab bar ────────────────────────────────
                _BottomTabBar(
                  isDark: isDark,
                  activeTab: _activeTab,
                  onTabSelected: _switchTab,
                  l10n: l10n,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _canSend {
    if (_activeTab == _Tab.gallery) return _selectedImages.isNotEmpty;
    if (_activeTab == _Tab.location) return _selectedLocation != null;
    return false;
  }

  void _onSend() {
    if (_activeTab == _Tab.gallery && _selectedImages.isNotEmpty) {
      Navigator.of(context).pop(ImageAttachment(List.unmodifiable(_selectedImages)));
    } else if (_activeTab == _Tab.location && _selectedLocation != null) {
      Navigator.of(context).pop(LocationAttachment(_selectedLocation!));
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Gallery grid with live thumbnails + camera first cell
// ──────────────────────────────────────────────────────────────────────────────

class _GalleryGrid extends StatefulWidget {
  final bool isDark;
  final List<File> selectedImages;
  final File? cameraCapture;
  final VoidCallback onCapture;
  final ValueChanged<File> onToggle;

  const _GalleryGrid({
    required this.isDark,
    required this.selectedImages,
    required this.cameraCapture,
    required this.onCapture,
    required this.onToggle,
  });

  @override
  State<_GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<_GalleryGrid> with WidgetsBindingObserver {
  List<AssetEntity> _assets = [];
  bool _loading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGallery();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-check permission when user returns from Settings
    if (state == AppLifecycleState.resumed && _permissionDenied) {
      setState(() {
        _loading = true;
        _permissionDenied = false;
      });
      _loadGallery();
    }
  }

  Future<void> _loadGallery() async {
    try {
      // Use permission_handler for reliable cross-platform permission check
      final PermissionStatus status;
      if (Platform.isAndroid) {
        // Android 13+ uses READ_MEDIA_IMAGES; older uses storage
        final sdkInt = await _androidSdkVersion();
        status = sdkInt >= 33
            ? await Permission.photos.request()
            : await Permission.storage.request();
      } else {
        status = await Permission.photos.request();
      }

      if (!mounted) return;

      if (!status.isGranted && !status.isLimited) {
        setState(() { _loading = false; _permissionDenied = true; });
        return;
      }

      // Tell photo_manager to skip its own permission check
      PhotoManager.setIgnorePermissionCheck(true);

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(type: OrderOptionType.createDate, asc: false),
          ],
        ),
      );

      if (!mounted) return;

      if (albums.isEmpty) {
        setState(() => _loading = false);
        return;
      }

      final recent = await albums.first.getAssetListRange(start: 0, end: 60);
      if (mounted) setState(() { _assets = recent; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _permissionDenied = true; });
    }
  }

  Future<int> _androidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      // Parse SDK int from system property via dart:io
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse((result.stdout as String).trim()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    // ── Loading spinner ──────────────────────────────────────────────────────
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? Colors.white : Colors.black,
          strokeWidth: 2,
        ),
      );
    }

    // ── Permission denied ────────────────────────────────────────────────────
    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: isDark ? Colors.white38 : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                'Allow photo access in Settings to pick from your library',
                textAlign: TextAlign.center,
                style: AppTypography.body2.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  await PhotoManager.openSetting();
                  // Will be re-checked via didChangeAppLifecycleState on resume
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Open Settings',
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Photo grid: first cell = camera, rest = gallery thumbnails ───────────
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: _assets.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CameraCell(
            isDark: isDark,
            capturedFile: widget.cameraCapture,
            onTap: widget.onCapture,
          );
        }
        final asset = _assets[index - 1];
        final selectedPaths = widget.selectedImages.map((f) => f.path).toSet();
        return _GalleryThumbnailCell(
          asset: asset,
          isDark: isDark,
          selectedPaths: selectedPaths,
          onTap: () async {
            final file = await asset.file;
            if (file != null && context.mounted) widget.onToggle(file);
          },
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Camera cell (first grid item)
// ──────────────────────────────────────────────────────────────────────────────

class _CameraCell extends StatelessWidget {
  final bool isDark;
  final File? capturedFile;
  final VoidCallback onTap;

  const _CameraCell({
    required this.isDark,
    required this.capturedFile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (capturedFile != null)
              Image.file(capturedFile!, fit: BoxFit.cover)
            else
              Container(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            Container(
              color: Colors.black.withValues(
                alpha: capturedFile != null ? 0.35 : 0.0,
              ),
              child: Center(
                child: Icon(
                  Icons.camera_alt_rounded,
                  color: isDark || capturedFile != null
                      ? Colors.white
                      : Colors.black54,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Gallery thumbnail cell
// ──────────────────────────────────────────────────────────────────────────────

class _GalleryThumbnailCell extends StatefulWidget {
  final AssetEntity asset;
  final bool isDark;
  final Set<String> selectedPaths;
  final VoidCallback onTap;

  const _GalleryThumbnailCell({
    required this.asset,
    required this.isDark,
    required this.selectedPaths,
    required this.onTap,
  });

  @override
  State<_GalleryThumbnailCell> createState() => _GalleryThumbnailCellState();
}

class _GalleryThumbnailCellState extends State<_GalleryThumbnailCell> {
  Uint8List? _thumb;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  Future<void> _loadThumb() async {
    final bytes = await widget.asset.thumbnailDataWithSize(
      const ThumbnailSize(300, 300),
    );
    final file = await widget.asset.file;
    if (mounted) setState(() { _thumb = bytes; _filePath = file?.path; });
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = _filePath != null && widget.selectedPaths.contains(_filePath);
    final selectionNumber = isSelected
        ? widget.selectedPaths.toList().indexOf(_filePath!) + 1
        : -1;
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _thumb != null
                ? Image.memory(_thumb!, fit: BoxFit.cover)
                : Container(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                  ),
            if (isSelected)
              Container(color: Colors.black.withValues(alpha: 0.35)),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : Colors.transparent,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Center(
                        child: Text(
                          '$selectionNumber',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Location content — Google Maps
// ──────────────────────────────────────────────────────────────────────────────

class _LocationContent extends StatefulWidget {
  final bool isDark;
  final LatLng mapCenter;
  final bool loadingLocation;
  final LatLng? selectedLocation;
  final ValueChanged<LatLng> onCenterChanged;
  final VoidCallback onMyLocation;
  final ValueChanged<GoogleMapController> onMapCreated;

  const _LocationContent({
    required this.isDark,
    required this.mapCenter,
    required this.loadingLocation,
    required this.selectedLocation,
    required this.onCenterChanged,
    required this.onMyLocation,
    required this.onMapCreated,
  });

  @override
  State<_LocationContent> createState() => _LocationContentState();
}

class _LocationContentState extends State<_LocationContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Map ─────────────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Google Maps widget — gestureRecognizers uses
                  // EagerGestureRecognizer so the map wins the gesture arena
                  // before the BottomSheet drag handler can intercept
                  // scroll/pan events.
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: widget.mapCenter,
                      zoom: 15,
                    ),
                    onMapCreated: widget.onMapCreated,
                    onCameraMove: (position) {
                      widget.onCenterChanged(position.target);
                    },
                    myLocationButtonEnabled: false,
                    myLocationEnabled: false,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    gestureRecognizers: {
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                  ),

                  // ── Centre pin (always visible) ────────────────────
                  IgnorePointer(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Icon(
                          Icons.location_pin,
                          size: 44,
                          color:
                              widget.isDark ? Colors.white : Colors.black,
                          shadows: const [
                            Shadow(
                              blurRadius: 8,
                              color: Color(0x55000000),
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Loading overlay ────────────────────────────────
                  if (widget.loadingLocation)
                    Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                          child: CircularProgressIndicator()),
                    ),

                  // ── My-location FAB ────────────────────────────────
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: widget.onMyLocation,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? Colors.black
                              : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.my_location_rounded,
                          size: 22,
                          color: widget.isDark
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Coordinates label ──────────────────────────────────────
        if (widget.selectedLocation != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: widget.isDark
                      ? Colors.white54
                      : Colors.black45,
                ),
                const SizedBox(width: 5),
                Text(
                  '${widget.selectedLocation!.latitude.toStringAsFixed(5)}, '
                  '${widget.selectedLocation!.longitude.toStringAsFixed(5)}',
                  style: AppTypography.caption.copyWith(
                    color: widget.isDark
                        ? Colors.white54
                        : Colors.black45,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 4),
      ],
    );
  }
}

class _BottomTabBar extends StatelessWidget {
  final bool isDark;
  final _Tab activeTab;
  final ValueChanged<_Tab> onTabSelected;
  final AppLocalizations l10n;

  const _BottomTabBar({
    required this.isDark,
    required this.activeTab,
    required this.onTabSelected,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabItem(
              isDark: isDark,
              icon: Icons.photo_library_rounded,
              label: l10n.chatAttachGallery,
              isActive: activeTab == _Tab.gallery,
              onTap: () => onTabSelected(_Tab.gallery),
            ),
          ),
          Container(
            width: 0.5,
            height: 30,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.08),
          ),
          Expanded(
            child: _TabItem(
              isDark: isDark,
              icon: Icons.location_on_rounded,
              label: l10n.chatAttachLocation,
              isActive: activeTab == _Tab.location,
              onTap: () => onTabSelected(_Tab.location),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabItem({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDark ? Colors.white : Colors.black;
    final inactiveColor = isDark ? Colors.white38 : Colors.black38;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? activeColor : inactiveColor,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight:
                  isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? activeColor : inactiveColor,
            ),
          ),
        ],
      ),
    );
  }
}
