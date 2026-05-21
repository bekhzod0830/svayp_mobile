import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:swipe/core/constants/app_colors.dart';
import 'package:swipe/core/constants/app_typography.dart';
import 'package:swipe/l10n/app_localizations.dart';

/// Opens the closet image-picker bottom sheet.
/// Returns a list of chosen [File]s or null if the sheet is dismissed.
Future<List<File>?> showClosetImagePickerSheet(BuildContext context) {
  return showModalBottomSheet<List<File>>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => const _PickerSheet(),
  );
}

// ─── Sheet ────────────────────────────────────────────────────────────────────

class _PickerSheet extends StatefulWidget {
  const _PickerSheet();

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final List<File> _selected = [];
  File? _cameraCapture;

  Future<void> _captureFromCamera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      final file = File(picked.path);
      setState(() {
        _cameraCapture = file;
        if (!_selected.any((f) => f.path == file.path)) {
          _selected.add(file);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPad + 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: size.height * 0.72,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 2),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.20)
                          : Colors.black.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 8, 6),
                  child: Row(
                    children: [
                      Text(
                        l10n.addToCloset,
                        style: AppTypography.heading4.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                // Gallery
                Expanded(
                  child: _GalleryGrid(
                    isDark: isDark,
                    selectedPaths: _selected.map((f) => f.path).toSet(),
                    cameraCapture: _cameraCapture,
                    onCapture: _captureFromCamera,
                    onToggle: (file) => setState(() {
                      final path = file.path;
                      if (_selected.any((f) => f.path == path)) {
                        _selected.removeWhere((f) => f.path == path);
                      } else {
                        _selected.add(file);
                      }
                    }),
                  ),
                ),
                // Confirm button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _selected.isNotEmpty
                      ? Padding(
                          key: const ValueKey('confirm-btn'),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: GestureDetector(
                            onTap: () => Navigator.of(context)
                                .pop(List<File>.from(_selected)),
                            child: Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white : Colors.black,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                _selected.length == 1
                                    ? l10n.addToCloset
                                    : 'Add ${_selected.length} items',
                                textAlign: TextAlign.center,
                                style: AppTypography.body2.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('no-btn')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Gallery Grid ─────────────────────────────────────────────────────────────

class _GalleryGrid extends StatefulWidget {
  final bool isDark;
  final Set<String> selectedPaths;
  final File? cameraCapture;
  final VoidCallback onCapture;
  final ValueChanged<File> onToggle;

  const _GalleryGrid({
    required this.isDark,
    required this.selectedPaths,
    required this.cameraCapture,
    required this.onCapture,
    required this.onToggle,
  });

  @override
  State<_GalleryGrid> createState() => _GalleryGridState();
}

class _GalleryGridState extends State<_GalleryGrid>
    with WidgetsBindingObserver {
  static const _pageSize = 60;

  List<AssetEntity> _assets = [];
  AssetPathEntity? _album;
  int _totalCount = 0;
  bool _loading = true;
  bool _loadingMore = false;
  bool _permissionDenied = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _loadGallery();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _permissionDenied) {
      setState(() {
        _loading = true;
        _permissionDenied = false;
      });
      _loadGallery();
    }
  }

  void _onScroll() {
    if (_loadingMore) return;
    if (_assets.length >= _totalCount) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      _loadMoreAssets();
    }
  }

  Future<int> _androidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      final result = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse((result.stdout as String).trim()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _loadGallery() async {
    try {
      final PermissionStatus status;
      if (Platform.isAndroid) {
        final sdkInt = await _androidSdkVersion();
        status = sdkInt >= 33
            ? await Permission.photos.request()
            : await Permission.storage.request();
      } else {
        status = await Permission.photos.request();
      }

      if (!mounted) return;

      if (!status.isGranted && !status.isLimited) {
        setState(() {
          _loading = false;
          _permissionDenied = true;
        });
        return;
      }
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
      final album = albums.first;
      final total = await album.assetCountAsync;
      final firstBatch = await album.getAssetListRange(
        start: 0,
        end: _pageSize,
      );
      if (mounted) {
        setState(() {
          _album = album;
          _totalCount = total;
          _assets = firstBatch;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _permissionDenied = true;
        });
      }
    }
  }

  Future<void> _loadMoreAssets() async {
    if (_loadingMore || _album == null) return;
    setState(() => _loadingMore = true);
    try {
      final start = _assets.length;
      final end = (start + _pageSize).clamp(0, _totalCount);
      if (start >= end) {
        setState(() => _loadingMore = false);
        return;
      }
      final batch = await _album!.getAssetListRange(start: start, end: end);
      if (mounted) {
        setState(() {
          _assets = [..._assets, ...batch];
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.isDark ? Colors.white : Colors.black,
          strokeWidth: 2,
        ),
      );
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 52,
                color: widget.isDark ? Colors.white30 : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                'Allow photo access in Settings to pick from your library',
                textAlign: TextAlign.center,
                style: AppTypography.body2.copyWith(
                  color: widget.isDark ? Colors.white54 : AppColors.gray600,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => PhotoManager.openSetting(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.isDark ? Colors.white : Colors.black,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'Open Settings',
                    style: AppTypography.body2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final hasMore = _assets.length < _totalCount;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      // +1 for camera cell, +1 for loading indicator when more to fetch
      itemCount: _assets.length + 1 + (hasMore || _loadingMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == 0) {
          return _CameraCell(
            isDark: widget.isDark,
            capturedFile: widget.cameraCapture,
            onTap: widget.onCapture,
          );
        }
        // Loading footer cell
        if (i == _assets.length + 1 && (hasMore || _loadingMore)) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.isDark ? Colors.white54 : Colors.black38,
                ),
              ),
            ),
          );
        }
        return _GalleryCell(
          asset: _assets[i - 1],
          isDark: widget.isDark,
          selectedPaths: widget.selectedPaths,
          onToggle: widget.onToggle,
        );
      },
    );
  }
}

// ─── Camera Cell ──────────────────────────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(4),
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
            if (capturedFile != null)
              Container(color: Colors.black.withValues(alpha: 0.38)),
            Center(
              child: Icon(
                Icons.camera_alt_rounded,
                color: isDark || capturedFile != null
                    ? Colors.white
                    : Colors.black54,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gallery Cell ─────────────────────────────────────────────────────────────

class _GalleryCell extends StatefulWidget {
  final AssetEntity asset;
  final bool isDark;
  final Set<String> selectedPaths;
  final ValueChanged<File> onToggle;

  const _GalleryCell({
    required this.asset,
    required this.isDark,
    required this.selectedPaths,
    required this.onToggle,
  });

  @override
  State<_GalleryCell> createState() => _GalleryCellState();
}

class _GalleryCellState extends State<_GalleryCell> {
  Uint8List? _thumb;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bytes = await widget.asset
        .thumbnailDataWithSize(const ThumbnailSize(300, 300));
    final file = await widget.asset.file;
    if (mounted) {
      setState(() {
        _thumb = bytes;
        _filePath = file?.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSelected =
        _filePath != null && widget.selectedPaths.contains(_filePath);

    return GestureDetector(
      onTap: () {
        if (_filePath != null) widget.onToggle(File(_filePath!));
      },
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
              Container(color: Colors.black.withValues(alpha: 0.45)),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.white : Colors.transparent,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(Icons.check,
                            size: 14, color: Colors.black),
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
