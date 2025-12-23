part of 'package:bluetooth_classic/bluetooth_classic.dart';

class ClassicBluetooth extends Fluetooth<FlutterBluetoothSerial, ClassicBluetoothDevice> {
  final FlutterBluetoothSerial _instance = FlutterBluetoothSerial.instance;

  ClassicConnectedDevice? _connectedDevice;
  final _discoveryController = StreamController<ClassicBluetoothDevice>.broadcast();
  late List<BluetoothDiscoveryResult> notifiedDevices = [];
  static ClassicBluetooth? _classicBluetooth;

  factory ClassicBluetooth() => _classicBluetooth ??= ClassicBluetooth._();

  ClassicBluetooth._() {
    super.init();
  }

  @override
  FlutterBluetoothSerial origin() {
    return _instance;
  }

  @override
  Future<bool> availableBluetooth() async {
    return await _instance.isAvailable ?? false;
  }

  @override
  Future<bool> bluetoothIsEnabled() async {
    return await _instance.isEnabled ?? false;
  }

  @override
  Future<ConnectedDevice> connect(ClassicBluetoothDevice device) async {
    var originDevice = device.origin;
    var address = originDevice.address;
    var connection = await BluetoothConnection.toAddress(address);
    _connectedDevice = ClassicConnectedDevice(
      connection: connection,
      connectedDevice: device,
    );
    return _connectedDevice!;
  }

  Future<ConnectedDevice> connectWithMac(String name, String macAddress) async {
    var connection = await BluetoothConnection.toAddress(macAddress);
    _connectedDevice = ClassicConnectedDevice(
      connection: connection,
      connectedDevice: _Helpers.fromMacAddress(name, macAddress),
    );
    return _connectedDevice!;
  }

  @override
  Future<bool> isConnected() async {
    return ConnectionState.connected == _connectedDevice?.connectionState();
  }

  @override
  Future<bool> isDiscovery() async {
    var status = await Permission.bluetoothScan.status;
    if (!status.isGranted) return false;
    return await _instance.isDiscovering ?? false;
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
    notifiedDevices.clear();
    _instance.startDiscovery().listen((result) {
      _discoveryController.add(_Helpers.fromClassicScanResult(result));
    });
  }

  @override
  Future<void> stopDiscovery() async {
    await _instance.cancelDiscovery();
  }

  //# private function
  Future<bool> _isReadyDiscovery() async {
    if (await _instance.isEnabled == false) {
      return false;
    }
    if (await _instance.isAvailable == false) {
      return false;
    }
    return true;
  }

  Future<void> setPin(String? pin) async {
    if (pin == null) {
      _instance.setPairingRequestHandler(null);
      return;
    }
    _instance.setPairingRequestHandler((BluetoothPairingRequest request) {
      if (request.pairingVariant == PairingVariant.Pin) {
        return Future.value(pin);
      } else if (request.pairingVariant == PairingVariant.Consent) {
        return Future.value(true);
      }
      return Future.value(null);
    });
  }
}

class _Helpers {
  static ClassicBluetoothDevice fromClassicScanResult(BluetoothDiscoveryResult result) {
    var device = result.device;
    return ClassicBluetoothDevice(
      origin: device,
      name: device.name,
      mac: device.address,
      rssi: result.rssi,
    );
  }
  static ClassicBluetoothDevice fromMacAddress(String name ,String macAddress) {
    return ClassicBluetoothDevice(
      origin: BluetoothDevice(address: macAddress),
      name: name,
      mac: macAddress,
    );
  }
}
