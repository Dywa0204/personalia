// import 'package:flutter/material.dart';
// import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
//
//   class FaceDetectorPainter extends CustomPainter {
//   FaceDetectorPainter(this.faces, this.imageSize, this.rotation, this.isFlip, this.isFull);
//
//   final List<Face> faces;
//   final Size imageSize;
//   final InputImageRotation rotation;
//   final bool isFlip;
//   final Function(bool) isFull;
//
//   bool _isFullyFace = false;
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint paint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0;
//
//     final Paint contourPaint = Paint()
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3.0
//       ..color = Colors.blue; // Warna untuk kontur wajah
//
//     // Hitung skala sesuai orientasi kamera
//     double scaleX, scaleY;
//
//     print("Canvas width  : ${size.width}");
//     print("Canvas height : ${size.height}");
//     print("Image width   : ${imageSize.width}");
//     print("Image height  : ${imageSize.height}");
//
//     if (rotation == InputImageRotation.rotation90deg ||
//         rotation == InputImageRotation.rotation270deg) {
//       // Jika rotasi adalah 90 atau 270 derajat, kita perlu membalikkan skala
//       scaleX = size.width / imageSize.height;
//       scaleY = size.height / imageSize.width;
//     } else {
//       // Rotasi default (0 atau 180 derajat)
//       scaleX = size.width / imageSize.width;
//       scaleY = size.height / imageSize.height;
//     }
//
//     if (faces.length > 0) {
//       final face = faces[0];
//       final boundingBox = face.boundingBox;
//
//       // Hitung posisi bounding box berdasarkan nilai isFlip
//       final double left = isFlip ? size.width - (boundingBox.right * scaleX) : boundingBox.left * scaleX;
//       final double right = isFlip ? size.width - (boundingBox.left * scaleX) : boundingBox.right * scaleX;
//
//       final Rect scaledRect = Rect.fromLTRB(
//         left,
//         boundingBox.top * scaleY,
//         right,
//         boundingBox.bottom * scaleY,
//       );
//
//       // Periksa apakah wajah sepenuhnya terlihat di layar
//       final isFullyVisible = scaledRect.left >= 0 &&
//           scaledRect.top >= 0 &&
//           scaledRect.right <= size.width &&
//           scaledRect.bottom <= size.height;
//
//       isFull(isFullyVisible);
//
//       // Menentukan apakah wajah terlalu kecil
//       final double faceWidth = scaledRect.width;
//       final double faceHeight = scaledRect.height;
//       final double minFaceSize = 50; // Threshold untuk ukuran minimum wajah
//
//       // Ubah warna stroke berdasarkan apakah wajah terlihat penuh, sebagian, atau terlalu kecil
//       if (faceWidth < minFaceSize || faceHeight < minFaceSize) {
//         paint.color = Colors.red; // Merah jika wajah terlalu kecil
//       } else if (isFullyVisible) {
//         paint.color = Colors.green; // Hijau jika wajah terlihat penuh
//       } else {
//         paint.color = Colors.red; // Merah jika wajah hanya sebagian terlihat
//       }
//
//       // Gambar bounding box
//       canvas.drawRect(scaledRect, paint);
//
//       // Gambar kontur wajah dengan flipping jika diperlukan
//       paintContour(canvas, face, FaceContourType.face, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.leftEyebrowTop, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.leftEyebrowBottom, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.rightEyebrowTop, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.rightEyebrowBottom, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.leftEye, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.rightEye, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.upperLipTop, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.upperLipBottom, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.lowerLipTop, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.lowerLipBottom, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.noseBridge, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.leftCheek, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//       paintContour(canvas, face, FaceContourType.rightCheek, contourPaint, scaleX, scaleY, size.width, isFullyVisible);
//     } else {
//       isFull(false);
//     }
//
//     // for (final face in faces) {
//     //   final boundingBox = face.boundingBox;
//     //
//     //
//     // }
//   }
//
//   // Metode untuk menggambar kontur wajah dengan flipping horizontal jika diperlukan
//   void paintContour(Canvas canvas, Face face, FaceContourType type, Paint paint, double scaleX, double scaleY, double canvasWidth, bool isFullyVisible) {
//     final contour = face.contours[type];
//     if (contour?.points != null) {
//       if (isFullyVisible) {
//         paint.color = Colors.green;  // Warna hijau jika wajah terlihat penuh
//       } else {
//         paint.color = Colors.red;    // Warna merah jika wajah hanya sebagian terlihat
//       }
//       final points = contour!.points
//           .map((point) => Offset(
//           isFlip ? canvasWidth - (point.x * scaleX) : point.x * scaleX, // Flip horizontal jika isFlip true
//           point.y * scaleY))
//           .toList();
//       if (points.isNotEmpty) {
//         // Gambar garis yang menghubungkan titik-titik kontur
//         for (int i = 0; i < points.length - 1; i++) {
//           canvas.drawLine(points[i], points[i + 1], paint);
//         }
//       }
//     }
//   }
//
//   bool isFullFace() {
//     return _isFullyFace;
//     // for (final face in faces) {
//     //   final boundingBox = face.boundingBox;
//     //
//     //   // Hitung skala sesuai orientasi kamera
//     //   double scaleX, scaleY;
//     //
//     //   if (rotation == InputImageRotation.rotation90deg ||
//     //       rotation == InputImageRotation.rotation270deg) {
//     //     scaleX = imageSize.height / imageSize.width;
//     //     scaleY = imageSize.width / imageSize.height;
//     //   } else {
//     //     scaleX = imageSize.width / imageSize.width;
//     //     scaleY = imageSize.height / imageSize.height;
//     //   }
//     //
//     //   final Rect scaledRect = Rect.fromLTRB(
//     //     boundingBox.left * scaleX,
//     //     boundingBox.top * scaleY,
//     //     boundingBox.right * scaleX,
//     //     boundingBox.bottom * scaleY,
//     //   );
//     //
//     //   // Memeriksa apakah wajah sepenuhnya terlihat di layar
//     //   final isFullyVisible = scaledRect.left >= 0 &&
//     //       scaledRect.top >= 0 &&
//     //       scaledRect.right <= imageSize.width &&
//     //       scaledRect.bottom <= imageSize.height;
//     //
//     //   // Jika ada wajah yang tidak terlihat sepenuhnya, kembalikan false
//     //   if (!isFullyVisible) {
//     //     return false;
//     //   }
//     // }
//     // // Jika semua wajah terlihat sepenuhnya, kembalikan true
//     // return true;
//   }
//
//   @override
//   bool shouldRepaint(FaceDetectorPainter oldDelegate) {
//     return oldDelegate.faces != faces || oldDelegate.isFlip != isFlip;
//   }
// }
