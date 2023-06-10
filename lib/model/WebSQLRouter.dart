class WebSQLRouter {
  String? action = "";
  Map<String, dynamic>? jsonData = {};
  String? routerId = "";

  WebSQLRouter(this.action, this.jsonData, this.routerId);

  @override
  String toString() {
    return 'WebSQLRouter{action: $action, jsonData: $jsonData, routerId: $routerId}';
  }
}
