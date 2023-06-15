class HostInfo {
  String platform = "";
  String host = "";
  bool _isLocalHost = false;

  HostInfo(this.host, this.platform);

  setIsLocalHost(bool isLocalHost) {
    _isLocalHost = isLocalHost;
  }

  bool isLocalHost() {
    return _isLocalHost;
  }

  @override
  String toString() {
    return 'HostInfo{platform: $platform, host: $host';
  }

  String getPlatformIcon() {
    String icon = "images/icon_pc.png";
    switch (platform) {
      case "ios":
        icon = "images/icon_apple.png";
        break;
      case "android":
        icon = "images/icon_android.png";
        break;
    }
    return icon;
  }
}
