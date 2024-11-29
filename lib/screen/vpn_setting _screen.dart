import 'dart:io';

import 'package:dart_ping/dart_ping.dart';
import 'package:personalia/utils/general_helper.dart';
import 'package:personalia/widget/custom/custom_card.dart';
import 'package:personalia/widget/responsive/responsive_container.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:wireguard_flutter/wireguard_flutter.dart';

import '../constant/custom_colors.dart';
import '../constant/environment.dart';
import '../widget/custom/custom_button.dart';
import '../widget/custom/custom_form_field.dart';
import '../widget/custom/custom_snackbar.dart';
import '../widget/loading_dialog.dart';
import '../widget/responsive/responsive_icon.dart';
import '../widget/responsive/responsive_text.dart';

class VpnSettingScreen extends StatefulWidget {
  const VpnSettingScreen({super.key});

  @override
  State<VpnSettingScreen> createState() => _VpnSettingScreenState();
}

class _VpnSettingScreenState extends State<VpnSettingScreen> {
  TextEditingController _vpnName = TextEditingController();
  TextEditingController _vpnConfig = TextEditingController();

  String _vpnNameTxt = "";
  String _vpnConfigTxt = "";

  String _wireGuardStatus = "";
  bool _isAutoWG = true;

  @override
  void initState() {
    super.initState();

    _vpnNameTxt = GeneralHelper.preferences.getString("vpn_name") ?? "";
    _vpnConfigTxt = GeneralHelper.preferences.getString("vpn_config") ?? "";

    _vpnConfig.text = _vpnConfigTxt;

    _checkStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.secondary,
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                CustomCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: Icon(Icons.arrow_back)
                          ),
                          Expanded(
                            child: ResponsiveText(
                              textAlign: TextAlign.center,
                              "Pengaturan Konfigurasi VPN",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                              onPressed: null,
                              icon: Icon(Icons.arrow_back, color: Colors.white,)
                          ),
                        ],
                      ),
                      SizedBox(height: 16,),
                      CustomCard(
                        color: CustomColor.secondary,
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ResponsiveIcon(Icons.crisis_alert_outlined, color: Colors.black,),
                                SizedBox(width: 16,),
                                Expanded(
                                  child: ResponsiveText(
                                    "Aktifkan VPN secara otomatis saat aplikasi dibuka",
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16,),
                                Switch(
                                  value: _isAutoWG,
                                  activeColor: CustomColor.success,
                                  onChanged: (bool value) {
                                    GeneralHelper.setAutoWG(value);
                                    setState(() {
                                      _isAutoWG = value;
                                    });
                                  },
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24,),

                CustomCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ResponsiveText(
                        textAlign: TextAlign.center,
                        "Konfigurasi VPN",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8,),
                      CustomFormField(
                        backgroundColor: CustomColor.secondary,
                        hint: "Konfigurasi",
                        controller: _vpnConfig,
                        prefixIcon: Icons.settings,
                        iconColor: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        minLines: 1,
                        maxLines: 16,
                        type: TextInputType.multiline,
                        onChange: (value) {
                          _saveConfig();
                        },
                        onTapOutside: () {
                          setState(() {
                            FocusScope.of(context).unfocus();
                          });
                        },
                      ),
                      SizedBox(height: 8,),
                      ResponsiveText(
                        textAlign: TextAlign.center,
                        "Atau",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 8,),
                      CustomButton(
                        onClick: () async {
                          _importFile();
                        },
                        iconSize: 24,
                        text: "Import file konfigurasi",
                        iconColor: Colors.white,
                        prefixIcon: Icons.file_open,
                        textColor: Colors.white,
                        color: CustomColor.primary,
                        borderRadius: 16,
                        textAlign: TextAlign.start,
                      )
                    ],
                  ),
                ),
                SizedBox(height: 24,),
                CustomCard(
                  child: Column(
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
                                    color: _getStatusColor(_wireGuardStatus)
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 24,),
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
                          SizedBox(width: 20,),
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
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
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

  Future<void> _saveConfig() async {
    String config = _vpnConfig.text;

    await GeneralHelper.preferences.setString("vpn_name", "vpn_user");
    await GeneralHelper.preferences.setString("vpn_config", config);

    print("Success");
    _onlyCheck();
  }

  Future<void> _checkStatus() async {
    _isAutoWG = await GeneralHelper.preferences.getBool("isAutoWG") ?? true;

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

  Future<void> _onlyCheck() async {
    final stage = await GeneralHelper.wireGuard.stage();
    print("status ${stage.name}");
    setState(() {
      _wireGuardStatus = _getStatus(stage.name);
    });

    if (!_wireGuardStatus.toLowerCase().contains("mati")) {
      GeneralHelper.wireGuard.stopVpn();
    }
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

  Future<void> _importFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['conf', 'txt', 'bin'],
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);

        final content = await file.readAsString();

        setState(() {
          _vpnConfig.text = content;
          _vpnConfigTxt = content;
        });

        _saveConfig();
      }
    } catch (e) {
      setState(() {
        // fileContent = 'Error reading file: $e';
      });
    }
  }
}
