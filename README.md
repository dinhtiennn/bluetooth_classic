# bluetooth_classic

Classic bluetooth device package for Flutter.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  bluetooth_classic:
    git:
      url: https://github.com/dinhtiennn/bluetooth_classic.git
      branch: main
```

## Android Configuration

This package depends on `flutter_bluetooth_serial` which may require Android API 33+ for some attributes.

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

## Usage

```dart
import 'package:bluetooth_classic/bluetooth_classic.dart';

final bluetooth = ClassicBluetooth();
// ... use bluetooth
```
