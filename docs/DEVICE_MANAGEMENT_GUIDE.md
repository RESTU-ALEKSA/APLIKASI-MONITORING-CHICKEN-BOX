# Device Management Layer — Usage Guide

Phase 1 implementation complete! This guide shows you how to use the new device management layer.

---

## 📦 What Was Built

### Models
1. **`PaginatedResponse<T>`** — Generic pagination wrapper
2. **`Device`** — Device model with nullable handling and utility methods
3. **`SensorLog`** — Sensor reading model with alert support
4. **`DeviceComponent`** — Enum for component control (kipas, lampu, pompa, pakanOtomatis)

### Services
5. **`DeviceService`** — 4 core methods:
   - `getDevices()` — Get paginated device list
   - `controlDevice()` — Control device components
   - `claimDevice()` — Claim unclaimed devices
   - `getDeviceLogs()` — Get sensor logs

---

## 🚀 Quick Start

### 1. Get Devices List

```dart
import 'services/device_service.dart';
import 'core/network/api_exception.dart';

final deviceService = DeviceService();

try {
  final response = await deviceService.getDevices(page: 1, limit: 20);
  
  print('Total devices: ${response.total}');
  print('Current page: ${response.page}/${response.totalPages}');
  
  for (var device in response.data) {
    print('${device.displayName} - ${device.onlineStatusDisplay}');
  }
  
  if (response.hasNextPage) {
    // Load next page
    final nextPage = await deviceService.getDevices(page: response.page + 1);
  }
} on ForbiddenException catch (e) {
  showErrorDialog('Akses Ditolak', e.message);
} on RateLimitException catch (e) {
  showSnackbar(e.message);
} on NetworkException catch (e) {
  showRetrySnackbar(e.message, onRetry: _loadDevices);
}
```

---

### 2. Control Device Components

```dart
import 'models/device/device_component.dart';

try {
  // Turn on fan
  await deviceService.controlDevice(
    deviceId: device.id,
    component: DeviceComponent.kipas,
    state: true,
  );
  
  showSuccessSnackbar('Kipas berhasil dinyalakan');
} on ForbiddenException catch (e) {
  // Viewer role cannot control
  showErrorDialog('Akses Ditolak', e.message);
} on ServerException catch (e) {
  // MQTT broker unreachable
  showErrorDialog('Gagal Mengirim Perintah', e.message);
}
```

**All Components:**
```dart
DeviceComponent.kipas          // Fan
DeviceComponent.lampu          // Light
DeviceComponent.pompa          // Pump
DeviceComponent.pakanOtomatis  // Auto Feeder
```

---

### 3. Claim Device via QR Code

```dart
try {
  final device = await deviceService.claimDevice(
    macAddress: scannedMac,
    name: nameController.text,
  );
  
  Navigator.pop(context);
  showSuccessSnackbar('Device ${device.displayName} berhasil diklaim!');
} on BadRequestException catch (e) {
  // Already claimed
  showErrorDialog('Gagal Klaim', e.message);
} on NotFoundException catch (e) {
  // MAC not registered
  showErrorDialog('Device Tidak Ditemukan', e.message);
} on ValidationException catch (e) {
  // Invalid MAC format or name
  showErrorDialog('Validasi Gagal', e.allMessages);
}
```

---

### 4. Get Sensor Logs

```dart
try {
  final response = await deviceService.getDeviceLogs(
    deviceId: device.id,
    page: 1,
    limit: 50,
  );
  
  for (var log in response.data) {
    print('${log.formattedTimestamp}: ${log.temperatureDisplay}');
    
    if (log.hasAlert) {
      print('  Alert: ${log.alertMessage}');
    }
    
    print('  Status: ${log.temperatureStatus}');
  }
} on NotFoundException catch (e) {
  showErrorDialog('Device Tidak Ditemukan', e.message);
}
```

---

## 📊 Model Usage Examples

### Device Model

```dart
// Check device status
if (device.isOnline) {
  print('Device is online');
}

if (device.isClaimed) {
  print('Owner: ${device.userId}');
}

// Display information
print(device.displayName);              // "Kandang Utara" or "Device 44:1D:64"
print(device.onlineStatusDisplay);      // "Online" or "Offline"
print(device.timeSinceLastSeenDisplay); // "5 menit yang lalu"

// Check connection history
if (device.hasNeverConnected) {
  print('Device has never connected');
}
```

### SensorLog Model

```dart
// Display sensor readings
print(log.temperatureDisplay);  // "30.5°C"
print(log.humidityDisplay);     // "75.0%"
print(log.ammoniaDisplay);      // "12.5 ppm"

// Check temperature status
print(log.temperatureStatus);   // "Normal", "Waspada", or "Bahaya"

if (log.isTemperatureNormal) {
  // Temperature is in normal range (25-30°C)
}

if (log.isTemperatureDanger) {
  // Temperature is in danger range (<20°C or >35°C)
}

// Display timestamps
print(log.formattedTimestamp);      // "26 Apr 2026, 10:30"
print(log.shortFormattedTimestamp); // "10:30" (today) or "26 Apr" (other days)
print(log.relativeTimeDisplay);     // "5 menit yang lalu"
```

### PaginatedResponse

```dart
// Pagination info
print('Page ${response.page} of ${response.totalPages}');
print('Showing ${response.itemCount} of ${response.total} items');
print('Items ${response.startItemNumber}-${response.endItemNumber}');

// Navigation helpers
if (response.hasNextPage) {
  // Show "Next" button
}

if (response.hasPreviousPage) {
  // Show "Previous" button
}

if (response.isFirstPage) {
  // Disable "Previous" button
}

if (response.isLastPage) {
  // Disable "Next" button
}
```

---

## 🎨 UI Integration Examples

### Devices Page

```dart
class DevicesPage extends StatefulWidget {
  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  final DeviceService _deviceService = DeviceService();
  PaginatedResponse<Device>? _devicesResponse;
  bool _isLoading = false;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _deviceService.getDevices(
        page: _currentPage,
        limit: 20,
      );
      
      setState(() {
        _devicesResponse = response;
        _isLoading = false;
      });
    } on ForbiddenException catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Akses Ditolak', e.message);
    } on RateLimitException catch (e) {
      setState(() => _isLoading = false);
      _showSnackbar(e.message);
    } on NetworkException catch (e) {
      setState(() => _isLoading = false);
      _showRetrySnackbar(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_devicesResponse == null || _devicesResponse!.isEmpty) {
      return Center(child: Text('Tidak ada device'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _devicesResponse!.itemCount,
            itemBuilder: (context, index) {
              final device = _devicesResponse!.data[index];
              return DeviceCard(device: device);
            },
          ),
        ),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildPaginationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: _devicesResponse!.hasPreviousPage
              ? () {
                  setState(() => _currentPage--);
                  _loadDevices();
                }
              : null,
        ),
        Text('Page ${_devicesResponse!.page}/${_devicesResponse!.totalPages}'),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: _devicesResponse!.hasNextPage
              ? () {
                  setState(() => _currentPage++);
                  _loadDevices();
                }
              : null,
        ),
      ],
    );
  }
}
```

---

### Device Control Widget

```dart
class DeviceControlWidget extends StatelessWidget {
  final Device device;
  final DeviceService _deviceService = DeviceService();

  DeviceControlWidget({required this.device});

  Future<void> _toggleComponent(
    BuildContext context,
    DeviceComponent component,
    bool currentState,
  ) async {
    try {
      await _deviceService.controlDevice(
        deviceId: device.id,
        component: component,
        state: !currentState,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${component.displayName} berhasil ${!currentState ? "dinyalakan" : "dimatikan"}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } on ForbiddenException catch (e) {
      _showErrorDialog(context, 'Akses Ditolak', e.message);
    } on ServerException catch (e) {
      _showErrorDialog(context, 'Gagal Mengirim Perintah', e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildControlButton(
          context,
          DeviceComponent.kipas,
          Icons.air,
          false, // Get actual state from device
        ),
        _buildControlButton(
          context,
          DeviceComponent.lampu,
          Icons.lightbulb,
          false,
        ),
        _buildControlButton(
          context,
          DeviceComponent.pompa,
          Icons.water_drop,
          false,
        ),
        _buildControlButton(
          context,
          DeviceComponent.pakanOtomatis,
          Icons.restaurant,
          false,
        ),
      ],
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    DeviceComponent component,
    IconData icon,
    bool currentState,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(component.displayName),
      trailing: Switch(
        value: currentState,
        onChanged: (value) => _toggleComponent(context, component, currentState),
      ),
    );
  }
}
```

---

### Scan and Claim Page

```dart
class ScanPage extends StatefulWidget {
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final DeviceService _deviceService = DeviceService();
  final TextEditingController _nameController = TextEditingController();

  Future<void> _handleQRCodeScanned(String macAddress) async {
    // Show name input dialog
    final name = await _showNameInputDialog();
    
    if (name == null || name.isEmpty) return;
    
    try {
      final device = await _deviceService.claimDevice(
        macAddress: macAddress,
        name: name,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device ${device.displayName} berhasil diklaim!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    } on BadRequestException catch (e) {
      _showErrorDialog('Gagal Klaim Device', e.message);
    } on ForbiddenException catch (e) {
      _showErrorDialog('Akses Ditolak', e.message);
    } on NotFoundException catch (e) {
      _showErrorDialog('Device Tidak Ditemukan', e.message);
    } on ValidationException catch (e) {
      _showErrorDialog('Validasi Gagal', e.allMessages);
    }
  }

  Future<String?> _showNameInputDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nama Device'),
        content: TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Contoh: Kandang Utara',
          ),
          maxLength: 100,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _nameController.text),
            child: Text('Klaim'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🛡️ Error Handling Reference

| Exception | HTTP Code | When It Happens | UI Action |
|-----------|-----------|-----------------|-----------|
| `UnauthorizedException` | 401 | Token expired | Auto-logout (handled by interceptor) |
| `ForbiddenException` | 403 | Permission denied | Show error dialog |
| `NotFoundException` | 404 | Device not found | Show "not found" message |
| `ValidationException` | 422 | Invalid input | Highlight invalid fields |
| `RateLimitException` | 429 | Too many requests | Show "please wait" snackbar |
| `ServerException` | 500 | MQTT broker down | Show error with retry |
| `NetworkException` | N/A | No internet | Show retry option |

---

## 📝 Logging

All operations are logged with the `DeviceService` name:

```
→ Loading devices (page: 1, limit: 20)
✓ Loaded 5 devices (page 1/1)

→ Controlling device a1b2c3d4-...: kipas = ON
✓ Device controlled successfully: Perintah kipas dikirim ke Kandang Utara

→ Claiming device: MAC=44:1D:64:BE:22:08, name=Kandang Utara
✓ Device claimed successfully: Kandang Utara (a1b2c3d4-...)

→ Loading logs for device a1b2c3d4-... (page: 1, limit: 50)
✓ Loaded 50 logs (page 1/10)
```

---

## 🎯 Next Steps

1. **Update Devices Page** — Replace HTTP calls with `deviceService.getDevices()`
2. **Update Control UI** — Use `DeviceComponent` enum for control buttons
3. **Update Scan Page** — Use `deviceService.claimDevice()` after QR scan
4. **Create Logs Page** — Use `deviceService.getDeviceLogs()` to display history

---

## 📚 API Contract Reference

All implementations follow `API_CONTRACT.md`:
- Section 3.3: Device Management Endpoints
- Section 6: Pagination Format
- Section 7: Validation Constraints

---

**Phase 1 Complete! Ready to integrate with your UI. 🚀**
