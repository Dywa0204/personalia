import 'dart:convert';
import 'dart:typed_data';

import 'package:personalia/constant/custom_colors.dart';
import 'package:personalia/controller/user.dart';
import 'package:personalia/model/user.dart';
import 'package:personalia/screen/about_screen.dart';
import 'package:personalia/screen/login_screen.dart';
import 'package:personalia/screen/main_screen.dart';
import 'package:personalia/screen/photo_profile_screen.dart';
import 'package:personalia/screen/setting_screen.dart';
import 'package:personalia/utils/general_helper.dart';
import 'package:personalia/widget/custom/custom_button.dart';
import 'package:personalia/widget/custom/custom_card.dart';
import 'package:personalia/widget/responsive/responsive_container.dart';
import 'package:flutter/material.dart';

import '../widget/custom/custom_form_field.dart';
import '../widget/custom/custom_mini_button.dart';
import '../widget/custom/custom_snackbar.dart';
import '../widget/loading_dialog.dart';
import '../widget/responsive/responsive_image.dart';
import '../widget/responsive/responsive_text.dart';
import 'list_more_screen.dart';
import 'package:image/image.dart' as img;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  UserController _userController = UserController();
  late String _idKaryawan = "0";

  bool _showSalary = false;

  String? _thumbnail;
  String _imageBase64 = "";

  TextEditingController passwordController = TextEditingController();
  final CustomFormFieldController formFieldController = CustomFormFieldController();
  final UserController userController = new UserController();

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _getUserIdentity(String id) async {
    User user = await _userController.identity(idKaryawan: id);

    setState(() {
      _user = user;
      _imageBase64 = user.avatar!.replaceAll("data:image/png;base64,", "");
    });

    final thumbnailByte = await _getThumbnail(_imageBase64);
    if (thumbnailByte != null) {
      await GeneralHelper.preferences.setString("avatarThumbnail", base64Encode(thumbnailByte));
    }
  }

  Future<Uint8List?> _getThumbnail(String base64Image) async {
    Uint8List bytes = base64Decode(base64Image);

    img.Image? imageTemp = img.decodeImage(bytes);
    if (imageTemp != null) {
      img.Image thumbnail = img.copyResize(imageTemp, width: 32, height: 32);
      final thumbnailBytes = img.encodeJpg(thumbnail);

      return Uint8List.fromList(thumbnailBytes);
    }
    return null;
  }

  void _initializeUser() async {
    _thumbnail = await GeneralHelper.preferences.getString("avatarThumbnail") ?? "";

    await GeneralHelper.getUserFromPreferences().then((value) {
      _idKaryawan = "${value?.idKaryawan}";
      setState(() {
        _user = value;
      });
      _getUserIdentity(_idKaryawan);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          CustomCard(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () async {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => PhotoProfileScreen(
                            gender: _user!.jekel!,
                            idKaryawan: _idKaryawan,
                            avatar: _thumbnail,
                            onClose: (isReload) {
                              if (isReload) _updateAvatar();
                            },
                          ))
                        ).then((onValue) {
                          if (GeneralHelper.isProfileUpdate) {
                            GeneralHelper.isProfileUpdate = false;
                            _updateAvatar();
                          }
                        });
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ResponsiveContainer(
                          height: 150,
                          width: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: _buildImage(),
                        ),
                      ),
                    ),
                    SizedBox(width: 16,),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            fit: FlexFit.loose,
                            child: ResponsiveText(
                              _user?.nama ?? "Napoleon Bonaparte",
                              style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  height: 1
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ),
                          SizedBox(height: 12,),
                          Flexible(
                            fit: FlexFit.loose,
                            child: ResponsiveText(
                              "${_user?.jabatan} | ${_user?.statusText}",
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                  color: CustomColor.gray500,
                                  height: 1
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 3,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                SizedBox(height: 20,),
                Container(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  "ID Karyawan",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: CustomColor.gray500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  _user?.kode ?? "FG.000",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(
                                height: 12,
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  "Jenis Kelamin",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: CustomColor.gray500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  "${_user?.jekel == "L" ? "Laki-laki" : "Perempuan"}",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(
                                height: 12,
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  "Status PTKP",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: CustomColor.gray500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  _user?.idStatusPtkp ?? "-",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(
                                height: 12,
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  "Email",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: CustomColor.gray500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  _user?.email ?? "-",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(
                                height: 12,
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  "Gaji Pokok",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: CustomColor.gray500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: Row(
                                  children: [
                                    ResponsiveText(
                                      "${_showSalary ? "Rp ${_user?.gajiPokok}" : "•••••••••"}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black,
                                          fontSize: 17),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        if (GeneralHelper.isLockSalary) {
                                          if (_showSalary) {
                                            setState(() {
                                              _showSalary = !_showSalary;
                                            });
                                          } else {
                                            showDialog(
                                                context: context,
                                                builder: (context) => _passwordDialog(context)
                                            );
                                          }
                                        } else {
                                          setState(() {
                                            _showSalary = !_showSalary;
                                          });
                                        }
                                      },
                                      child: ResponsiveImage(
                                        "assets/icons/${_showSalary ? "visible" : "invisible"}.png",
                                        width: 32,
                                        height: 32,
                                      ),
                                    )
                                  ],
                                )
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  "Level",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: CustomColor.gray500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  _user?.level ?? "-",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(
                                height: 12,
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  "Tanggal Masuk",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: CustomColor.gray500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  _user?.tglMasuk != null ? "${GeneralHelper.convertDate(_user?.tglMasuk! ?? "10-10-2010")}" : "-",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(
                                height: 12,
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  "Username",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: CustomColor.gray500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  _user?.user ?? "-",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(
                                height: 12,
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  "No HP",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: CustomColor.gray500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  _user?.noHp ?? "-",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(
                                height: 12,
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  "No Rekening",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: CustomColor.gray500),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Flexible(
                                fit: FlexFit.loose,
                                child: ResponsiveText(
                                  _user?.norek ?? "-",
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                      fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )),
                SizedBox(
                  height: 24,
                ),
              ],
            ),
          ),


          SizedBox(
            height: 20,
          ),
          CustomButton(
            onClick: () async {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ListMoreScreen(
                    idKaryawan: _idKaryawan,
                    title: "Rekap Slip Gaji",
                    listType: ListType.salary,
                  ))
              );
            },
            iconSize: 32,
            textColor: Colors.black,
            iconColor: CustomColor.gray700,
            text: "Rekap Slip Gaji",
            prefixIcon: Icons.currency_exchange,
            color: Colors.white,
            borderRadius: 16,
            textAlign: TextAlign.start,
          ),
          SizedBox(
            height: 20,
          ),
          CustomButton(
            onClick: () async {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SettingScreen(context: context, username: _user!.user,))
              ).then((onValue) {
                if (GeneralHelper.isSettingUpdate) {
                  GeneralHelper.isSettingUpdate = false;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (builder) => MainScreen())
                  );
                }
              });
            },
            iconSize: 32,
            textColor: Colors.black,
            iconColor: CustomColor.gray700,
            text: "Pengaturan",
            prefixIcon: Icons.settings,
            color: Colors.white,
            borderRadius: 16,
            textAlign: TextAlign.start,
          ),
          SizedBox(
            height: 20,
          ),
          CustomButton(
            onClick: () async {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => AboutScreen())
              );
            },
            iconSize: 32,
            textColor: Colors.black,
            iconColor: CustomColor.gray700,
            text: "Tentang Aplikasi",
            prefixIcon: Icons.error,
            color: Colors.white,
            borderRadius: 16,
            textAlign: TextAlign.start,
          ),
          SizedBox(
            height: 20,
          ),
          CustomButton(
            onClick: () async {
              await GeneralHelper.preferences.setString("userToken", "");

              CustomSnackBar.of(context).show(
                  message: "Berhasil Keluar!",
                  onTop: true,
                  showCloseIcon: true,
                  prefixIcon: Icons.check_circle,
                  backgroundColor: CustomColor.success);

              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => LoginScreen()));
            },
            iconSize: 32,
            iconColor: Colors.white,
            text: "Keluar",
            prefixIcon: Icons.outbond,
            color: CustomColor.error,
            borderRadius: 16,
            textAlign: TextAlign.start,
          )
        ],
      ),
    );
  }

  _updateAvatar() async {
    String thumbnail = await GeneralHelper.preferences.getString("avatarThumbnail") ?? "";
    setState(() {
      _thumbnail = thumbnail;
    });

    _initializeUser();
  }

  Widget _buildImage() {
    if (_imageBase64.isNotEmpty) {
      return Image.memory(
        base64Decode(_imageBase64),
        fit: BoxFit.fill,
      );
    } else if (_thumbnail != null && _thumbnail!.isNotEmpty) {
      return Image.memory(
        base64Decode(_thumbnail!),
        fit: BoxFit.fill,
      );
    } else {
      String imagePath = "assets/images/${_user?.jekel == "L" ? "male" : "female"}.png";
      return Image.asset(
        imagePath,
        width: 150,
        height: 150,
        fit: BoxFit.fill,
      );
    }
  }

  Widget _passwordDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Gunakan Password'),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomFormField(
              obscureText: true,
              hint: "Password",
              prefixIcon: Icons.lock,
              suffixImage: "invisible",
              controller: passwordController,
              formFieldController: formFieldController,
              suffixIconCallback: () {
                bool isTextObscured = formFieldController.getObscureText() ?? false;
                formFieldController.setSuffixIcon(image: isTextObscured ? "visible" : "invisible");
                formFieldController.setObscureText(!isTextObscured);
              },
            ),
            SizedBox(height: 12,),
            Row(
              children: [
                Expanded(child: Container()),
                CustomMiniButton(
                  child: Text("Batal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),),
                  color: CustomColor.gray400,
                  onClick: () {
                    Navigator.of(context).pop();
                  },
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                ),
                SizedBox(width: 12,),
                CustomMiniButton(
                  child: Text("Oke", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),),
                  color: CustomColor.success,
                  onClick: () {
                    _checkPassword();
                  },
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  _checkPassword() async {
    try {
      String password = passwordController.text;

      if (password == "") {
        CustomSnackBar.of(context).show(
            message: "Harap isi password",
            onTop: true,
            showCloseIcon: true,
            prefixIcon: Icons.warning,
            backgroundColor: CustomColor.error
        );
      } else {
        LoadingDialog.of(context).show(message: "Tunggu Sebentar...", isDismissible: true);

        await userController.login(
            username: _user!.user,
            password: password
        );

        FocusManager.instance.primaryFocus?.unfocus();

        LoadingDialog.of(context).hide();
        Navigator.of(context).pop();
        CustomSnackBar.of(context).show(
            message: "Berhasil!",
            onTop: true,
            showCloseIcon: true,
            prefixIcon: Icons.check_circle,
            backgroundColor: CustomColor.success
        );

        FocusManager.instance.primaryFocus?.unfocus();

        setState(() {
          _showSalary = !_showSalary;
        });
        passwordController.text = "";
      }
    } catch (error) {
      print(error);
      LoadingDialog.of(context).hide();
      CustomSnackBar.of(context).show(
          message: error.toString().contains("Password") ? "Gagal! Password salah" : error.toString(),
          onTop: true,
          showCloseIcon: true,
          prefixIcon: error.toString().contains("koneksi") ? Icons.wifi : Icons.warning,
          backgroundColor: CustomColor.error
      );
    }
  }
}
