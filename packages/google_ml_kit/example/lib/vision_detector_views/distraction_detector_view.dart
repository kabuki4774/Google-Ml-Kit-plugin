import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'attention_detector_view.dart';
import 'attention_view.dart';

class DistractionView extends StatefulWidget {
  @override
  State<DistractionView> createState() => _DistractionViewState();
}

class _DistractionViewState extends State<DistractionView> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.accurate,
    ),
  );
  late ObjectDetector _objectDetector;
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  String? _text;
  dynamic listName = [0, 0.0,""];
  dynamic listName2 = [];
  dynamic listNameTemp = [];

  @override
  void initState() {
    super.initState();
    _initializeDetector(DetectionMode.stream);
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    _objectDetector.close();
    super.dispose();
  }

  void _onScreenModeChanged(ScreenMode mode) {
    _initializeDetector(DetectionMode.stream);
    return;
  }

  void _initializeDetector(DetectionMode mode) async {
    print('Set detector in mode: $mode');

    // uncomment next lines if you want to use the default model
    final options = ObjectDetectorOptions(
        mode: mode,
        classifyObjects: true,
        multipleObjects: true);
    _objectDetector = ObjectDetector(options: options);

    _canProcess = true;
  }

  @override
  Widget build(BuildContext context) {
    return AttentionView(
      // title: 'Face Detector',
      // text: _text,
      // labels: [listName, listName2],
      // onImage: (inputImage) {
      //   processImage(inputImage);
      // },
      // initialDirection: CameraLensDirection.front,
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
    String text = 'Faces found: ${faces.length}\n\n';
    for (Face face in faces) {
      final Rect boundingBox = face.boundingBox;

      final double? rotY = face.headEulerAngleY; // Head is rotated to the right rotY degrees
      final double? rotZ = face.headEulerAngleZ; // Head is tilted sideways rotZ degrees

      // If landmark detection was enabled with FaceDetectorOptions (mouth, ears,
      // eyes, cheeks, and nose available):
      // final FaceLandmark leftEar = face.getLandmark(FaceLandmarkType.leftEar);
      // if (leftEar != null) {
      //   final Point<double> leftEarPos = leftEar.position;
      // }

      // If classification was enabled with FaceDetectorOptions:
      if (face.smilingProbability != null) {
        final double? smileProb = face.smilingProbability;
        print(smileProb);
        //listName[1] = smileProb;
        if(smileProb!=null){
          if(smileProb>0.5){
            listName[2] = "🤪";
          } else {
            listName[2] = "";
          }
        }

      }

      // If face tracking was enabled with FaceDetectorOptions:
      if (face.trackingId != null) {
        final int? id = face.trackingId;
      }
    }
    listNameTemp = [];
    //final objects = await _objectDetector.processImage(inputImage);
    final List<DetectedObject> objects = await _objectDetector.processImage(inputImage);

    for(DetectedObject detectedObject in objects){
      for(Label label in detectedObject.labels){
        print('${label.text} ${label.confidence}');
        if(listName2.contains(label.text)){
        } else {
          listName2.add(label.text);
        }
      }
    }

    // for (final object in objects) {
    //   text +=
    //   'Object:  ${object.labels.map((e) => e.text)}\n\n';
    //   listNameTemp.add(object.labels.map((e) => e.text));
    // }
    // for (final item in listNameTemp){
    //   if(listName.contains(item)){
    //     print(item);
    //   } else {
    //     listName.add(item);
    //   }
    // }
    listName[0] = faces.length;
    print(text);
    _text = text;
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}

