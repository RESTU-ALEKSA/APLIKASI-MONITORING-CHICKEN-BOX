import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({Key? key}) : super(key: key);

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _deviceIdController = TextEditingController();
  final _deviceNameController = TextEditingController();
  int _currentIndex = 2; // Riwayat/Add tab

  @override
  void dispose() {
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  void _handleBottomNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });
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
        // Scan
        Navigator.pushNamed(context, AppRoutes.scan);
        break;
      case 2:
        // Riwayat/Add - already on this page
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

  void _saveDevice() {
    if (_deviceIdController.text.isEmpty || _deviceNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon isi semua field'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // TODO: Implement API call to save device to server
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alat berhasil ditambahkan'),
        duration: Duration(seconds: 2),
      ),
    );
  }

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
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              const SizedBox(height: 16),
              const Text(
                'TAMBAHKAN ALAT MANUAL',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F1F1F),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),

              // Input ID Kandang Section
              const Text(
                'Input ID Kandang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Masukkan ID serial number yang tertera distiker alat.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF8B8B8B),
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),

              // ID Alat Field
              const Text(
                'ID Alat (Serial Number)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _deviceIdController,
                decoration: InputDecoration(
                  hintText: 'Contoh: ESP32-A1B2C3',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9B9B7B),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2D2D1F),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFA500),
                      width: 2,
                    ),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // Nama Kandang Field
              const Text(
                'Nama Kandang',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F1F1F),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _deviceNameController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Kandang Ayam Boiler',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9B9B7B),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF2D2D1F),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFFFA500),
                      width: 2,
                    ),
                  ),
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveDevice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D1F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Simpan ke Server',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
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
            backgroundColor: const Color(0xFFE8DCC8),
            currentIndex: _currentIndex,
            onTap: _handleBottomNavigation,
            items: [
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _currentIndex == 0
                      ? BoxDecoration(
                          color: const Color(0xFFC9A878),
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  child: Icon(
                    Icons.home_filled,
                    color: _currentIndex == 0 ? const Color(0xFF1F1F1F) : const Color(0xFF666666),
                    size: 24,
                  ),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.qr_code_scanner,
                  color: _currentIndex == 1 ? const Color(0xFF1F1F1F) : const Color(0xFF888888),
                  size: 20,
                ),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _currentIndex == 2 ? const Color(0xFFC9A878) : const Color(0xFFC9A878),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: const Color(0xFF1F1F1F),
                    size: 24,
                  ),
                ),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.history,
                  color: _currentIndex == 3 ? const Color(0xFF1F1F1F) : const Color(0xFF888888),
                  size: 22,
                ),
                label: 'Riwayat',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.person,
                  color: _currentIndex == 4 ? const Color(0xFF1F1F1F) : const Color(0xFF888888),
                  size: 22,
                ),
                label: 'Profil',
              ),
            ],
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFF1F1F1F),
            unselectedItemColor: const Color(0xFF888888),
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1F1F),
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF888888),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
