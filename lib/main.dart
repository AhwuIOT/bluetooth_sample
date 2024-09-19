import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BLEScanScreen(),
    );
  }
}

class BLEScanScreen extends StatefulWidget {
  @override
  _BLEScanScreenState createState() => _BLEScanScreenState();
}

class _BLEScanScreenState extends State<BLEScanScreen> {
  List<ScanResult> scanResults = [];

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  Future<void> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (statuses[Permission.location]!.isGranted &&
        statuses[Permission.bluetooth]!.isGranted &&
        statuses[Permission.bluetoothScan]!.isGranted &&
        statuses[Permission.bluetoothConnect]!.isGranted) {
      startScan();
    } else {
      print('Permissions not granted');
    }
  }

  void startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 4));
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          scanResults = results;
          print("Found ${results.length} devices");
        });
      }, onError: (error) {
        print("Scan error: $error");
      });
    } catch (e) {
      print("Error starting scan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    print("42${scanResults.length}");
    return Scaffold(
      appBar: AppBar(title: Text('BLE Scanner')),
      body: ListView.builder(
        itemCount: scanResults.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(scanResults[index].device.advName ?? 'Unknown device'),
            subtitle: Text(scanResults[index].device.toString()),
            onTap: () {
              // Connect to the device
              print("52${scanResults[index].device.toString()}");
              connectToDevice(scanResults[index].device);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: startScan,
      ),
    );
  }

  void connectToDevice(BluetoothDevice device) {
    // Implement connection logic here
    print('Connecting to ${device.name}');
    // Navigate to a new screen for device interaction
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeviceScreen(device: device),
      ),
    );
  }
}

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  DeviceScreen({Key? key, required this.device}) : super(key: key);

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  BluetoothCharacteristic? _characteristic;

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  void _connectToDevice() async {
    try {
      await widget.device.connect();
      print('Connected to ${widget.device.advName}');
      _discoverServices();
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void _discoverServices() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    services.forEach((service) {
      // 根據你的設備特性，找到正確的服務和特徵
      // 這裡假設我們知道特定的UUID
      if (service.uuid.toString() == '295a8771-1529-4765-950f-a5fdb3e4537c') {
        var characteristics = service.characteristics;
        for (BluetoothCharacteristic c in characteristics) {
          if (c.uuid.toString() == '295a8771-1529-4765-950f-a5fdb3e4537c') {
            setState(() {
              _characteristic = c;
            });
            break;
          }
        }
      }
    });
  }

  // void _writeValue() async {
  //   if (_characteristic != null) {
  //     List<int> value = [0x01, 0x02, 0x03]; // 要寫入的值
  //     await _characteristic!.write(value);
  //     print('Value written successfully');
  //   } else {
  //     print('Characteristic not found');
  //   }
  // }
  void _writeValue() async {
    if (_characteristic != null) {
      List<int> value = utf8.encode("ON"); // 將 "ON" 轉換為 UTF-8 編碼的字節
      try {
        await _characteristic!.write(value);
        print('Value "ON" written successfully');
      } catch (e) {
        print('Error writing value: $e');
      }
    } else {
      print('Characteristic not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.advName ?? 'Unknown device')),
      body: Center(
        child: ElevatedButton(
          child: Text('Write Value'),
          onPressed: _writeValue,
        ),
      ),
    );
  }
}
