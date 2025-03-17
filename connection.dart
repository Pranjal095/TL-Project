import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() async {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  flutterBlue.startScan(timeout: Duration(seconds: 5));

  flutterBlue.scanResults.listen((results) {
    for (ScanResult r in results) {
      if (r.device.name == "ESP32_Sensor") {
        r.device.connect();
        readSensorValue(r.device);
        break;
      }
    }
  });
}

Future<void> readSensorValue(BluetoothDevice device) async {
  List<BluetoothService> services = await device.discoverServices();
  for (var service in services) {
    if (service.uuid.toString() == "12345678-1234-5678-1234-56789abcdef0") {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == "87654321-4321-6789-4321-fedcba987654") {
          characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            print("Sensor Value: ${String.fromCharCodes(value)}");
          });
        }
      }
    }
  }
}
