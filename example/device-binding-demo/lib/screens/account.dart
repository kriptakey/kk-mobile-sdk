import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'package:e2ee_device_binding_demo_flutter/main.dart';
import 'package:e2ee_device_binding_demo_flutter/core/api_client.dart';
import 'package:e2ee_device_binding_demo_flutter/util/cache_parameters.dart';
import 'package:e2ee_device_binding_demo_flutter/util/util.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/device_registration.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/show_account.dart';

import 'package:kms_e2ee_package/api.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key, this.username}) : super(key: key);

  final String? username;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final bool isDeviceBinding = CacheParameters().getDeviceBindingFlag();
  final ApiClient apiClient = ApiClient();
  final LocalAuthentication _auth = LocalAuthentication();
  final String _authenticationMessage = "Please authenticate yourself";
  final Util _util = Util();

  Future<void> logout() async {
    dynamic res = await apiClient.logout();

    if (res['message'] == "User logged out successfully!") {
      switchToLoginScreen(res['message']);
    } else {
      getAlert('Error: ${res['message']}');
    }
  }

  void switchToLoginScreen(String message) {
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

  void switchToShowAccountScreen(
      String message,
      String username,
      String firstName,
      String familyName,
      String personalIdNumber,
      String dayOfBirth,
      String address,
      String phoneNumber,
      Uint8List imageBytes) {
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
                  builder: (context) => ShowAccountScreen(
                      username: username,
                      firstName: firstName,
                      familyName: familyName,
                      personIdNumber: personalIdNumber,
                      dayOfBirth: dayOfBirth,
                      address: address,
                      phoneNumber: phoneNumber,
                      imageBytes: imageBytes)));
        },
      ),
      backgroundColor: Colors.deepPurple,
    ));
  }

  void switchToDeviceRegistrationScreen(String message) {
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
                  builder: (context) => DeviceRegistrationScreen()));
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
              MaterialPageRoute(builder: (context) => const AccountScreen()));
        },
      ),
      backgroundColor: Colors.red[400],
    ));
  }

  Future<void> showDeviceBindingConfirmation() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('AlertDialog'),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Your device has been registered.'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  // Switch to Login screen
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const AccountScreen()));
                },
              ),
            ],
          );
        });
  }

  Future<void> showAccount() async {
    // Fetch ClientKey
    KMSWrappedKeyMetadata? kmsWrappedKeyMetadata;
    try {
      // NOTE: Only applicable for Android API level >= 28, or starting from Android 9
      kmsWrappedKeyMetadata =
          await E2eeSdkPackage().fetchWrappedClientKeyFromSecureStorage();
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }

    // Get user data from database
    Map<String, dynamic> getAccountData = {
      "name": widget.username!,
      "encryptedClientKey": kmsWrappedKeyMetadata.encodedKMSKeyWrapped,
      "encryptedClientKeyMetadata":
          kmsWrappedKeyMetadata.encodedEncryptedMetadata
    };

    dynamic getAccountResponse = await apiClient.getUserData(getAccountData);
    List<RequestSingleE2eeDecrypt> singleEncryptedDataBlockList = [];
    for (final ciphertext in getAccountResponse['ciphertextList']) {
      final RequestSingleE2eeDecrypt singleEncryptedDataBlock =
          RequestSingleE2eeDecrypt(
              ciphertext['text'], ciphertext['mac'], ciphertext['iv']);
      singleEncryptedDataBlockList.add(singleEncryptedDataBlock);
    }

    // Decrypt client data
    await decryptClientData(getAccountResponse['username'],
        singleEncryptedDataBlockList, kmsWrappedKeyMetadata.aad);
  }

  Future<void> decryptClientData(
      String username,
      List<RequestSingleE2eeDecrypt> singleEncryptedDataList,
      Uint8List aad) async {
    // Encrypt the payload using kms e2ee sdk
    final RequestE2eeDecrypt requestE2eeDecrypt =
        RequestE2eeDecrypt(singleEncryptedDataList, aad);
    ResponseE2eeDecrypt? responseE2eeDecrypt;
    try {
      responseE2eeDecrypt =
          await E2eeSdkPackage().e2eeDecryptInSecureStorage(requestE2eeDecrypt);
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }

    final String firstName = utf8.decode(responseE2eeDecrypt.messages[0]);
    final String familyName = utf8.decode(responseE2eeDecrypt.messages[1]);
    final String personalIdNumber =
        utf8.decode(responseE2eeDecrypt.messages[2]);
    final String dayOfBirth = utf8.decode(responseE2eeDecrypt.messages[3]);
    final String address = utf8.decode(responseE2eeDecrypt.messages[4]);
    final String phoneNumber = utf8.decode(responseE2eeDecrypt.messages[5]);
    final Uint8List imageBytes = responseE2eeDecrypt.messages[6];

    // Show user data
    switchToShowAccountScreen(
        "Notification: Display user account!",
        username,
        firstName,
        familyName,
        personalIdNumber,
        dayOfBirth,
        address,
        phoneNumber,
        imageBytes);
  }

  Future<void> authenticateUserToShowAccount() async {
    // Authenticate user
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

    // The following authentication prompt is only for Android sample.
    // Meanwhile, the iOS authentication prompt has been covered by the SDK itself.
    // NOTE: iOS based SDK authentication does not work in simulator.
    // You need to test iOS use case in actual device.
    if (canAuthenticate) {
      try {
        final bool didAuthenticate = await _auth.authenticate(
            localizedReason: _authenticationMessage,
            options: const AuthenticationOptions(stickyAuth: true));
        if (didAuthenticate) {
          await showAccount();
        } else {
          getAlert("User not authenticated.");
        }
      } on PlatformException catch (e) {
        getAlert('Error - ${e.message}');
      }
    }
  }

  Future<void> authenticateUserToUnregisterDevice() async {
    // Authenticate user
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

    // The following authentication prompt is only for Android sample.
    // Meanwhile, the iOS authentication prompt has been covered by the SDK itself.
    // NOTE: iOS based SDK authentication does not work in simulator.
    // You need to test iOS use case in actual device.
    if (canAuthenticate && Platform.isAndroid) {
      try {
        final bool didAuthenticate = await _auth.authenticate(
            localizedReason: _authenticationMessage,
            options: const AuthenticationOptions(stickyAuth: true));
        if (didAuthenticate) {
          await E2eeSdkPackage().unregisterDeviceFromSecureStorage();
          CacheParameters().setDeviceBinding(false);
          switchToLoginScreen(
              "Notification: The device has been unregistered successfully!");
        } else {
          getAlert("User not authenticated.");
        }
      } on PlatformException catch (e) {
        getAlert('Error - ${e.message}');
      }
    } else if (Platform.isIOS) {
      await E2eeSdkPackage().unregisterDeviceFromSecureStorage();
      CacheParameters().setDeviceBinding(false);
      switchToLoginScreen(
          "Notification: The device has been unregistered successfully!");
    }
  }

  Future<void> unregisterDevice() async {
    // NOTE: Unregister device to support testing only. Don't use it during production unless if it's necessary.
    // The unregistration process will delete all keys that you already created in the secure storage

    // Delete user data from DB. You can delete entire user data or partial data related to device binding only.
    // In this demo, we only remove the device related data such as its public key and its password.
    // So, the user can register new device after unregistering the old device.
    // Get user data from database
    Map<String, dynamic> unregisterDeviceData = {"name": widget.username!};

    // Unregister device from server
    dynamic response = await apiClient.unregisterDevice(unregisterDeviceData);
    if (response['message'] ==
        "The device has been unregistered successfully!") {
      await authenticateUserToUnregisterDevice();
    } else {
      getAlert('Alert: ${response['message']}');
    }
  }

  @override
  Widget build(BuildContext context) { // UI for user account
    return Scaffold(
      backgroundColor: Colors.deepPurple[100],
      body: Form(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              const SizedBox(height: 150),
              Center(
                child: Text("Welcome back",
                    style: Theme.of(context).textTheme.headlineLarge),
              ),
              const SizedBox(height: 10),

              // Button
              const SizedBox(height: 60),
              Column(
                children: [
                  // Button Register Device
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      if (isDeviceBinding) {
                        await showDeviceBindingConfirmation(); // Only for confirmation
                      } else {
                        // Start device registration
                        switchToDeviceRegistrationScreen( // Invoke device registration page
                            "Notification: Register your device!");
                      }
                    },
                    child: const Text(
                      "Register Device",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Button Show Account
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      await authenticateUserToShowAccount();
                    },
                    child: const Text(
                      "Show Account",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Button Unregister Device
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size.fromHeight(45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () async {
                      await unregisterDevice();
                    },
                    child: const Text(
                      "Unregister Device",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Sign out from account."),
                      TextButton(
                        onPressed: () async {
                          // Call api logout and switch to login screen
                          await logout();
                        },
                        child: const Text("Sign Out",
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
