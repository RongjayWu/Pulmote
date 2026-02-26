import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../remotes/data/remotes_provider.dart';
import '../../../models/models.dart';
import '../../../services/api_client.dart';

class AddRemotePage extends ConsumerStatefulWidget {
  final String deviceId;
  const AddRemotePage({super.key, required this.deviceId});

  @override
  ConsumerState<AddRemotePage> createState() => _AddRemotePageState();
}

class _AddRemotePageState extends ConsumerState<AddRemotePage> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = 'remote';
  bool _loading = false;

  static const _iconOptions = [
    ('remote', Icons.settings_remote_rounded, '遙控器'),
    ('ac', Icons.ac_unit_rounded, '冷氣'),
    ('tv', Icons.tv_rounded, '電視'),
    ('fan', Icons.air_rounded, '風扇'),
    ('light', Icons.lightbulb_outline_rounded, '燈光'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請輸入遙控器名稱')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/remotes', data: {
        'deviceId': widget.deviceId,
        'name': _nameCtrl.text.trim(),
        'icon': _selectedIcon,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('遙控器新增成功！')),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('新增失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
        title: const Text('新增遙控器'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: '遙控器名稱',
                hintText: '例如：客廳冷氣',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
            ),
            const Gap(32),

            Text(
              '選擇圖示',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _iconOptions.map((opt) {
                final isSelected = _selectedIcon == opt.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = opt.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 90,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primaryContainer
                          : colors.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          opt.$2,
                          size: 28,
                          color: isSelected
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                        const Gap(8),
                        Text(
                          opt.$3,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : null,
                            color: isSelected
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
            const Gap(40),

            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text('新增遙控器'),
            ),
          ],
        ),
      ),
    );
  }
}
