import 'dart:io';
import 'package:uuid/uuid.dart';

class DeviceInfo {
  String platform = Platform.operatingSystem;
  String version = Platform.version;
  String localHostname = Platform.localHostname;
  String uuid = const Uuid().v5(Uuid.NAMESPACE_URL, "http://www.example.com");
}
