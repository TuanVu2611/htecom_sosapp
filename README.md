# hcmu_sos

A new Flutter project.

## Build iOS bằng Xcode

Sau khi pull code, đổi dependencies hoặc chạy `flutter clean`, chạy từ thư mục project:

```sh
bash tool/prepare_ios.sh
```

Sau đó mở `ios/Runner.xcworkspace` để Run hoặc Archive.

Script chạy `flutter pub get` và `flutter build ios --config-only --debug --no-codesign --no-pub`
để đồng bộ Swift Package với deployment target iOS 15.6 của Runner.
Nếu đã chạy riêng `flutter pub get`, chạy lệnh `flutter build ios --config-only --debug --no-codesign --no-pub`
trước khi build bằng Xcode.

Flutter hiện có [lỗi #186804](https://github.com/flutter/flutter/issues/186804):
`pub get` sinh lại `FlutterGeneratedPluginSwiftPackage/Package.swift` với iOS 13.0,
trong khi Firebase yêu cầu iOS 15.0 trở lên. Không sửa tay file trong `ios/Flutter/ephemeral/`
vì Flutter sẽ ghi đè. Script trên là cách tránh lỗi với SDK hiện tại, không sửa lỗi bên trong SDK.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
