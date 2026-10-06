import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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

  /// Что видит Android прямо сейчас; null — ещё ищем.
  List<CameraDescription>? _cameras;
  String? _camerasError;

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.api.deviceKey ?? '');
    _demoForced = widget.demo.forced;
    _fullscreen = widget.fullscreen;
    _cameraName = widget.cameraName;
    if (widget.onCameraChanged != null) _scanCameras();
  }

  Future<void> _scanCameras() async {
    setState(() {
      _cameras = null;
      _camerasError = null;
    });
    try {
      final cameras = await availableCameras();
      if (mounted) setState(() => _cameras = cameras);
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameras = const [];
          _camerasError = '$e';
        });
      }
    }
  }

  void _chooseCamera(String? name) {
    setState(() => _cameraName = name);
    widget.onCameraChanged!(name);
  }

  Widget _buildCameraSection(TextTheme textTheme) {
    final cameras = _cameras;
    final auto = cameras == null ? null : pickKioskCamera(cameras);
    // Выбранная вручную камера сейчас не подключена — киоск откроет авто.
    final missing = _cameraName != null &&
        cameras != null &&
        cameras.every((c) => c.name != _cameraName);
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
            'Android не видит ни одной камеры. Подключите USB-камеру до '
            'запуска приложения и перезапустите его. Если камеру не видит '
            'и системное приложение «Камера» — планшет не поддерживает '
            'USB-камеры (UVC).'
            '${_camerasError != null ? '\n$_camerasError' : ''}',
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
                  subtitle: Text(
                    auto == null ? '—' : 'Сейчас: ${kioskCameraLabel(auto)}',
                  ),
                ),
                for (final c in cameras)
                  RadioListTile<String?>(
                    contentPadding: EdgeInsets.zero,
                    value: c.name,
                    title: Text(kioskCameraLabel(c)),
                  ),
              ],
            ),
          ),
        if (missing)
          Text(
            'Выбранная камера (id $_cameraName) не подключена — '
            'используется авто.',
            style: textTheme.bodySmall,
          ),
      ],
    );
  }

  @override
  void dispose() {
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
