import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../data/remotes_provider.dart';
import '../../../models/models.dart';
import '../../../services/api_client.dart';

class RemotePanelPage extends ConsumerWidget {
  final String remoteId;
  const RemotePanelPage({super.key, required this.remoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final signalsAsync = ref.watch(signalsProvider(remoteId));

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('遙控面板'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: '編輯按鈕',
            onPressed: () => context.push('/remotes/$remoteId'),
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
              Center(
                child: Text('載入失敗', style: TextStyle(color: colors.error)),
              ),
            ],
          ),
          data: (signalList) {
            if (signalList.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const Gap(120),
                  _EmptyPanel(
                    onEdit: () => context.push('/remotes/$remoteId'),
                  ),
                ],
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                // Responsive grid: 3 cols on phones, 4 on large phones, 5+ on tablets
                final cols = constraints.maxWidth >= 900
                    ? 6
                    : constraints.maxWidth >= 720
                        ? 5
                        : constraints.maxWidth >= 480
                            ? 4
                            : 3;
                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: signalList.length,
                  itemBuilder: (context, index) =>
                      _IrButton(signal: signalList[index]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final VoidCallback onEdit;
  const _EmptyPanel({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.touch_app_rounded,
          size: 64,
          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const Gap(16),
        Text(
          '還沒有任何按鈕',
          style: theme.textTheme.titleMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const Gap(12),
        FilledButton.tonal(onPressed: onEdit, child: const Text('前往設定錄製')),
      ],
    );
  }
}

class _IrButton extends ConsumerStatefulWidget {
  final IrSignal signal;
  const _IrButton({required this.signal});

  @override
  ConsumerState<_IrButton> createState() => _IrButtonState();
}

class _IrButtonState extends ConsumerState<_IrButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCommand() async {
    HapticFeedback.mediumImpact();
    _animCtrl.forward().then((_) => _animCtrl.reverse());

    setState(() => _sending = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/signals/${widget.signal.id}/send');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('發送失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPower = widget.signal.icon == 'power' ||
        widget.signal.name.contains('開') ||
        widget.signal.name.contains('關');

    final bgColor =
        isPower ? colors.errorContainer : colors.surfaceContainerHigh;
    final fgColor = isPower ? colors.error : colors.primary;
    final labelColor =
        isPower ? colors.onErrorContainer : colors.onSurface;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          onTap: _sending ? null : _sendCommand,
          borderRadius: BorderRadius.circular(20),
          splashColor: fgColor.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_sending)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: fgColor,
                    ),
                  )
                else
                  Icon(_getIcon(widget.signal.icon), size: 28, color: fgColor),
                const Gap(8),
                Text(
                  widget.signal.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String icon) {
    switch (icon) {
      case 'power':
        return Icons.power_settings_new_rounded;
      case 'temp_up':
        return Icons.keyboard_arrow_up_rounded;
      case 'temp_down':
        return Icons.keyboard_arrow_down_rounded;
      case 'fan':
        return Icons.air_rounded;
      case 'mode':
        return Icons.tune_rounded;
      case 'swing':
        return Icons.swap_vert_rounded;
      case 'timer':
        return Icons.timer_rounded;
      case 'vol_up':
        return Icons.volume_up_rounded;
      case 'vol_down':
        return Icons.volume_down_rounded;
      case 'mute':
        return Icons.volume_off_rounded;
      case 'ch_up':
        return Icons.arrow_upward_rounded;
      case 'ch_down':
        return Icons.arrow_downward_rounded;
      default:
        return Icons.radio_button_checked_rounded;
    }
  }
}
