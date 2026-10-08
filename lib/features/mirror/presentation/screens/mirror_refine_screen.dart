import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_chrome.dart';
import '../widgets/mirror_station_card.dart';
import 'mirror_shop_brand_screen.dart';

/// «Что изменить?» — перед «Пересобрать» в ветке «создать». Причины отмечаются
/// плитками и складываются: «Дешевле» или «Дороже» (одно из двух) плюс любые из
/// «Другой цвет / Другой бренд / Поменять стиль». У цвета, бренда и стиля под
/// плитками раскрывается свой выбор. Пересборка — одной кнопкой внизу, когда
/// всё отмечено; без причин она же — «Просто пересобрать».
class MirrorRefineScreen extends StatefulWidget {
  const MirrorRefineScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  State<MirrorRefineScreen> createState() => _MirrorRefineScreenState();
}

class _MirrorRefineScreenState extends State<MirrorRefineScreen> {
  final Set<String> _reasons = {};
  final Set<String> _colors = {};
  final Set<String> _brands = {};
  final Set<String> _styles = {};

  /// Причина, чей выбор (цвета, бренды, стили) сейчас раскрыт под плитками.
  /// Раскрыт всегда один: иначе новый выбор открывался под прежним, за краем
  /// экрана, и казалось, что кнопка не сработала.
  String? _open;
  final GlobalKey _panelKey = GlobalKey();

  static const _withPanel = {'COLOR', 'BRAND', 'STYLE'};

  MirrorSessionController get c => widget.controller;

  bool get _needBrand => _reasons.contains('BRAND') && _brands.isEmpty;
  bool get _needStyle => _reasons.contains('STYLE') && _styles.isEmpty;

  /// Касание плитки: не отмечена — отметить (и раскрыть её выбор вместо
  /// прежнего); отмечена, но выбор свёрнут — раскрыть, чтобы поправить;
  /// отмечена и раскрыта — снять.
  void _toggleReason(String code) {
    c.touch();
    setState(() {
      if (!_reasons.contains(code)) {
        _reasons.add(code);
        // Дешевле и дороже одновременно не бывает.
        if (code == 'CHEAPER') _reasons.remove('PRICIER');
        if (code == 'PRICIER') _reasons.remove('CHEAPER');
        if (_withPanel.contains(code)) _open = code;
      } else if (_withPanel.contains(code) && _open != code) {
        _open = code;
      } else {
        _reasons.remove(code);
        if (_open == code) _open = null;
      }
    });
    if (_open != null) _revealPanel();
  }

  void _openPanel(String code) {
    c.touch();
    setState(() => _open = code);
    _revealPanel();
  }

  /// Прокрутить так, чтобы плитки «Образ» встали наверх, а раскрытый выбор —
  /// сразу под ними: видно и выбор, и соседние плитки. Ждём, пока панель
  /// раскроется, — иначе прокрутке не хватит высоты.
  void _revealPanel() {
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      final ctx = _panelKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _toggleIn(Set<String> set, String code) {
    c.touch();
    setState(() {
      if (!set.remove(code)) set.add(code);
    });
  }

  /// Бренды — с той же логикой, что на шаге брендов: «Все бренды» исключает
  /// остальные.
  void _toggleBrand(String code) {
    c.touch();
    setState(() {
      if (code == kioskAnyBrand) {
        final wasAll = _brands.contains(kioskAnyBrand);
        _brands.clear();
        if (!wasAll) _brands.add(kioskAnyBrand);
      } else {
        _brands.remove(kioskAnyBrand);
        if (!_brands.remove(code)) _brands.add(code);
      }
    });
  }

  void _rebuild() {
    c.rebuild(
      reasons: Set.of(_reasons),
      colors: _reasons.contains('COLOR') ? _colors.toList() : const [],
      brands: _reasons.contains('BRAND') ? Set.of(_brands) : null,
      styles: _reasons.contains('STYLE') ? _styles.toList() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    final lang = c.shopperLang;
    final otherStyles = t.brand.stylesFor(c.gender).where((st) => !c.styles.contains(st.code)).toList();

    Widget reason(String code, String label, IconData icon) => Expanded(
          child: _ReasonTile(
            label: label,
            icon: icon,
            selected: _reasons.contains(code),
            onTap: () => _toggleReason(code),
          ),
        );

    final hint = _needBrand
        ? l10n.mirrorRefineNeedBrand
        : _needStyle
            ? l10n.mirrorRefineNeedStyle
            : null;
    // Подсказка ведёт к выбору, которого не хватает.
    final hintTarget = _needBrand ? 'BRAND' : (_needStyle ? 'STYLE' : null);

    final Widget? panel = switch (_open) {
      'COLOR' => _Panel(
          key: const ValueKey('COLOR'),
          title: l10n.mirrorRefineColorsPick,
          child: MirrorColorGrid(
            lang: lang,
            selected: _colors,
            onToggle: (code) => _toggleIn(_colors, code),
            shrinkWrap: true,
            columns: 4,
          ),
        ),
      'BRAND' => _Panel(
          key: const ValueKey('BRAND'),
          title: l10n.mirrorRefineBrandsPick,
          child: MirrorBrandGrid(
            shrinkWrap: true,
            selected: _brands,
            // Один бренд — его и прячем: «другой» значит не этот.
            exclude: c.shopBrands.length == 1 ? c.shopBrands.first : null,
            onPick: _toggleBrand,
          ),
        ),
      'STYLE' => _Panel(
          key: const ValueKey('STYLE'),
          title: l10n.mirrorRefineStylesPick,
          child: Wrap(
            spacing: 10 * s,
            runSpacing: 10 * s,
            children: [
              for (final st in otherStyles)
                _Pill(
                  label: t.brand.styleLabel(st, lang),
                  selected: _styles.contains(st.code),
                  onTap: () => _toggleIn(_styles, st.code!),
                ),
            ],
          ),
        ),
      _ => null,
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 24 * s),
          MirrorStationHeading(title: l10n.mirrorRefineTitle, subtitle: l10n.mirrorRefineSubtitle),
          SizedBox(height: 20 * s),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(bottom: 12 * s),
              children: [
                _FaceQuestion(liked: c.faceLiked, onAnswer: c.setFaceLiked),
                SizedBox(height: 24 * s),
                _SectionLabel(l10n.mirrorRefinePrice),
                SizedBox(height: 10 * s),
                Row(
                  children: [
                    reason('CHEAPER', l10n.mirrorRefineCheaper, Icons.south_rounded),
                    SizedBox(width: 12 * s),
                    reason('PRICIER', l10n.mirrorRefinePricier, Icons.north_rounded),
                  ],
                ),
                SizedBox(height: 22 * s),
                _SectionLabel(l10n.mirrorRefineLook, key: _panelKey),
                SizedBox(height: 10 * s),
                Row(
                  children: [
                    reason('COLOR', l10n.mirrorRefineColor, Icons.palette_outlined),
                    SizedBox(width: 12 * s),
                    reason('BRAND', l10n.mirrorRefineBrand, Icons.storefront_outlined),
                    SizedBox(width: 12 * s),
                    reason('STYLE', l10n.mirrorRefineStyle, Icons.style_outlined),
                  ],
                ),
                // Раскрытый выбор — под плитками, один за раз.
                AnimatedSize(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: panel ?? const SizedBox(width: double.infinity),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10 * s),
          SizedBox(
            height: 22 * s,
            child: hint == null
                ? null
                : GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openPanel(hintTarget!),
                    child: Text(
                      hint,
                      textAlign: TextAlign.center,
                      style: t.subtitle(14 * s, color: t.accent),
                    ),
                  ),
          ),
          SizedBox(height: 6 * s),
          MirrorPrimaryButton(
            label: _reasons.isEmpty ? l10n.mirrorRefineAgain : l10n.mirrorRegenerate,
            subLabel: _reasons.isEmpty ? null : l10n.mirrorRefineChosen(_reasons.length),
            height: 72 * s,
            enabled: c.canRegenerate && hint == null,
            onTap: _rebuild,
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    return Text(t.kickerCase(text), style: t.kicker(s));
  }
}

/// Плитка причины: значок в круге и подпись, чек в углу. Отмеченная — заливка
/// цветом бренда (в тёмной теме — светлая плитка), её видно издалека.
class _ReasonTile extends StatelessWidget {
  const _ReasonTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    final fg = selected ? t.onPrimary : t.ink;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 128 * s,
          padding: EdgeInsets.fromLTRB(16 * s, 14 * s, 12 * s, 14 * s),
          decoration: BoxDecoration(
            color: selected ? t.primary : t.surface,
            borderRadius: BorderRadius.circular(t.rCard),
            border: Border.all(color: selected ? t.primary : t.hairline, width: selected ? 2 : 1),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                right: 0,
                child: MirrorCheck(selected: selected, size: 24 * s, onDark: selected),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 44 * s,
                    height: 44 * s,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? t.onPrimary.withValues(alpha: 0.14) : t.selectedBg,
                    ),
                    child: Icon(icon, size: 24 * s, color: fg),
                  ),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.label(17 * s, weight: FontWeight.w700, color: fg).copyWith(height: 1.15),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Выбор под причиной (цвета, бренды, стили).
class _Panel extends StatelessWidget {
  const _Panel({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    return Padding(
      padding: EdgeInsets.only(top: 22 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: t.label(18 * s, weight: FontWeight.w700)),
          SizedBox(height: 12 * s),
          child,
        ],
      ),
    );
  }
}

class _FaceQuestion extends StatelessWidget {
  const _FaceQuestion({required this.liked, required this.onAnswer});

  final bool? liked;
  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    return Container(
      padding: EdgeInsets.fromLTRB(20 * s, 14 * s, 14 * s, 14 * s),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.rCard),
        border: Border.all(color: t.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.face_retouching_natural_outlined, size: 24 * s, color: t.ink),
              SizedBox(width: 12 * s),
              Expanded(
                child: Text(
                  l10n.mirrorRefineFaceShort,
                  style: t.label(17 * s, weight: FontWeight.w700),
                ),
              ),
              _Pill(label: l10n.mirrorYes, selected: liked == true, onTap: () => onAnswer(true)),
              SizedBox(width: 8 * s),
              _Pill(label: l10n.mirrorNo, selected: liked == false, onTap: () => onAnswer(false)),
            ],
          ),
          if (liked == false) ...[
            SizedBox(height: 10 * s),
            Text(l10n.mirrorFaceNoHint, style: t.subtitle(13.5 * s)),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.selected = false});

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(horizontal: 22 * s, vertical: 12 * s),
          decoration: BoxDecoration(
            color: selected ? t.primary : t.surface,
            borderRadius: BorderRadius.circular(t.rChip),
            border: Border.all(color: selected ? t.primary : t.hairline),
          ),
          child: Text(
            label,
            style: t.label(16 * s, weight: FontWeight.w600, color: selected ? t.onPrimary : t.ink),
          ),
        ),
      ),
    );
  }
}
