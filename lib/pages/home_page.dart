import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  Map<String, bool> deviceStates = {
    'Lampu Pemanas': false,
    'Pompa Air': false,
    'Kipas Exhaust': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8DCC8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8DCC8),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: const Color(0xFFE8DCC8),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and Title Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Logo with Chicken and Wifi indicator
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFA500),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/logo.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.home,
                                      size: 38,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4A90E2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.wifi,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Title
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KANDANG',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1F1F1F),
                                letterSpacing: 1.5,
                                height: 1.0,
                              ),
                            ),
                            const Text(
                              'PINTAR',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1F1F1F),
                                letterSpacing: 1.5,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Monitoring Ternak Lebih Efisien.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B6B6B),
                                letterSpacing: 0.2,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Monitoring Realtime Section
                  const Text(
                    'Monitoring Realtime',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1F1F),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Monitoring Cards Grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.92,
                    children: [
                      // Suhu Card
                      _buildMonitoringCard(
                        icon: Icons.thermostat,
                        label: 'Suhu',
                        value: '28.5',
                        unit: '°C',
                        iconColor: const Color(0xFFD4AF37),
                      ),
                      // Kelembapan Card
                      _buildMonitoringCard(
                        icon: Icons.water_drop,
                        label: 'Kelembapan',
                        value: '65',
                        unit: '%',
                        iconColor: const Color(0xFF5DADE2),
                      ),
                      // Amonia Card
                      _buildMonitoringCard(
                        icon: Icons.waves,
                        label: 'Amonia',
                        value: '12.4',
                        unit: 'PPM',
                        iconColor: const Color(0xFF58D68D),
                      ),
                      // Pakan Card
                      _buildMonitoringCard(
                        icon: Icons.kitchen,
                        label: 'Pakan',
                        value: '5.8',
                        unit: 'KG',
                        iconColor: const Color(0xFFEC7063),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Kontrol Perangkat Section
                  const Text(
                    'Kontrol Perangkat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F1F1F),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Control Switches
                  _buildControlSwitch(
                    icon: Icons.lightbulb,
                    label: 'Lampu Pemanas',
                    deviceKey: 'Lampu Pemanas',
                    iconColor: const Color(0xFFFFA500),
                  ),
                  const SizedBox(height: 12),
                  _buildControlSwitch(
                    icon: Icons.water,
                    label: 'Pompa Air',
                    deviceKey: 'Pompa Air',
                    iconColor: const Color(0xFF5DADE2),
                  ),
                  const SizedBox(height: 12),
                  _buildControlSwitch(
                    icon: Icons.air,
                    label: 'Kipas Exhaust',
                    deviceKey: 'Kipas Exhaust',
                    iconColor: const Color(0xFF58D68D),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.black.withOpacity(0.08),
              width: 1,
            ),
          ),
          color: const Color(0xFFE8DCC8),
        ),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.home,
                  label: 'Home',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan',
                  index: 1,
                ),
                _buildCenterNavItem(),
                _buildNavItem(
                  icon: Icons.history,
                  label: 'Riwayat',
                  index: 3,
                ),
                _buildNavItem(
                  icon: Icons.person_outline,
                  label: 'Profil',
                  index: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
        _navigateToTab(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFC9A878),
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected 
                  ? const Color(0xFF1F1F1F) 
                  : const Color(0xFF888888),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? const Color(0xFF1F1F1F) 
                    : const Color(0xFF888888),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = 2;
        });
        _navigateToTab(2);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: Color(0xFFC9A878),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: Color(0xFF1F1F1F),
          size: 26,
        ),
      ),
    );
  }

  void _navigateToTab(int index) {
    switch (index) {
      case 0:
        // Home - already on home page
        break;
      case 1:
        // Scan
        Navigator.pushNamed(context, AppRoutes.scan);
        break;
      case 2:
        // Add device (Plus button)
        Navigator.pushNamed(context, AppRoutes.addDevice);
        break;
      case 3:
        // Riwayat History
        Navigator.pushNamed(context, AppRoutes.history);
        break;
      case 4:
        // Profil
        Navigator.pushNamed(context, AppRoutes.settings);
        break;
    }
  }

  Widget _buildMonitoringCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D1F),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and Label
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9B9B7B),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Value
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 2),
                  child: Text(
                    unit,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9B9B7B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlSwitch({
    required IconData icon,
    required String label,
    required String deviceKey,
    required Color iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D1F),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Toggle Switch
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: deviceStates[deviceKey] ?? false,
              onChanged: (value) {
                setState(() {
                  deviceStates[deviceKey] = value;
                });
              },
              activeColor: Colors.white,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFF5A5A52),
              activeTrackColor: const Color(0xFFFFA500),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}