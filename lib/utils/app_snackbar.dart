import 'package:corehris/utils/app_alert.dart';

class AppSnackbar {
  static void error(String message, {String title = 'Error'}) => AppAlert.toast(
        title: title,
        message: message,
        type: AppAlertType.error,
      );

  static void success(String title, String message) => AppAlert.toast(
        title: title,
        message: message,
        type: AppAlertType.success,
      );

  static void warning(String title, String message) => AppAlert.toast(
        title: title,
        message: message,
        type: AppAlertType.warning,
      );

  static void info(String title, String message) => AppAlert.toast(
        title: title,
        message: message,
        type: AppAlertType.info,
      );
}
