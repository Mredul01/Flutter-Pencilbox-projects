import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
String getFormattedDateTime(num dt, String pattern) {
  return DateFormat(pattern).format(DateTime.fromMillisecondsSinceEpoch(dt.toInt() * 1000));
}
showMsg(BuildContext context,String msg){
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
void showMsgWithAction(
    {
      required BuildContext context,
      required String msg,
      required VoidCallback callback}) {
  ScaffoldMessenger.of(context)
      .showSnackBar(
      SnackBar(
        duration: const Duration(days: 365),
        content: Text(msg),
        action: SnackBarAction(
          label: 'Go to Settings',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            callback();
          },
        ),
      ));
}