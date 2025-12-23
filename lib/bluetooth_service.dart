import 'dart:async';

import 'src/flutter_bluetooth_classic_patched.dart';

/// Service wrapper (giống demo) cho Bluetooth Classic Serial.
///
/// - Android: thường hoạt động với thiết bị SPP/RFCOMM.
/// - iOS: phụ thuộc thiết bị & giới hạn iOS (thường chỉ hoạt động với thiết bị MFi / giải pháp tương thích).
class BluetoothService {
  final FlutterBluetoothClassic _bluetooth = FlutterBluetoothClassic();

  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<BluetoothData>? _dataSubscription;
  StreamSubscription<BluetoothState>? _stateSubscription;
  StreamSubscription<BluetoothDevice>? _deviceDiscoverySubscription;

  Stream<BluetoothState> get onStateChanged => _bluetooth.onStateChanged;
  Stream<BluetoothConnectionState> get onConnectionChanged =>
      _bluetooth.onConnectionChanged;
  Stream<BluetoothData> get onDataReceived => _bluetooth.onDataReceived;
  Stream<BluetoothDevice> get onDeviceDiscovered =>
      _bluetooth.onDeviceDiscovered;

  Future<bool> isBluetoothSupported() async {
    try {
      return await _bluetooth.isBluetoothSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> isBluetoothEnabled() async {
    try {
      return await _bluetooth.isBluetoothEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await _bluetooth.getPairedDevices();
    } catch (_) {
      return <BluetoothDevice>[];
    }
  }

  /// Setup listeners giống demo (optional).
  void setupListeners({
    void Function(BluetoothState state)? onState,
    void Function(BluetoothConnectionState state)? onConnection,
    void Function(BluetoothData data)? onData,
    void Function(BluetoothDevice device)? onDevice,
  }) {
    _stateSubscription?.cancel();
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _deviceDiscoverySubscription?.cancel();

    _stateSubscription = _bluetooth.onStateChanged.listen((s) {
      onState?.call(s);
    });
    _connectionSubscription = _bluetooth.onConnectionChanged.listen((s) {
      onConnection?.call(s);
    });
    _dataSubscription = _bluetooth.onDataReceived.listen((d) {
      onData?.call(d);
    });
    _deviceDiscoverySubscription = _bluetooth.onDeviceDiscovered.listen((d) {
      onDevice?.call(d);
    });
  }

  Future<bool> connectToDevice(String deviceAddress) async {
    try {
      return await _bluetooth.connect(deviceAddress);
    } catch (_) {
      return false;
    }
  }

  Future<bool> sendMessage(String message) async {
    try {
      return await _bluetooth.sendString(message);
    } catch (_) {
      return false;
    }
  }

  /// Send raw bytes (khuyến nghị khi gửi ESC/POS, CPCL, TSPL…)
  Future<bool> sendData(List<int> data) async {
    try {
      return await _bluetooth.sendData(data);
    } catch (_) {
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      return await _bluetooth.disconnect();
    } catch (_) {
      return false;
    }
  }

  Future<bool> startDiscovery() async {
    try {
      return await _bluetooth.startDiscovery();
    } catch (_) {
      return false;
    }
  }

  Future<bool> stopDiscovery() async {
    try {
      return await _bluetooth.stopDiscovery();
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _connectionSubscription?.cancel();
    _dataSubscription?.cancel();
    _stateSubscription?.cancel();
    _deviceDiscoverySubscription?.cancel();
  }
}
