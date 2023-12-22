import 'package:flutter_test/flutter_test.dart';
import 'package:e2ee_sdk_flutter/e2ee_sdk_flutter.dart';
import 'package:e2ee_sdk_flutter/native_bridge/e2ee_sdk_flutter_platform_interface.dart';
import 'package:e2ee_sdk_flutter/native_bridge/e2ee_sdk_flutter_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockE2eeSdkFlutterPlatform
    with MockPlatformInterfaceMixin
    implements E2eeSdkFlutterPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final E2eeSdkFlutterPlatform initialPlatform = E2eeSdkFlutterPlatform.instance;

  test('$MethodChannelE2eeSdkFlutter is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelE2eeSdkFlutter>());
  });

  test('getPlatformVersion', () async {
    E2eeSdkFlutter e2eeSdkFlutterPlugin = E2eeSdkFlutter();
    MockE2eeSdkFlutterPlatform fakePlatform = MockE2eeSdkFlutterPlatform();
    E2eeSdkFlutterPlatform.instance = fakePlatform;

    expect(await e2eeSdkFlutterPlugin.getPlatformVersion(), '42');
  });
}
