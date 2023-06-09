class HostInfo {
  String platform = "";
  String host = "";
  String post = "";

  HostInfo(this.platform, this.host, this.post);

  @override
  String toString() {
    return 'HostInfo{platform: $platform, host: $host, post: $post}';
  }
}
