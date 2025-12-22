part of 'package:psdk_bluetooth_classic/psdk_bluetooth_classic.dart';

class ClassicBluetoothDevice extends FluetoothDevice<BluetoothDevice> {
  ClassicBluetoothDevice({
    required BluetoothDevice origin,
    String? name,
    String? mac,
    int? rssi,
  }) : super(
          origin: origin,
          protocol: BluetoothProtocol.classic,
          name: name,
          mac: mac,
          rssi: rssi,
        );
}
