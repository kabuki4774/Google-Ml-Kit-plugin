import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'attention_view.dart';
import 'camera_view.dart';
import 'painters/face_detector_painter.dart';

class FaceDetectorView extends StatefulWidget {
  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String _text = "";
  dynamic listName = [0, 0.0,""];
  dynamic faceInfo = [0, 0.0,'']; //count, confidence, smileFlag
  dynamic attention = 0.0;
  dynamic area = 0.0;
  dynamic fx = 0.0;
  dynamic fy = 0.0;
  dynamic fz = 0.0;
  dynamic distraction = 0.0;
  String view = 'front';

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UserAttnView(
      title: 'Face Finder : ' + view,
      text: _text! + view,
      labels: [["Face Info\n=>"], faceInfo, ["\nAttention values=>"], attention, ["\nFace values Area; angles - x ; y; x;=>\n"], area, ["\n"],fx, ["\n"],fy,["\n"],fz],
      onImage: (inputImage) {
        processImage(inputImage);
      },
      initialDirection: CameraLensDirection.front,
    );
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final faces = await _faceDetector.processImage(inputImage);

    // if (inputImage.inputImageData?.size != null &&
    //     inputImage.inputImageData?.imageRotation != null) {
    //   final painter = FaceDetectorPainter(
    //       faces,
    //       inputImage.inputImageData!.size,
    //       inputImage.inputImageData!.imageRotation);
    //   _customPaint = CustomPaint(painter: painter);
    // } else {
    //   String text = 'Faces found: ${faces.length}\n\n';
    //   for (final face in faces) {
    //     text += 'face: ${face.boundingBox}\n\n';
    //   }
    // _text = text;
    // _customPaint = null;
    // }


    /*
    The following terms describe the angle a face is oriented with respect to the camera:

      - Euler X: A face with a positive Euler X angle is facing upward.
      - Euler Y: A face with a positive Euler Y angle is looking to the (reversed in portrait mode for tablets) right of the camera, or looking to the left if negative.
      - Euler Z: A face with a positive Euler Z angle is rotated (up down on portrait mode for tablets) counter-clockwise relative to the camera.

      ML Kit doesn't report the Euler X, Euler Y or Euler Z angle of a detected face when
       LANDMARK_MODE_NONE, CONTOUR_MODE_ALL, CLASSIFICATION_MODE_NONE and PERFORMANCE_MODE_FAST
       are set together.

       */
    for (final Face face in faces) {
      final double? rotX = face.headEulerAngleX; // Head is rotated to the right rotX degrees
      final double? rotY = face.headEulerAngleY; // Head is rotated to the right rotY degrees
      final double? rotZ = face.headEulerAngleZ; // Head is tilted sideways rotZ degrees
      final double? left = face.leftEyeOpenProbability; // Head is rotated to the right rotX degrees
      final double? right = face.rightEyeOpenProbability; // Head is rotated to the right rotX degrees
      if(left != null && right != null && rotX != null && rotY != null && rotZ != null){
        attention = left.abs() * right.abs() - (rotX.abs() * rotY.abs() * rotZ.abs())/(pow(45,3));
      }

      area = face.boundingBox.size.width*face.boundingBox.size.height;
      fx = rotX;
      fy = rotY;
      fz = rotZ;
      // If classification was enabled with FaceDetectorOptions:
      if (face.smilingProbability != null) {
        final double? smileProb = face.smilingProbability;
        print(smileProb);
        faceInfo[1] = smileProb;
        if(smileProb!=null){
          if(smileProb>0.5){
            faceInfo[2] = '🤪';
          } else {
            faceInfo[2] = '';
          }
        } else {
          faceInfo[2] = '';
        }
      }
    }
    // for (final face in faces) {
    //   text += 'face: ${face.boundingBox}\n\n';
    // }
    faceInfo[0] = faces.length;
    // _text = text;
    print(_text);
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
    // print(text);
    // _text = text;
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
