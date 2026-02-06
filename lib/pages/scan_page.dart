import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool isBluetoothEnabled = false;
  bool isScanning = false;

  void _handleBottomNavigation(int index) {
    switch (index) {
      case 0:
        // Home
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.home,
          (route) => false,
        );
        break;
      case 1:
        // Scan - already on scan page
        break;
      case 2:
        // Riwayat Plus
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8DCC8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8DCC8),
        elevation: 0,
        title: const Text(
          'Scan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.home,
            (route) => false,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Card container
            Container(
              width: 300,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8DCC8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black26, width: 1),
              ),
              child: Column(
                children: [
                  // Alert badge (shown only when scanning)
                  if (isScanning)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8A758),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Cari Alat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  if (isScanning) const SizedBox(height: 24),
                  
                  // Title
                  const Text(
                    'RIWAYAT SENSOR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Bluetooth icon
                  Icon(
                    isScanning 
                        ? Icons.bluetooth_searching 
                        : Icons.bluetooth,
                    size: 80,
                    color: Colors.black87,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Status text
                  Text(
                    isScanning 
                        ? 'Siap Mencari'
                        : 'Bluetooth Mati',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Description text
                  Text(
                    isScanning
                        ? 'Pastikan alat sudah di colok ke listrik'
                        : 'Mohon nyalakan Bluetooth untuk mencari alat',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          if (isScanning) {
                            // Start scanning logic here
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Memulai scan...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            // Enable bluetooth
                            isBluetoothEnabled = true;
                            isScanning = true;
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isScanning
                            ? const Color(0xFFE8A758)
                            : const Color(0xFF2196F3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isScanning 
                            ? 'Mulai Scan'
                            : 'Nyalakan Bluetooth',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.black.withOpacity(0.1),
              width: 1,
            ),
          ),
          color: const Color(0xFFE8DCC8),
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color(0xFFE8DCC8),
            selectedItemColor: const Color(0xFFFFA500),
            unselectedItemColor: const Color(0xFF888888),
            currentIndex: 1, // Scan tab selected
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Profil',
              ),
            ],
            onTap: (index) {
              _handleBottomNavigation(index);
            },
          ),
        ),
      ),
    );
  }
}