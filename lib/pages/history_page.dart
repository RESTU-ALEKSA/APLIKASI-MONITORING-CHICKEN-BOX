import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _currentIndex = 3; // Riwayat tab
  int _selectedFilter = 0; // 0: Suhu, 1: Kelembapan, 2: Amonia, 3: Pakan

  final List<String> _filterOptions = ['Suhu', 'Kelembapan', 'Amonia', 'Pakan'];

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
        // Riwayat History - already on this page
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
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              color: const Color(0xFFE8DCC8),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  const Text(
                    'RIWAYAT PENGGUNA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1F1F),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subtitle
                  const Text(
                    'Riwayat Database Full',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Tabs
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterOptions.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedFilter == index;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: FilterChip(
                            label: Text(
                              _filterOptions[index],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1F1F1F),
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = index;
                              });
                            },
                            backgroundColor: Colors.transparent,
                            selectedColor: const Color(0xFFC9A878),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFC9A878)
                                  : const Color(0xFF1F1F1F),
                              width: 1.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Content Area
            Container(
              color: const Color(0xFFE8DCC8),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Empty State
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 60,
                          color: Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada database.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF8B8B8B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
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
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: _currentIndex == 3
                      ? BoxDecoration(
                          color: const Color(0xFFC9A878),
                          borderRadius: BorderRadius.circular(10),
                        )
                      : null,
                  child: Icon(
                    Icons.history,
                    color: _currentIndex == 3 ? const Color(0xFF1F1F1F) : const Color(0xFF888888),
                    size: 22,
                  ),
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
