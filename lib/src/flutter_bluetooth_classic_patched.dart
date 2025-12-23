import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

/// Patched wrapper for `flutter_bluetooth_classic_serial`.
///
/// Why: Android EventChannel often delivers `Map<Object?, Object?>`, but the
/// original plugin casts to `Map<String, dynamic>` and can crash at runtime.
/// This wrapper keeps the **same channels** and **same API**, but parses maps
/// safely.
class FlutterBluetoothClassic {
  static const MethodChannel _channel = MethodChannel(
    'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic',
  );
  static const EventChannel _stateChannel = EventChannel(
    'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic_state',
  );
  static const EventChannel _connectionChannel = EventChannel(
    'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic_connection',
  );
  static const EventChannel _dataChannel = EventChannel(
    'com.flutter_bluetooth_classic.plugin/flutter_bluetooth_classic_data',
  );

  static FlutterBluetoothClassic? _instance;

  final _stateStreamController = StreamController<BluetoothState>.broadcast();
  final _connectionStreamController =
      StreamController<BluetoothConnectionState>.broadcast();
  final _dataStreamController = StreamController<BluetoothData>.broadcast();
  final _deviceDiscoveryStreamController =
      StreamController<BluetoothDevice>.broadcast();

  Stream<BluetoothState> get onStateChanged => _stateStreamController.stream;
  Stream<BluetoothConnectionState> get onConnectionChanged =>
      _connectionStreamController.stream;
  Stream<BluetoothData> get onDataReceived => _dataStreamController.stream;
  Stream<BluetoothDevice> get onDeviceDiscovered =>
      _deviceDiscoveryStreamController.stream;

  factory FlutterBluetoothClassic() {
    _instance ??= FlutterBluetoothClassic._();
    return _instance!;
  }

  FlutterBluetoothClassic._() {
    _stateChannel.receiveBroadcastStream().listen((dynamic event) {
      final eventMap = _asStringKeyedMap(event);
      if (eventMap == null) return;

      if (eventMap['event'] == 'deviceFound') {
        final deviceMap = _asStringKeyedMap(eventMap['device']);
        if (deviceMap != null) {
          _deviceDiscoveryStreamController
              .add(BluetoothDevice.fromMap(deviceMap));
        }
      } else {
        _stateStreamController.add(BluetoothState.fromMap(eventMap));
      }
    }, onError: (_) {});

    _connectionChannel.receiveBroadcastStream().listen((dynamic event) {
      final map = _asStringKeyedMap(event);
      if (map == null) return;
      _connectionStreamController.add(BluetoothConnectionState.fromMap(map));
    }, onError: (_) {});

    _dataChannel.receiveBroadcastStream().listen((dynamic event) {
      final map = _asStringKeyedMap(event);
      if (map == null) return;
      _dataStreamController.add(BluetoothData.fromMap(map));
    }, onError: (_) {});
  }

  static Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      // Convert Map<Object?, Object?> -> Map<String, dynamic>
      final out = <String, dynamic>{};
      for (final entry in value.entries) {
        final k = entry.key?.toString();
        if (k == null) continue;
        out[k] = entry.value;
      }
      return out;
    }
    return null;
  }

  Future<bool> isBluetoothSupported() async {
    return await _channel.invokeMethod<bool>('isBluetoothSupported') ?? false;
  }

  Future<bool> isBluetoothEnabled() async {
    return await _channel.invokeMethod<bool>('isBluetoothEnabled') ?? false;
  }

  Future<bool> enableBluetooth() async {
    return await _channel.invokeMethod<bool>('enableBluetooth') ?? false;
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    final devices =
        await _channel.invokeMethod<List<dynamic>>('getPairedDevices') ??
            <dynamic>[];
    return devices
        .whereType<Map>()
        .map((m) => BluetoothDevice.fromMap(_asStringKeyedMap(m) ?? const {}))
        .toList();
  }

  Future<List<BluetoothDevice>> getDiscoveredDevices() async {
    final devices =
        await _channel.invokeMethod<List<dynamic>>('getDiscoveredDevices') ??
            <dynamic>[];
    return devices
        .whereType<Map>()
        .map((m) => BluetoothDevice.fromMap(_asStringKeyedMap(m) ?? const {}))
        .toList();
  }

  Future<bool> startDiscovery() async {
    return await _channel.invokeMethod<bool>('startDiscovery') ?? false;
  }

  Future<bool> stopDiscovery() async {
    return await _channel.invokeMethod<bool>('stopDiscovery') ?? false;
  }

  Future<bool> connect(String address) async {
    return await _channel.invokeMethod<bool>('connect', {'address': address}) ??
        false;
  }

  Future<bool> disconnect() async {
    return await _channel.invokeMethod<bool>('disconnect') ?? false;
  }

  Future<bool> sendData(List<int> data) async {
    return await _channel.invokeMethod<bool>('sendData', {'data': data}) ??
        false;
  }

  Future<bool> sendString(String message) async {
    final data = utf8.encode(message);
    return await sendData(data);
  }

  void dispose() {
    _stateStreamController.close();
    _connectionStreamController.close();
    _deviceDiscoveryStreamController.close();
    _dataStreamController.close();
  }
}

class BluetoothException implements Exception {
  final String message;
  BluetoothException(this.message);
  @override
  String toString() => 'BluetoothException: $message';
}

class BluetoothState {
  final bool isEnabled;
  final String status;
  BluetoothState({required this.isEnabled, required this.status});

  factory BluetoothState.fromMap(Map<String, dynamic> map) {
    return BluetoothState(
      isEnabled: map['isEnabled'] == true,
      status: (map['status'] ?? '').toString(),
    );
  }
}

class BluetoothDevice {
  final String name;
  final String address;
  final bool paired;

  BluetoothDevice(
      {required this.name, required this.address, required this.paired});

  factory BluetoothDevice.fromMap(Map<String, dynamic> map) {
    return BluetoothDevice(
      name: (map['name'] ?? 'Unknown').toString(),
      address: (map['address'] ?? '').toString(),
      paired: map['paired'] == true,
    );
  }
}

class BluetoothConnectionState {
  final bool isConnected;
  final String deviceAddress;
  final String status;

  BluetoothConnectionState({
    required this.isConnected,
    required this.deviceAddress,
    required this.status,
  });

  factory BluetoothConnectionState.fromMap(Map<String, dynamic> map) {
    return BluetoothConnectionState(
      isConnected: map['isConnected'] == true,
      deviceAddress: (map['deviceAddress'] ?? '').toString(),
      status: (map['status'] ?? '').toString(),
    );
  }
}

class BluetoothData {
  final String deviceAddress;
  final List<int> data;

  BluetoothData({required this.deviceAddress, required this.data});

  String asString() => utf8.decode(data, allowMalformed: true);

  factory BluetoothData.fromMap(Map<String, dynamic> map) {
    final raw = map['data'];
    final list =
        (raw is List) ? raw.map((e) => (e as num).toInt()).toList() : <int>[];
    return BluetoothData(
      deviceAddress: (map['deviceAddress'] ?? '').toString(),
      data: list,
    );
  }
}
