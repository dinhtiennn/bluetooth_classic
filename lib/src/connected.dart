import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:psdk_bluetooth_classic/psdk_bluetooth_classic.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';

class ClassicConnectedDevice extends ConnectedDevice {
  BluetoothConnection? _connection;
  ClassicBluetoothDevice? _connectedDevice;
  final _readController = StreamController<Uint8List>.broadcast();
  bool _isWriting = false;
  ClassicConnectedDevice({
    required BluetoothConnection connection,
    required ClassicBluetoothDevice connectedDevice,
  }) {
    _connection = connection;
    _connectedDevice = connectedDevice;
    var input = _connection!.input;
    if (input == null) {
      return;
    }
    input.listen((data) {
      _readController.add(data);
    });
  }

  @override
  ClassicBluetoothDevice? origin() {
    return _connectedDevice;
  }

  @override
  ConnectionState connectionState() {
    return (_connection?.isConnected ?? false)
        ? ConnectionState.connected
        : ConnectionState.disconnected;
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
    _connection?.close();
    _connection = null;
    _connectedDevice = null;
  }

  @override
  Stream<Uint8List> read(ReadOptions? options){
    return _readController.stream;
  }

  @override
  Future<void> write(
    Uint8List data, {
    bool sendDone = true,
  }) async {
    // 加锁
    if (_isWriting) {
      throw Exception("[bluetooth-classic] write is already in progress");
    }
    _isWriting = true;
    try {
      _connection!.output.add(data);
      if (sendDone) {
        await _connection!.output.allSent;
      }
    } finally {
      // 释放锁
      _isWriting = false;
    }

  }
}
