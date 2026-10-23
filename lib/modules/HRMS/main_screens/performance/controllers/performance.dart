import 'package:corehris/auth/authservices.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:corehris/utils/app_alert.dart';

class PerformanceItem {
  final int id;
  final String title;
  int score;

  PerformanceItem({required this.id, required this.title, this.score = 0});
}

class SubmittedPerformance {
  final int id;
  final String month;
  final String submittedDate;
  final List<Map<String, dynamic>> criteria;

  SubmittedPerformance({
    required this.id,
    required this.month,
    required this.submittedDate,
    required this.criteria,
  });
}

class PerformanceController extends GetxController {
  var username = ''.obs;
  var employeeId = ''.obs;

  final AuthService authService = AuthService();

  var isLoading = false.obs;
  var activeTab = 'pending'.obs;

  var performanceData = <PerformanceItem>[].obs;
  var submittedPerformances = <SubmittedPerformance>[].obs;
  var employeeInfo = {}.obs;

  @override
  void onInit() {
    super.onInit();
    getEmployeeCodeFromCache();
  }

  /// ✅ Get employee info from local cache then trigger fetch
  Future<void> getEmployeeCodeFromCache() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      username.value = prefs.getString('username') ?? '';
      employeeId.value = prefs.getString('username') ?? '';

      if (employeeId.isNotEmpty) {
        await fetchPerformanceData();
        await loadSubmittedPerformancesFromApi(employeeId.value, "april 2025");
      } else {
        AppAlert.toast(
          title: "Error",
          message: "No employee ID found in cache",
        );
      }
    } catch (e) {
      AppAlert.toast(
        title: "Error",
        message: "Failed to load user info from cache",
      );
    }
  }

  Future<void> fetchPerformanceData() async {
    try {
      isLoading(true);

      final response = await authService.performance
          .getPerformanceHistory(employeeId.value, "april 2025");

      if (response['success'] == true) {
        employeeInfo.value = response['employee'] ?? {};

        final criteriaList = response['criteria'] as List;

        performanceData.value = criteriaList.map((e) {
          return PerformanceItem(
            id: e['criteria_id'] ?? DateTime.now().millisecondsSinceEpoch,
            title: e['criteria_name'] ?? 'Unnamed',
            score: e['score'] ?? 0,
          );
        }).toList();
      } else {
        AppAlert.toast(
          title: "Error",
          message: "Failed to fetch criteria for pending sheet",
        );
      }
    } catch (e) {
      print("Error fetching performance data: $e");
      AppAlert.toast(
        title: "Error",
        message: "Could not load pending sheet criteria",
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> loadSubmittedPerformancesFromApi(
      String employeeId, String date) async {
    try {
      isLoading(true);

      final response =
          await authService.performance.getPerformanceHistory(employeeId, date);

      if (response['success'] == true) {
        final criteriaList = response['criteria'] as List;

        List<Map<String, dynamic>> criteria = criteriaList.map((e) {
          return {
            'title': e['criteria_name'] ?? 'Unnamed',
            'score': e['score'] ?? 0,
          };
        }).toList();

        submittedPerformances.value = [
          SubmittedPerformance(
            id: DateTime.now().millisecondsSinceEpoch,
            month: "2025 January",
            submittedDate: "2025.01.04",
            criteria: criteria,
          )
        ];
      } else {
        AppAlert.toast(
          title: "Error",
          message: "Performance history fetch unsuccessful",
        );
      }
    } catch (e) {
      print("Error loading submitted performance: $e");
      AppAlert.toast(
        title: "Error",
        message: "Failed to fetch performance history",
      );
    } finally {
      isLoading(false);
    }
  }

  void incrementScore(int index) {
    if (performanceData[index].score < 5) {
      performanceData[index].score++;
      performanceData.refresh();
    }
  }

  void decrementScore(int index) {
    if (performanceData[index].score > 0) {
      performanceData[index].score--;
      performanceData.refresh();
    }
  }

  /// ✅ Submit to Backend API
  Future<void> submitPerformanceToBackend() async {
    final empId = employeeId.value;

    final criteriaUpdates = performanceData.map((item) {
      return {
        "criteria_id": item.id,
        "score": item.score,
      };
    }).toList();

    try {
      isLoading(true);
      final result = await authService.performance
          .updatePerformanceScore(empId, criteriaUpdates);

      if (result['success'] == true) {
        AppAlert.toast(
          title: "Success",
          message: "Performance submitted successfully",
        );
      } else {
        AppAlert.toast(
          title: "Failed",
          message: result['message'] ?? "Submission failed",
        );
      }
    } catch (e) {
      print("Error submitting performance: $e");
      AppAlert.toast(
        title: "Error",
        message: "Could not submit performance",
      );
    } finally {
      isLoading(false);
    }
  }

  void deleteSubmittedPerformance(int id) {
    submittedPerformances.removeWhere((item) => item.id == id);
    AppAlert.toast(
      title: "Deleted",
      message: "Performance has been deleted",
    );
  }
}
