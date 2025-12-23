# bluetooth_classic

Classic bluetooth device package for Flutter with cross-platform support (iOS & Android).

## Platform Support

✅ **Cross-platform support**:
- ✅ **Android**: Fully supported
- ✅ **iOS**: Supported (with limitations)
- ✅ **macOS**: Supported
- ✅ **Linux**: Supported  
- ✅ **Windows**: Supported

This package uses `flutter_bluetooth_classic_serial` which provides cross-platform Bluetooth Classic Serial Port Profile (SPP) support.

**Note**: iOS support may have limitations due to iOS system restrictions. Ensure proper permissions are configured.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  bluetooth_classic:
    git:
      url: https://github.com/dinhtiennn/bluetooth_classic.git
      branch: main
```

## Platform Configuration

### Android

This package uses `flutter_bluetooth_classic_serial` which may require Android API 33+ for some attributes.

### Fix android:attr/lStar Error

If you encounter the error `android:attr/lStar not found` when building, add the following to your `android/build.gradle`:

```groovy
allprojects {
    configurations.all {
        resolutionStrategy {
            force 'androidx.core:core:1.12.0'
            force 'androidx.core:core-ktx:1.12.0'
        }
    }
}

subprojects {
    afterEvaluate { project ->
        if (project.hasProperty("android")) {
            def android = project.android
            if (android.hasProperty("compileSdk")) {
                android.compileSdk = 36
            }
            if (android.hasProperty("compileSdkVersion")) {
                android.compileSdkVersion = 36
            }
        }
    }
}
```

And ensure your `android/app/build.gradle` has:

```groovy
android {
    compileSdk = 36
    // ... other configs
}
```

### iOS

Add Bluetooth permissions to `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth access to connect to devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth access to connect to devices</string>
```

## Usage

```dart
import 'package:bluetooth_classic/bluetooth_classic.dart';

final bluetooth = ClassicBluetooth();

// Check if Bluetooth is available
if (await bluetooth.availableBluetooth() && await bluetooth.bluetoothIsEnabled()) {
  // Start discovery (gets paired devices)
  await bluetooth.startDiscovery();
  
  // Listen for discovered devices
  bluetooth.discovered().listen((device) {
    print('Found device: ${device.name} - ${device.mac}');
  });
  
  // Connect to a device by MAC address
  final connectedDevice = await bluetooth.connectWithMac(
    'Device Name',
    '00:11:22:33:44:55',
  );
  
  // Or connect using discovered device
  // final connectedDevice = await bluetooth.connect(device);
  
  // Read data from device
  connectedDevice.read().listen((data) {
    print('Received: $data');
  });
  
  // Write data to device
  final dataToSend = Uint8List.fromList([0x1B, 0x40, 0x0A]); // Example: ESC/POS commands
  await connectedDevice.write(dataToSend);
  
  // Disconnect when done
  await connectedDevice.disconnect();
}
```

## Sending Data to Peripheral Devices

This package supports sending binary data to Bluetooth Classic devices (printers, scanners, etc.):

```dart
// Example: Send ESC/POS commands to a thermal printer
final printer = await bluetooth.connectWithMac('Printer', '00:11:22:33:44:55');

// Initialize printer
await printer.write(Uint8List.fromList([0x1B, 0x40])); // ESC @

// Print text
final text = 'Hello World\n';
await printer.write(Uint8List.fromList(text.codeUnits));

// Cut paper
await printer.write(Uint8List.fromList([0x1D, 0x56, 0x41])); // GS V A
```
