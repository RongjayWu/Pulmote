import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/smart_device.dart';
import '../models/user.dart';

class HomePage extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;

  const HomePage({super.key, required this.user, required this.onLogout});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<SmartDevice> devices;
  int _selectedDeviceIndex = -1;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();
    _initializeDevices();
    _googleSignIn.initialize();
  }

  void _initializeDevices() {
    devices = [
      SmartDevice(
        id: '1',
        name: '客廳燈',
        icon: '💡',
        type: 'light',
        brightness: 75,
      ),
      SmartDevice(id: '2', name: '電視', icon: '📺', type: 'tv', isOn: true),
      SmartDevice(id: '3', name: '空調', icon: '❄️', type: 'ac', temperature: 22),
      SmartDevice(id: '4', name: '風扇', icon: '🌀', type: 'fan'),
      SmartDevice(id: '5', name: '窗簾', icon: '🪟', type: 'curtain'),
      SmartDevice(id: '6', name: '門鎖', icon: '🔐', type: 'lock'),
    ];
  }

  Future<void> _handleLogout() async {
    try {
      await _googleSignIn.signOut();
      widget.onLogout();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登出失敗: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PulMote - 萬用遙控器'),
        elevation: 2,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: PopupMenuButton<String>(
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Row(
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 8),
                            Text(widget.user.name),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem<String>(
                        value: 'logout',
                        child: const Row(
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text('登出'),
                          ],
                        ),
                      ),
                    ],
                onSelected: (String value) {
                  if (value == 'logout') {
                    _handleLogout();
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CircleAvatar(
                    backgroundImage:
                        widget.user.photoUrl != null
                            ? NetworkImage(widget.user.photoUrl!)
                            : null,
                    child:
                        widget.user.photoUrl == null
                            ? const Icon(Icons.account_circle)
                            : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body:
          _selectedDeviceIndex == -1
              ? _buildDeviceList()
              : _buildControlPanel(),
      bottomNavigationBar:
          _selectedDeviceIndex != -1
              ? Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedDeviceIndex = -1;
                        });
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('返回'),
                    ),
                    Text(
                      '${devices[_selectedDeviceIndex].name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 80),
                  ],
                ),
              )
              : null,
    );
  }

  Widget _buildDeviceList() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 歡迎卡片
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '歡迎回家，${widget.user.name}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '已連接設備: ${devices.length} 個',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 設備列表
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            '我的設備',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: devices.length,
          itemBuilder: (context, index) {
            final device = devices[index];
            return _buildDeviceCard(device, index);
          },
        ),
      ],
    );
  }

  Widget _buildDeviceCard(SmartDevice device, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDeviceIndex = index;
        });
      },
      child: Card(
        elevation: 2,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  device.isOn
                      ? [Colors.blue[400]!, Colors.blue[700]!]
                      : [Colors.grey[300]!, Colors.grey[400]!],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(device.icon, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(
                device.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                device.isOn ? '開啟' : '關閉',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    final device = devices[_selectedDeviceIndex];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 設備圖標和名稱
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.indigo[400]!, Colors.indigo[700]!],
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                children: [
                  Text(device.icon, style: const TextStyle(fontSize: 80)),
                  const SizedBox(height: 16),
                  Text(
                    device.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 電源開關
            _buildPowerControl(device),
            const SizedBox(height: 20),

            // 根據設備類型顯示不同的控制元件
            if (device.type == 'light') ...[
              _buildBrightnessControl(device),
            ] else if (device.type == 'ac') ...[
              _buildTemperatureControl(device),
            ] else if (device.type == 'tv') ...[
              _buildTVRemote(device),
            ] else if (device.type == 'fan') ...[
              _buildFanControl(device),
            ],

            const SizedBox(height: 24),

            // 快速命令
            _buildQuickCommands(device),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerControl(SmartDevice device) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '電源',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Switch(
              value: device.isOn,
              onChanged: (value) {
                setState(() {
                  device.isOn = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrightnessControl(SmartDevice device) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '亮度',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${device.brightness}%',
                  style: const TextStyle(fontSize: 16, color: Colors.indigo),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: device.brightness.toDouble(),
              min: 0,
              max: 100,
              onChanged: (value) {
                setState(() {
                  device.brightness = value.toInt();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureControl(SmartDevice device) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '溫度',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${device.temperature}°C',
                  style: const TextStyle(fontSize: 16, color: Colors.indigo),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Slider(
              value: device.temperature.toDouble(),
              min: 16,
              max: 30,
              onChanged: (value) {
                setState(() {
                  device.temperature = value.toInt();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTVRemote(SmartDevice device) {
    return Column(
      children: [
        const Text(
          '電視遙控器',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // 上下左右按鈕
        Center(
          child: Column(
            children: [
              _buildRemoteButton(Icons.arrow_upward, '上'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildRemoteButton(Icons.arrow_back, '左'),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.indigo,
                    ),
                    child: const Icon(
                      Icons.circle_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildRemoteButton(Icons.arrow_forward, '右'),
                ],
              ),
              _buildRemoteButton(Icons.arrow_downward, '下'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 頻道控制
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRemoteButton(Icons.remove, '音量-'),
            _buildRemoteButton(Icons.add, '音量+'),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRemoteButton(Icons.skip_previous, '上一頻道'),
            _buildRemoteButton(Icons.skip_next, '下一頻道'),
          ],
        ),
      ],
    );
  }

  Widget _buildRemoteButton(IconData icon, String label) {
    return Column(
      children: [
        FloatingActionButton(
          mini: true,
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('發送: $label')));
          },
          child: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildFanControl(SmartDevice device) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '風扇速度',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSpeedButton('低', Colors.blue),
                _buildSpeedButton('中', Colors.orange),
                _buildSpeedButton('高', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedButton(String label, Color color) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      onPressed: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('風扇速度: $label')));
      },
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _buildQuickCommands(SmartDevice device) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '快速命令',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildCommandChip('最大', Colors.red),
                _buildCommandChip('最小', Colors.blue),
                _buildCommandChip('自動', Colors.green),
                _buildCommandChip('定時', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandChip(String label, Color color) {
    return ActionChip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.2),
      labelStyle: TextStyle(color: color),
      onPressed: () {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('執行快速命令: $label')));
      },
    );
  }
}
