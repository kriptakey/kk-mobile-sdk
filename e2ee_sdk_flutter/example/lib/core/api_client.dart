import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio();

  /// Download wrapped client key from backend server.
  /// Adjust endpoint destination by changing the following IP address and port
  Future<Map<String, dynamic>> getWrappedClientKey(
      Map<String, dynamic>? getWrappedClientKeyPayload) async {
    try {
      Response response =
          await _dio.post('http://10.30.0.8:3000/mobile/getWrappedClientKey',
              data: getWrappedClientKeyPayload,
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.30.0.8:3000/mobile/getWrappedClientKey',
              }));
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  /// Authenticate backend server everytime application launched for the first time.
  /// Adjust endpoint destination by changing the following IP address and port
  Future<Map<String, dynamic>> startServerAuthentication(
      Map<String, dynamic>? serverAuthenticationData) async {
    try {
      Response response = await _dio.post(
          'http://10.30.0.8:3000/mobile/startServerAuthentication',
          data: serverAuthenticationData,
          options: Options(headers: {
            'content-type': 'application/json',
            'Access-Control-Allow-Origin':
                'http://10.30.0.8:3000/mobile/startServerAuthentication',
          }));
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  /// Call API /preAuthenticate to download server public key, oaep label, and e2ee session id.
  /// The response's entities are used to encrypt user password or data in mobile side.
  /// Adjust endpoint destination by changing the following IP address and port
  Future<Map<String, dynamic>> preAuthentication() async {
    try {
      Response response = await _dio.get(
        'http://10.30.0.8:3000/mobile/preAuthentication',
      );
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  /// Call API /registerWithPassword to register user for the first time by using user based password.
  /// Adjust endpoint destination by changing the following IP address and port
  Future<Map<String, dynamic>> registerUserWithPassword(
      Map<String, dynamic>? userData) async {
    // Implement user registration
    try {
      Response response =
          await _dio.post('http://10.30.0.8:3000/mobile/registerWithPassword',
              data: userData,
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.30.0.8:3000/mobile/registerWithPassword',
              }));
      // Return the successful json object
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  /// Call API /updateAccount to update user data and store the encrypted data in database.
  /// Adjust endpoint destination by changing the following IP address and port
  Future<Map<String, dynamic>> updateUserAccount(
      Map<String, dynamic>? userData) async {
    // Implement user account completion
    try {
      Response response =
          await _dio.post('http://10.30.0.8:3000/mobile/updateAccount',
              data: userData, //Request body
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.30.0.8:3000/mobile/updateAccount',
              }));
      // Return the successful json object
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  /// Call API /loginWithPassword to authenticate user that has been registered previously.
  /// Adjust endpoint destination by changing the following IP address and port
  Future<Map<String, dynamic>> loginWithPassword(
      Map<String, dynamic>? userData) async {
    // Implement user registration
    try {
      Response response =
          await _dio.post('http://10.30.0.8:3000/mobile/loginWithPassword',
              data: userData,
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.30.0.8:3000/mobile/loginWithPassword',
              }));
      // Return the successful json object
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  /// Call API /getUserData to retrieve user data from backend server.
  /// Adjust endpoint destination by changing the following IP address and port
  Future<Map<String, dynamic>> getUserData(
      Map<String, dynamic>? userData) async {
    // Query user data
    try {
      Response response =
          await _dio.post('http://10.30.0.8:3000/mobile/getUserData',
              data: userData, //Request body
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.30.0.8:3000/mobile/getUserData',
              }));
      // Return the successful json object
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }

  /// Call API /certSign to request mobile CSR to be signed by KMS server.
  /// Adjust endpoint destination by changing the following IP address and port
  Future<Map<String, dynamic>> certificateSigning(
      Map<String, dynamic>? certificateRequestData) async {
    try {
      Response response =
          await _dio.post('http://10.30.0.8:3000/mobile/certSign',
              data: certificateRequestData,
              options: Options(headers: {
                'content-type': 'application/json',
                'Access-Control-Allow-Origin':
                    'http://10.30.0.8:3000/mobile/certSign',
              }));
      return response.data;
    } on DioException catch (e) {
      // Return the error object if any
      return e.response!.data;
    }
  }
}
