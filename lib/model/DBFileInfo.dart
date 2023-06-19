class DBFileInfo {
  String dbFileName = "";
  String dbFilePath = "";

  DBFileInfo(this.dbFileName, this.dbFilePath);

  DBFileInfo.fromJson(Map<String, dynamic> json) {
    dbFileName = json['dbFileName'];
    dbFilePath = json['dbFilePath'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};
    data['dbFileName'] = dbFileName;
    data['dbFilePath'] = dbFilePath;
    return data;
  }
}
