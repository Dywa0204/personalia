import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:personalia/constant/custom_colors.dart';
import 'package:personalia/controller/attendance.dart';
import 'package:personalia/model/master_leave.dart';
import 'package:personalia/screen/attendance/attendance_screen.dart';
import 'package:personalia/screen/home_screen.dart';
import 'package:personalia/screen/overtime/overtime_screen.dart';
import 'package:personalia/screen/profile_screen.dart';
import 'package:personalia/utils/general_helper.dart';
import 'package:personalia/widget/camera_widget.dart';
import 'package:personalia/widget/custom/custom_card.dart';
import 'package:personalia/widget/location_widget.dart';
import 'package:personalia/widget/responsive/responsive_container.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:location/location.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../controller/leave.dart';
import '../model/user.dart';
import '../utils/face_detector_painter.dart';
import '../widget/bottom_slide_up.dart';
import '../widget/custom/custom_snackbar.dart';
import '../widget/loading_dialog.dart';
import '../widget/responsive/responsive_icon.dart';
import '../widget/responsive/responsive_image.dart';
import '../widget/responsive/responsive_text.dart';
import 'leave/leave_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Slide Up Panel
  late PanelController _slideUpPanelController;
  final GlobalKey<BottomSlideUpState> _bottomSlideUpKey = GlobalKey<BottomSlideUpState>();

  bool _isAttendanceIN = true;
  AttendanceScreenController _attendanceScreenController = AttendanceScreenController();
  LeaveController _leaveController = LeaveController();

  Widget _cameraWidget = Container();
  CameraWidgetController _cameraWidgetController = CameraWidgetController();

  // Navigation
  int _selectedNav = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    LeaveScreen(),
    Container(),
    OvertimeScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    _isAttendanceIN = GeneralHelper.isStatusIN;
    _screens[2] = AttendanceScreen(
      onClick: (attStatus) => { _openSLideUp(attStatus) },
      controller: _attendanceScreenController,
    );
    _getMasterLeaveTypeList();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: BottomSlideUp(
        isScrollable: false,
        key: _bottomSlideUpKey,
        onPanelCreated: (panelController) {
          _slideUpPanelController = panelController;
        },
        onPanelClosed: () {
          _cameraWidgetController.onDispose();
        },
        header: Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 5),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  _slideUpPanelController.close();
                },
                icon: ResponsiveIcon(Icons.arrow_back, color: Colors.black, size: 32),
              ),
              Expanded(
                child: ResponsiveText(
                  _isAttendanceIN ? "Presensi Masuk" : "Presensi Pulang",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        child: Expanded(
          child: _cameraWidget
        ),
        body: Scaffold(
          backgroundColor: CustomColor.secondary,
          body: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: _screens[_selectedNav],
            ),
          ),
          floatingActionButtonAnimator: NoScalingAnimation(),
          floatingActionButton: ResponsiveContainer(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(GeneralHelper.calculateSize(context, 16)),
              color: _selectedNav == 2 ? CustomColor.primary : CustomColor.gray400,
            ),
            width: 90,
            height: 90,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(GeneralHelper.calculateSize(context, 16)),
                highlightColor: Colors.black.withOpacity(0.2),
                splashColor: Colors.black.withOpacity(0.2),
                onTap: () async {
                  setState(() {
                    _selectedNav = 2;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ResponsiveImage("assets/icons/fact_check.png", width: 56, fit: BoxFit.fitWidth),
                    const SizedBox(height: 6),
                    ResponsiveText(
                      "Presensi",
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            height: GeneralHelper.calculateSize(context, 96),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.white,
            elevation: 24,
            shadowColor: Colors.black,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(child: _navbarResponsiveIcon(
                  index: 0,
                  selectedIndex: _selectedNav,
                  icon: Icons.home_filled,
                  text: "Home",
                  onSelected: () {
                    setState(() {
                      _selectedNav = 0;
                    });
                  },
                )),
                Expanded(child: _navbarResponsiveIcon(
                  index: 1,
                  selectedIndex: _selectedNav,
                  icon: Icons.arrow_circle_up,
                  text: "Cuti",
                  onSelected: () {
                    setState(() {
                      _selectedNav = 1;
                    });
                  },
                )),
                ResponsiveContainer(width: 130,),
                Expanded(child: _navbarResponsiveIcon(
                  index: 3,
                  selectedIndex: _selectedNav,
                  icon: Icons.work_history,
                  text: "Lembur",
                  onSelected: () {
                    setState(() {
                      _selectedNav = 3;
                    });
                  },
                )),
                Expanded(child: _navbarResponsiveIcon(
                  index: 4,
                  selectedIndex: _selectedNav,
                  icon: Icons.person_pin,
                  text: "Profil",
                  onSelected: () {
                    setState(() {
                      _selectedNav = 4;
                    });
                  },
                )),
              ],
            ),
          ),
          floatingActionButtonLocation: CustomFloatingActionButtonLocation(),
        ),
      ),
    );
  }

  Widget _navbarResponsiveIcon({
    required int index, required int selectedIndex,
    required IconData icon, required String text,
    required VoidCallback onSelected
  })
  {
    final isSelected = index == selectedIndex;
    final color = isSelected ? CustomColor.primary : CustomColor.gray200;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSelected,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              ResponsiveIcon(icon, size: 36, color: color),
              ResponsiveText(
                text,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openSLideUp(String attStatus) async {
    _slideUpPanelController.open();

    setState(() {
      _cameraWidget = CameraWidget(
        slideUpPanelController: _slideUpPanelController,
        attendanceScreenController: _attendanceScreenController,
        isAttendanceIN: attStatus == "IN",
        cameraWidgetController: _cameraWidgetController,
      );
      _isAttendanceIN = attStatus == "IN";
    });

    _cameraWidgetController.initializeCamera();
  }

  _getMasterLeaveTypeList() async {
    try {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      List<MasterLeaveType> list = await _leaveController.master();

      GeneralHelper.listMasterLeaveType = list;
      if (list.length != 0) {
        String masterLeaveJson = "";
        list.forEach((item) {
          masterLeaveJson += "${item.toString()},";
        });

        await preferences.setString("masterLeaveType", "{\"data\":[${masterLeaveJson.substring(0, masterLeaveJson.length - 1)}]}");
      }

    } catch(e) {

    }
  }
}

class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width - scaffoldGeometry.floatingActionButtonSize.width) / 2;
    final double fabY = scaffoldGeometry.scaffoldSize.height - scaffoldGeometry.floatingActionButtonSize.height - scaffoldGeometry.minInsets.bottom - 20;
    return Offset(fabX, fabY);
  }
}

class NoScalingAnimation extends FloatingActionButtonAnimator {
  @override
  Offset getOffset({required Offset begin, required Offset end, required double progress}) {
    return end;
  }

  @override
  Animation<double> getRotationAnimation({required Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }

  @override
  Animation<double> getScaleAnimation({required Animation<double> parent}) {
    return Tween<double>(begin: 1.0, end: 1.0).animate(parent);
  }
}

