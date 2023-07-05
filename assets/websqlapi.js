///路由协议格式
///websql://host?action=xxx&routerId=xxx&dataKey=dataValue
///其中dataValue需要url encode

function execSQL(routerId,dbName,sql,params){
    try {
        const jsonDataParamsMap = new Map().set("dbName",dbName)
                                .set("sql",sql)
                                .set("sqlParams",params);
        window.websql.postMessage(buildWebSQLRoute(routerId,'execSQL',jsonDataParamsMap));
    } catch(e) {
        showAlert('执行sql失败');
    }
}

//js回调函数（客户端回调）
function onWebSQLCallback(routerResult,routerId){
    routerResult = Base64.decode(routerResult);
    console.log("onWebSQLCallback: routerId "+routerId +"\n"+"routerResult: "+routerResult);
    showAlert("routerId =  "+routerId +"\n"+"routerResult = "+routerResult)
}

function buildWebSQLRoute(routerId,actionParamsName,jsonDataParamsMap){
    const routerSchema = "websql://"
    const routerHost = "host"
    const routerAction = "action="
    const routerIdConst = "routerId="
    var webSQLRouter = routerSchema + routerHost + "?"
    + routerAction + actionParamsName + "&"
    + routerIdConst + routerId;
    for (var [key, value] of jsonDataParamsMap) {
        console.log(key + ' = ' + value);
        webSQLRouter = webSQLRouter + "&" + key + "=" + encodeURIComponent(value);
    }
    return webSQLRouter;
}

function showAlert(msg) {
    setTimeout(function () {
        alert(msg)
    }, 100)
}