import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../data/remotes_provider.dart';
import '../../../models/models.dart';
import '../../../services/api_client.dart';

class RemoteDetailPage extends ConsumerWidget {
  final String remoteId;
  const RemoteDetailPage({super.key, required this.remoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final signalsAsync = ref.watch(signalsProvider(remoteId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('遙控器設定'),
        actions: [
          IconButton(
            icon: const Icon(Icons.gamepad_rounded),
            tooltip: '開啟遙控面板',
            onPressed: () => context.push('/remotes/$remoteId/panel'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(signalsProvider(remoteId));
          await ref.read(signalsProvider(remoteId).future);
        },
        child: signalsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const Gap(120),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colors.error),
                  const Gap(16),
                  const Text('載入失敗'),
                  const Gap(12),
                  FilledButton.tonal(
                    onPressed: () =>
                        ref.invalidate(signalsProvider(remoteId)),
                    child: const Text('重試'),
                  ),
                ],
              ),
            ],
          ),
          data: (signalList) {
            if (signalList.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const Gap(96),
                  _EmptySignalsView(onRecord: () => _startRecording(context, ref)),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: signalList.length,
              separatorBuilder: (_, __) => const Gap(8),
              itemBuilder: (context, index) {
                final signal = signalList[index];
                return _SignalTile(
                  signal: signal,
                  onDelete: () => _deleteSignal(context, ref, signal),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _startRecording(context, ref),
        icon: const Icon(Icons.fiber_manual_record_rounded),
        label: const Text('錄製新按鈕'),
        backgroundColor: colors.error,
        foregroundColor: colors.onError,
      ),
    );
  }

  Future<void> _startRecording(BuildContext context, WidgetRef ref) async {
    // Need the device ID to trigger recording on the right ESP32
    String? deviceId;
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/remotes');
      final remotes = (res.data as List)
          .map((e) => Remote.fromJson(e))
          .where((r) => r.id == remoteId)
          .toList();
      if (remotes.isEmpty) throw Exception('Remote not found');
      deviceId = remotes.first.deviceId;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法取得設備資訊：$e')),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final result = await showDialog<_RecordResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _RecordDialog(deviceId: deviceId!),
    );

    if (result == null || !context.mounted) return;

    // Ask user for button name + icon
    final meta = await showDialog<_SignalMeta>(
      context: context,
      builder: (ctx) => const _NameSignalDialog(),
    );
    if (meta == null || !context.mounted) return;

    // Save the signal
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/signals', data: {
        'remoteId': remoteId,
        'name': meta.name,
        'icon': meta.icon,
        'rawData': result.rawData,
        if (result.protocol != null) 'protocol': result.protocol,
        'frequency': result.frequency,
      });
      ref.invalidate(signalsProvider(remoteId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已新增按鈕「${meta.name}」')),
        );
      }
    } on DioException catch (e) {
      if (context.mounted) {
        final msg = e.response?.data?['error']?.toString() ?? e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗：$msg')),
        );
      }
    }
  }

  Future<void> _deleteSignal(
    BuildContext context,
    WidgetRef ref,
    IrSignal signal,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除按鈕'),
        content: Text('確定刪除「${signal.name}」？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/signals/${signal.id}');
      ref.invalidate(signalsProvider(remoteId));
    } on DioException catch (e) {
      if (context.mounted) {
        final msg = e.response?.data?['error']?.toString() ?? e.message;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('刪除失敗：$msg')),
        );
      }
    }
  }
}

class _SignalTile extends StatelessWidget {
  final IrSignal signal;
  final VoidCallback onDelete;
  const _SignalTile({required this.signal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_signalIcon(signal.icon), color: colors.primary),
        ),
        title: Text(
          signal.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${signal.protocol ?? 'RAW'} · ${signal.frequency}Hz',
          style: theme.textTheme.bodySmall,
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete_outline_rounded, color: colors.error),
          tooltip: '刪除',
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _EmptySignalsView extends StatelessWidget {
  final VoidCallback onRecord;
  const _EmptySignalsView({required this.onRecord});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(
            Icons.radio_button_unchecked,
            size: 48,
            color: colors.onSurfaceVariant,
          ),
        ),
        const Gap(24),
        Text('尚未錄製任何按鈕', style: theme.textTheme.titleMedium),
        const Gap(8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            '將原廠遙控器對準 ESP32，點擊下方按鈕開始錄製',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ),
        const Gap(20),
        FilledButton.tonalIcon(
          onPressed: onRecord,
          icon: const Icon(Icons.fiber_manual_record_rounded),
          label: const Text('開始錄製'),
        ),
      ],
    );
  }
}

class _RecordResult {
  final dynamic rawData;
  final String? protocol;
  final int frequency;
  _RecordResult({
    required this.rawData,
    this.protocol,
    this.frequency = 38000,
  });
}

/// Dialog that asks the backend to put the ESP32 into record mode, waits for
/// the device to capture an IR signal, and returns the raw data.
///
/// Currently the backend fires the MQTT trigger but doesn't persist the
/// recorded payload back to the HTTP API. Until that's wired up, this dialog
/// accepts manually-pasted raw data as a fallback so users can still create
/// signals.
class _RecordDialog extends ConsumerStatefulWidget {
  final String deviceId;
  const _RecordDialog({required this.deviceId});

  @override
  ConsumerState<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends ConsumerState<_RecordDialog> {
  final _rawCtrl = TextEditingController();
  final _protocolCtrl = TextEditingController();
  final _freqCtrl = TextEditingController(text: '38000');
  bool _triggering = false;
  bool _triggered = false;
  String? _error;

  @override
  void dispose() {
    _rawCtrl.dispose();
    _protocolCtrl.dispose();
    _freqCtrl.dispose();
    super.dispose();
  }

  Future<void> _trigger() async {
    setState(() {
      _triggering = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/signals/record', data: {'deviceId': widget.deviceId});
      if (mounted) setState(() => _triggered = true);
    } on DioException catch (e) {
      if (mounted) {
        setState(() =>
            _error = e.response?.data?['error']?.toString() ?? e.message);
      }
    } finally {
      if (mounted) setState(() => _triggering = false);
    }
  }

  void _submit() {
    final raw = _rawCtrl.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = '請貼上或等待 ESP32 回傳 raw data');
      return;
    }
    // Try to parse as JSON array, fall back to comma-separated numbers
    dynamic parsed;
    try {
      parsed = raw.startsWith('[')
          ? raw
          : raw
              .split(RegExp(r'[,\s]+'))
              .where((s) => s.isNotEmpty)
              .map(int.parse)
              .toList();
    } catch (_) {
      parsed = raw;
    }
    Navigator.pop(
      context,
      _RecordResult(
        rawData: parsed,
        protocol: _protocolCtrl.text.trim().isEmpty
            ? null
            : _protocolCtrl.text.trim(),
        frequency: int.tryParse(_freqCtrl.text) ?? 38000,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AlertDialog(
      title: const Text('錄製 IR 按鈕'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_triggered)
                Text(
                  '點擊「啟動錄製」會通知 ESP32 進入學習模式。請對準設備後按下原廠遙控器上的按鈕。',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sensors_rounded, color: colors.primary),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          'ESP32 已進入錄製模式，請按下遙控器按鈕後把 raw data 貼到下方',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              const Gap(16),
              TextField(
                controller: _rawCtrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Raw data (JSON 陣列或逗號分隔)',
                  hintText: '例如: [9000, 4500, 560, 560, ...]',
                ),
              ),
              const Gap(12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _protocolCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Protocol (選填)',
                        hintText: 'NEC / SONY / RAW',
                      ),
                    ),
                  ),
                  const Gap(12),
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _freqCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '頻率 Hz'),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const Gap(12),
                Text(_error!, style: TextStyle(color: colors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        if (!_triggered)
          FilledButton.tonal(
            onPressed: _triggering ? null : _trigger,
            child: _triggering
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('啟動錄製'),
          ),
        FilledButton(
          onPressed: _submit,
          child: const Text('儲存'),
        ),
      ],
    );
  }
}

class _SignalMeta {
  final String name;
  final String icon;
  _SignalMeta(this.name, this.icon);
}

class _NameSignalDialog extends StatefulWidget {
  const _NameSignalDialog();

  @override
  State<_NameSignalDialog> createState() => _NameSignalDialogState();
}

class _NameSignalDialogState extends State<_NameSignalDialog> {
  final _ctrl = TextEditingController();
  String _icon = 'power';

  static const _icons = <(String, IconData, String)>[
    ('power', Icons.power_settings_new_rounded, '電源'),
    ('temp_up', Icons.keyboard_arrow_up_rounded, '溫度+'),
    ('temp_down', Icons.keyboard_arrow_down_rounded, '溫度-'),
    ('vol_up', Icons.volume_up_rounded, '音量+'),
    ('vol_down', Icons.volume_down_rounded, '音量-'),
    ('mute', Icons.volume_off_rounded, '靜音'),
    ('fan', Icons.air_rounded, '風速'),
    ('mode', Icons.tune_rounded, '模式'),
    ('swing', Icons.swap_vert_rounded, '擺動'),
    ('timer', Icons.timer_rounded, '定時'),
    ('ch_up', Icons.arrow_upward_rounded, '頻道+'),
    ('ch_down', Icons.arrow_downward_rounded, '頻道-'),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return AlertDialog(
      title: const Text('命名按鈕'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _ctrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '按鈕名稱',
                  hintText: '例如：電源、冷氣 26°C',
                ),
              ),
              const Gap(16),
              Text(
                '圖示',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((opt) {
                  final selected = _icon == opt.$1;
                  return InkWell(
                    onTap: () => setState(() => _icon = opt.$1),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.primaryContainer
                            : colors.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              selected ? colors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            opt.$2,
                            size: 22,
                            color: selected
                                ? colors.primary
                                : colors.onSurfaceVariant,
                          ),
                          const Gap(4),
                          Text(
                            opt.$3,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final name = _ctrl.text.trim();
            if (name.isEmpty) return;
            Navigator.pop(context, _SignalMeta(name, _icon));
          },
          child: const Text('完成'),
        ),
      ],
    );
  }
}

IconData _signalIcon(String icon) {
  switch (icon) {
    case 'power':
      return Icons.power_settings_new_rounded;
    case 'temp_up':
      return Icons.keyboard_arrow_up_rounded;
    case 'temp_down':
      return Icons.keyboard_arrow_down_rounded;
    case 'vol_up':
      return Icons.volume_up_rounded;
    case 'vol_down':
      return Icons.volume_down_rounded;
    case 'mute':
      return Icons.volume_off_rounded;
    case 'fan':
      return Icons.air_rounded;
    case 'mode':
      return Icons.tune_rounded;
    case 'swing':
      return Icons.swap_vert_rounded;
    case 'timer':
      return Icons.timer_rounded;
    case 'ch_up':
      return Icons.arrow_upward_rounded;
    case 'ch_down':
      return Icons.arrow_downward_rounded;
    default:
      return Icons.radio_button_checked_rounded;
  }
}
