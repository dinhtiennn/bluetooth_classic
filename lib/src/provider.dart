part of 'package:bluetooth_classic/bluetooth_classic.dart';

class ClassicBluetooth
    extends Fluetooth<FlutterBluetoothClassic, ClassicBluetoothDevice> {
  final FlutterBluetoothClassic _instance = FlutterBluetoothClassic();

  ClassicBluetooth._() {
    super.init();
  }

  ClassicConnectedDevice? _connectedDevice;
  final _discoveryController =
      StreamController<ClassicBluetoothDevice>.broadcast();
  StreamSubscription<BluetoothData>? _dataSubscription;
  static ClassicBluetooth? _classicBluetooth;

  factory ClassicBluetooth() => _classicBluetooth ??= ClassicBluetooth._();

  @override
  FlutterBluetoothClassic origin() {
    return _instance;
  }

  @override
  Future<bool> availableBluetooth() async {
    return await _instance.isBluetoothSupported();
  }

  @override
  Future<bool> bluetoothIsEnabled() async {
    return await _instance.isBluetoothEnabled();
  }

  @override
  Future<ConnectedDevice> connect(ClassicBluetoothDevice device) async {
    await stopDiscovery();

    var address = device.mac ?? device.origin.address;
    if (address.isEmpty) {
      throw Exception("[bluetooth-classic] device address is empty");
    }

    final connected = await _instance.connect(address);
    if (!connected) {
      throw Exception(
          "[bluetooth-classic] failed to connect to device: $address");
    }

    _connectedDevice = ClassicConnectedDevice(
      bluetooth: _instance,
      connectedDevice: device,
    );

    // Listen for incoming data
    _dataSubscription?.cancel(); // Cancel previous subscription if any
    _dataSubscription = _instance.onDataReceived.listen((data) {
      _connectedDevice?._onDataReceived(data);
    });

    return _connectedDevice!;
  }

  Future<ConnectedDevice> connectWithMac(String name, String macAddress) async {
    final device = _Helpers.fromMacAddress(name, macAddress);
    return await connect(device);
  }

  @override
  Future<bool> isConnected() async {
    return _connectedDevice?.connectionState() == ConnectionState.connected;
  }

  @override
  Future<bool> isDiscovery() async {
    // flutter_bluetooth_classic_serial không có method isDiscovering
    // Sử dụng stream controller để track
    return false; // Simplified - có thể cải thiện sau
  }

  @override
  Stream<ClassicBluetoothDevice> discovered() {
    return _discoveryController.stream;
  }

  @override
  Future<void> startDiscovery({
    bool disconnectConnectedDevice = true,
    bool useMac = true,
    Duration timeout = FluetoothConst.defDiscoveryTimeout,
  }) async {
    if (disconnectConnectedDevice && await isConnected()) {
      await _connectedDevice?.disconnect();
    }

    if (!await _isReadyDiscovery()) {
      return;
    }

    try {
      // Lấy danh sách thiết bị đã paired
      final pairedDevices = await _instance.getPairedDevices();

      for (final device in pairedDevices) {
        _discoveryController.add(_Helpers.fromBluetoothDevice(device));
      }
    } catch (e) {
      throw Exception("[bluetooth-classic] discovery failed: $e");
    }
  }

  @override
  Future<void> stopDiscovery() async {
    // flutter_bluetooth_classic_serial không có cancelDiscovery
    // Discovery dựa trên getPairedDevices nên không cần stop
  }

  //# private function
  Future<bool> _isReadyDiscovery() async {
    if (!await _instance.isBluetoothEnabled()) {
      return false;
    }
    if (!await _instance.isBluetoothSupported()) {
      return false;
    }
    return true;
  }

  Future<void> setPin(String? pin) async {
    // flutter_bluetooth_classic_serial không có setPin method
    // Có thể cần implement riêng nếu cần
  }
}

class _Helpers {
  static ClassicBluetoothDevice fromBluetoothDevice(BluetoothDevice device) {
    return ClassicBluetoothDevice(
      origin: device,
      name: device.name,
      mac: device.address,
      rssi:
          null, // flutter_bluetooth_classic_serial không có RSSI trong paired devices
    );
  }

  static ClassicBluetoothDevice fromMacAddress(String name, String macAddress) {
    // Tạo một BluetoothDevice giả để giữ compatibility
    return ClassicBluetoothDevice(
      origin: BluetoothDevice(
        name: name,
        address: macAddress,
        paired: true, // Assume paired when connecting by MAC
      ),
      name: name,
      mac: macAddress,
    );
  }
}
