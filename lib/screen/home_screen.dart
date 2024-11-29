import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_ping/dart_ping.dart';
import 'package:personalia/constant/custom_colors.dart';
import 'package:personalia/controller/home.dart';
import 'package:personalia/model/home.dart';
import 'package:personalia/screen/vpn_setting%20_screen.dart';
import 'package:personalia/utils/general_helper.dart';
import 'package:personalia/widget/responsive/responsive_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constant/environment.dart';
import '../model/leave.dart';
import '../model/overtime.dart';
import '../widget/custom/custom_button.dart';
import '../widget/custom/custom_card.dart';
import '../widget/custom/custom_loading_list.dart';
import '../widget/custom/custom_snackbar.dart';
import '../widget/list_item/leave_item.dart';
import '../widget/list_item/overtime_item.dart';
import '../widget/loading_dialog.dart';
import '../widget/responsive/responsive_container.dart';
import '../widget/responsive/responsive_icon.dart';
import '../widget/responsive/responsive_image.dart';
import 'detail_screen.dart';
import 'list_more_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _name = "Napoleon Bonaparte";
  late String _idKaryawan = "1";
  late String _level = "Karyawan";
  bool _isLoading = false;

  HomeController _homeController = HomeController();
  List<Leave> _leaveList = [];
  List<Overtime> _overtimeList = [];
  String _leaveLeft = "";
  String _nextPayment = "0";

  DateTime _dateNow = DateTime.now();
  late String _dateNowStr = "";

  String _wireGuardStatus = "";

  @override
  void initState() {
    super.initState();

    _checkStatus();

    _initializeUser();
    _dateNowStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_dateNow);
  }

  _initializeUser() async {
    await GeneralHelper.getUserFromPreferences().then((value) {
      _getHomeContent("${value?.idKaryawan}", "${value?.level}");
      _generateRecordedUser(value!.idKaryawan);

      setState(() {
        _name = value.nama;
        _idKaryawan = value.idKaryawan;
        _level = value.level;
      });
    });
}

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      "Selamat Datang",
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color: CustomColor.gray500,
                          fontWeight: FontWeight.w600,
                          fontSize: 18
                      ),
                    ),
                    ResponsiveText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      _name,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 24
                      ),
                    ),
                    ResponsiveText(
                      _dateNowStr,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                          color: CustomColor.gray500,
                          fontWeight: FontWeight.w600,
                          fontSize: 16
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 24,),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.all(Radius.circular(32)),
                    onTap: () {},
                    child: ResponsiveImage("assets/icons/notification.png"),
                  ),
                ),
              )
            ],
          ),
          SizedBox(height: 36,),

          CustomCard(
            constraints: BoxConstraints(
              minWidth: double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomCard(
                  color: CustomColor.secondary,
                  child: Row(
                    children: [
                      ResponsiveIcon(Icons.confirmation_num_outlined, color: Colors.black,),
                      SizedBox(width: 16,),
                      Expanded(
                        child: ResponsiveText("Status VPN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black),),
                      ),
                      ResponsiveContainer(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          color: _getStatusColor(_wireGuardStatus).withOpacity(0.22),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        child: ResponsiveText(
                          _wireGuardStatus,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            // color: _getStatusColor(_wireGuardStatus)
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 16,),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        onClick: () async {
                          if (_wireGuardStatus.toLowerCase().contains("mati")) {
                            _activate();
                          } else {
                            _deactivate();
                          }
                        },
                        iconSize: 24,
                        text: _wireGuardStatus.toLowerCase().contains("mati") ? "Hidupkan" : "Matikan",
                        prefixIcon: Icons.settings_power_outlined,
                        iconColor: Colors.white,
                        textColor: Colors.white,
                        color: CustomColor.primary,
                        borderRadius: 16,
                        textAlign: TextAlign.start,
                      ),
                    ),
                    SizedBox(width: 16,),
                    Expanded(
                      child: CustomButton(
                        onClick: () async {
                          _ping();
                        },
                        iconSize: 24,
                        text: "Cek Koneksi",
                        iconColor: Colors.white,
                        prefixIcon: Icons.wifi,
                        textColor: Colors.white,
                        color: CustomColor.primary,
                        borderRadius: 16,
                        textAlign: TextAlign.start,
                      ),
                    ),
                    SizedBox(width: 16,),
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => VpnSettingScreen()));
                      },
                      icon: ResponsiveIcon(Icons.settings, size: GeneralHelper.calculateSize(context, 48),),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24,),

          CustomCard(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: ResponsiveText(
                          "Gajian",
                          style: TextStyle(fontWeight: FontWeight.w500, color: CustomColor.gray500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Flexible(
                        fit: FlexFit.loose,
                        child: ResponsiveText(
                          !_isLoading ? "${_nextPayment} Hari Lagi" : "...",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 28),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Flexible(
                        fit: FlexFit.loose,
                        child: ResponsiveText(
                          int.parse(_nextPayment) >= 10 ? "Harus semangat kerja!" : "Tetap semangat kerja!",
                          style: TextStyle(fontWeight: FontWeight.w500, color: CustomColor.gray500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: CustomColor.gray500,
                  width: 1,
                  height: 48,
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        fit: FlexFit.loose,
                        child: ResponsiveText(
                          "Sisa",
                          style: TextStyle(fontWeight: FontWeight.w500, color: CustomColor.gray500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Flexible(
                        fit: FlexFit.loose,
                        child: ResponsiveText(
                          !_isLoading ? _leaveLeft : "...",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 28),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      Flexible(
                        fit: FlexFit.loose,
                        child: ResponsiveText(
                          "Cuti Tahunan",
                          style: TextStyle(fontWeight: FontWeight.w500, color: CustomColor.gray500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32,),

          // Loading
          AnimatedSize(
            duration: Duration(milliseconds: 200),
            child: _isLoading ? Container(
              margin: EdgeInsets.only(bottom: 24),
              child: CustomLoadingList("Memperbaharui usulan..."),
            ) : Container(),
          ),

          if (!_isLoading)
            Expanded(
            child: RefreshIndicator(
              onRefresh: () => _getHomeContent(_idKaryawan, _level),
              color: CustomColor.primary,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ResponsiveText(
                          "Usulan Cuti",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              color: CustomColor.gray700,
                              fontWeight: FontWeight.w600,
                              fontSize: 24
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => ListMoreScreen(
                                  idKaryawan: _idKaryawan,
                                  title: "Riwayat Cuti",
                                  listType: ListType.leave,
                                ))
                            );
                          },
                          child: ResponsiveText(
                            "Lihat Semua",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                color: CustomColor.accentBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 18
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 16,),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _leaveList.length > 5 ? 5 : _leaveList.length,
                      itemBuilder: (context, index) {
                        final leave = _leaveList[index];
                        return LeaveItem(
                          leave: leave,
                          onClick: (result) {
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => DetailScreen(
                                  title: "Detail Cuti",
                                  leave: result,
                                  canEdit: result.status!.contains("Pengajuan"),
                                ))
                            );
                          },
                        );
                      },
                    ),

                    SizedBox(height: 32,),

                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ResponsiveText(
                          "Usulan Lembur",
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              color: CustomColor.gray700,
                              fontWeight: FontWeight.w600,
                              fontSize: 24
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => ListMoreScreen(
                                  idKaryawan: _idKaryawan,
                                  title: "Riwayat Lembur",
                                  listType: ListType.overtime,
                                ))
                            );
                          },
                          child: ResponsiveText(
                            "Lihat Semua",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                color: CustomColor.accentBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 18
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 16,),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: _overtimeList.length > 5 ? 5 : _overtimeList.length,
                      itemBuilder: (context, index) {
                        final overtime = _overtimeList[index];
                        return OvertimeItem(
                          overtime: overtime,
                          onClick: (result) {
                            Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => DetailScreen(
                                  title: "Detail Lembur",
                                  overtime: result,
                                  canEdit: result.status_approval_direksi == null && result.status_approval_spv == null,
                                  idKaryawan: _idKaryawan,
                                ))
                            );
                          },
                        );
                      },
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _getHomeContent(String idKaryawan, String level) async {
    setState(() {
      _isLoading = true;
    });

    try {
      Home home = await _homeController.home(idKaryawan: idKaryawan, level: level);

      setState(() {
        _leaveList = home.usulan_cuti!;
        _overtimeList = home.usulan_lembur!;
        _leaveLeft = home.sisa_cuti_tahunan!;
        _nextPayment = _getPaymentCountdown(home.next_gajian!);
        _isLoading = false;
      });

    } catch (e) {
      print(e);
      CustomSnackBar.of(context).show(
          message: e.toString(),
          onTop: true,
          showCloseIcon: true,
          prefixIcon: e.toString().contains("koneksi") ? Icons.wifi : Icons.warning,
          backgroundColor: CustomColor.error
      );
    }
  }

  String _getPaymentCountdown(String next) {
    Map<String, int> monthMap = {
      "Jan": 1,
      "Feb": 2,
      "Mar": 3,
      "Apr": 4,
      "May": 5,
      "Jun": 6,
      "Jul": 7,
      "Aug": 8,
      "Sep": 9,
      "Oct": 10,
      "Nov": 11,
      "Dec": 12
    };

    List<String> parts = next.split(' ');
    String monthStr = parts[0];
    int day = int.parse(parts[1]);
    int year = int.parse(parts[2]);

    List<String> timeParts = parts[3].split(':');
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);
    int second = int.parse(timeParts[2]);

    int month = monthMap[monthStr]!;

    // Create DateTime object
    DateTime nextDate = DateTime(year, month, day, hour, minute, second);
    DateTime dateNow = DateTime.now();

    Duration duration = nextDate.difference(dateNow);

    return duration.inDays.toString();
  }

  Future<void> _activate() async {
    try {
      String name = GeneralHelper.preferences.getString("vpn_name") ?? "";
      String config = GeneralHelper.preferences.getString("vpn_config") ?? "";

      await GeneralHelper.wireGuard.initialize(interfaceName: name);
      await GeneralHelper.wireGuard.startVpn(
        serverAddress: BASE_URL,
        wgQuickConfig: config,
        providerBundleIdentifier: 'co.id.farmagitechs.personalia',
      );
    } catch (e) {
      print("error : ${e}");
      CustomSnackBar.of(context).show(
          message: "Gagal menghidupkan VPN, silahkan coba lagi",
          onTop: true,
          showCloseIcon: true,
          prefixIcon: Icons.warning,
          backgroundColor: CustomColor.error,
          duration: Duration(seconds: 5)
      );
    }
  }

  Future<void> _deactivate() async {
    try {
      await GeneralHelper.wireGuard.stopVpn();
    } catch (e) {
      print("error : ${e}");
      CustomSnackBar.of(context).show(
          message: "Gagal mematikan VPN, silahkan coba lagi",
          onTop: true,
          showCloseIcon: true,
          prefixIcon: Icons.warning,
          backgroundColor: CustomColor.error,
          duration: Duration(seconds: 5)
      );
    }
  }

  Future<void> _checkStatus() async {
    final stage = await GeneralHelper.wireGuard.stage();
    print("status ${stage.name}");
    setState(() {
      _wireGuardStatus = _getStatus(stage.name);
    });

    GeneralHelper.wireGuard.vpnStageSnapshot.listen((event) {
      print("status changed $event");
      setState(() {
        _wireGuardStatus = _getStatus(event.name);
      });
    });
  }

  String _getStatus(String wgStatus) {
    switch(wgStatus) {
      case "disconnected":
        return "Mati";
      case "preparing":
        return "Menyiapkan";
      case "connecting":
        return "Menghidupakan";
      case "connected":
        return "Hidup";
      case "disconnecting":
        return "Mematikan";
      default:
        return "Mati";
    }
  }

  Color _getStatusColor(String status) {
    switch(status) {
      case "Mati":
        return CustomColor.error;
      case "Hidup":
        return CustomColor.success;
      default:
        return CustomColor.warn;
    }
  }

  void _ping() async {
    LoadingDialog.of(context).show(message: "Tunggu Sebentar...", isDismissible: true);
    FocusManager.instance.primaryFocus?.unfocus();

    final ping = Ping("12.11.1.7", count: 3);

    int i = 0;
    ping.stream.listen((event) {
      if (event.error != null) {
        LoadingDialog.of(context).hide();
        ping.stop();

        CustomSnackBar.of(context).show(
            message: "Gagal terhubung ke server",
            onTop: true,
            showCloseIcon: true,
            prefixIcon: Icons.wifi,
            backgroundColor: CustomColor.error
        );
      }

      if (i == 3) {
        LoadingDialog.of(context).hide();

        CustomSnackBar.of(context).show(
            message: "Terhubung ke server",
            onTop: true,
            showCloseIcon: true,
            prefixIcon: Icons.check_circle,
            backgroundColor: CustomColor.success
        );
      }

      print(i);
      print(event);
      i++;
    });
  }

  Future<void> _generateRecordedUser(String idKaryawan) async {
    try {
      final document = FirebaseFirestore.instance.collection('config').doc('recorded_users');
      final snapshot = await document.get();

      if (snapshot.exists) {
        List<dynamic>? ids = snapshot.data()?['ids'];

        if (ids != null) {
          if (ids.contains(idKaryawan)) {
            GeneralHelper.preferences.setBool("isRecorded", true);
          } else {
            GeneralHelper.preferences.setBool("isRecorded", false);
          }
        } else {
          print('Field "angka" tidak ditemukan atau bukan array.');
        }
      } else {
        print('Dokumen dengan ID "config" tidak ditemukan.');
      }
    } catch (e) {
      print('Error mendapatkan data: $e');
    }
  }
}
