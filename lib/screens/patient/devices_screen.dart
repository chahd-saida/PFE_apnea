import 'package:flutter/material.dart';

import 'package:apnea_project/l10n/app_localizations.dart';
import 'package:apnea_project/widgets/chatbot_fab.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final List<_Device> _devices = [
    _Device(
      id: 'A1B2',
      name: 'ESP32 #A1B2',
      battery: 85,
      connected: true,
      lastSeen: DateTime.now(),
      sensors: _defaultSensors(),
    ),
  ];

  bool _isScanning = false;

  _Device? get _connectedDevice {
    for (final device in _devices) {
      if (device.connected) return device;
    }
    return null;
  }

  Future<void> _scanDevices() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final now = DateTime.now();
    final existingIds = _devices.map((d) => d.id).toSet();
    final candidates = [
      _Device(
        id: 'C7D9',
        name: 'ESP32 #C7D9',
        battery: 62,
        connected: false,
        lastSeen: now,
        sensors: _defaultSensors(),
      ),
      _Device(
        id: 'E3F1',
        name: 'ESP32 #E3F1',
        battery: 41,
        connected: false,
        lastSeen: now,
        sensors: _defaultSensors(),
      ),
    ];

    for (final candidate in candidates) {
      if (!existingIds.contains(candidate.id)) {
        _devices.add(candidate);
      }
    }

    setState(() => _isScanning = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recherche terminee.')));
  }

  void _toggleConnection(_Device device) {
    setState(() {
      for (final d in _devices) {
        d.connected = false;
      }
      device.connected = true;
      device.lastSeen = DateTime.now();
    });
  }

  void _disconnect(_Device device) {
    setState(() {
      device.connected = false;
      device.lastSeen = DateTime.now();
    });
  }

  Future<void> _renameDevice(_Device device) async {
    final controller = TextEditingController(text: device.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renommer le dispositif'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nom'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;
    setState(() => device.name = name);
  }

  void _removeDevice(_Device device) {
    setState(() => _devices.remove(device));
  }

  void _toggleSensor(_DeviceSensor sensor) {
    setState(() => sensor.active = !sensor.active);
  }

  void _openGuide() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Guide de connexion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12),
              Text('1. Activez le Bluetooth du telephone.'),
              SizedBox(height: 6),
              Text('2. Allumez votre dispositif ESP32.'),
              SizedBox(height: 6),
              Text('3. Lancez une recherche puis connectez-vous.'),
              SizedBox(height: 6),
              Text('4. Verifiez l\'etat des capteurs actifs.'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connected = _connectedDevice;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.devicesTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.connectionStatusLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (connected == null)
              _EmptyConnectionCard(onScan: _scanDevices)
            else
              _ConnectedDeviceCard(
                device: connected,
                onDisconnect: () => _disconnect(connected),
                onRename: () => _renameDevice(connected),
              ),
            const SizedBox(height: 24),
            Text(
              'Appareils disponibles',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ..._devices
                .where((d) => !d.connected)
                .map(
                  (device) => _AvailableDeviceCard(
                    device: device,
                    onConnect: () => _toggleConnection(device),
                    onRemove: () => _removeDevice(device),
                    onRename: () => _renameDevice(device),
                  ),
                )
                .toList(),
            if (_devices.where((d) => !d.connected).isEmpty)
              const Text('Aucun autre appareil detecte.'),
            const SizedBox(height: 24),
            Text(
              l10n.activeSensorsLabel,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (connected == null)
              const Text('Connectez un appareil pour activer les capteurs.')
            else
              Column(
                children: connected.sensors.map((sensor) {
                  return SwitchListTile(
                    value: sensor.active,
                    onChanged: (_) => _toggleSensor(sensor),
                    secondary: Icon(
                      sensor.icon,
                      color: sensor.active ? Colors.green : Colors.grey,
                    ),
                    title: Text(sensor.name),
                    subtitle: Text(sensor.description),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanDevices,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(l10n.searchNewDeviceButton),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(220, 50),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _openGuide,
                    icon: const Icon(Icons.info_outline),
                    label: Text(l10n.connectionGuideLabel),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(220, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const PatientChatbotFAB(),
    );
  }
}

class _ConnectedDeviceCard extends StatelessWidget {
  final _Device device;
  final VoidCallback onDisconnect;
  final VoidCallback onRename;
  const _ConnectedDeviceCard({
    required this.device,
    required this.onDisconnect,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(device.name, style: const TextStyle(fontSize: 18)),
                const Icon(Icons.bluetooth_connected, color: Colors.green),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              l10n.deviceConnectedLabel,
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 5),
            Text('🔋 ${device.battery}%'),
            const SizedBox(height: 6),
            Text(
              'Derniere synchro: ${_formatLastSeen(device.lastSeen)}',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onRename,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Renommer'),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: onDisconnect,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(l10n.disconnectButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableDeviceCard extends StatelessWidget {
  final _Device device;
  final VoidCallback onConnect;
  final VoidCallback onRemove;
  final VoidCallback onRename;
  const _AvailableDeviceCard({
    required this.device,
    required this.onConnect,
    required this.onRemove,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.bluetooth),
        title: Text(device.name),
        subtitle: Text('Batterie: ${device.battery}%'),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'connect') onConnect();
            if (value == 'rename') onRename();
            if (value == 'remove') onRemove();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'connect', child: Text('Connecter')),
            PopupMenuItem(value: 'rename', child: Text('Renommer')),
            PopupMenuItem(value: 'remove', child: Text('Supprimer')),
          ],
        ),
        onTap: onConnect,
      ),
    );
  }
}

class _EmptyConnectionCard extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyConnectionCard({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.bluetooth_disabled, size: 36, color: Colors.grey),
            const SizedBox(height: 8),
            const Text('Aucun appareil connecte.'),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onScan,
              child: const Text('Rechercher un appareil'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Device {
  final String id;
  String name;
  int battery;
  bool connected;
  DateTime lastSeen;
  final List<_DeviceSensor> sensors;
  _Device({
    required this.id,
    required this.name,
    required this.battery,
    required this.connected,
    required this.lastSeen,
    required this.sensors,
  });
}

class _DeviceSensor {
  final String name;
  final String description;
  final IconData icon;
  bool active;
  _DeviceSensor({
    required this.name,
    required this.description,
    required this.icon,
    required this.active,
  });
}

List<_DeviceSensor> _defaultSensors() {
  return [
    _DeviceSensor(
      name: 'ECG (AD8232)',
      description: 'Rythme cardiaque et variabilite.',
      icon: Icons.monitor_heart,
      active: true,
    ),
    _DeviceSensor(
      name: 'SpO₂ (MAX30102)',
      description: 'Saturation en oxygene et pouls.',
      icon: Icons.air,
      active: true,
    ),
    _DeviceSensor(
      name: 'Mouvement (MPU6050)',
      description: 'Position et micro-reveils.',
      icon: Icons.directions_run,
      active: true,
    ),
    _DeviceSensor(
      name: 'Temperature (DS18B20)',
      description: 'Variation thermique nocturne.',
      icon: Icons.thermostat,
      active: true,
    ),
  ];
}

String _formatLastSeen(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'a l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  return '${time.day}/${time.month}/${time.year}';
}
