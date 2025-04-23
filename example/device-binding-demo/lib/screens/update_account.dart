import 'dart:convert';
import 'dart:typed_data';

import 'package:e2ee_device_binding_demo_flutter/util/util.dart';
import 'package:flutter/material.dart';

import 'package:e2ee_device_binding_demo_flutter/core/api_client.dart';
import 'package:e2ee_device_binding_demo_flutter/main.dart';

import 'package:kms_e2ee_package/api.dart';

class UpdateAccountScreen extends StatefulWidget {
  static String id = "update_account_screen";
  const UpdateAccountScreen({Key? key}) : super(key: key);

  @override
  State<UpdateAccountScreen> createState() => _UpdateAccountScreenState();
}

class _UpdateAccountScreenState extends State<UpdateAccountScreen> {
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerFirstName = TextEditingController();
  final TextEditingController _controllerFamilyName = TextEditingController();
  final TextEditingController _controllerDayOfBirth = TextEditingController();
  final TextEditingController _controllerAddress = TextEditingController();
  final TextEditingController _controllerPersonalIdNumber =
      TextEditingController();
  final TextEditingController _controllerPhoneNumber = TextEditingController();

  final FocusNode _focusNodeEntry = FocusNode();

  final ApiClient _apiClient = ApiClient();
  final Util util = Util();
  late Uint8List imageBytes;

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
      backgroundColor: Colors.red.shade300,
    ));
  }

  Future<void> updateUserAccount() async {
    // Request server public key
    dynamic response = await _apiClient.preAuthentication();

    // Call API e2eeEncrypt to encrypt password entered by user
    final RequestE2eeEncrypt requestE2eeEncrypt =
        RequestE2eeEncrypt(response['publicKey'], response['oaepLabel'], [
      Uint8List.fromList(utf8.encode(_controllerFirstName.text)),
      Uint8List.fromList(utf8.encode(_controllerFamilyName.text)),
      Uint8List.fromList(utf8.encode(_controllerDayOfBirth.text)),
      Uint8List.fromList(utf8.encode(_controllerAddress.text)),
      Uint8List.fromList(utf8.encode(_controllerPersonalIdNumber.text)),
      Uint8List.fromList(utf8.encode(_controllerPhoneNumber.text)),
      imageBytes
    ]);
    ResponseE2eeEncrypt? responseE2eeEncrypt;
    try {
      responseE2eeEncrypt =
          await E2eeSdkPackage().e2eeEncrypt(requestE2eeEncrypt);
    } on KKException catch (e) {
      print("Error: ${e.message}, error code: ${e.code}");
      rethrow;
    }
    ///////////////////////////////////////////////////////////

    // Send encrypted data to application server
    Map<String, dynamic> userData = {
      "name": _controllerUsername.text,
      "encryptedFirstNameBlock": responseE2eeEncrypt.encryptedDataBlockList[0],
      "encryptedFamilyNameBlock": responseE2eeEncrypt.encryptedDataBlockList[1],
      "encryptedDayOfBirthBlock": responseE2eeEncrypt.encryptedDataBlockList[2],
      "encryptedAddressBlock": responseE2eeEncrypt.encryptedDataBlockList[3],
      "encryptedPersonalIdBlock": responseE2eeEncrypt.encryptedDataBlockList[4],
      "encryptedPhoneNumberBlock":
          responseE2eeEncrypt.encryptedDataBlockList[5],
      "encryptedImage": responseE2eeEncrypt.encryptedDataBlockList[6],
      "publicKey": response['publicKey'],
      "e2eeSessionId": response['e2eeSessionId'],
      "metaData": responseE2eeEncrypt.metadata
    };

    dynamic updateUserAccountResponse =
        await _apiClient.udpateUserAccount(userData);
    if (updateUserAccountResponse['message'] == "User account updated.") {
      switchToLoginAccountScreen(
          "Notification: The account has been updated successfully!");
    } else {
      getAlert('Alert: ${updateUserAccountResponse['message']}');
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
              const SizedBox(height: 30),
              Center(
                child: Text("Complete Account",
                    style: Theme.of(context).textTheme.headlineLarge),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text("Complete your personal data",
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 5),

              // First name
              const SizedBox(height: 20),
              TextFormField(
                controller: _controllerFirstName,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: "First Name",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodeEntry.requestFocus(),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter first name.";
                  }
                  return null;
                },
              ),

              // Family name
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerFamilyName,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: "Family Name",
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodeEntry.requestFocus(),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter family name.";
                  }
                  return null;
                },
              ),

              // Username
              const SizedBox(height: 10),
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
                onEditingComplete: () => _focusNodeEntry.requestFocus(),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter username.";
                  }
                  return null;
                },
              ),

              // Day of birth
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerDayOfBirth,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: "Day of birth",
                  prefixIcon: const Icon(Icons.date_range),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodeEntry.requestFocus(),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter day of birth.";
                  }
                  return null;
                },
              ),

              // Address
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerAddress,
                keyboardType: TextInputType.streetAddress,
                decoration: InputDecoration(
                  labelText: "Address",
                  prefixIcon: const Icon(Icons.home_max_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodeEntry.requestFocus(),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your address.";
                  }
                  return null;
                },
              ),

              // Personal identity number
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerPersonalIdNumber,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Personal ID number",
                  prefixIcon: const Icon(Icons.numbers_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodeEntry.requestFocus(),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your ID number.";
                  }
                  return null;
                },
              ),

              // Phone number
              const SizedBox(height: 10),
              TextFormField(
                controller: _controllerPhoneNumber,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Phone number",
                  prefixIcon: const Icon(Icons.phone_android_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onEditingComplete: () => _focusNodeEntry.requestFocus(),
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter your phone number.";
                  }
                  return null;
                },
              ),

              // Button
              const SizedBox(height: 30),
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
                      await updateUserAccount();
                    },
                    child: const Text(
                      "Update Account",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Upload your picture?"),
                      TextButton(
                        onPressed: () async {
                          imageBytes = await util.readImageAsBytesFromGallery();
                        },
                        child: const Text("Upload",
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
