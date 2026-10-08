import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';

import '../mirror_session_controller.dart';
import '../mirror_theme.dart';
import '../widgets/mirror_buttons.dart';
import '../widgets/mirror_station_card.dart';
import 'mirror_shop_brand_screen.dart';

/// Шаг после брендов (только ветка «создать»): цвета, которых НЕ должно быть в
/// образе. Отмечать необязательно — «Пропустить» показывает все цвета. Плашка над
/// сеткой всё время напоминает, что отмеченное исключается, а не выбирается.
class MirrorColorsScreen extends StatelessWidget {
  const MirrorColorsScreen({super.key, required this.controller});

  final MirrorSessionController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = mirrorStationScale(context);
    final c = controller;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24 * s),
          MirrorStationHeading(
            kicker: l10n.mirrorAvoidKicker,
            title: l10n.mirrorColorsTitle,
            subtitle: l10n.mirrorAvoidSubtitle,
          ),
          SizedBox(height: 16 * s),
          _AvoidBanner(count: c.avoidColors.length),
          SizedBox(height: 16 * s),
          Expanded(
            child: MirrorColorGrid(
              lang: c.shopperLang,
              selected: c.avoidColors.toSet(),
              onToggle: c.toggleAvoidColor,
            ),
          ),
          SizedBox(height: 16 * s),
          Row(
            children: [
              Expanded(
                child: MirrorGhostButton(
                  label: l10n.mirrorSkip,
                  height: 64 * s,
                  onTap: () => c.confirmColors(skip: true),
                ),
              ),
              SizedBox(width: 14 * s),
              Expanded(
                flex: 2,
                child: MirrorPrimaryButton(
                  label: l10n.mirrorCtaCreate,
                  height: 64 * s,
                  onTap: c.confirmColors,
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

/// «Исключено цветов: N» знаком «нет» цветом ошибки; пока ничего не отмечено —
/// спокойное «покажем все цвета».
class _AvoidBanner extends StatelessWidget {
  const _AvoidBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = MirrorTheme.of(context);
    final s = mirrorStationScale(context);
    final active = count > 0;
    final fg = active ? t.danger : t.muted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
      decoration: BoxDecoration(
        color: active ? t.danger.withValues(alpha: 0.1) : t.surface,
        borderRadius: BorderRadius.circular(t.rChip),
        border: Border.all(color: active ? t.danger : t.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block_rounded, size: 20 * s, color: fg),
          SizedBox(width: 10 * s),
          Flexible(
            child: Text(
              active ? l10n.mirrorAvoidCount(count) : l10n.mirrorAvoidNone,
              style: t.label(15 * s, weight: FontWeight.w600, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
