import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_station_card.dart';

/// Шаг 03 — стиль (только ветка «создать»). Дизайн станции LIBAS: 8 стилей пола на
/// двух страницах по четыре, мультивыбор, выбор сохраняется при переключении
/// страниц; внизу — сколько и что выбрано на обеих страницах.
class MirrorStyleScreen extends StatefulWidget {
  const MirrorStyleScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  State<MirrorStyleScreen> createState() => _MirrorStyleScreenState();
}

class _MirrorStyleScreenState extends State<MirrorStyleScreen> {
  static const _perPage = 4;
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    final lang = c.shopperLang;
    final brand = t.brand;
    final styles = brand.stylesFor(c.gender);
    final pages = (styles.length / _perPage).ceil().clamp(1, 99);
    final page = _page.clamp(0, pages - 1);
    final visible = styles.skip(page * _perPage).take(_perPage).toList();
    final chosen = styles.where((st) => c.styles.contains(st.code)).toList();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24 * s),
          MirrorStationHeading(
            kicker: c.gender == 'MALE' ? l10n.mirrorWardrobeMen : l10n.mirrorWardrobeWomen,
            title: l10n.mirrorStyleTitle,
            subtitle: l10n.mirrorStyleSubtitleStation,
          ),
          SizedBox(height: 24 * s),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: MirrorStationGrid(
                key: ValueKey(page),
                children: [
                  for (final style in visible)
                    MirrorStationCard(
                      title: brand.styleLabel(style, lang),
                      description: kioskStyleDescriptions[style.code]?.label(lang),
                      photo: kioskStylePhoto(c.gender, style.code),
                      multi: true,
                      selected: c.styles.contains(style.code),
                      onTap: () => c.toggleStyle(style.code!),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 14 * s),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.mirrorStylesSelected(chosen.length),
                      style: t.label(16 * s, weight: FontWeight.w700),
                    ),
                    if (chosen.isNotEmpty) ...[
                      SizedBox(height: 4 * s),
                      Text(
                        chosen.map((st) => brand.styleLabel(st, lang)).join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.subtitle(13 * s),
                      ),
                    ],
                  ],
                ),
              ),
              if (pages > 1)
                for (var p = 0; p < pages; p++)
                  Padding(
                    padding: EdgeInsets.only(left: 8 * s),
                    child: _PageChip(
                      label: l10n.mirrorStylesPage(
                        p * _perPage + 1,
                        ((p + 1) * _perPage).clamp(0, styles.length),
                        styles.length,
                      ),
                      selected: p == page,
                      onTap: () {
                        c.touch();
                        setState(() => _page = p);
                      },
                    ),
                  ),
            ],
          ),
          SizedBox(height: 16 * s),
          MirrorPrimaryButton(
            label: l10n.mirrorContinue,
            height: 64 * s,
            enabled: c.styles.isNotEmpty,
            onTap: c.confirmStyles,
          ),
          SizedBox(height: 24 * s),
        ],
      ),
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

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
          padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 14 * s),
          decoration: BoxDecoration(
            color: selected ? t.primary : t.surface,
            borderRadius: BorderRadius.circular(t.rChip),
            border: Border.all(color: selected ? t.primary : t.hairline),
          ),
          child: Text(
            label,
            style: t.label(14 * s, weight: FontWeight.w700, color: selected ? t.onPrimary : t.ink),
          ),
        ),
      ),
    );
  }
}
