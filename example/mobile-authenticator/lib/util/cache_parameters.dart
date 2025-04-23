class CacheParameters {
  static final CacheParameters _instance = CacheParameters._internal();

  factory CacheParameters() {
    return _instance;
  }

  CacheParameters._internal();

  late String serverIpAddress;
  late String serverPort;
  bool isDeviceBinding = false;

  void setServerIpAdress(String serverIpAddress) {
    this.serverIpAddress = serverIpAddress;
  }

  void setServerPort(String serverPort) {
    this.serverPort = serverPort;
  }

  void setDeviceBinding(bool isDeviceBinding) {
    this.isDeviceBinding = isDeviceBinding;
  }

  String getServerIpAddress() {
    return serverIpAddress;
  }

  String getServerPort() {
    return serverPort;
  }

  bool getDeviceBindingFlag() {
    return isDeviceBinding;
  }
}
