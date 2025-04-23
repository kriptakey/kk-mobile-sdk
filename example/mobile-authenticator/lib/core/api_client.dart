import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart';

class ApiClient {
  final Dio _dio = Dio();

  Future<Dio> createDioWithSelfSignedCert() async {
    // Load the self-signed cert from assets
    final sslCert = await rootBundle.load('assets/keycloak-server.pem');

    // Create a custom SecurityContext
    SecurityContext context = SecurityContext(withTrustedRoots: false);
    context.setTrustedCertificatesBytes(sslCert.buffer.asUint8List());

    // Use the custom context in HttpClient
    final httpClient = HttpClient(context: context);

    // Hook HttpClient into Dio
    final adapter = DefaultHttpClientAdapter();
    adapter.onHttpClientCreate = (_) => httpClient;

    final dio = Dio();
    // dio.httpClientAdapter = adapter;

    // Custom adapter to override cert validation
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        // 🔥 This skips ALL certificate validation, including IP/domain mismatch
        return true;
      };
      return client;
    };

    return dio;
  }

  Future<Map<String, dynamic>> processQR(
      Map<String, dynamic>? certificateRequestData) async {
    try {
      print("Inside processQR API");
      print("Certificate request data: ${jsonEncode(certificateRequestData)}");
      final dio = await createDioWithSelfSignedCert();
      Response response = await dio.post(
          'https://103.129.16.48:8443/realms/quickstart/kki-e2ee-qrcode-res/process',
          data: {"username": certificateRequestData!['username'], "sessionMetadata": certificateRequestData!['sessionMetadata']},
          options: Options(headers: {
            'content-type': 'application/json',
            'Access-Control-Allow-Origin':
                'https://103.129.16.48:8443/realms/quickstart/kki-e2ee-qrcode-res/process',
          }));
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      print(e.stackTrace.toString());
      // return e.response!.data;
      rethrow;
    }
  }
}
