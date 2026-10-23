import 'package:get/get.dart';
import 'package:corehris/auth/authservices.dart';

class HolidayController extends GetxController {
  final holidays = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  final AuthService _authService = Get.put<AuthService>(AuthService());

  @override
  void onInit() {
    super.onInit();
    fetchHolidays();
  }

  Future<void> fetchHolidays() async {
    try {
      isLoading(true);
      final res = await _authService.holidays.fetchHolidays();
      holidays.assignAll(res);
    } catch (e) {
      print("Error fetching holidays: $e");
    } finally {
      isLoading(false);
    }
  }
}
