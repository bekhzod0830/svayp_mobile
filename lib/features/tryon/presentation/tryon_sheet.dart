import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_diamond.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/widgets/body_scan_visual.dart';
import '../data/tryon_service.dart';
import 'widgets/try_on_pill.dart' show kTryOnCost;

/// Открыть примерку товара (манекен / на своём фото). Гармент берётся из
/// каноничной вещи товара на бэке (бэкфилл). Строки — RU (рынок RU-first);
/// TODO вынести в l10n при следующей локализации.
Future<void> showProductTryOnSheet(
  BuildContext context, {
  required String productId,
  String? previewImage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    // Present above the root-level floating bottom navbar so it doesn't cover
    // the sheet's action button.
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TryOnSheet(productId: productId, previewImage: previewImage),
  );
}

enum _Mode { mannequin, self }

enum _Phase { setup, working, result, failed }

class _TryOnSheet extends StatefulWidget {
  final String productId;
  final String? previewImage;
  const _TryOnSheet({required this.productId, this.previewImage});

  @override
  State<_TryOnSheet> createState() => _TryOnSheetState();
}

class _TryOnSheetState extends State<_TryOnSheet> {
  final _service = TryOnService();
  final _picker = ImagePicker();

  _Mode _mode = _Mode.self;
  _Phase _phase = _Phase.setup;
  File? _photo;
  String? _personKey; // blobKey загруженного фото
  bool _uploading = false;
  String? _resultUrl;
  String? _error;

  static const _pink = Color(0xFFF370A7);

  bool get _canStart =>
      !_uploading &&
      (_mode == _Mode.mannequin || _personKey != null);

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;
    setState(() {
      _photo = File(picked.path);
      _personKey = null;
      _uploading = true;
    });
    try {
      final key = await _service.uploadOwnPhoto(_photo!);
      if (!mounted) return;
      setState(() {
        _personKey = key;
        _uploading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _photo = null;
      });
      _toast(AppLocalizations.of(context)!.tryOnPhotoUploadFailed);
    }
  }

  Future<void> _start() async {
    if (!_canStart) return;
    setState(() {
      _phase = _Phase.working;
      _error = null;
    });
    try {
      final job = await _service.createForProduct(
        widget.productId,
        personImageKey: _mode == _Mode.self ? _personKey : null,
      );
      final done = await _service.waitUntilDone(job.id);
      if (!mounted) return;
      if (done.status == TryOnStatus.completed && done.resultImageUrl != null) {
        setState(() {
          _resultUrl = done.resultImageUrl;
          _phase = _Phase.result;
        });
      } else {
        setState(() {
          _error = done.failureReason ?? AppLocalizations.of(context)!.tryOnFailedDefault;
          _phase = _Phase.failed;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.isInsufficientCoins) {
        Navigator.of(context).pop();
        _showNeedCoins(context, e.requiredCoins, e.balanceCoins);
        return;
      }
      setState(() {
        // Подписочный лимит (тоже 402) — это НЕ нехватка монет: показываем понятный
        // текст про лимит, а не ведём на экран покупки монет.
        _error = e.isQuotaExceeded
            ? 'Лимит примерок на этот месяц исчерпан. Оформите премиум для большего количества.'
            : e.message;
        _phase = _Phase.failed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context)!.tryOnSomethingWrong;
        _phase = _Phase.failed;
      });
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final ink = isDark ? Colors.white : const Color(0xFF141118);
    final sub = isDark ? const Color(0xFF8E8E93) : const Color(0xFF9A8F98);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.86,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE2DBE1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Text(l10n.tryItOn,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: sub),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _body(isDark, ink, sub),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(bool isDark, Color ink, Color sub) {
    final l10n = AppLocalizations.of(context)!;
    switch (_phase) {
      case _Phase.working:
        return _TryOnProcessing(ink: ink, sub: sub);
      case _Phase.result:
        return Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: _resultUrl == null
                  ? const SizedBox()
                  : Image.network(_resultUrl!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton(l10n.done, () => Navigator.of(context).pop()),
        ]);
      case _Phase.failed:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 36),
          child: Column(children: [
            const Icon(Icons.error_outline, color: _pink, size: 40),
            const SizedBox(height: 12),
            Text(_error ?? l10n.error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: ink)),
            const SizedBox(height: 16),
            _primaryButton(l10n.tryAgain, () => setState(() => _phase = _Phase.setup)),
          ]),
        );
      case _Phase.setup:
        return _setup(isDark, ink, sub);
    }
  }

  Widget _setup(bool isDark, Color ink, Color sub) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Body-scan animation preview + the diamond cost of a try-on, shown the
        // moment the sheet opens.
        Container(
          height: 235,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF3E6EE),
            ),
          ),
          child: BodyScanVisual(badge: _diamondCostBadge()),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _modeCard(
            selected: _mode == _Mode.mannequin,
            icon: Icons.accessibility_new_rounded,
            label: l10n.tryOnModeMannequin,
            onTap: () => setState(() => _mode = _Mode.mannequin),
            isDark: isDark, ink: ink,
          ),
          const SizedBox(width: 12),
          _modeCard(
            selected: _mode == _Mode.self,
            icon: Icons.person_rounded,
            label: l10n.tryOnModeSelf,
            onTap: () => setState(() => _mode = _Mode.self),
            isDark: isDark, ink: ink,
          ),
        ]),
        if (_mode == _Mode.self) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _uploading ? null : _pickPhoto,
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _personKey != null ? _pink : (isDark ? const Color(0xFF2A2A2C) : const Color(0xFFECECED)),
                  width: 1.5,
                ),
              ),
              child: Row(children: [
                const SizedBox(width: 14),
                if (_photo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_photo!, width: 68, height: 68, fit: BoxFit.cover),
                  )
                else
                  Icon(Icons.add_a_photo_outlined, color: sub, size: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _uploading
                        ? l10n.tryOnUploadingPhoto
                        : _personKey != null
                            ? l10n.tryOnPhotoReady
                            : l10n.tryOnPickPhoto,
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: ink),
                  ),
                ),
                if (_uploading)
                  const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _pink)),
                  ),
                const SizedBox(width: 6),
              ]),
            ),
          ),
        ],
        const SizedBox(height: 20),
        _primaryButton(l10n.tryItOn, _canStart ? _start : null),
      ],
    );
  }

  Widget _modeCard({
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color ink,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? _pink : (isDark ? const Color(0xFF2A2A2C) : const Color(0xFFECECED)), width: 1.5),
            color: selected ? _pink.withValues(alpha: 0.10) : Colors.transparent,
          ),
          child: Column(children: [
            Icon(icon, color: selected ? _pink : ink, size: 26),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
          ]),
        ),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _pink,
          disabledBackgroundColor: _pink.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Диалог нехватки алмазов (402). Баланс пополняется в разделе «Гардероб» (WebView).
void _showNeedCoins(BuildContext context, int? required, int? balance) {
  final l10n = AppLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.tryOnNeedDiamondsTitle),
      content: Text(
        required != null && balance != null
            ? l10n.tryOnNeedDiamondsBody(required, balance)
            : l10n.tryOnNeedDiamondsBodyShort,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.gotIt),
        ),
      ],
    ),
  );
}

/// Brand diamond-cost badge — the faceted LIBAS gem (same [IntroDiamond] used on
/// the closet/try-on pill) plus how many diamonds a try-on costs. Shown on the
/// body-scan visual both in setup and while the try-on is processing; the gem
/// replaces the old "✨ AI" chip so the paid action reads consistently.
Widget _diamondCostBadge() {
  return Container(
    padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
    decoration: BoxDecoration(
      color: const Color(0xFFF370A7),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const IntroDiamond(size: 13),
        const SizedBox(width: 4),
        Text('$kTryOnCost',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    ),
  );
}

/// Try-on processing view — a body-scan animation (glowing pink rings sweeping
/// over the product) plus a 30s progress bar with a percentage. Brand-coloured
/// take on the reference "Примеряем на вас…" screen.
class _TryOnProcessing extends StatefulWidget {
  final Color ink;
  final Color sub;
  const _TryOnProcessing({required this.ink, required this.sub});

  @override
  State<_TryOnProcessing> createState() => _TryOnProcessingState();
}

class _TryOnProcessingState extends State<_TryOnProcessing>
    with SingleTickerProviderStateMixin {
  static const _pink = Color(0xFFF370A7);
  late final AnimationController _progress; // 30s fill

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? const Color(0xFF3A2E36) : const Color(0xFFF0E0EA);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Full-bleed stage: no card frame, so the figure floats directly on the
        // sheet surface like the reference screen.
        SizedBox(
          height: math.min(MediaQuery.of(context).size.height * 0.52, 470),
          width: double.infinity,
          child: BodyScanVisual(badge: _diamondCostBadge()),
        ),
        const SizedBox(height: 20),
        Text(AppLocalizations.of(context)!.tryOnProcessingTitle,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w800, color: widget.ink)),
        const SizedBox(height: 6),
        Text(AppLocalizations.of(context)!.tryOnProcessingSubtitle,
            style: TextStyle(fontSize: 13, color: widget.sub)),
        const SizedBox(height: 18),
        // 30s progress bar with a percentage read-out.
        AnimatedBuilder(
          animation: _progress,
          builder: (context, _) {
            final v = Curves.easeOut.transform(_progress.value);
            final pct = math.min(99, (v * 100).round());
            return Row(
              children: [
                Expanded(
                  // Track + fill as explicitly-sized boxes. (An earlier Stack of
                  // childless ColoredBox/DecoratedBox collapsed to 0 height under
                  // the default StackFit.loose, so the bar was invisible.)
                  child: LayoutBuilder(
                    builder: (context, c) => Container(
                      height: 8,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: trackColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Container(
                        height: 8,
                        width: c.maxWidth * v.clamp(0.03, 1.0),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                          gradient: LinearGradient(
                            colors: [Color(0xFFF9A9CB), _pink],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 42,
                  child: Text(
                    '$pct%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _pink,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
