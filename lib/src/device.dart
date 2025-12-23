part of 'package:bluetooth_classic/bluetooth_classic.dart';

class ClassicBluetoothDevice extends FluetoothDevice<BluetoothDevice> {
  ClassicBluetoothDevice({
    required BluetoothDevice origin,
    String? name,
    String? mac,
    int? rssi,
  }) : super(
          origin: origin,
          // NOTE: Đây là Bluetooth Classic (SPP/RFCOMM), không phải BLE.
          // Nếu đổi sang BLE thì đường truyền gửi dữ liệu sẽ không đúng cho thiết bị Classic.
          protocol: BluetoothProtocol.classic,
          name: name ?? origin.name,
          mac: mac ?? origin.address,
          rssi: rssi,
        );
}
