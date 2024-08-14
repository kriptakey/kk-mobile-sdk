import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio();

  Future<Map<String, dynamic>> startServerAuthentication(
      Map<String, dynamic>? serverAuthenticationData) async {
    try {
      Response response = await _dio.post(
          'http://10.21.0.6:3000/mobile/startServerAuthentication',
          data: serverAuthenticationData,
          options: Options(headers: {
            'content-type': 'application/json',
            'Access-Control-Allow-Origin':
                'http://10.21.0.6:3000/mobile/startServerAuthentication',
          }));
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> getWrappedClientKey(
      Map<String, dynamic>? getWrappedClientKeyPayload) async {
    try {
      Response response =
          await _dio.post('http://10.21.0.6:3000/mobile/getWrappedClientKey',
              data: getWrappedClientKeyPayload,
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.21.0.6:3000/mobile/getWrappedClientKey',
              }));
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> preAuthentication() async {
    try {
      Response response = await _dio.get(
        'http://10.21.0.6:3000/mobile/preAuthentication',
      );
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> registerUserWithPassword(
      Map<String, dynamic>? userData) async {
    // Implement user registration
    try {
      Response response =
          await _dio.post('http://10.2.10.6:3000/mobile/registerWithPassword',
              data: userData,
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.21.0.6:3000/mobile/registerWithPassword',
              }));
      // Return the successful json object
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> loginWithPassword(
      Map<String, dynamic>? userData) async {
    // Implement user registration
    try {
      Response response =
          await _dio.post('http://10.21.0.6:3000/mobile/loginWithPassword',
              data: userData,
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.21.0.6:3000/mobile/loginWithPassword',
              }));
      // Return the successful json object
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> activateDevice(
      Map<String, dynamic>? userData) async {
    // Implement user registration
    try {
      Response response =
          await _dio.post('http://10.21.0.6:3000/mobile/activateDevice',
              data: userData,
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.21.0.6:3000/mobile/activateDevice',
              }));
      // Return the successful json object
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> authenticateUserAndDevice(
      Map<String, dynamic>? userData) async {
    // Implement user registration
    try {
      Response response = await _dio.post(
          'http://10.21.0.6:3000/mobile/authenticateUserAndDevice',
          data: userData,
          options: Options(headers: {
            'content-type': 'application/json',
            'Access-Control-Allow-Origin':
                'http://10.21.0.6:3000/mobile/authenticateUserAndDevice',
          }));
      // Return the successful json object
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> logout() async {
    // Implement user logout
    try {
      Response response = await _dio.get(
        'http://10.21.0.6:3000/mobile/logout',
      );
      return response.data;
    } on DioException catch (e) {
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> certificateSigning(
      Map<String, dynamic>? certificateRequestData) async {
    try {
      Response response =
          await _dio.post('http://10.21.0.6:3000/mobile/certSign',
              data: certificateRequestData,
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.21.0.6:3000/mobile/certSign',
              }));
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> udpateUserAccount(
      Map<String, dynamic>? userData) async {
    // Implement user account completion
    try {
      Response response =
          await _dio.post('http://10.21.0.6:3000/mobile/updateAccount',
              data: userData, //Request body
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.21.0.6:3000/mobile/updateAccount',
              }));
      // Return the successful json object
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> getUserData(
      Map<String, dynamic>? userData) async {
    // Query user data
    try {
      Response response =
          await _dio.post('http://10.21.0.6:3000/mobile/getUserData',
              data: userData, //Request body
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.21.0.6:3000/mobile/getUserData',
              }));
      // Return the successful json object
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  Future<Map<String, dynamic>> unregisterDevice(
      Map<String, dynamic>? userData) async {
    // Query user data
    try {
      Response response =
          await _dio.post('http://10.21.0.6:3000/mobile/unregisterDevice',
              data: userData, //Request body
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.21.0.6:30000/mobile/unregisterDevice',
              }));
      // Return the successful json object
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }
}
