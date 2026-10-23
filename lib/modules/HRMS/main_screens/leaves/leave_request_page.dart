import 'package:corehris/modules/HRMS/main_screens/leaves/controller_/leave_req_con.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Talexa leave request page — shares the minimalist Settings/Drawer language.
/// All data mutations and API calls are delegated to LeaveRequestController.
class LeaveRequestPage extends StatefulWidget {
  const LeaveRequestPage({super.key, required this.selectedDates});
  final List<Map<String, dynamic>> selectedDates;

  @override
  State<LeaveRequestPage> createState() => _LeaveRequestPageState();
}

class _LeaveRequestPageState extends State<LeaveRequestPage> {
  static const _blue = Color(0xFF1769E8);
  static const _navy = Color(0xFF182237);
  static const _muted = Color(0xFF89919D);
  late final LeaveRequestController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<LeaveRequestController>()
        ? Get.find<LeaveRequestController>()
        : Get.put(LeaveRequestController());
    controller.initializeRequestedDates(widget.selectedDates);
  }

  bool get _dark => Theme.of(context).brightness == Brightness.dark;
  Color get _bg => _dark ? const Color(0xFF101623) : const Color(0xFFF5F6F8);
  Color get _surface => _dark ? const Color(0xFF1B2638) : Colors.white;
  Color get _ink => _dark ? Colors.white : _navy;
  Color get _secondary => _dark ? Colors.white60 : _muted;
  Color get _line => _dark ? Colors.white12 : const Color(0xFFECEFF3);
  Color get _inputBg =>
      _dark ? const Color(0xFF222F42) : const Color(0xFFF8FAFD);

  Widget _heading(String title, String description) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: _ink)),
          const SizedBox(height: 4),
          Text(description,
              style: TextStyle(fontSize: 12, height: 1.4, color: _secondary)),
        ]),
      );

  Widget _panel({required Widget child, EdgeInsets? padding}) => Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _surface, borderRadius: BorderRadius.circular(20)),
        child: child,
      );

  Widget _selectedDatesPanel() => _panel(
        child: Column(children: [
          for (int i = 0; i < controller.requestedDates.length; i++) ...[
            if (i > 0) Divider(height: 23, color: _line, thickness: 1),
            Builder(builder: (context) {
              final date = controller.requestedDates[i];
              final half =
                  date['is_half_day'] == 1 || date['is_half_day'] == '1';
              final day =
                  (date['request_day'] ?? date['date'] ?? '-').toString();
              final type = (date['leave_type'] ?? '').toString();
              return Row(children: [
                Icon(Icons.calendar_today_outlined, color: _blue, size: 21),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(day,
                          style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: _ink)),
                      const SizedBox(height: 4),
                      Text(
                          [
                            half ? 'Half day' : 'Full day',
                            if (type.isNotEmpty) type
                          ].join(' • '),
                          style: TextStyle(fontSize: 11.5, color: _secondary)),
                    ])),
                Icon(Icons.check_circle_rounded, size: 19, color: _blue),
              ]);
            }),
          ],
          if (controller.requestedDates.isEmpty)
            Text('No dates selected', style: TextStyle(color: _secondary)),
        ]),
      );

  Widget _employeeSearch() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Search employee',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600, color: _ink)),
        const SizedBox(height: 9),
        TextField(
          onChanged: controller.onSearchChanged,
          style: TextStyle(color: _ink, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Name, employee number or designation',
            hintStyle: TextStyle(color: _secondary, fontSize: 12.5),
            prefixIcon: Icon(Icons.search_rounded, size: 20, color: _secondary),
            filled: true,
            fillColor: _inputBg,
            border: _outline(),
            enabledBorder: _outline(),
            focusedBorder: _outline(active: true),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
          ),
        ),
        Obx(() {
          if (controller.searchQuery.value.trim().length < 2)
            return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(top: 12),
            constraints: const BoxConstraints(maxHeight: 240),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _line),
              color: _inputBg,
            ),
            child: controller.isSearchingEmployees.value
                ? const Padding(
                    padding: EdgeInsets.all(22),
                    child: Center(
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _blue)))
                : controller.searchResults.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(17),
                        child: Text('No employees found',
                            style: TextStyle(color: _secondary)))
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: controller.searchResults.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: _line),
                        itemBuilder: (context, index) {
                          final employee = controller.searchResults[index];
                          final name =
                              (employee['employee_fullname'] ?? 'Employee')
                                  .toString();
                          final number =
                              (employee['employee_no'] ?? '-').toString();
                          return ListTile(
                            dense: true,
                            title: Text(name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: _ink,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '$number • ${employee['designation_name'] ?? ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: _secondary, fontSize: 11.5)),
                            trailing: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: _blue,
                                size: 21),
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              controller.addCoveringEmployee(employee);
                            },
                          );
                        },
                      ),
          );
        }),
      ]);

  OutlineInputBorder _outline({bool active = false}) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            BorderSide(color: active ? _blue : _line, width: active ? 1.5 : 1),
      );

  Future<void> _pickTime(String employeeNo, {required bool start}) async {
    final value =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (!mounted || value == null) return;
    controller.setTime(employeeNo, isStart: start, time: value.format(context));
  }

  Widget _timeButton(String label, VoidCallback callback) => Expanded(
        child: Material(
          color: _inputBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: callback,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 13),
              decoration: BoxDecoration(
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(12)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.access_time_rounded, size: 16, color: _blue),
                const SizedBox(width: 6),
                Flexible(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _ink))),
              ]),
            ),
          ),
        ),
      );

  Widget _coveringEmployees() => Obx(() {
        final employees = controller.selectedCoveringEmployees;
        if (employees.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 17),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 17, color: _secondary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('No covering employees selected',
                      style: TextStyle(fontSize: 12, color: _secondary))),
            ]),
          );
        }
        return Column(children: [
          const SizedBox(height: 16),
          for (int i = 0; i < employees.length; i++) ...[
            Divider(height: 18, color: _line),
            Builder(builder: (context) {
              final employee = employees[i];
              final id = (employee['employee_no'] ?? '').toString();
              final name =
                  (employee['employee_fullname'] ?? 'Employee').toString();
              return Column(children: [
                Row(children: [
                  const Icon(Icons.person_outline_rounded,
                      color: _blue, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text('$id • ${employee['designation_name'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(color: _secondary, fontSize: 11.5)),
                      ])),
                  IconButton(
                    tooltip: 'Remove employee',
                    onPressed: () => controller.removeCoveringEmployee(id),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFFD64550), size: 19),
                  ),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  _timeButton(
                      (employee['start_time'] ?? '').toString().isEmpty
                          ? 'Start time'
                          : employee['start_time'].toString(),
                      () => _pickTime(id, start: true)),
                  const SizedBox(width: 10),
                  _timeButton(
                      (employee['end_time'] ?? '').toString().isEmpty
                          ? 'End time'
                          : employee['end_time'].toString(),
                      () => _pickTime(id, start: false)),
                ]),
              ]);
            }),
          ],
        ]);
      });

  Widget _attachmentPanel() => _panel(
          child: Column(children: [
        Material(
          color: _inputBg,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: controller.pickFiles,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _line),
              ),
              child: Column(children: [
                const Icon(Icons.cloud_upload_outlined, color: _blue, size: 28),
                const SizedBox(height: 9),
                Text('Choose supporting files',
                    style: TextStyle(
                        color: _ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('Tap to browse your device',
                    style: TextStyle(color: _secondary, fontSize: 11.5)),
              ]),
            ),
          ),
        ),
        Obx(() {
          if (controller.attachedFiles.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
                children: controller.attachedFiles.map((file) {
              final label = file.replaceAll('\\', '/').split('/').last;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      color: _blue, size: 18),
                  const SizedBox(width: 9),
                  Expanded(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: _ink, fontSize: 12.5))),
                  IconButton(
                    tooltip: 'Remove attachment',
                    onPressed: () => controller.attachedFiles.remove(file),
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFFD64550)),
                  ),
                ]),
              );
            }).toList()),
          );
        }),
      ]));

  Widget _submitBar(double contentWidth) => SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 11, 18, 15),
          decoration: BoxDecoration(
              color: _surface, border: Border(top: BorderSide(color: _line))),
          child: Center(
              child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Obx(() {
              final busy = controller.isSubmitting.value;
              return SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: busy
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          controller
                              .submitLeaveRequest(controller.username.value);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _blue.withOpacity(.45),
                    elevation: 0,
                    shape: const StadiumBorder(),
                  ),
                  child: busy
                      ? const SizedBox(
                          width: 21,
                          height: 21,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.4, color: Colors.white))
                      : const Text('Submit Leave Request',
                          style: TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700)),
                ),
              );
            }),
          )),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final contentWidth = width >= 720 ? 640.0 : width;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Leave Request',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
          top: false,
          child: Column(children: [
            Expanded(
                child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Center(
                  child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('REVIEW YOUR REQUEST',
                          style: TextStyle(
                              color: _blue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text('Almost there',
                          style: TextStyle(
                              color: _ink,
                              fontSize: 25,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text('Review the details before submitting your leave.',
                          style: TextStyle(color: _secondary, fontSize: 12.5)),
                      const SizedBox(height: 27),
                      _heading('Selected Dates',
                          'Dates included in your leave request'),
                      _selectedDatesPanel(),
                      const SizedBox(height: 25),
                      _heading('Covering Employees',
                          'Who will cover your responsibilities?'),
                      _panel(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _employeeSearch(),
                            _coveringEmployees(),
                          ])),
                      const SizedBox(height: 25),
                      _heading('Reason for Leave', 'Add a short explanation'),
                      _panel(
                          child: TextFormField(
                        onChanged: (value) => controller.reason.value = value,
                        maxLines: 4,
                        minLines: 3,
                        style: TextStyle(fontSize: 13.5, color: _ink),
                        decoration: InputDecoration(
                          hintText: 'Tell us why you need leave...',
                          hintStyle:
                              TextStyle(fontSize: 12.5, color: _secondary),
                          filled: true,
                          fillColor: _inputBg,
                          border: _outline(),
                          enabledBorder: _outline(),
                          focusedBorder: _outline(active: true),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      )),
                      const SizedBox(height: 25),
                      _heading(
                          'Attachments', 'Add supporting documents if needed'),
                      _attachmentPanel(),
                      const SizedBox(height: 12),
                      Center(
                          child: Text(
                              'Your request will follow the approval workflow.',
                              style: TextStyle(
                                  color: _secondary, fontSize: 11.5))),
                    ]),
              )),
            )),
            _submitBar(contentWidth),
          ])),
    );
  }
}
