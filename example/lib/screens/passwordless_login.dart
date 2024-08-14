import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

import 'package:e2ee_device_binding_demo_flutter/core/api_client.dart';
import 'package:e2ee_device_binding_demo_flutter/util/util.dart';
import 'package:e2ee_device_binding_demo_flutter/main.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/account.dart';

import 'package:kms_e2ee_package/api.dart';

class PasswordlessLoginScreen extends StatefulWidget {
  const PasswordlessLoginScreen({Key? key}) : super(key: key);

  @override
  State<PasswordlessLoginScreen> createState() =>
      _PasswordlessLoginScreenState();
}

class _PasswordlessLoginScreenState extends State<PasswordlessLoginScreen> {
  final TextEditingController _controllerUsername = TextEditingController();
  final FocusNode _focusNodePassword = FocusNode();
  final ApiClient _apiClient = ApiClient();
  final Util util = Util();
  final String _authenticationMessage = "Please authenticate yourself";

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

  void switchToAccountScreen(String message) {
    if (!context.mounted) return;
    // Notify user that session has been created
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          // Switch to account screen
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      AccountScreen(username: _controllerUsername.text)));
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

  Future<void> authenticateDeviceAndUserToServer(
      ResponseE2eeEncrypt deviceBasedEncryptedPassword,
      String serverPublicKey,
      String e2eeSessionId,
      String nonce,
      String nonceSignature) async {
    // Send encrypted password and metadata to app server
    Map<String, dynamic> deviceAuthenticationData = {
      "name": _controllerUsername.text,
      "encryptedPasswordBlock":
          deviceBasedEncryptedPassword.encryptedDataBlockList[0],
      "publicKey": serverPublicKey,
      "e2eeSessionId": e2eeSessionId,
      "nonce": nonce,
      "nonceSignature": nonceSignature,
      "metaData": deviceBasedEncryptedPassword.metadata
    };
    dynamic deviceActivationResponse =
        await _apiClient.authenticateUserAndDevice(deviceAuthenticationData);

    if (deviceActivationResponse['message'] ==
        "User and device authenticated.") {
      switchToAccountScreen(
          "Notification: User and device authenticated successfully.");
    } else {
      getAlert('Alert: ${deviceActivationResponse['message']}');
    }
  }

  Future<void> authenticateUserAndDevice() async {
    // Request server public key
    dynamic response = await _apiClient.preAuthentication();
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
                .getDeviceBasedEncryptedPasswordFromSecureStorage(
                    response['publicKey'], response['oaepLabel']);
          } on KKException catch (e) {
            print("Error: ${e.message}, error code: ${e.code}");
            rethrow;
          }

          // Generate 10 bytes random
          String? nonce;
          try {
            nonce = await E2eeSdkPackage().generateRandomString(10);
          } on KKException catch (e) {
            print("Error: ${e.message}, error code: ${e.code}");
            rethrow;
          }
          Uint8List? nonceSignature;
          try {
            nonceSignature = await E2eeSdkPackage()
                .signByDeviceIdKeypairInSecureStorage(
                    Uint8List.fromList(utf8.encode(nonce)));
          } on KKException catch (e) {
            print("Error: ${e.message}, error code: ${e.code}");
            rethrow;
          }

          // Activate device to application server
          await authenticateDeviceAndUserToServer(
              deviceBasedEncryptedPassword,
              response['publicKey'],
              response['e2eeSessionId'],
              nonce,
              base64Encode(nonceSignature));
        }
      } on PlatformException catch (e) {
        getAlert('Error - ${e.message}');
      }
    } else if (Platform.isIOS) {
      ResponseE2eeEncrypt? deviceBasedEncryptedPassword;
      try {
        deviceBasedEncryptedPassword = await E2eeSdkPackage()
            .getDeviceBasedEncryptedPasswordFromSecureStorage(
                response['publicKey'], response['oaepLabel']);
      } on KKException catch (e) {
        print("Error: ${e.message}, error code: ${e.code}");
        rethrow;
      }

      // Generate 10 bytes random
      String? nonce;
      try {
        nonce = await E2eeSdkPackage().generateRandomString(10);
      } on KKException catch (e) {
        print("Error: ${e.message}, error code: ${e.code}");
        rethrow;
      }
      Uint8List? nonceSignature;
      try {
        nonceSignature = await E2eeSdkPackage()
            .signByDeviceIdKeypairInSecureStorage(
                Uint8List.fromList(utf8.encode(nonce)));
      } on KKException catch (e) {
        print("Error: ${e.message}, error code: ${e.code}");
        rethrow;
      }

      // Activate device to application server
      await authenticateDeviceAndUserToServer(
          deviceBasedEncryptedPassword,
          response['publicKey'],
          response['e2eeSessionId'],
          nonce,
          base64Encode(nonceSignature));
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
                child: Text("Passwordless Login",
                    style: Theme.of(context).textTheme.headlineLarge),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text("Authenticate user and device",
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
                      await authenticateUserAndDevice();
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Authentication cancelled."),
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
