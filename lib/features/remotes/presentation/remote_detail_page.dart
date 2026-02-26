import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../data/remotes_provider.dart';
import '../../../models/models.dart';

class RemoteDetailPage extends ConsumerWidget {
  final String remoteId;
  const RemoteDetailPage({super.key, required this.remoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final signals = ref.watch(signalsProvider(remoteId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('遙控器詳情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.gamepad_rounded),
            tooltip: '開啟遙控面板',
            onPressed: () => context.go('/remotes/$remoteId/panel'),
          ),
        ],
      ),
      body: signals.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const Gap(16),
              Text('載入失敗'),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(signalsProvider(remoteId)),
                child: const Text('重試'),
              ),
            ],
          ),
        ),
        data: (signalList) {
          if (signalList.isEmpty) {
            return Center(
              child: Column(
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
                  Text(
                    '尚未錄製任何按鈕',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Gap(8),
                  Text(
                    '將 ESP32 對準遙控器\n按下「錄製」來新增按鈕',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: signalList.length,
            separatorBuilder: (_, __) => const Gap(8),
            itemBuilder: (context, index) {
              final signal = signalList[index];
              return Card(
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getSignalIcon(signal.icon),
                      color: colors.primary,
                    ),
                  ),
                  title: Text(signal.name),
                  subtitle: Text(
                    signal.protocol ?? 'RAW',
                    style: theme.textTheme.bodySmall,
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.outline,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Trigger recording via MQTT
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('錄製功能需搭配 ESP32 使用')),
          );
        },
        icon: const Icon(Icons.fiber_manual_record_rounded),
        label: const Text('錄製'),
        backgroundColor: colors.error,
        foregroundColor: colors.onError,
      ),
    );
  }

  IconData _getSignalIcon(String icon) {
    switch (icon) {
      case 'power':
        return Icons.power_settings_new_rounded;
      case 'temp_up':
        return Icons.arrow_upward_rounded;
      case 'temp_down':
        return Icons.arrow_downward_rounded;
      case 'fan':
        return Icons.air_rounded;
      case 'mode':
        return Icons.tune_rounded;
      default:
        return Icons.radio_button_checked_rounded;
    }
  }
}
