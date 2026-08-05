import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/features/onboarding/presentation/widgets/intro/intro_diamond.dart';

import '../../../core/network/api_client.dart';
import '../../main/presentation/screens/main_screen.dart';
import '../data/tryon_service.dart';
import '../data/tryon_share.dart';
import 'tryon_failure.dart';
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

/// Status codes whose [ApiException.message] is lifted verbatim out of the
/// backend response body (see `ApiClient._handleResponseError`) and so can hold
/// raw provider text. Everything else already carries a message we wrote.
bool _carriesProviderText(int statusCode) =>
    statusCode == 400 || statusCode == 422 || statusCode == 429;

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
  bool _sharing = false;

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
          // Never the raw reason: it is a provider payload, not a message.
          _error = mapTryOnFailure(done.failureReason, AppLocalizations.of(context)!);
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
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        // Подписочный лимит (тоже 402) — это НЕ нехватка монет: показываем понятный
        // текст про лимит, а не ведём на экран покупки монет.
        if (e.isQuotaExceeded) {
          _error = l10n.tryOnQuotaExceeded;
        } else if (_carriesProviderText(e.statusCode)) {
          // For these the client hands through the backend body's own
          // `error.message`, which for a try-on is the provider's payload —
          // the "Error code: 400 - {'error': {'message': 'Your request was
          // rejected by the safety system…'}}" users were being shown. Bucket
          // it the same way a failed job is bucketed.
          _error = mapTryOnFailure(e.message, l10n);
        } else {
          // Timeouts, offline, 5xx: api_client already authored a readable
          // message for these, and it says more than the generic fallback.
          _error = e.message;
        }
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

  /// What the progress screen scans: the user's photo in "on my photo" mode,
  /// the garment otherwise. Null only if a caller passed no preview image.
  ImageProvider? _subjectImage() {
    if (_mode == _Mode.self && _photo != null) return FileImage(_photo!);
    final preview = widget.previewImage;
    return preview == null ? null : NetworkImage(preview);
  }

  /// Hand the finished look to the OS share sheet with the LIBΛS mark burned
  /// in — the same image the closet produces for its "share to other apps".
  Future<void> _shareResult() async {
    final url = _resultUrl;
    if (url == null || _sharing) return;
    setState(() => _sharing = true);
    try {
      await shareWatermarkedTryOn(url);
    } catch (_) {
      if (mounted) _toast(AppLocalizations.of(context)!.tryOnShareFailed);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  /// Close the sheet and land the user on the closet's Outfits tab, where the
  /// look they just made is listed with the rest of their try-ons.
  void _openMyOutfits() {
    Navigator.of(context).pop();
    MainScreen.globalKey.currentState?.openClosetPath('/closet?tab=outfits');
  }

  Widget _myOutfitsButton(AppLocalizations l10n) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _openMyOutfits,
        style: ElevatedButton.styleFrom(
          backgroundColor: _pink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.checkroom_rounded, size: 17),
            const SizedBox(width: 7),
            Flexible(
              child: Text(l10n.tryOnMyOutfits,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
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
        // Show what the result will be built from: the user's own photo when
        // there is one, otherwise the garment. Both beat the body-scan
        // silhouette that used to stand in here — it was the same generic
        // figure whatever you were trying on.
        return TryOnProcessingView(
          ink: ink,
          sub: sub,
          subject: _subjectImage(),
        );
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
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: TextButton(
                  onPressed: _sharing ? null : _shareResult,
                  style: TextButton.styleFrom(
                    backgroundColor:
                        isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF3F4F6),
                    foregroundColor: ink,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _sharing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: ink),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.ios_share_rounded, size: 17),
                            const SizedBox(width: 7),
                            Flexible(
                              child: Text(l10n.tryOnShare,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _myOutfitsButton(l10n)),
          ]),
        ]);
      case _Phase.failed:
        // Same shape as the closet's failure card: a headline that names what
        // went wrong, one plain-language sentence under it, and a way out that
        // isn't only "try again".
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Column(children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A2126) : const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 26),
            ),
            const SizedBox(height: 14),
            Text(l10n.tryOnFailedTitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 6),
            Text(_error ?? l10n.tryOnFailedGeneric,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, height: 1.35, color: sub)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF3F4F6),
                      foregroundColor: ink,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(l10n.close,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _primaryButton(
                  l10n.tryAgain,
                  () => setState(() => _phase = _Phase.setup),
                ),
              ),
            ]),
          ]),
        );
      case _Phase.setup:
        return _setup(isDark, ink, sub);
    }
  }

  /// Setup step, laid out like the closet web app's `TryOnConfirmModal`:
  /// the thing being tried on, a segmented target control, then one photo row.
  ///
  /// The animated body-scan silhouette that used to fill the top is gone. It
  /// showed a generic mannequin figure rather than the garment, which told the
  /// user nothing about what they were about to spend diamonds on — the product
  /// image (already passed in as `previewImage`, and until now unused) is the
  /// closet's own choice for that slot.
  Widget _setup(bool isDark, Color ink, Color sub) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        if (widget.previewImage != null) ...[
          _previewCard(isDark),
          const SizedBox(height: 18),
        ],
        _targetSegmented(isDark, ink, sub, l10n),
        if (_mode == _Mode.self) ...[
          const SizedBox(height: 16),
          _photoRow(isDark, ink, sub, l10n),
        ],
        const SizedBox(height: 20),
        _primaryButton(l10n.tryOnConfirm, _canStart ? _start : null),
      ],
    );
  }

  /// The garment being tried on, with the diamond price in the corner — the one
  /// piece of the old stage worth keeping, since this action costs coins.
  Widget _previewCard(bool isDark) {
    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232325) : const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF0F0F2),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            widget.previewImage!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox(),
          ),
          Positioned(top: 12, right: 12, child: _diamondCostBadge()),
        ],
      ),
    );
  }

  /// Mannequin / own-photo as a segmented pill, matching the closet's control
  /// (a two-state choice doesn't need two description cards).
  Widget _targetSegmented(
      bool isDark, Color ink, Color sub, AppLocalizations l10n) {
    Widget option(_Mode mode, IconData icon, String label) {
      final on = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mode = mode),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on
                  ? (isDark ? const Color(0xFF3A3A3C) : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: on
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: on ? ink : sub),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: on ? ink : sub,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF4F4F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(children: [
        option(_Mode.mannequin, Icons.person_outline_rounded,
            l10n.tryOnTargetMannequin),
        const SizedBox(width: 6),
        option(_Mode.self, Icons.photo_camera_outlined, l10n.tryOnTargetSelf),
      ]),
    );
  }

  /// Upload row: a dashed drop-target that becomes the chosen photo, plus the
  /// shooting guidance. No worked example thumbnail.
  Widget _photoRow(bool isDark, Color ink, Color sub, AppLocalizations l10n) {
    final hasPhoto = _photo != null;
    return GestureDetector(
      onTap: _uploading ? null : _pickPhoto,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 74,
            height: 96,
            // foregroundPainter, not painter: the child fills its own rounded
            // rect opaquely, and a background painter's stroke lands underneath
            // it — drawn, but invisible.
            child: CustomPaint(
              foregroundPainter: _PickerBorderPainter(
                color: hasPhoto
                    ? _pink
                    : (isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE7E7EC)),
                dashed: !hasPhoto,
                radius: 16,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasPhoto)
                      Image.file(_photo!, fit: BoxFit.cover)
                    else
                      Container(
                        color: isDark
                            ? const Color(0xFF232325)
                            : const Color(0xFFFAFAFC),
                        child: const Icon(Icons.photo_camera_outlined,
                            color: _pink, size: 24),
                      ),
                    if (_uploading)
                      Container(
                        color: Colors.white.withValues(alpha: 0.7),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: _pink),
                          ),
                        ),
                      ),
                    if (_personKey != null && !_uploading)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _uploading
                      ? l10n.tryOnUploadingPhoto
                      : _personKey != null
                          ? l10n.tryOnChangePhoto
                          : l10n.tryOnUploadPhoto,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: ink),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tryOnPhotoHint,
                  style: TextStyle(fontSize: 12, height: 1.35, color: sub),
                ),
              ],
            ),
          ),
        ],
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

/// Rounded border for the photo drop-target, dashed while empty and solid once
/// a photo is chosen — the closet's `border: 1.5px dashed|solid` in a form
/// Flutter's [Border] can't express.
class _PickerBorderPainter extends CustomPainter {
  final Color color;
  final bool dashed;
  final double radius;
  const _PickerBorderPainter({
    required this.color,
    required this.dashed,
    required this.radius,
  });

  static const _dash = 5.0;
  static const _gap = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color;

    // Inset by half the stroke so the line sits inside the box rather than
    // straddling its edge (which the ClipRRect child would shave off).
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(radius),
    );

    if (!dashed) {
      canvas.drawRRect(rect, paint);
      return;
    }

    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + _dash, metric.length)),
          paint,
        );
        d += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_PickerBorderPainter old) =>
      old.color != color || old.dashed != dashed || old.radius != radius;
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

/// Try-on processing view.
///
/// Mirrors the closet web app's `TryOnModal` waiting state (swipe-web
/// `components/closet/TryOnFlow.tsx`) so the same product looks the same
/// wherever it is started: the user's own photo under a travelling scan beam,
/// a spinner, a four-segment progress bar with a time estimate, a phase label,
/// and a rotating style tip. The photo matters most — waiting on a generic
/// silhouette gave no sign of *whose* try-on was being generated.
///
/// [subject] is whatever the result is built from — the user's photo, or the
/// garment on a mannequin run. Null only when a caller supplied neither, in
/// which case the stage is simply left out rather than filled with a stand-in.
class TryOnProcessingView extends StatefulWidget {
  final Color ink;
  final Color sub;
  final ImageProvider? subject;
  const TryOnProcessingView(
      {super.key, required this.ink, required this.sub, this.subject});

  @override
  State<TryOnProcessingView> createState() => _TryOnProcessingState();
}

class _TryOnProcessingState extends State<TryOnProcessingView>
    with TickerProviderStateMixin {
  static const _pink = Color(0xFFF370A7);

  /// Segment boundaries in seconds — 10 / 15 / 20 / 15, 60s total. Same split
  /// as the web so the phase labels change at the same moments.
  static const _phaseEnds = [10, 25, 45, 60];
  static const _tipEverySeconds = 6;
  static const _tipCount = 8;

  late final AnimationController _scan; // beam sweep + glow pulse
  late final AnimationController _spin;
  Timer? _tick;
  int _elapsed = 0;
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    _scan = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    // Start somewhere in the list so a user who retries doesn't reread the
    // same tip; the web randomises the same way.
    _tipIndex = math.Random().nextInt(_tipCount);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed++;
        if (_elapsed % _tipEverySeconds == 0) _tipIndex++;
      });
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _scan.dispose();
    _spin.dispose();
    super.dispose();
  }

  /// Kept in step with [_tipCount].
  List<String> _tips(AppLocalizations l10n) => [
        l10n.tryOnTip1, l10n.tryOnTip2, l10n.tryOnTip3, l10n.tryOnTip4,
        l10n.tryOnTip5, l10n.tryOnTip6, l10n.tryOnTip7, l10n.tryOnTip8,
      ];

  int get _currentPhase => _elapsed < _phaseEnds[0]
      ? 0
      : _elapsed < _phaseEnds[1]
          ? 1
          : _elapsed < _phaseEnds[2]
              ? 2
              : 3;

  /// How full segment [i] is, 0..1: filled once its window has passed, partial
  /// while it is the live one.
  double _segmentFill(int i) {
    final start = i == 0 ? 0 : _phaseEnds[i - 1];
    final end = _phaseEnds[i];
    if (_elapsed >= end) return 1;
    if (_elapsed <= start) return 0;
    return (_elapsed - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tips = _tips(l10n);
    final phaseLabels = [
      l10n.tryOnStarting,
      l10n.tryOnPhase2,
      l10n.tryOnPhase3,
      l10n.tryOnPhase4,
    ];
    final tipHeaders = [l10n.tryOnStyleTip, l10n.tryOnProTip, l10n.tryOnDidYouKnow];
    final secondsLeft = math.max(0, 60 - _elapsed);
    final timeLabel = _elapsed < 5 ? l10n.tryOnTimeEstimate : '~$secondsLeft s';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        if (widget.subject != null) ...[
          _ScanningPhoto(image: widget.subject!, anim: _scan),
          const SizedBox(height: 18),
        ],

        // Spinner with the brand sparkle at its centre.
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: _spin,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    value: 0.22, // fixed arc — the rotation carries the motion
                    color: _pink,
                    backgroundColor:
                        isDark ? const Color(0xFF2A2A2C) : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
              const Icon(Icons.auto_awesome, size: 18, color: _pink),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Four-segment progress bar + time estimate.
        Row(
          children: List.generate(4, (i) {
            final fill = _segmentFill(i);
            final isActive = i == _currentPhase;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 3 ? 0 : 6),
                child: LayoutBuilder(
                  builder: (context, c) => Container(
                    height: 6,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2C) : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(seconds: 1),
                      curve: Curves.easeOut,
                      height: 6,
                      width: c.maxWidth * fill,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [_pink, Color(0xFFE0409A)])
                            : null,
                        color: isActive ? null : _pink,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(timeLabel,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: widget.sub)),
        const SizedBox(height: 14),

        // Phase label.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: Text(
            phaseLabels[_currentPhase],
            key: ValueKey(_currentPhase),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: widget.ink),
          ),
        ),
        const SizedBox(height: 16),

        // Rotating style tip.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232325) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✦ ${tipHeaders[_tipIndex % tipHeaders.length].toUpperCase()}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _pink,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Text(
                  tips[_tipIndex % tips.length],
                  key: ValueKey(_tipIndex % tips.length),
                  style: TextStyle(fontSize: 12, height: 1.45, color: widget.sub),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The user's photo with a pink beam travelling down it and a breathing glow —
/// the Flutter counterpart of the web's `tryOnPhotoScan` / `tryOnPhotoGlow`
/// keyframes, matched to the same 2.8s period.
class _ScanningPhoto extends StatelessWidget {
  final ImageProvider image;
  final Animation<double> anim;
  const _ScanningPhoto({required this.image, required this.anim});

  static const _pink = Color(0xFFF370A7);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, child) {
        // Glow pulses twice per sweep, as on the web (2.6s vs 2.8s there — one
        // controller drives both here, and the difference isn't perceptible).
        final pulse = 0.5 - 0.5 * math.cos(2 * math.pi * anim.value);
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _pink.withValues(alpha: 0.16 + 0.12 * pulse),
                blurRadius: 24 + 6 * pulse,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 170,
          child: AspectRatio(
            key: const ValueKey('tryon-scan-card'),
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image(image: image, fit: BoxFit.cover),
                // Beam: a soft band sweeping from just above the top edge to
                // just below the bottom one, fading in and out at the extremes.
                // Offsets are computed in pixels off the measured card rather
                // than as fractional translations, which are relative to the
                // moving child's own height and would overshoot the card.
                LayoutBuilder(
                  builder: (context, c) {
                    final bandH = c.maxHeight * 0.24;
                    return AnimatedBuilder(
                      animation: anim,
                      builder: (context, _) {
                        final t = anim.value;
                        // -130%..430% of the band's height, as in the web's
                        // `tryOnPhotoScan` keyframes.
                        final top = bandH * (-1.3 + t * 5.6);
                        final opacity = t < 0.12
                            ? t / 0.12
                            : t > 0.88
                                ? (1 - t) / 0.12
                                : 1.0;
                        return Stack(
                          children: [
                            Positioned(
                              top: top,
                              left: 0,
                              right: 0,
                              height: bandH,
                              child: Opacity(
                                key: const ValueKey('tryon-scan-beam'),
                                opacity: opacity.clamp(0.0, 1.0),
                                child: const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0x00F370A7),
                                        Color(0x6BF370A7),
                                        Color(0x00F370A7),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                // Constant wash so the photo reads as "being processed".
                // No cost badge here, matching the closet: the diamonds are
                // already spent by this point, so quoting the price again is
                // noise over the one thing the user wants to look at.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x1FFFFFFF), Color(0x12F370A7)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
