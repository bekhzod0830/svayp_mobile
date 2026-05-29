import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked != null && mounted) {
      final file = File(picked.path);
      setState(() {
        if (!_selected.any((f) => f.path == file.path)) {
          _selected.add(file);
        }
      });
    }
  }

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
        if (!_selected.any((f) => f.path == file.path)) {
          _selected.add(file);
        }
      });
    }
  }

  void _remove(File file) {
    setState(() => _selected.removeWhere((f) => f.path == file.path));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.72;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPad + 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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

                  // Selected images grid
                  if (_selected.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxHeight * 0.45),
                      child: GridView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                          childAspectRatio: 1,
                        ),
                        itemCount: _selected.length,
                        itemBuilder: (context, i) {
                          final file = _selected[i];
                          return GestureDetector(
                            onTap: () => _remove(file),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(file, fit: BoxFit.cover),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Confirm button
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: _selected.isNotEmpty
                        ? Padding(
                            key: const ValueKey('confirm-btn'),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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

                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      children: [
                        _ActionButton(
                          isDark: isDark,
                          icon: Icons.image_rounded,
                          iconBackground: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
                          ),
                          label: l10n.chatAttachGallery,
                          subtitle: l10n.chatAttachGallerySubtitle,
                          onTap: _pickFromGallery,
                        ),
                        const SizedBox(height: 10),
                        _ActionButton(
                          isDark: isDark,
                          icon: Icons.camera_alt_rounded,
                          iconBackground: const LinearGradient(
                            colors: [Color(0xFFFF9800), Color(0xFFFF9800)],
                          ),
                          label: l10n.chatAttachCamera,
                          subtitle: l10n.chatAttachCameraSubtitle,
                          onTap: _captureFromCamera,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Action button ────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Gradient iconBackground;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.isDark,
    required this.icon,
    required this.iconBackground,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.body2.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF111111),
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.body2.copyWith(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
