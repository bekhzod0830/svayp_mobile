import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_ffi_uvc/flutter_ffi_uvc.dart';

import '../../data/kiosk_api.dart';
import '../../data/kiosk_camera.dart';
import '../../data/kiosk_demo.dart';

/// Скрытый шит настройки киоска (5 касаний по знаку бренда на постере):
/// ключ устройства X-Kiosk-Key, принудительный демо-режим и выбор камеры.
/// Это экран
/// продавца, не покупателя — намеренно утилитарный, не локализованный под
/// язык покупателя и без токенов бренда: шит строится в оверлее корневого
/// Navigator'а, где оформления киоска нет.
class MirrorSetupSheet extends StatefulWidget {
  const MirrorSetupSheet({
    super.key,
    required this.api,
    required this.demo,
    this.fullscreen = false,
    this.onFullscreenChanged,
    this.brandName,
    this.onChooseBrand,
    this.cameraName,
    this.onCameraChanged,
    this.uvcMaxWidth = kUvcMaxWidth,
    this.onUvcMaxWidthChanged,
    this.cameraDebug = false,
    this.onCameraDebugChanged,
  });

  final KioskApi api;
  final KioskDemoService demo;
  final bool fullscreen;
  final ValueChanged<bool>? onFullscreenChanged;

  /// Текущее оформление и переход к экрану выбора.
  final String? brandName;
  final VoidCallback? onChooseBrand;

  /// Камера, выбранная вручную (null — авто), и её смена.
  final String? cameraName;
  final ValueChanged<String?>? onCameraChanged;

  /// Планка качества USB-камеры напрямую (ширина кадра) и её смена.
  final int uvcMaxWidth;
  final ValueChanged<int>? onUvcMaxWidthChanged;

  /// Диагностика потока в углу экрана камеры и её тумблер.
  final bool cameraDebug;
  final ValueChanged<bool>? onCameraDebugChanged;

  static Future<void> show(
    BuildContext context, {
    required KioskApi api,
    required KioskDemoService demo,
    bool fullscreen = false,
    ValueChanged<bool>? onFullscreenChanged,
    String? brandName,
    VoidCallback? onChooseBrand,
    String? cameraName,
    ValueChanged<String?>? onCameraChanged,
    int uvcMaxWidth = kUvcMaxWidth,
    ValueChanged<int>? onUvcMaxWidthChanged,
    bool cameraDebug = false,
    ValueChanged<bool>? onCameraDebugChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => MirrorSetupSheet(
        api: api,
        demo: demo,
        fullscreen: fullscreen,
        onFullscreenChanged: onFullscreenChanged,
        brandName: brandName,
        onChooseBrand: onChooseBrand,
        cameraName: cameraName,
        onCameraChanged: onCameraChanged,
        uvcMaxWidth: uvcMaxWidth,
        onUvcMaxWidthChanged: onUvcMaxWidthChanged,
        cameraDebug: cameraDebug,
        onCameraDebugChanged: onCameraDebugChanged,
      ),
    );
  }

  @override
  State<MirrorSetupSheet> createState() => _MirrorSetupSheetState();
}

class _MirrorSetupSheetState extends State<MirrorSetupSheet> {
  late final TextEditingController _keyController;
  late bool _demoForced;
  late bool _fullscreen;
  String? _status;
  bool _testing = false;

  String? _cameraName;
  late int _uvcMaxWidth;
  late bool _cameraDebug;

  /// Что видит планшет прямо сейчас (USB напрямую + камеры Android);
  /// null — ещё ищем.
  List<KioskCameraOption>? _cameras;

  /// Втыкание/выдёргивание USB-камеры — список обновляется сам.
  StreamSubscription<UvcDeviceEvent>? _usbSub;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.api.deviceKey ?? '');
    _demoForced = widget.demo.forced;
    _fullscreen = widget.fullscreen;
    _cameraName = widget.cameraName;
    _uvcMaxWidth = widget.uvcMaxWidth;
    _cameraDebug = widget.cameraDebug;
    if (widget.onCameraChanged != null) {
      _scanCameras();
      if (Platform.isAndroid) {
        try {
          _usbSub = uvcCamera.deviceEvents.listen((_) => _scanCameras());
        } catch (_) {}
      }
    }
  }

  Future<void> _scanCameras() async {
    setState(() => _cameras = null);
    final cameras = await listKioskCameras();
    if (mounted) setState(() => _cameras = cameras);
  }

  void _chooseCamera(String? name) {
    setState(() => _cameraName = name);
    widget.onCameraChanged!(name);
  }

  void _chooseUvcMaxWidth(int width) {
    setState(() => _uvcMaxWidth = width);
    widget.onUvcMaxWidthChanged?.call(width);
  }

  /// Что реально отдала USB-камера при последнем запуске: режим потока и
  /// почему не крупнее. Пока экран камеры не открывался — пусто.
  Widget _buildUvcStatus(TextTheme textTheme) {
    return ValueListenableBuilder<KioskUvcStatus?>(
      valueListenable: kioskUvcStatus,
      builder: (context, status, _) {
        if (status == null) {
          return Text(
            'Поток: ещё не запускался — откройте экран камеры, и здесь '
            'появится реальный режим.',
            style: textTheme.bodySmall,
          );
        }
        final mode = status.mode;
        final mjpeg = status.supportedModes
            .where((m) => m.formatName == 'MJPEG')
            .map((m) => '${m.width}x${m.height}@${m.fps}')
            .toSet()
            .join(', ');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mode == null
                  ? 'Поток: не запустился ни в одном режиме'
                  : 'Поток сейчас: ${mode.label}',
              style: textTheme.bodyMedium,
            ),
            if (status.attempts.length > 1)
              Text(
                'Пробовали: ${status.attempts.join('; ')}',
                style: textTheme.bodySmall,
              ),
            if (mjpeg.isNotEmpty)
              Text('Камера умеет (MJPEG): $mjpeg', style: textTheme.bodySmall),
          ],
        );
      },
    );
  }

  Widget _buildCameraSection(TextTheme textTheme) {
    final cameras = _cameras;
    final auto = cameras == null ? null : pickKioskCamera(cameras);
    // Выбранная вручную камера сейчас не подключена — киоск откроет авто.
    final missing =
        _cameraName != null &&
        cameras != null &&
        cameras.every((c) => c.id != _cameraName);
    final hasUvc = cameras?.any((c) => c.kind == KioskCameraKind.uvc) ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Камера', style: textTheme.titleMedium)),
            IconButton(
              tooltip: 'Найти камеры заново',
              icon: const Icon(Icons.refresh),
              onPressed: cameras == null ? null : _scanCameras,
            ),
          ],
        ),
        if (cameras == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          )
        else if (cameras.isEmpty)
          Text(
            'Планшет не видит ни одной камеры. Проверьте, что USB-камера '
            'воткнута в порт с поддержкой USB-host (OTG) и горит индикатор; '
            'список обновится сам.',
            style: textTheme.bodySmall,
          )
        else
          RadioGroup<String?>(
            groupValue: missing ? null : _cameraName,
            onChanged: _chooseCamera,
            child: Column(
              children: [
                RadioListTile<String?>(
                  contentPadding: EdgeInsets.zero,
                  value: null,
                  title: const Text('Авто — USB-камера, если подключена'),
                  subtitle: Text(auto == null ? '—' : 'Сейчас: ${auto.label}'),
                ),
                for (final c in cameras)
                  RadioListTile<String?>(
                    contentPadding: EdgeInsets.zero,
                    value: c.id,
                    title: Text(c.label),
                  ),
              ],
            ),
          ),
        if (missing)
          Text(
            'Выбранная камера ($_cameraName) не подключена — '
            'используется авто.',
            style: textTheme.bodySmall,
          ),
        if (hasUvc && widget.onUvcMaxWidthChanged != null) ...[
          const SizedBox(height: 12),
          Text('Качество USB-камеры', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            'Верхняя планка кадра. 2K даёт больше деталей, но тяжелее для '
            'USB и процессора планшета и может идти рывками — тогда Full HD. '
            'На экране 1080p разницы в резкости между 2K и Full HD нет.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: [
              for (final e in kUvcQualityOptions.entries)
                ButtonSegment(value: e.key, label: Text(e.value)),
            ],
            selected: {_uvcMaxWidth},
            onSelectionChanged: (s) => _chooseUvcMaxWidth(s.first),
          ),
          const SizedBox(height: 8),
          _buildUvcStatus(textTheme),
        ],
        if (widget.onCameraDebugChanged != null)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Диагностика камеры на экране'),
            subtitle: const Text(
              'Режим, реальные fps и пропуски кадров мелким текстом в углу '
              'экрана камеры. Для настройки, покупателям выключить.',
            ),
            value: _cameraDebug,
            onChanged: (v) {
              setState(() => _cameraDebug = v);
              widget.onCameraDebugChanged!(v);
            },
          ),
      ],
    );
  }

  @override
  void dispose() {
    _usbSub?.cancel();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _status = null;
    });
    await widget.api.setDeviceKey(_keyController.text);
    try {
      final session = await widget.api.startSession('ru', 'create');
      // Пробную сессию сразу закрываем — она не должна висеть на бэкенде.
      widget.api.resetSession(session.sessionId).catchError((_) {});
      if (!mounted) return;
      setState(
        () => _status =
            'OK · ${session.storeLabel} · товаров: ${session.catalogSize}',
      );
    } on KioskApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _status =
            'Ошибка: ${e.statusCode ?? 'сеть'} ${e.code ?? e.message}',
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Настройка киоска', style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Ключ устройства выдаётся при подключении магазина.',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _keyController,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'X-Kiosk-Key',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.onChooseBrand != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Сменить оформление'),
              subtitle: Text('Сейчас: ${widget.brandName ?? '—'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pop();
                widget.onChooseBrand!();
              },
            ),
          if (widget.onFullscreenChanged != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Полноэкранный киоск-режим'),
              subtitle: const Text(
                'Скрывает вкладки продавца. Вернуться сюда — 5 касаний по логотипу.',
              ),
              value: _fullscreen,
              onChanged: (v) {
                setState(() => _fullscreen = v);
                widget.onFullscreenChanged!(v);
              },
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Демо-режим (принудительно)'),
            subtitle: const Text(
              'Каталог настоящий, примерка имитируется. Для показов.',
            ),
            value: _demoForced,
            onChanged: (v) {
              setState(() => _demoForced = v);
              widget.demo.setForced(v);
            },
          ),
          if (widget.onCameraChanged != null) ...[
            const SizedBox(height: 8),
            _buildCameraSection(textTheme),
          ],
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, style: textTheme.bodySmall),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _testing ? null : _testConnection,
                  child: _testing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Проверить связь'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await widget.api.setDeviceKey(_keyController.text);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Сохранить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
