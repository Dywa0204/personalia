import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../model/user.dart';
import 'general_helper.dart';

class FirebaseUploader {
  //Firebase
  final storageRef = FirebaseStorage.instance.ref();
  final db = FirebaseFirestore.instance;

  FirebaseUploader() {}

  Future<bool> beginUploadTask(Map<String, dynamic>? inputData) async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final filePath = inputData?['filePath'];
      if (filePath != null) {
        final data = await GeneralHelper.readStringFromFile(filePath);

        String firebaseResponse = await _firebaseUploadImage(
            inputData?['id_karyawan'],
            inputData?['name'],
            inputData?['att_option'],
            'data:image/png;base64,${data}'
        );
        if (firebaseResponse.isEmpty) {
          Future.value(false);
        }

        bool firebaseStoreResponse = await _firebaseStoreData(
            firebaseResponse,
            inputData?['id_karyawan'],
            inputData?['name'],
            inputData?['att_option'],
            inputData?['location_lat'],
            inputData?['location_lng'],
            inputData?['address']
        );
        if (!firebaseStoreResponse) {
          Future.value(false);
        }
      }
    } catch (e) {
      Future.value(false);
    }

    return true;
  }

  Future<String> _firebaseUploadImage(String idKaryawan, String name, String status, String data) async {
    String dirName = "${idKaryawan}_${name}";

    String formattedDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
    String fileName = "${idKaryawan}_${status}_${formattedDate}_${GeneralHelper.generateRandomString(12)}";

    final mountainsRef = storageRef.child("${dirName}/${fileName}.png");

    final dataUrl = await GeneralHelper.compressBase64Image(data);

    try {
      await mountainsRef.putString(dataUrl, format: PutStringFormat.dataUrl);

      return await mountainsRef.getDownloadURL();
    } on FirebaseException catch (e) {
      print("Firebase error - upload image : ${e}");
      return "";
    }
  }

  Future<bool> _firebaseStoreData(String imageURL, String id, String name, String status, String latitude, String longitude, String address) async {
    try {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(now);
      int timestamp = DateTime.now().millisecondsSinceEpoch;

      final data = <String, dynamic>{
        "id": id,
        "name": name,
        "status": status,
        "latitude": latitude,
        "longitude": longitude,
        "address": address,
        "time": formattedDate,
        "timestamp": timestamp,
        "imageURL": imageURL
      };

      await db.collection("reports")
          .doc("${id}_${GeneralHelper.generateRandomString(16)}")
          .set(data);

      await db.collection("users").doc("${id}_${name}").set({
        "id": id,
        "name": name
      });

      return true;
    } catch (e) {
      print('Firebase error - store data : $e');
      return false;
    }
  }
}