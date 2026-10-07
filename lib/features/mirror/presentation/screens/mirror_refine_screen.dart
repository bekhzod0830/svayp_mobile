import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_station_card.dart';
import 'mirror_shop_brand_screen.dart';

/// «Что изменить?» — перед «Пересобрать» в ветке «создать» (задача 7 по
/// планшетам): быстрые кнопки «Дешевле / Дороже / Другой цвет / Другой бренд /
/// Поменять стиль» и вопрос про лицо. «Другой цвет» открывает сетку цветов,
/// «Другой бренд» и «Поменять стиль» — список под кнопкой.
class MirrorRefineScreen extends StatefulWidget {
  const MirrorRefineScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  State<MirrorRefineScreen> createState() => _MirrorRefineScreenState();
}

enum _Open { none, brand, style }

class _MirrorRefineScreenState extends State<MirrorRefineScreen> {
  bool _colors = false;
  _Open _open = _Open.none;
  final Set<String> _avoid = {};

  MirrorSessionController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    return _colors ? _colorsView(context) : _menu(context);
  }

  Widget _menu(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    final lang = c.shopperLang;
    final otherStyles = t.brand.stylesFor(c.gender).where((st) => !c.styles.contains(st.code)).toList();

    Widget option(String label, IconData icon, VoidCallback onTap, {bool open = false}) => Padding(
          padding: EdgeInsets.only(bottom: 12 * s),
          child: _OptionRow(label: label, icon: icon, open: open, onTap: onTap),
        );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24 * s),
          MirrorStationHeading(title: l10n.mirrorRefineTitle, subtitle: l10n.mirrorRefineSubtitle),
          SizedBox(height: 22 * s),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                _FaceQuestion(
                  liked: c.faceLiked,
                  onAnswer: c.setFaceLiked,
                ),
                SizedBox(height: 20 * s),
                option(l10n.mirrorRefineCheaper, Icons.south_rounded, () => c.rebuild('CHEAPER')),
                option(l10n.mirrorRefinePricier, Icons.north_rounded, () => c.rebuild('PRICIER')),
                option(l10n.mirrorRefineColor, Icons.palette_outlined, () {
                  c.touch();
                  setState(() => _colors = true);
                }),
                option(
                  l10n.mirrorRefineBrand,
                  Icons.storefront_outlined,
                  () => _toggle(_Open.brand),
                  open: _open == _Open.brand,
                ),
                if (_open == _Open.brand)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16 * s),
                    child: MirrorBrandGrid(
                      shrinkWrap: true,
                      selected: null,
                      exclude: c.shopBrand,
                      onPick: (code) => c.rebuild('BRAND', brand: code),
                    ),
                  ),
                option(
                  l10n.mirrorRefineStyle,
                  Icons.style_outlined,
                  () => _toggle(_Open.style),
                  open: _open == _Open.style,
                ),
                if (_open == _Open.style)
                  Padding(
                    padding: EdgeInsets.only(bottom: 16 * s),
                    child: Wrap(
                      spacing: 10 * s,
                      runSpacing: 10 * s,
                      children: [
                        for (final st in otherStyles)
                          _Pill(
                            label: t.brand.styleLabel(st, lang),
                            onTap: () => c.rebuild('STYLE', style: st.code),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 12 * s),
          MirrorGhostButton(
            label: l10n.mirrorRefineAgain,
            height: 56 * s,
            enabled: c.canRegenerate,
            onTap: () => c.rebuild(null),
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }

  void _toggle(_Open which) {
    c.touch();
    setState(() => _open = _open == which ? _Open.none : which);
  }

  Widget _colorsView(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = mirrorStationScale(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24 * s),
          MirrorStationHeading(title: l10n.mirrorColorsTitle, subtitle: l10n.mirrorColorsSubtitle),
          SizedBox(height: 22 * s),
          Expanded(
            child: MirrorColorGrid(
              lang: c.shopperLang,
              selected: _avoid,
              onToggle: (code) {
                c.touch();
                setState(() => _avoid.contains(code) ? _avoid.remove(code) : _avoid.add(code));
              },
            ),
          ),
          SizedBox(height: 16 * s),
          Row(
            children: [
              Expanded(
                child: MirrorGhostButton(
                  label: l10n.mirrorSkip,
                  height: 64 * s,
                  onTap: () => c.rebuild('COLOR'),
                ),
              ),
              SizedBox(width: 14 * s),
              Expanded(
                flex: 2,
                child: MirrorPrimaryButton(
                  label: l10n.mirrorContinue,
                  height: 64 * s,
                  enabled: _avoid.isNotEmpty,
                  onTap: () => c.rebuild('COLOR', colors: _avoid.toList()),
                ),
              ),
            ],
          ),
          SizedBox(height: 24 * s),
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
      padding: EdgeInsets.all(18 * s),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(t.rCard),
        border: Border.all(color: t.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mirrorFaceQuestion, style: t.label(17 * s, weight: FontWeight.w700)),
          SizedBox(height: 14 * s),
          Row(
            children: [
              _Pill(label: l10n.mirrorYes, selected: liked == true, onTap: () => onAnswer(true)),
              SizedBox(width: 10 * s),
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

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.label, required this.icon, required this.onTap, this.open = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool open;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 68 * s,
          padding: EdgeInsets.symmetric(horizontal: 20 * s),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(t.rButton),
            border: Border.all(color: open ? t.primary : t.hairline, width: open ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 24 * s, color: t.ink),
              SizedBox(width: 16 * s),
              Expanded(child: Text(label, style: t.label(18 * s, weight: FontWeight.w600))),
              Icon(open ? Icons.expand_less_rounded : Icons.chevron_right_rounded, size: 26 * s, color: t.muted),
            ],
          ),
        ),
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
          padding: EdgeInsets.symmetric(horizontal: 26 * s, vertical: 14 * s),
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
