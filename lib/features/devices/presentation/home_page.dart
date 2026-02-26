import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../auth/data/auth_provider.dart';
import '../data/devices_provider.dart';
import '../../../models/models.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final devices = ref.watch(devicesProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar.large(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '我的設備',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (user != null)
                  Text(
                    '嗨，${user.displayName ?? user.username}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: '登出',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('確認登出'),
                      content: const Text('確定要登出嗎？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            ref.read(authStateProvider.notifier).logout();
                          },
                          child: const Text('登出'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Gap(8),
            ],
          ),

          // Content
          devices.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: colors.error),
                    const Gap(16),
                    Text('載入失敗', style: theme.textTheme.titleMedium),
                    const Gap(8),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(devicesProvider),
                      child: const Text('重試'),
                    ),
                  ],
                ),
              ),
            ),
            data: (deviceList) {
              if (deviceList.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(
                            Icons.devices_other_rounded,
                            size: 56,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const Gap(24),
                        Text(
                          '尚未新增設備',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(8),
                        Text(
                          '點擊下方按鈕新增你的第一台 ESP32',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList.separated(
                  itemCount: deviceList.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (context, index) {
                    return _DeviceCard(device: deviceList[index]);
                  },
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/devices/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新增設備'),
      ),
    );
  }
}

class _DeviceCard extends ConsumerWidget {
  final Device device;
  const _DeviceCard({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final remotesAsync = ref.watch(remotesForDeviceProvider(device.id));

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Device icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: device.isOnline
                          ? colors.primaryContainer
                          : colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.developer_board_rounded,
                      color: device.isOnline
                          ? colors.primary
                          : colors.onSurfaceVariant,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: device.isOnline
                                    ? Colors.green
                                    : colors.outlineVariant,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              device.isOnline ? '在線' : '離線',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const Gap(12),
                            Text(
                              device.mqttTopic,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.outline,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // More options
                  PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'delete') {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('刪除設備'),
                            content: Text('確定刪除「${device.name}」？所有相關遙控器也會被刪除。'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('取消'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(
                                  backgroundColor: colors.error,
                                ),
                                child: const Text('刪除'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await ref
                              .read(devicesProvider.notifier)
                              .deleteDevice(device.id);
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            Gap(8),
                            Text('刪除設備'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Gap(16),
              const Divider(height: 1),
              const Gap(12),

              // Remotes list
              remotesAsync.when(
                loading: () => const SizedBox(
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (_, __) => Text(
                  '載入遙控器失敗',
                  style: TextStyle(color: colors.error),
                ),
                data: (remotes) {
                  if (remotes.isEmpty) {
                    return Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            '尚未新增遙控器',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              context.go('/remotes/add/${device.id}'),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('新增'),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      ...remotes.map(
                        (remote) => ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            _getRemoteIcon(remote.icon),
                            color: colors.primary,
                          ),
                          title: Text(remote.name),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                          ),
                          onTap: () =>
                              context.go('/remotes/${remote.id}/panel'),
                        ),
                      ),
                      const Gap(4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              context.go('/remotes/add/${device.id}'),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('新增遙控器'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getRemoteIcon(String icon) {
    switch (icon) {
      case 'ac':
        return Icons.ac_unit_rounded;
      case 'tv':
        return Icons.tv_rounded;
      case 'fan':
        return Icons.air_rounded;
      case 'light':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.settings_remote_rounded;
    }
  }
}
