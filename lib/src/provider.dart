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
  StreamSubscription<BluetoothDevice>? _deviceDiscoverySubscription;
  bool _isDiscovering = false;
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
    return _isDiscovering;
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

    // reset
    _isDiscovering = true;
    await stopDiscovery();

    // Listen realtime device found events (giống demo)
    _deviceDiscoverySubscription =
        _instance.onDeviceDiscovered.listen((BluetoothDevice device) {
      _discoveryController.add(_Helpers.fromBluetoothDevice(device));
    });

    // Start discovery
    final ok = await _instance.startDiscovery();
    if (!ok) {
      _isDiscovering = false;
      throw Exception('[bluetooth-classic] startDiscovery returned false');
    }

    // Auto-stop sau timeout (giống behavior BLE package)
    Timer(timeout, () {
      // ignore: discarded_futures
      stopDiscovery();
    });
  }

  @override
  Future<void> stopDiscovery() async {
    try {
      await _instance.stopDiscovery();
    } catch (_) {
      // ignore
    }
    await _deviceDiscoverySubscription?.cancel();
    _deviceDiscoverySubscription = null;
    _isDiscovering = false;
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
