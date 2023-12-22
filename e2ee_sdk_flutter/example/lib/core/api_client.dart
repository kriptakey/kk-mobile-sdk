import 'package:dio/dio.dart';

class ApiClient {
  final Dio _dio = Dio();

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

  // Future<Map<String, dynamic>> logout() async {
  //   // Query user data
  //   final serverUrl = cacheParameter.getServerIpAddress();
  //   final serverPort = cacheParameter.getServerPort();
  //   // Implement user logout
  //   try {
  //     Response response = await _dio.get(
  //       'http://$serverUrl:$serverPort/mobile/logout',
  //     );
  //     return response.data;
  //   } on DioException catch (e) {
  //     return e.response!.data;
  //   }
  // }

  // Future<Map<String, dynamic>> verifyOtp(
  //     Map<String, dynamic>? verifyOtpData, String deviceId) async {
  //   final serverUrl = cacheParameter.getServerIpAddress();
  //   final serverPort = cacheParameter.getServerPort();

  //   try {
  //     Response response =
  //         await _dio.post('http://$serverUrl:$serverPort/mobile/verifyOtp',
  //             data: verifyOtpData,
  //             options: Options(headers: {
  //               'content-type': 'application/json',
  //               'Access-Control-Allow-Origin':
  //                   'http://$serverUrl:$serverPort/mobile/verifyOtp',
  //               'device_id': deviceId,
  //             }));
  //     return response.data;
  //   } on DioException catch (e) {
  //     // Return the error object if any
  //     return e.response!.data;
  //   }
  // }

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

  // Future<Map<String, dynamic>> registerUser(
  //     Map<String, dynamic>? userData, String deviceId) async {
  //   // Implement user registration
  //   final serverUrl = cacheParameter.getServerIpAddress();
  //   final serverPort = cacheParameter.getServerPort();
  //   try {
  //     Response response =
  //         await _dio.post('http://$serverUrl:$serverPort/mobile/auth/register',
  //             data: userData,
  //             options: Options(headers: {
  //               'content-type': 'application/json',
  //               'Access-Control-Allow-Origin':
  //                   'http://$serverUrl:$serverPort/mobile/auth/register',
  //               'device_id': deviceId,
  //             }));
  //     // Return the successful json object
  //     return response.data;
  //   } on DioException catch (e) {
  //     // Return the error object if any
  //     return e.response!.data;
  //   }
  // }

  // Future<Map<String, dynamic>> login(Map<String, dynamic>? loginData) async {
  //   // Implement user login
  //   final serverUrl = cacheParameter.getServerIpAddress();
  //   final serverPort = cacheParameter.getServerPort();
  //   try {
  //     Response response =
  //         await _dio.post('http://$serverUrl:$serverPort/mobile/auth/login',
  //             data: loginData,
  //             options: Options(headers: {
  //               'content-type': 'application/json',
  //               'Access-Control-Allow-Origin':
  //                   'http://$serverUrl:$serverPort/mobile/auth/login',
  //             }));
  //     return response.data;
  //   } on DioException catch (e) {
  //     // Return the error object if any
  //     return e.response!.data;
  //   }
  // }
}