import 'dart:async';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:e2ee_device_binding_demo_flutter/main.dart';
import 'package:e2ee_device_binding_demo_flutter/core/api_client.dart';
import 'package:e2ee_device_binding_demo_flutter/util/util.dart';
import 'package:e2ee_device_binding_demo_flutter/screens/approval_register.dart';

class MobileScannerRegisterScreen extends StatefulWidget {
  const MobileScannerRegisterScreen({
    Key? key,
    this.username,
  }) : super(key: key);

  final String? username;

  @override
  State<MobileScannerRegisterScreen> createState() => _MobileScannerRegisterScreenState();
}

class _MobileScannerRegisterScreenState extends State<MobileScannerRegisterScreen> {
  final MobileScannerController controller = MobileScannerController(
    // Optional parameters;
    detectionSpeed: DetectionSpeed.noDuplicates,
    returnImage: true,
  );
  StreamSubscription<Object?>? _subscription;
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  final String _authenticationMessage = "Please authenticate yourself";
  final ApiClient _apiClient = ApiClient();
  final Util _util = Util();

  // Variable to hold the scanned data
  String? _scannedData;

  void switchToApprovalRegister(
      String scannedData, String message, String username) {
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
                  builder: (context) => ApprovalRegister(
                      scannedData: scannedData, username: username)));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  setState(() async {
                    _scannedData = barcodes.first.rawValue;
                    switchToApprovalRegister(
                        _scannedData!,
                        "Notification: Scanning QRCode success!",
                        widget.username!);
                  });
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.flash_on),
        onPressed: () => controller.toggleTorch(),
      ),
    );
  }
}
