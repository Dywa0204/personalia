import 'package:dart_ping/dart_ping.dart';
import 'package:personalia/constant/custom_colors.dart';
import 'package:personalia/constant/environment.dart';
import 'package:personalia/controller/user.dart';
import 'package:personalia/screen/main_screen.dart';
import 'package:personalia/screen/vpn_setting%20_screen.dart';
import 'package:personalia/utils/general_helper.dart';
import 'package:personalia/widget/custom/custom_button.dart';
import 'package:personalia/widget/custom/custom_snackbar.dart';
import 'package:personalia/widget/loading_dialog.dart';
import 'package:flutter/material.dart';

import '../model/user.dart';
import '../widget/custom/custom_form_field.dart';
import '../widget/responsive/responsive_image.dart';
import '../widget/responsive/responsive_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final UserController userController = new UserController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  final CustomFormFieldController formFieldController = CustomFormFieldController();

  @override
  initState() {
    super.initState();
    // usernameController.text = "richi";
    // passwordController.text = "Henshin123!";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/bg_pattern.png"),
          fit: BoxFit.cover,
        ),
      ),
      padding: EdgeInsets.all(24),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      _ping();
                    },
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.wifi, color: CustomColor.gray700, size: 32,),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) => VpnSettingScreen()));
                    },
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.settings, color: CustomColor.gray700, size: 32,),
                    ),
                  )
                ],
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ResponsiveImage(
                      "assets/images/fg_logo.png",
                      width: double.infinity,
                    ),
                    SizedBox(height: 50,),
                    ResponsiveText(
                      "FG PERSONALIA",
                      style: TextStyle(
                          fontFamily: "LilitaOne",
                          fontWeight: FontWeight.w500,
                          fontSize: 39
                      ),
                    ),
                    SizedBox(height: 4,),
                    ResponsiveText(
                      APP_VERSION,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 20
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    color: Colors.white
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10,),
                    ResponsiveText(
                      "Selamat Datang!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24
                      ),
                    ),
                    SizedBox(height: 20,),
                    CustomFormField(
                      hint: "Username",
                      prefixIcon: Icons.person,
                      controller: usernameController,
                    ),
                    SizedBox(height: 20,),
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
                    SizedBox(height: 20,),
                    CustomButton(
                      text: 'Login',
                      onClick: () {
                        _login();
                      },
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  _login() async {
    try {
      String username = usernameController.text;
      String password = passwordController.text;
      print(username);
      print(password);

      if (username == "" || password == "") {
        CustomSnackBar.of(context).show(
            message: "Harap isi semua kolom",
            onTop: true,
            showCloseIcon: true,
            prefixIcon: Icons.warning,
            backgroundColor: CustomColor.error
        );
      } else {
        LoadingDialog.of(context).show(message: "Tunggu Sebentar...", isDismissible: true);

        User user = await userController.login(
            username: username,
            password: password
        );

        FocusManager.instance.primaryFocus?.unfocus();

        User userIdentity = await userController.identity(idKaryawan: user.idKaryawan);

        String encryptedUser = await GeneralHelper.encryptText(userIdentity.toString());

        await GeneralHelper.preferences.setString("userToken", encryptedUser);

        LoadingDialog.of(context).hide();
        CustomSnackBar.of(context).show(
            message: "Login Berhasil!",
            onTop: true,
            showCloseIcon: true,
            prefixIcon: Icons.check_circle,
            backgroundColor: CustomColor.success
        );

        FocusManager.instance.primaryFocus?.unfocus();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreen())
        );
      }
    } catch (error) {
      print(error);
      LoadingDialog.of(context).hide();
      CustomSnackBar.of(context).show(
        message: error.toString(),
        onTop: true,
        showCloseIcon: true,
        prefixIcon: error.toString().contains("koneksi") ? Icons.wifi : Icons.warning,
        backgroundColor: CustomColor.error
      );
    }

  }

  _ping() async {
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
}
