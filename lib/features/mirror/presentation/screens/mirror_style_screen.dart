import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../../data/kiosk_taxonomy.dart';
import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_station_card.dart';

/// Шаг 03 — стиль (только ветка «создать»). Дизайн станции LIBAS: 8 стилей пола на
/// двух страницах по четыре, мультивыбор. Страницы листаются свайпом или стрелками,
/// где ты — показывают точки; выбор сохраняется между страницами, внизу — сколько и
/// что выбрано на обеих.
class MirrorStyleScreen extends StatefulWidget {
  const MirrorStyleScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  State<MirrorStyleScreen> createState() => _MirrorStyleScreenState();
}

class _MirrorStyleScreenState extends State<MirrorStyleScreen> {
  static const _perPage = 4;
  final _pager = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    widget.controller.touch();
    _pager.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

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
            child: PageView.builder(
              controller: _pager,
              itemCount: pages,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (p) {
                c.touch();
                setState(() => _page = p);
              },
              itemBuilder: (context, p) => MirrorStationGrid(
                children: [
                  for (final style in styles.skip(p * _perPage).take(_perPage))
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
          if (pages > 1) ...[
            SizedBox(height: 12 * s),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PageArrow(
                  icon: Icons.chevron_left_rounded,
                  label: l10n.mirrorStylesPrev,
                  onTap: page > 0 ? () => _goTo(page - 1) : null,
                ),
                SizedBox(width: 16 * s),
                for (var p = 0; p < pages; p++)
                  _PageDot(active: p == page, onTap: () => _goTo(p)),
                SizedBox(width: 16 * s),
                _PageArrow(
                  icon: Icons.chevron_right_rounded,
                  label: l10n.mirrorStylesNext,
                  onTap: page < pages - 1 ? () => _goTo(page + 1) : null,
                ),
              ],
            ),
          ],
          SizedBox(height: 12 * s),
          Text(
            l10n.mirrorStylesSelected(chosen.length),
            style: t.label(16 * s, weight: FontWeight.w700),
          ),
          SizedBox(height: 4 * s),
          // Место под список держим всегда — кнопка не прыгает при первом выборе.
          SizedBox(
            height: 36 * s,
            child: Text(
              chosen.map((st) => brand.styleLabel(st, lang)).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: t.subtitle(13 * s),
            ),
          ),
          SizedBox(height: 8 * s),
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

/// Круглая стрелка листания; null в [onTap] — край, стрелка гаснет.
class _PageArrow extends StatelessWidget {
  const _PageArrow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : 0.3,
          child: Container(
            width: 48 * s,
            height: 48 * s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: t.surface,
              border: Border.all(color: t.hairline),
            ),
            child: Icon(icon, size: 28 * s, color: t.ink),
          ),
        ),
      ),
    );
  }
}

/// Точка страницы: текущая вытягивается в черту цвета бренда.
class _PageDot extends StatelessWidget {
  const _PageDot({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5 * s, vertical: 12 * s),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: (active ? 28 : 10) * s,
          height: 10 * s,
          decoration: BoxDecoration(
            color: active ? t.primary : t.muted.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(5 * s),
          ),
        ),
      ),
    );
  }
}
