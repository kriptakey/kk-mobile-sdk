import 'dart:typed_data';
import 'package:e2ee_device_binding_demo_flutter/main.dart';
import 'package:flutter/material.dart';

import 'package:e2ee_device_binding_demo_flutter/core/api_client.dart';

class ShowAccountScreen extends StatefulWidget {
  const ShowAccountScreen({
    Key? key,
    this.username,
    this.firstName,
    this.familyName,
    this.personIdNumber,
    this.dayOfBirth,
    this.address,
    this.phoneNumber,
    this.imageBytes,
  }) : super(key: key);

  final String? username;
  final String? firstName;
  final String? familyName;
  final String? personIdNumber;
  final String? dayOfBirth;
  final String? address;
  final String? phoneNumber;
  final Uint8List? imageBytes;

  @override
  State<ShowAccountScreen> createState() => _ShowAccountScreenState();
}

class _ShowAccountScreenState extends State<ShowAccountScreen> {
  final ApiClient _apiClient = ApiClient();

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
      backgroundColor: Colors.red[400],
    ));
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

  Future<void> logout() async {
    dynamic res = await _apiClient.logout();

    if (res['message'] == "User logged out successfully!") {
      switchToLoginScreen(res['message']);
    } else {
      getAlert('Error: ${res['message']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
        backgroundColor: Colors.deepPurple[100],
        body: SizedBox(
            width: size.width,
            height: size.height,
            child: Align(
                alignment: Alignment.center,
                child: Container(
                    width: size.width,
                    height: size.height,
                    color: Colors.deepPurple[100],
                    child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 50, horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    clipBehavior: Clip.hardEdge,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.transparent,
                                      border: Border.all(
                                          width: 1,
                                          color: Colors.blue.shade100),
                                    ),
                                    child: Container(
                                      height: 70,
                                      width: 70,
                                      clipBehavior: Clip.hardEdge,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.memory(
                                        widget.imageBytes!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),

                                // Display user first name
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.topCenter,
                                  child: Text(
                                    widget.username ?? 'N/A',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),

                                // Account details
                                const SizedBox(height: 18),
                                Container(
                                  width: size.width,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 7, horizontal: 10),
                                  decoration: BoxDecoration(
                                      color: Colors.deepPurple[200],
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Text('ACCOUNT DETAILS',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700)),
                                ),

                                // Show user first name
                                const SizedBox(height: 18),
                                Container(
                                  width: size.width,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.deepPurple[200],
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('First Name:',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black)),
                                      const SizedBox(height: 7),
                                      Text(widget.firstName ?? 'N/A',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),

                                // Show user last name
                                const SizedBox(height: 18),
                                Container(
                                  width: size.width,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.deepPurple[200],
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Last Name:',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black)),
                                      const SizedBox(height: 7),
                                      Text(widget.familyName ?? 'N/A',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),

                                // Show day of birth
                                const SizedBox(height: 18),
                                Container(
                                  width: size.width,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.deepPurple[200],
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Birthday:',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black)),
                                      const SizedBox(height: 7),
                                      Text(widget.dayOfBirth ?? 'N/A',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),

                                // Show address
                                const SizedBox(height: 18),
                                Container(
                                  width: size.width,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.deepPurple[200],
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Address:',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black)),
                                      const SizedBox(height: 7),
                                      Text(widget.address ?? 'N/A',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),

                                // Show personal id number
                                const SizedBox(height: 18),
                                Container(
                                  width: size.width,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.deepPurple[200],
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Personal ID number:',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black)),
                                      const SizedBox(height: 7),
                                      Text(widget.personIdNumber ?? 'N/A',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),

                                // Show phone number
                                const SizedBox(height: 18),
                                Container(
                                  width: size.width,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 5),
                                  decoration: BoxDecoration(
                                      color: Colors.deepPurple[200],
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Phone number:',
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black)),
                                      const SizedBox(height: 7),
                                      Text(widget.phoneNumber ?? 'N/A',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white)),
                                    ],
                                  ),
                                ),

                                // Logout button
                                const SizedBox(height: 18),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: () async {
                                      await logout();
                                    },
                                    style: TextButton.styleFrom(
                                        backgroundColor: Colors.deepPurple,
                                        minimumSize: const Size.fromHeight(45),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20)),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 25)),
                                    child: const Text(
                                      'Logout',
                                      style: TextStyle(
                                          // fontSize: 20,
                                          // fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )))))));
  }
}
