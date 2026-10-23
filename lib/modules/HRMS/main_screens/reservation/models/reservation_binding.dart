import 'package:corehris/modules/HRMS/main_screens/reservation/controllers/reservation_con.dart';
import 'package:get/get.dart';

class ReservationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReservationController>(() => ReservationController());
  }
}
