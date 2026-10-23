import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class AppLifecycleController extends GetxController
    with WidgetsBindingObserver {
  RxBool isForeground = true.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    isForeground.value = state == AppLifecycleState.resumed;
  }
}
