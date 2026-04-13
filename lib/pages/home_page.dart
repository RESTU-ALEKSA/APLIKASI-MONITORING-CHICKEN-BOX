import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class HomePage extends StatelessWidget {
  final String? deviceId;
  final bool isOnline;
  final String temperature;
  final String humidity;
  final String ammonia;
  final bool isSensorLoading;
  final List<Map<String, dynamic>> controlItems;
  final Function(int, bool)? onToggle;

  const HomePage({
    super.key,
    this.deviceId,
    required this.isOnline,
    required this.temperature,
    required this.humidity,
    required this.ammonia,
    required this.isSensorLoading,
    required this.controlItems,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEBEBEB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (deviceId == null)
              const Center(child: Text("Belum ada kandang terdaftar"))
            else ...[
              _buildHeader(),
              const SizedBox(height: 10),
              _buildConditionCards(),
              const SizedBox(height: 25),
              const Text("KONTROL KANDANG", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 10),
              _buildControlList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("KONDISI KANDANG", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
        Text("ID: ${deviceId!.substring(0, 8).toUpperCase()}", style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildConditionCards() {
    return Row(
      children: [
        _SensorCard(label: 'SUHU', value: temperature, unit: '°C', icon: Icons.thermostat, color: Colors.orange),
        const SizedBox(width: 10),
        _SensorCard(label: 'LEMBAB', value: humidity, unit: '%', icon: Icons.opacity, color: Colors.blue),
        const SizedBox(width: 10),
        _SensorCard(label: 'AMONIA', value: ammonia, unit: 'PPM', icon: Icons.air, color: Colors.green),
      ],
    );
  }

  Widget _buildControlList() {
    return Column(
      children: List.generate(controlItems.length, (index) {
        final item = controlItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: item['color'].withOpacity(0.1), child: Icon(item['icon'], color: item['color'])),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(item['subtitle'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Switch(
                value: item['isEnabled'],
                // Toggle OTOMATIS MATI kalau alat OFFLINE
                onChanged: isOnline ? (val) => onToggle?.call(index, val) : null,
                activeColor: const Color(0xFF4A3728),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _SensorCard({required this.label, required this.value, required this.unit, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("$value$unit", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}