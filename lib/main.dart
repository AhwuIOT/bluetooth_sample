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
    print('Connecting to ${device.advName}');
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
  bool _isDisposed = false;
  BluetoothCharacteristic? _characteristic;
  String _receivedData = '';

  @override
  void initState() {
    super.initState();
    _connectToDevice();
  }

  void _connectToDevice() async {
    if (_isDisposed) return;
    try {
      await widget.device.connect();
      if (!_isDisposed) {
        setState(() {
          // 更新連接狀態
        });
        print('Connected to ${widget.device.advName}');
        _discoverServices();
      }
    } catch (e) {
      print('Error connecting to device: $e');
    }
  }

  void _discoverServices() async {
    if (_isDisposed) return;
    List<BluetoothService> services = await widget.device.discoverServices();
    if (!_isDisposed) {
      services.forEach((service) {
        print('Service: ${service.uuid}');
        service.characteristics.forEach((characteristic) {
          print('Characteristic: ${characteristic.uuid}');
          _characteristic = characteristic;
        });
      });
      // 處理服務發現結果
    }
  }

  void _subscribeToCharacteristic() async {
    if (_characteristic != null) {
      await _characteristic!.setNotifyValue(true);
      _characteristic!.lastValueStream.listen((value) {
        print("69${value}");
        if (!_isDisposed) {
          setState(() {
            _receivedData = utf8.decode(value);
          });
          print('Received data: $_receivedData');
        }
      });
    }
  }

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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Received Data: $_receivedData'),
            ElevatedButton(
              child: Text('Write "ON"'),
              onPressed: _writeValue,
            ),
            ElevatedButton(
              child: Text('Read Value'),
              onPressed: _subscribeToCharacteristic,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    _characteristic?.setNotifyValue(false);
    widget.device.disconnect();
    super.dispose();
  }
}
