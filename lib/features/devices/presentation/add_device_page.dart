import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../data/devices_provider.dart';

class AddDevicePage extends ConsumerStatefulWidget {
  const AddDevicePage({super.key});

  @override
  ConsumerState<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends ConsumerState<AddDevicePage> {
  final _nameCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();
  String _type = 'ir_blaster';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _topicCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請填寫所有欄位')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(devicesProvider.notifier).addDevice(
            name: _nameCtrl.text.trim(),
            mqttTopic: _topicCtrl.text.trim(),
            deviceType: _type,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('設備新增成功！')),
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
        title: const Text('新增設備'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Illustration
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(
                  Icons.developer_board_rounded,
                  size: 48,
                  color: colors.primary,
                ),
              ),
            ),
            const Gap(32),

            Text(
              '設備資訊',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(16),

            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '設備名稱',
                hintText: '例如：客廳 ESP32',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
            ),
            const Gap(16),

            TextField(
              controller: _topicCtrl,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'MQTT Topic',
                hintText: '例如：living-room',
                prefixIcon: Icon(Icons.tag_rounded),
                helperText: '設備的 MQTT 識別名稱，建議用英文小寫加連字號',
              ),
            ),
            const Gap(24),

            Text(
              '設備類型',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(12),

            Wrap(
              spacing: 12,
              children: [
                _TypeChip(
                  label: 'IR 發射器',
                  icon: Icons.settings_remote_rounded,
                  value: 'ir_blaster',
                  selected: _type == 'ir_blaster',
                  onTap: () => setState(() => _type = 'ir_blaster'),
                ),
                _TypeChip(
                  label: '感測器',
                  icon: Icons.sensors_rounded,
                  value: 'sensor',
                  selected: _type == 'sensor',
                  onTap: () => setState(() => _type = 'sensor'),
                ),
              ],
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
                  : const Text('新增設備'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const Gap(6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: colors.primaryContainer,
      checkmarkColor: colors.primary,
    );
  }
}
