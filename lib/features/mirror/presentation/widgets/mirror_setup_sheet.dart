import 'package:flutter/material.dart';

import '../../data/kiosk_api.dart';
import '../../data/kiosk_demo.dart';
import '../mirror_theme.dart';

/// Скрытый шит настройки киоска (5 касаний по словесному знаку на постере):
/// ключ устройства X-Kiosk-Key и принудительный демо-режим. Это экран
/// продавца, не покупателя — намеренно утилитарный и не локализованный
/// под язык покупателя.
class MirrorSetupSheet extends StatefulWidget {
  const MirrorSetupSheet({
    super.key,
    required this.api,
    required this.demo,
    this.fullscreen = false,
    this.onFullscreenChanged,
  });

  final KioskApi api;
  final KioskDemoService demo;
  final bool fullscreen;
  final ValueChanged<bool>? onFullscreenChanged;

  static Future<void> show(
    BuildContext context, {
    required KioskApi api,
    required KioskDemoService demo,
    bool fullscreen = false,
    ValueChanged<bool>? onFullscreenChanged,
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

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.api.deviceKey ?? '');
    _demoForced = widget.demo.forced;
    _fullscreen = widget.fullscreen;
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
      setState(() => _status =
          'OK · ${session.storeLabel} · товаров: ${session.catalogSize}');
    } on KioskApiException catch (e) {
      if (!mounted) return;
      setState(() => _status =
          'Ошибка: ${e.statusCode ?? 'сеть'} ${e.code ?? e.message}');
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Настройка киоска', style: MirrorTheme.headline(22)),
          const SizedBox(height: 4),
          Text(
            'Ключ устройства выдаётся при подключении магазина.',
            style: MirrorTheme.subtitle(13),
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
          if (widget.onFullscreenChanged != null)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Полноэкранный киоск-режим'),
              subtitle: const Text(
                'Скрывает вкладки продавца. Вернуться сюда — 5 касаний по логотипу.',
              ),
              value: _fullscreen,
              activeThumbColor: MirrorTheme.pink,
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
            activeThumbColor: MirrorTheme.pink,
            onChanged: (v) {
              setState(() => _demoForced = v);
              widget.demo.setForced(v);
            },
          ),
          if (_status != null) ...[
            const SizedBox(height: 8),
            Text(_status!, style: MirrorTheme.subtitle(13)),
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
