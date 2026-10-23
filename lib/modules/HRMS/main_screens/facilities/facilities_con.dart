import 'package:corehris/components/facilities_card/claimtypes/claimtypes.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/auth/authservices.dart';

class FacilitiesController extends GetxController {
  final AuthService authService = Get.put(AuthService());

  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString memberNo = ''.obs;

  final RxList<ClaimType> claimTypes = <ClaimType>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadFacilities();
  }

  Future<void> loadFacilities() async {
    try {
      isLoading.value = true;
      error.value = '';

      final prefs = await SharedPreferences.getInstance();
      memberNo.value = prefs.getString('username') ?? '';

      final res = await authService.claims.fetchClaimTypes(memberNo.value);

      claimTypes.value = res
          .map((e) => ClaimType.fromJson(e))
          .where((e) => e.isActive)
          .toList();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshAll() => loadFacilities();
}
