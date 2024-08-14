import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'package:e2ee_device_binding_demo_flutter/core/api_client.dart';
import 'package:e2ee_device_binding_demo_flutter/main.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/passwordless_login.dart';
import 'package:e2ee_device_binding_demo_flutter/util/util.dart';

import 'package:kms_e2ee_package/api.dart';

class DeviceActivationScreen extends StatefulWidget {
  static String id = "register_screen";
  const DeviceActivationScreen(
      {Key? key, this.e2eeSessionId, this.publicKey, this.oaepLabel})
      : super(key: key);

  final String? e2eeSessionId;
  final String? publicKey;
  final String? oaepLabel;

  @override
  State<DeviceActivationScreen> createState() => _DeviceActivationScreenState();
}

class _DeviceActivationScreenState extends State<DeviceActivationScreen> {
  final TextEditingController _controllerUsername = TextEditingController();
  final String _authenticationMessage = "Please authenticate yourself";
  final FocusNode _focusNodePassword = FocusNode();
  final ApiClient _apiClient = ApiClient();
  final Util _util = Util();

  void switchToPasswordlessLoginScreen(String message) {
    if (!context.mounted) return;
    // Notify user that session has been created
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          // Switch to insert otp screen
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const PasswordlessLoginScreen()));
        },
      ),
      backgroundColor: Colors.deepPurple,
    ));
  }

  void switchToLoginAccountScreen(String message) {
    if (!context.mounted) return;
    // Notify user that session has been created
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          // Switch to insert otp screen
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LoginScreen()));
        },
      ),
      backgroundColor: Colors.deepPurple,
    ));
  }

  void getAlert(String message) {
    if (!context.mounted) return;
    // Notify user that session creation is failed
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          // Switch to main builder
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const LoginScreen()));
        },
      ),
      backgroundColor: Colors.redAccent[100],
    ));
  }

  Future<void> downloadWrappedClientKeyAndSetDeviceBindingFlag() async {
    // Generate key pair in TEE
    // NOTE: The default function parameters of function generateRSAKeypairInSecureStorage():
    // requireAuth is false and allowOverwrite is true
    String? clientKeyWrapper;
    try {
      clientKeyWrapper =
          await E2eeSdkPackage().generateRSAKeypairInSecureStorage();
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }

    // Get wrapped client key from server
    final responseGetWrappedClientKey =
        await _util.getWrappedClientKeyFromServer(clientKeyWrapper, true);

    // Store the wrapped client key
    try {
      // NOTE: Only applicable for Android API level >= 28, or starting from Android 9
      await E2eeSdkPackage().updateClientKeyToSecureStorage(
          responseGetWrappedClientKey!.wrappedKey,
          responseGetWrappedClientKey.kmsKeyWrapped,
          true);
      print("Importing client key for device binding success.");
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }

    // Set device binding
    try {
      await E2eeSdkPackage().setDeviceBindingInSecureStorage();
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }
  }

  Future<void> activateDeviceToServer(
      ResponseE2eeEncrypt deviceBasedEncryptedPassword,
      String serverPublicKey,
      String e2eeSessionId) async {
    // Send encrypted password and metadata to app server
    Map<String, dynamic> deviceBasedEncryptedPasswordData = {
      "name": _controllerUsername.text,
      "encryptedPasswordBlock":
          deviceBasedEncryptedPassword.encryptedDataBlockList[0],
      "publicKey": serverPublicKey,
      "e2eeSessionId": e2eeSessionId,
      "metaData": deviceBasedEncryptedPassword.metadata
    };
    dynamic deviceActivationResponse =
        await _apiClient.activateDevice(deviceBasedEncryptedPasswordData);

    if (deviceActivationResponse['message'] ==
        "Device activated successfully.") {
      // Download wrapped client key and set device binding flag
      await downloadWrappedClientKeyAndSetDeviceBindingFlag();

      switchToPasswordlessLoginScreen(
          "Notification: Device activated successfully. Please authenticate to complete the registration process!");
    } else {
      getAlert('Alert: ${deviceActivationResponse['message']}');
    }
  }

  Future<void> activateDevice() async {
    // Authenticate user
    final LocalAuthentication localAuthentication = LocalAuthentication();
    final bool canAuthenticateWithBiometrics =
        await localAuthentication.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics ||
        await localAuthentication.isDeviceSupported();

    // The following authentication prompt is only for Android sample.
    // Meanwhile, the iOS authentication prompt has been covered by the SDK itself.
    // NOTE: iOS based SDK authentication does not work in simulator.
    // You need to test iOS use case in actual device.
    if (canAuthenticate && Platform.isAndroid) {
      try {
        final bool didAuthenticate = await localAuthentication.authenticate(
            localizedReason: _authenticationMessage,
            options: const AuthenticationOptions(stickyAuth: true));
        if (didAuthenticate) {
          // Generate device based encrypted password, default passwordKey is true
          // if the user activate the device for the first time
          ResponseE2eeEncrypt? deviceBasedEncryptedPassword;
          try {
            deviceBasedEncryptedPassword = await E2eeSdkPackage()
                .generateDeviceBasedEncryptedPasswordInSecureStorage(
                    widget.publicKey!, widget.oaepLabel!);
          } on KKException catch (e) {
            print("Error: ${e.message}, error code: ${e.code}");
            rethrow;
          }

          // Activate device to application server
          await activateDeviceToServer(deviceBasedEncryptedPassword,
              widget.publicKey!, widget.e2eeSessionId!);
        }
      } on PlatformException catch (e) {
        getAlert('Error - ${e.message}');
      }
    } else if (Platform.isIOS) {
      ResponseE2eeEncrypt? deviceBasedEncryptedPassword;
      try {
        deviceBasedEncryptedPassword = await E2eeSdkPackage()
            .generateDeviceBasedEncryptedPasswordInSecureStorage(
                widget.publicKey!, widget.oaepLabel!);
      } on KKException catch (e) {
        print("Error: ${e.message}, error code: ${e.code}");
        rethrow;
      }

      // Activate device to application server
      await activateDeviceToServer(deviceBasedEncryptedPassword,
          widget.publicKey!, widget.e2eeSessionId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      body: Form(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 120),
              Center(
                child: Text("Activate",
                    style: Theme.of(context).textTheme.headlineLarge),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text("Activate your device",
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 5),

              // Username
              const SizedBox(height: 60),
              TextFormField(
                controller: _controllerUsername,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: "Username",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodePassword.requestFocus(),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter username.";
                  }
                  return null;
                },
              ),

              // Button
              const SizedBox(height: 50),
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      await activateDevice();
                    },
                    child: const Text(
                      "Activate",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already activate the device?"),
                      TextButton(
                        onPressed: () {
                          switchToLoginAccountScreen("Switch to login screen");
                        },
                        child: const Text("Cancel",
                            style: TextStyle(color: Colors.deepPurple)),
                      )
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
