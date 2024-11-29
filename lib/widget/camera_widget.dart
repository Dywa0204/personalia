import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personalia/utils/firebase_uploader.dart';
import 'package:personalia/utils/general_helper.dart';
import 'package:personalia/widget/responsive/responsive_container.dart';
import 'package:personalia/widget/responsive/responsive_icon.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:workmanager/workmanager.dart';

import '../constant/custom_colors.dart';
import '../controller/attendance.dart';
import '../model/user.dart';
import '../screen/attendance/attendance_screen.dart';
import '../utils/face_detector_painter.dart';
import 'custom/custom_card.dart';
import 'custom/custom_snackbar.dart';
import 'loading_dialog.dart';
import 'location_widget.dart';

class CameraWidget extends StatefulWidget {
  final PanelController slideUpPanelController;
  final AttendanceScreenController attendanceScreenController;
  final bool isAttendanceIN;
  final CameraWidgetController cameraWidgetController;
  const CameraWidget({super.key, required this.slideUpPanelController, required this.attendanceScreenController, required this.isAttendanceIN, required this.cameraWidgetController});

  @override
  State<CameraWidget> createState() => _CameraWidgetState();
}

class _CameraWidgetState extends State<CameraWidget> {
  // Attendance
  final AttendanceController _attendanceController = new AttendanceController();

  // Location
  LocationWidgetController _locationWidgetController = LocationWidgetController();

  // Camera
  CameraController? _cameraController;
  Widget _cameraPreview = Container();
  String _storedImage = "";

  // Camera Button
  Widget _leftButton = Container();
  Widget _rightButton = Container();
  Widget _centerButton = Container();
  double _buttonSize = 86;

  // Image Face Detection
  CustomPaint? _customPaint;
  bool _faceDetectionCanProcess = true;
  bool _faceDetectionIsBusy = false;
  bool _canTakePicture = false;
  bool _isCameraFlipped = false;
  String _faceDetectionText = "";
  FaceDetector? _faceDetector;

  //Firebase
  final storageRef = FirebaseStorage.instance.ref();
  final db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();

    _leftButton = _flipCameraButton();
    _centerButton = _takePictureButton();
    _rightButton = _voidButton();

    _canTakePicture = false;
    _faceDetectionCanProcess = true;
    _initializeCamera();

    widget.cameraWidgetController._attach(this);
  }

  @override
  void dispose() {
    widget.cameraWidgetController._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          LocationWidget(
            widgetType: WidgetType.slideUp,
            controller: _locationWidgetController,
          ),
          Flexible(
            child: AspectRatio(
              aspectRatio: 9/16,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.scale(
                    scaleX: _isCameraFlipped ? -1 : 1,
                    child: _cameraPreview,
                  ),

                  // Face Contour
                  if (_customPaint != null) ClipRect(child: _customPaint!,),

                  // Face Detection Message
                  if (_faceDetectionText != "") Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        CustomCard(
                          color: !_faceDetectionText.contains("tidak") ? CustomColor.success : CustomColor.error,
                          child: Row(
                            children: [
                              Icon(!_faceDetectionText.contains("tidak") ? Icons.check_circle : Icons.warning, color: Colors.white,),
                              SizedBox(width: 12,),
                              Text(
                                _faceDetectionText,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  // Camera Button
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        color: Colors.black.withOpacity(0.5),
                        padding: const EdgeInsets.only(bottom: 24, top: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _leftButton,
                            _centerButton,
                            _rightButton
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _customPaint = null;
    });
    _faceDetectionIsBusy = false;
    _faceDetectionCanProcess = true;

    _faceDetector = new FaceDetector(
      options: FaceDetectorOptions(
          enableContours: true,
          enableClassification: true,
          enableTracking: true,
          minFaceSize: 0.1
      ),
    );

    await GeneralHelper.initializeFirstCamera();
    _cameraController = new CameraController(
      GeneralHelper.frontCamera,
      ResolutionPreset.high,
    );

    Future<void> _initializeControllerFuture = _cameraController!.initialize();
    _initializeControllerFuture.then((_) async {
      await _cameraController!.startImageStream(_processCameraImage);

      setState(() {
        _cameraPreview = CameraPreview(_cameraController!);
      });
    });

  }

  // Beginning of Image Face Detection Method
  Future _processCameraImage(final CameraImage image) async {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) allBytes.putUint8List(plane.bytes);
      final bytes = allBytes.done().buffer.asUint8List();

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final camera = GeneralHelper.frontCamera;
      final imageRotation = InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? InputImageRotation.rotation0deg;
      final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImageData = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes.first.bytesPerRow,
      );
      print("Input image size   : ${inputImageData.size.width}, ${inputImageData.size.height}");
      print("Input image format : ${inputImageData.format}");
      print("Input image rotate : ${inputImageData.rotation}");
      print("Input image rotate : ${inputImageData.bytesPerRow}");

      final inputImage = InputImage.fromBytes(bytes: bytes, metadata: inputImageData);
      await _processImage(inputImage);
    } catch (e) {
      print("Error processing camera image: $e");
    }
  }

  Future<void> _processImage(final InputImage inputImage) async {
    if (!_faceDetectionCanProcess) return;
    if (_faceDetectionIsBusy) return;
    _faceDetectionIsBusy = true;

    try {
      final faces = await _faceDetector?.processImage(inputImage);
      if (inputImage.metadata?.size != null && inputImage.metadata?.rotation != null) {
        final painter = FaceDetectorPainter(
            faces!,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            !_isCameraFlipped,
            (isFull) {
              _canTakePicture = isFull;
              if (!isFull) {
                _faceDetectionText = "Wajah tidak terlihat secara penuh";
              } else {
                _faceDetectionText = "Wajah terdeteksi";
              }
            }
        );
        if (faces.length <= 0) {
          _faceDetectionText = "Wajah tidak ditemukan";
        }

        _customPaint = CustomPaint(painter: painter);
      } else {
        _faceDetectionText = "Perangkat Anda tidak mendukung deteksi wajah";
        _customPaint = null;
        _faceDetectionIsBusy = false;
      }
    } catch (e) {
      _faceDetectionText = "Perangkat Anda tidak mendukung deteksi wajah";
      _customPaint = null;
      _faceDetectionIsBusy = false;
    }

    _faceDetectionIsBusy = false;

    if (mounted) setState(() {});
  }
  // End of Image Face Detection Method


  // Beginning of Camera Button Method
  Widget _voidButton() {
    return ResponsiveContainer(
      width: 86,
      height: 86,
    );
  }

  Widget _takePictureButton() {
    return InkWell(
      onTap: () {
        _takePicture();
      },
      child: ResponsiveContainer(
        width: 86,
        height: 86,
        child: AnimatedContainer(
          decoration: BoxDecoration(
            border: Border.all(width: 6, color: Colors.white),
            borderRadius: BorderRadius.all(Radius.circular(43)),
          ),
          width: _buttonSize,
          height: _buttonSize,
          duration: Duration(milliseconds: 150),
          child: ResponsiveIcon(Icons.camera, size: 64, color: Colors.white),
        ),
      ),
    );
  }

  Widget _okeButton() {
    return InkWell(
      onTap: () {
        _processAttendance();
      },
      child: ResponsiveContainer(
        width: 86,
        height: 86,
        child: AnimatedContainer(
          decoration: BoxDecoration(
            border: Border.all(width: 6, color: CustomColor.success),
            borderRadius: BorderRadius.all(Radius.circular(43)),
          ),
          width: _buttonSize,
          height: _buttonSize,
          duration: Duration(milliseconds: 150),
          child: ResponsiveIcon(Icons.check_circle, size: 64, color: CustomColor.success),
        ),
      ),
    );
  }

  Widget _cancelPreviewButton() {
    return InkWell(
      onTap: () {
        _resumeCamera();
      },
      child: ResponsiveContainer(
        width: 86,
        height: 86,
        child: ResponsiveIcon(Icons.cancel, size: 48, color: CustomColor.error),
      ),
    );
  }

  Widget _flipCameraButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _isCameraFlipped = !_isCameraFlipped;
        });
      },
      child: ResponsiveContainer(
        width: 86,
        height: 86,
        child: ResponsiveIcon(Icons.flip, size: 48, color: Colors.white),
      ),
    );
  }
  // End of Camera Button Method


  // Beginning of camera process method
  void _takePicture() async {
    if (_canTakePicture) {
      try {
        await _cameraController!.pausePreview();
        await _cameraController!.stopImageStream();

        XFile image = await _cameraController!.takePicture();
        List<int> imageBytes = await image.readAsBytes();
        _storedImage = base64.encode(imageBytes);

        setState(() {
          _customPaint = null;
          _canTakePicture = false;

          _leftButton = _cancelPreviewButton();
          _centerButton = _okeButton();
          _rightButton = _voidButton();
        });
      } catch (e) {
        print("Error while taking picture: $e");
        _showErrorTakeImage();
        widget.slideUpPanelController.close();
        _disposeCamera();
      }
    } else {
      _showFaceNotDetectedDialog();
    }
  }

  void _resumeCamera() {
    setState(() {
      _cameraController!.resumePreview().then((_) {
        _cameraController!.startImageStream(_processCameraImage);
        _canTakePicture = true;

        _leftButton = _flipCameraButton();
        _centerButton = _takePictureButton();
        _rightButton = _voidButton();
      }).catchError((e) {
        print("Error resuming camera: $e");
        _showCameraError();
        widget.slideUpPanelController.close();
        _disposeCamera();
      });
    });
  }

  Future<void> _disposeCamera() async {
    await _cameraController!.stopImageStream();
    await _cameraController!.dispose();
    _faceDetectionCanProcess = false;
    await _faceDetector?.close();
    _canTakePicture = false;
  }

  void _processAttendance() async {
    try {
      String? address = _locationWidgetController.getCurrentAddressStr();

      if (address!.contains("Memuat lokasi")) {
        _showStillLoadDialog();
      } else if (address.contains("Lokasi tidak ditemukan")) {
        _showUnknownDialog();
      } else {
        LocationData? locationData = _locationWidgetController.getCurrentLocation();
        User? user = await GeneralHelper.getUserFromPreferences();

        LoadingDialog.of(context).show(message: "Tunggu Sebentar...", isDismissible: false);

        String attendanceMessage = await _attendanceController.add(
            idKaryawan: user!.idKaryawan,
            latitude: "${locationData?.latitude ?? "0.0"}",
            longitude: "${locationData?.longitude ?? "0.0"}",
            status: "${widget.isAttendanceIN ? "IN" : "OUT"}",
            location: "${address}",
            foto: "data:image/png;base64,${_storedImage}"
        );
        // String attendanceMessage = "bisa dongg";
        LoadingDialog.of(context).hide();

        if (attendanceMessage.isNotEmpty) {
          CustomSnackBar.of(context).show(
              message: attendanceMessage,
              onTop: true,
              showCloseIcon: true,
              prefixIcon: Icons.check_circle,
              backgroundColor: CustomColor.success,
              duration: Duration(seconds: 5));

          widget.slideUpPanelController.close();
          widget.attendanceScreenController.refreshData();

          _resetButton();

          bool isRecorded = await GeneralHelper.preferences.getBool("isRecorded") ?? false;
          print("Is Recorded: $isRecorded");

          if (isRecorded) {
            String filePath = await GeneralHelper.saveStringToFile(_storedImage);
            Map<String, dynamic> inputData = {
              'id_karyawan': "${user.idKaryawan}",
              'name': "${user.nama}",
              'att_option': "${widget.isAttendanceIN ? "IN" : "OUT"}",
              'location_lat': "${locationData?.latitude.toString() ?? "0.0"}",
              'location_lng': "${locationData?.longitude.toString() ?? "0.0"}",
              'address': "${address}",
              "filePath": filePath
            };

            Workmanager().registerOneOffTask(
              "uploader",
              "upload_firebase",
              inputData: inputData,
            );
          }
        } else {
          _showErrorDialog(context);
        }
      }
    } catch (error) {
      LoadingDialog.of(context).hide();
      CustomSnackBar.of(context).show(
          message: error.toString(),
          onTop: true,
          showCloseIcon: true,
          prefixIcon: error.toString().contains("koneksi") ? Icons.wifi : Icons.warning,
          backgroundColor: CustomColor.error,
          duration: Duration(seconds: 5));
    }
  }


  void _resetButton() {
    _leftButton = _flipCameraButton();
    _centerButton = _takePictureButton();
    _rightButton = _voidButton();
  }
  // End of camera process method

  // Beginning of dialog message method
  void _showFaceNotDetectedDialog() {
    QuickAlert.show(
      context: context,
      confirmBtnText: "Oke",
      type: QuickAlertType.error,
      title: 'Wajah tidak ditemukan atau tidak sesuai',
      text: 'Pastikan wajah terlihat dengan jelas dan berada di dalam frame foto',
    );
  }

  void _showCameraError() {
    QuickAlert.show(
      context: context,
      confirmBtnText: "Oke",
      type: QuickAlertType.error,
      title: 'Gagal memuat kamera',
      text: 'Silahkan jalankan ulang aplikasi',
    );
  }

  void _showErrorTakeImage() {
    QuickAlert.show(
      context: context,
      confirmBtnText: "Oke",
      type: QuickAlertType.error,
      title: 'Gagal mengambil gambar',
      text: 'Silahkan jalankan ulang aplikasi',
    );
  }

  void _showStillLoadDialog() {
    QuickAlert.show(
      context: context,
      confirmBtnText: "Oke",
      type: QuickAlertType.error,
      title: "Masih memuat lokasi",
      text: 'Harap tunggu sebentar dan coba lagi',
    );
  }

  void _showUnknownDialog() {
    QuickAlert.show(
      context: context,
      confirmBtnText: "Oke",
      type: QuickAlertType.error,
      title: "Lokasi tidak ditemukan",
      text: 'Periksa kembali koneksi internet Anda..',
    );
  }

  void _showErrorDialog(BuildContext context) {
    CustomSnackBar.of(context).show(
        message: "Gagal melakukan presensi, silahkan coba lagi",
        onTop: true,
        showCloseIcon: true,
        prefixIcon: Icons.warning,
        backgroundColor: CustomColor.error,
        duration: Duration(seconds: 5)
    );
  }
  // End of dialog message method
}

class CameraWidgetController {
  _CameraWidgetState? _state;

  void _attach(_CameraWidgetState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  void onDispose() {
    _state?._disposeCamera();
  }

  void initializeCamera() {
    _state?._initializeCamera();
  }
}
