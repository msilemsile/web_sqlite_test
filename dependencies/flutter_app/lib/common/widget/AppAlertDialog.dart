import 'package:flutter/widgets.dart';
import 'package:flutter_app/common/widget/AppDialog.dart';
import 'package:flutter_app/common/widget/KeyboardPaddingWidget.dart';
import 'package:flutter_app/common/widget/SpaceWidget.dart';
import 'package:flutter_app/theme/res/ColorsRes.dart';

import '../../theme/ThemeProvider.dart';
import '../../theme/res/ColorsKey.dart';
import '../../theme/res/ShapeRes.dart';

typedef OnAlertDialogCallback = void Function(AppAlertDialog alertDialog);

class AppAlertDialog {

  String _title = "";
  String _content = "";
  String _cancelTxt = "";
  String _confirmTxt = "确定";
  String _extendActionTxt = "";
  OnAlertDialogCallback? _cancelCallback;
  OnAlertDialogCallback? _confirmCallback;
  OnAlertDialogCallback? _extendActionCallback;
  bool _canTouchClose = false;
  bool _canBackClose = false;
  Widget? _contentWidget;
  bool _autoClickButtonDismiss = true;
  late BuildContext _buildContext;
  bool _needHandleKeyboard = false;

  AppAlertDialog setTitle(String value) {
    _title = value;
    return this;
  }

  AppAlertDialog setContent(String value) {
    _content = value;
    return this;
  }

  AppAlertDialog setConfirmTxt(String value) {
    _confirmTxt = value;
    return this;
  }

  AppAlertDialog setCancelTxt(String value) {
    _cancelTxt = value;
    return this;
  }

  AppAlertDialog setExtendActionTxt(String value) {
    _extendActionTxt = value;
    return this;
  }

  AppAlertDialog setExtendActionCallback(OnAlertDialogCallback value) {
    _extendActionCallback = value;
    return this;
  }

  AppAlertDialog setCancelCallback(OnAlertDialogCallback value) {
    _cancelCallback = value;
    return this;
  }

  AppAlertDialog setConfirmCallback(OnAlertDialogCallback value) {
    _confirmCallback = value;
    return this;
  }

  AppAlertDialog setContentWidget(Widget widget) {
    _contentWidget = widget;
    return this;
  }

  AppAlertDialog setCanBackClose(bool value) {
    _canBackClose = value;
    return this;
  }

  AppAlertDialog setCanTouchClose(bool value) {
    _canTouchClose = value;
    return this;
  }

  AppAlertDialog setAutoClickButtonDismiss(bool value) {
    _autoClickButtonDismiss = value;
    return this;
  }

  AppAlertDialog setNeedHandleKeyboard(bool value) {
    _needHandleKeyboard = value;
    return this;
  }

  AppAlertDialog._();

  late AppDialog _appDialog;

  static AppAlertDialog builder() {
    AppAlertDialog appAlertDialog = AppAlertDialog._();
    appAlertDialog._appDialog = AppDialog();
    return appAlertDialog;
  }

  void show(BuildContext context) {
    _buildContext = context;
    _appDialog.show(context, buildAppAlertDialogWidget(context), _canTouchClose,
        _canBackClose);
  }

  void dismiss() {
    _appDialog.dismiss(_buildContext);
  }

  Widget buildAppAlertDialogWidget(BuildContext context) {
    Widget child = Padding(
        padding: const EdgeInsets.fromLTRB(35, 0, 35, 0),
        child: RectangleShape(
          solidColor: ThemeProvider.getColor(context, ColorsKey.bgLightMode),
          stokeColor: ThemeProvider.getColor(context, ColorsKey.lineColor),
          cornerAll: 10,
          stokeWidth: 0.5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SpaceWidget.createHeightSpace(12),
              Visibility(
                visible: _title.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              _contentWidget ?? Visibility(
                visible: _content.isNotEmpty,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _content,
                    style:
                    const TextStyle(color: Color(ColorsRes.color_6f6f6f)),
                  ),
                ),
              ),
              SpaceWidget.createHeightSpace(16),
              SpaceWidget.createHeightSpace(0.5,
                  spaceColor:
                  ThemeProvider.getColor(context, ColorsKey.lineColor)),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: buildBottomWidget(context),
              )
            ],
          ),
        ));
    return _needHandleKeyboard ? KeyboardPaddingWidget(child: child) : child;
  }

  Widget buildBottomWidget(BuildContext context) {
    if (_confirmTxt.isEmpty) {
      _confirmTxt = "确定";
    }
    return Row(
      children: [
        Visibility(
            visible: _cancelTxt.isNotEmpty,
            child: Expanded(child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Text(_cancelTxt),
              ),
              onTap: () {
                if (_autoClickButtonDismiss) {
                  dismiss();
                }
                _cancelCallback?.call(this);
              },
            ))),
        Visibility(
            visible: _cancelTxt.isNotEmpty,
            child: SpaceWidget.createWidthSpace(0.5,
                spaceColor: ThemeProvider.getColor(
                    context, ColorsKey.lineColor))),
        Visibility(
            visible: _extendActionTxt.isNotEmpty,
            child: Expanded(child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              child: Center(
                child: Text(_extendActionTxt),
              ),
              onTap: () {
                if (_autoClickButtonDismiss) {
                  dismiss();
                }
                _extendActionCallback?.call(this);
              },
            ))),
        Visibility(
            visible: _extendActionTxt.isNotEmpty,
            child: SpaceWidget.createWidthSpace(0.5,
                spaceColor: ThemeProvider.getColor(
                    context, ColorsKey.lineColor))),
        Expanded(child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Text(_confirmTxt,
              style: const TextStyle(
                  color: Color(ColorsRes.color_1E90FF)
              ),),
          ),
          onTap: () {
            if (_autoClickButtonDismiss) {
              dismiss();
            }
            _confirmCallback?.call(this);
          },
        ))
      ],
    );
  }

}
