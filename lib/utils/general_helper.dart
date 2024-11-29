import 'dart:convert';
import 'dart:io' show File, Platform;
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:personalia/constant/environment.dart';
import 'package:personalia/model/master_leave.dart';
import 'package:flutter/cupertino.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:wireguard_flutter/wireguard_flutter.dart';

import '../model/user.dart';

class GeneralHelper {
  static late CameraDescription firstCamera;
  static late CameraDescription lastCamera;

  static late CameraDescription frontCamera;
  static late List<CameraDescription> availableCamera;

  static encrypt.Key key = encrypt.Key.fromUtf8(ENCRYPT_KEY);
  static encrypt.IV iv = encrypt.IV.fromUtf8(ENCRYPT_IV);
  static encrypt.Encrypter encryptor = encrypt.Encrypter(encrypt.AES(key));

  static late SharedPreferences preferences;
  static late bool isStatusIN;
  static late List<MasterLeaveType> listMasterLeaveType;
  static late double scalingFactorDivide = 620;
  static late double scalingPercentage;
  static bool isSettingUpdate = false;
  static bool isProfileUpdate = false;
  static bool isUseAlert = true;
  static bool isAutoWG = true;
  static bool isLockSalary = false;

  static final wireGuard = WireGuardFlutter.instance;

  static Future<void> initializeApp() async {
    preferences = await SharedPreferences.getInstance();
    await initializeDateFormatting('id_ID', null);
    isStatusIN = await GeneralHelper.preferences.getBool('isAttendanceIN') ?? true;

    String master = preferences.getString("masterLeaveType") ?? "";
    if (master.isNotEmpty) {
      final Map<String, dynamic> masterJson = jsonDecode(master);
      final List<dynamic> masterList = masterJson['data'];
      listMasterLeaveType = masterList.map((att) => MasterLeaveType.fromJson(att)).toList();
    }

    scalingPercentage = preferences.getDouble("scalingFactor") ?? 100;
    scalingFactorDivide = 620 * (200 - scalingPercentage) / 100;

    isUseAlert = preferences.getBool("isUseAlert") ?? true;
    isLockSalary = preferences.getBool("isLockSalary") ?? false;

    _initializeVPN();
  }

  static Future<void> _initializeVPN() async {
    bool canActivate = await preferences.getBool("isAutoWG") ?? true;
    if (canActivate) {
      try {
        String name = GeneralHelper.preferences.getString("vpn_name") ?? "";
        String config = GeneralHelper.preferences.getString("vpn_config") ?? "";

        if (name.isNotEmpty && config.isNotEmpty) {
          await wireGuard.initialize(interfaceName: name);
          await wireGuard.startVpn(
            serverAddress: BASE_URL,
            wgQuickConfig: config,
            providerBundleIdentifier: 'co.id.farmagitechs.personalia',
          );
        }
      } catch (e) {
        print("error : ${e}");
      }
    }
  }

  static Future<void> initializeFirstCamera() async {
    availableCamera = await availableCameras();
    if (kIsWeb) {
      firstCamera = availableCamera.first;
      lastCamera = availableCamera.first;

      frontCamera = availableCamera.first;
    } else {
      frontCamera = Platform.isAndroid ? availableCamera.last : availableCamera.first;
      firstCamera = Platform.isAndroid ? availableCamera.last : availableCamera.first;

      lastCamera = Platform.isAndroid ? availableCamera.first : availableCamera.last;
    }
    await requestLocationPermission();
  }

  static Future<String> encryptText(String plainText) async {
    return await encryptor.encrypt(plainText, iv: iv).base64;
  }

  static Future<String> decryptText(String cipherText) async {
    return await encryptor.decrypt(encrypt.Encrypted.fromBase64(cipherText), iv: iv);
  }

  static Future<User?> getUserFromPreferences() async {
    String userToken = await GeneralHelper.preferences.getString('userToken') ?? "";

    if (!userToken.isEmpty) {
      String decryptedUser = await GeneralHelper.decryptText(userToken);

      final Map<String, dynamic> userJson = jsonDecode(decryptedUser);
      User user = User.fromJson(userJson);

      return user;
    } else {
      return null;
    }
  }

  static Future<void> requestLocationPermission() async {
    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
  }

  static String convertDate(String dateString, {String? format}) {
    DateTime dateTime = DateTime.parse(dateString);
    DateFormat dateFormat = DateFormat(format ?? 'd MMMM yyyy', 'id_ID');
    String formattedDate = dateFormat.format(dateTime);

    return formattedDate;
  }

  static String convertDateTime(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    DateFormat dateFormat = DateFormat('d MMMM yyyy - HH:mm', 'id_ID');
    String formattedDate = dateFormat.format(dateTime);

    return formattedDate;
  }

  static double calculateSize(BuildContext context, double size) {
    double baseSize = size;
    double screenWidth = MediaQuery.of(context).size.width;
    double scalingFactor = screenWidth / scalingFactorDivide;
    double result = baseSize * scalingFactor;
    return result < size ? result : size;
  }

  static setScalingSize(double percentage) async {
    preferences = await SharedPreferences.getInstance();
    scalingFactorDivide = 620 * (200 - percentage) / 100;
    scalingPercentage = percentage;

    preferences.setDouble("scalingFactor", percentage);
  }

  static setUseAlert(bool isUse) async {
    isUseAlert = isUse;

    preferences = await SharedPreferences.getInstance();
    preferences.setBool("isUseAlert", isUse);
  }

  static setAutoWG(bool isUse) async {
    isAutoWG = isUse;

    preferences = await SharedPreferences.getInstance();
    preferences.setBool("isAutoWG", isUse);
  }

  static setLockSalary(bool isLock) async {
    isLockSalary = isLock;

    preferences = await SharedPreferences.getInstance();
    preferences.setBool("isLockSalary", isLock);
  }

  static String compressBase64Image(String base64Image, {int quality = 30}) {
    // Decode Base64 ke Uint8List
    Uint8List imageBytes = base64Decode(base64Image.split(',')[1]);

    // Decode ke objek gambar
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Gagal memproses gambar');
    }

    // Kompres gambar
    List<int> compressedBytes = img.encodeJpg(image, quality: quality);

    // Encode kembali ke Base64
    String compressedBase64 = base64Encode(compressedBytes);
    return 'data:image/jpeg;base64,$compressedBase64';
  }

  static String generateRandomString(int length) {
    const characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();

    return String.fromCharCodes(Iterable.generate(
      length,
          (_) => characters.codeUnitAt(random.nextInt(characters.length)),
    ));
  }

  static Future<String> saveStringToFile(String data) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/taskData.txt';

    final file = File(filePath);
    await file.writeAsString(data);

    return filePath;
  }

  static Future<String?> readStringFromFile(String filePath) async {
    final file = File(filePath);

    if (await file.exists()) {
      return await file.readAsString();
    }

    return null;
  }
}