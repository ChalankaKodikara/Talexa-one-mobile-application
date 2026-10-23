import 'package:corehris/auth/authservices.dart';
import 'package:corehris/modules/HRMS/main_screens/facilities/claim_model.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClaimListController extends GetxController {
  final AuthService service = Get.put(AuthService());

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  /// Parsed model list (for main list UI)
  final RxList<EmployeeClaim> claims = <EmployeeClaim>[].obs;

  /// Raw response (for popup details)
  final RxList<Map<String, dynamic>> claimsRaw = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadClaims();
  }

  Future<void> loadClaims() async {
    try {
      isLoading.value = true;
      error.value = '';

      final prefs = await SharedPreferences.getInstance();
      final employeeNo = prefs.getString('username') ?? '';

      final res = await service.claims.fetchClaimsByEmployee(employeeNo);

      // ✅ Store raw JSON for popup view
      claimsRaw.value = List<Map<String, dynamic>>.from(res);

      // ✅ Store parsed list for main UI
      claims.value =
          res.map<EmployeeClaim>((e) => EmployeeClaim.fromJson(e)).toList();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refresh() => loadClaims();
}
