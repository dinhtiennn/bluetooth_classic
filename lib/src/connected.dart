part of 'package:bluetooth_classic/bluetooth_classic.dart';

/// Classic connected device
class ClassicConnectedDevice extends ConnectedDevice {
  final FlutterBluetoothClassic _bluetooth;
  ClassicBluetoothDevice? _connectedDevice;
  final _readController = StreamController<Uint8List>.broadcast();
  bool _isWriting = false;
  bool _isConnected = true;

  ClassicConnectedDevice({
    required FlutterBluetoothClassic bluetooth,
    required ClassicBluetoothDevice connectedDevice,
  }) : _bluetooth = bluetooth {
    _connectedDevice = connectedDevice;
  }

  void _onDataReceived(BluetoothData data) {
    if (_isConnected) {
      // BluetoothData có asString() - convert string to bytes
      final string = data.asString();
      // Convert string to Uint8List
      _readController.add(Uint8List.fromList(string.codeUnits));
    }
  }

  @override
  ClassicBluetoothDevice? origin() {
    return _connectedDevice;
  }

  @override
  ConnectionState connectionState() {
    return _isConnected ? ConnectionState.connected : ConnectionState.disconnected;
  }

  @override
  String? deviceName() {
    return _connectedDevice?.name;
  }

  @override
  String? deviceMac() {
    return _connectedDevice?.mac;
  }

  @override
  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (e) {
      // Ignore disconnect errors
    }
    _isConnected = false;
    _connectedDevice = null;
  }

  @override
  Stream<Uint8List> read(ReadOptions? options) {
    return _readController.stream;
  }

  @override
  Future<void> write(
    Uint8List data, {
    bool sendDone = true,
  }) async {
    if (!_isConnected) {
      throw Exception("[bluetooth-classic] device is not connected");
    }

    // 加锁
    if (_isWriting) {
      throw Exception("[bluetooth-classic] write is already in progress");
    }
    _isWriting = true;
    try {
      // Convert bytes to string và gửi
      // Note: Có thể mất dữ liệu nếu bytes không phải là text
      // Để gửi binary data, cần encode (ví dụ: base64)
      final string = String.fromCharCodes(data);
      await _bluetooth.sendString(string);
      
      // Nếu cần đợi gửi xong
      if (sendDone) {
        // flutter_bluetooth_classic_serial không có allSent
        // Thêm delay nhỏ để đảm bảo dữ liệu được gửi
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } finally {
      // 释放锁
      _isWriting = false;
    }
  }
}
