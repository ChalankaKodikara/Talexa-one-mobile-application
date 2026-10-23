import 'package:corehris/modules/HRMS/main_screens/noticeboard/model/notice.dart';
import 'package:get/get.dart';
import 'package:corehris/auth/authservices.dart';

class NoticeBoardController extends GetxController {
  final notices = <Notice>[].obs;
  final isLoading = false.obs;

  final AuthService _authService = Get.put<AuthService>(AuthService());

  @override
  void onInit() {
    super.onInit();
    fetchNotices();
  }

  Future<void> fetchNotices() async {
    try {
      isLoading(true);
      final res = await _authService.notice.fetchNotices();

      notices.assignAll(
        res.map((j) => Notice.fromJson(j)).toList(),
      );
    } catch (e) {
      print("Error fetching notices: $e");
    } finally {
      isLoading(false);
    }
  }
}
