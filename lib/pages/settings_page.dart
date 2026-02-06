import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _currentIndex = 4; // Profil tab

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
        // Riwayat/Add
        Navigator.pushNamed(context, AppRoutes.addDevice);
        break;
      case 3:
        // Riwayat History
        Navigator.pushNamed(context, AppRoutes.history);
        break;
      case 4:
        // Profil - already on this page
        break;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to login page
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (route) => false,
                );
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
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
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'PROFIL PENGGUNA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1F1F),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 60),

                // User Profile Section
                Center(
                  child: Container(
                    width: 280,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2D1F),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        // User Avatar
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFFC9A878),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF1F1F1F),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // User Name
                        const Text(
                          'Peternak Ayam',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // User Email
                        const Text(
                          'peternak@kandang.com',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9B9B7B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Logout Button
                ElevatedButton.icon(
                  onPressed: _showLogoutConfirmation,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 4,
                  ),
                  iconAlignment: IconAlignment.start,
                ),
              ],
            ),
          ),
        ],
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
                    color: const Color(0xFFC9A878),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFF1F1F1F),
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
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _currentIndex == 4
                      ? BoxDecoration(
                          color: const Color(0xFFC9A878),
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  child: Icon(
                    Icons.person,
                    color: _currentIndex == 4 ? const Color(0xFF1F1F1F) : const Color(0xFF888888),
                    size: 24,
                  ),
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