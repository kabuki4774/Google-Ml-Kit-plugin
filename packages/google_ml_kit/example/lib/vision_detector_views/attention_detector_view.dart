import 'dart:async';
import 'dart:io' as io;
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'attention_view.dart';

class AttentionView extends StatefulWidget {
  @override
  State<AttentionView> createState() => _AttentionViewState();
}

class _AttentionViewState extends State<AttentionView> {
  late ImageLabeler _imageLabeler;
  bool _canProcess = false;
  bool _isBusy = false;
  String _text = '';
  String mlModel = 'items';
  late FaceDetector _faceDetector;
  dynamic listName = [];
  late ObjectDetector _objectDetector;
  dynamic listNameTemp = [];
  dynamic faceInfo = [0, 0.0,'']; //count, confidence, smileFlag
  dynamic attention = 0.0;
  dynamic area = 0.0;
  dynamic fx = 0.0;
  dynamic fy = 0.0;
  dynamic fz = 0.0;
  dynamic distraction = 0.0;
  late List<DetectedObject> objects;
  var viewingSide = CameraLensDirection.front;
  List<String> pipeline = ['items','objects','faces'];
  var index =0;
  String view = '';


  @override
  void initState() {
    super.initState();
    modelInstances();
    processPipeline();
  }

  void modelInstances(){
    //face detection model
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );

    // items (in image) labelling model
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions(
        confidenceThreshold: 0.7,
    ));
    // object detection in images (returns 1 overall label)
    // uncomment next lines if you want to use the default model
    final objOptions = ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true);
    _objectDetector = ObjectDetector(options: objOptions);

    // uncomment next lines if you want to use a local model
    // make sure to add tflite model to assets/ml
    // final path = 'assets/ml/object_labeler.tflite';
    // final modelPath = await _getModel(path);
    // final options = LocalObjectDetectorOptions(
    //   mode: mode,
    //   modelPath: modelPath,
    //   classifyObjects: true,
    //   multipleObjects: true,
    // );
    // _objectDetector = ObjectDetector(options: options);

    // uncomment next lines if you want to use a remote model
    // make sure to add model to firebase
    // final modelName = 'bird-classifier';
    // final response =
    //     await FirebaseObjectDetectorModelManager().downloadModel(modelName);
    // print('Downloaded: $response');
    // final options = FirebaseObjectDetectorOptions(
    //   mode: mode,
    //   modelName: modelName,
    //   classifyObjects: true,
    //   multipleObjects: true,
    // );
    // _objectDetector = ObjectDetector(options: options);
  }

  void processPipeline() {
    const interval = Duration(seconds:2);
    Timer.periodic(interval, (Timer t) {
          if (index<pipeline.length){
            mlModel = pipeline[index];
            if (mlModel=='items') {
              viewingSide = CameraLensDirection.back;
              view = 'back';
            } else {
              viewingSide = CameraLensDirection.front;
              view = 'front';
            }
            _canProcess = true;
            index++;
          } else {
            index = 0;
            mlModel = pipeline[index];
            if (mlModel=='items') {
              viewingSide = CameraLensDirection.back;
              view = 'back';
            } else {
              viewingSide = CameraLensDirection.front;
              view = 'front';
            }
            _canProcess = true;
          }
    });
  }

  @override
  void dispose() {
    _canProcess = false;
    _imageLabeler.close();
    _objectDetector.close();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    switch(mlModel) {
      case "items": {
        return UserAttnView(
          title: 'Item Finder' + view,
          text: _text + view,
          labels: [["Objects Seen=>"], listName, ["Face Info=>"], faceInfo, ["Attention values=>"], attention, ["Distraction values=>"], distraction],
          onImage: processItems,
          initialDirection: viewingSide,
        );
      }
      break;

      case "objects": {
        return UserAttnView(
          title: 'Scene Labeler' + view,
          text: _text + view,
          labels: [["Objects Seen=>"], listName, ["Face Info=>"], faceInfo, ["Attention values=>"], attention, ["Distraction values=>"], distraction],
          onImage: (inputImage) {
            processImage(inputImage, mlModel);
          },
          initialDirection: viewingSide,
        );
      }
      break;

      case "faces": {
        return UserAttnView(
          title: 'Face Finder' + view,
          text: _text + view,
          labels: [["Objects Seen=>"], listName, ["Face Info=>"], faceInfo, ["Attention values=>"], attention, ["Distraction values=>"], distraction, ["Face values Area; angles - x ; y; x;=>\n"], area, ["\n"],fx, ["\n"],fy,["\n"],fz],
          onImage: (inputImage) {
            processImage(inputImage, mlModel);
          },
          initialDirection: viewingSide,
        );
      }
      break;

      default: {
        setState(() {
          viewingSide = CameraLensDirection.front;
        });
        return UserAttnView(
          title: 'Face Finder' + view,
          text: _text + view,
          labels: [["Objects Seen=>"], listName, ["Face Info=>"], faceInfo, ["Attention values=>"], attention, ["Distraction values=>"], distraction, ["Face values Area; angles - x ; y; x;=>\n"], area, ["\n"],fx, ["\n"],fy,["\n"],fz],
          onImage: (inputImage) {
            processImage(inputImage, mlModel);
          },
          initialDirection: viewingSide,
        );
      }
      break;
    }
  }


  Future<void> processItems(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final labels = await _imageLabeler.processImage(inputImage);
    String text = 'Labels found: ${labels.length}\n\n';
    for (final label in labels) {
      text += 'Label: ${label.label}, '
          'Confidence: ${label.confidence.toStringAsFixed(2)}\n\n';

      if(label.confidence>0.7){
        if(listName.contains(label.label)){
        } else {
          listName.add(label.label);
        }
      }
    }
    _text = text;
    print(_text);
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> processImage(InputImage inputImage, String mlMode) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });

    switch(mlMode) {
      case 'items': {
        final labels = await _imageLabeler.processImage(inputImage);
        //String text = 'Labels found: ${labels.length}\n\n';
        for (final label in labels) {
          // text += 'Label: ${label.label}, '
          //     'Confidence: ${label.confidence.toStringAsFixed(2)}\n\n';
          if(label.confidence>0.7){
            if(listName.contains(label.label)){
            } else {
              listName.add(label.label);
              distraction = distraction + listName.length + label.confidence.toDouble();
            }
          }
        }
        // _text = text;
        print(_text);
        _isBusy = false;
        if (mounted) {
          setState(() {});
        }
      }
      break;

      case 'objects': {
        objects = await _objectDetector.processImage(inputImage);
        for(final DetectedObject detectedObject in objects){
          for(final Label label in detectedObject.labels){
            print('${label.text} ${label.confidence}');
            if(listName.contains(label.text)){
            } else {
              listName.add(label.text);
              distraction = distraction + listName.length + label.confidence.toDouble();
            }
          }
        }
        // _text = text;
        print(_text);
        _isBusy = false;
        if (mounted) {
          setState(() {});
        }
      }
      break;

      case 'faces': {
        final faces = await _faceDetector.processImage(inputImage);
        //String text = 'Faces found: ${faces.length}\n\n';
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
      }
      break;

      default: {
        objects = await _objectDetector.processImage(inputImage);
        for(final DetectedObject detectedObject in objects){
          for(final Label label in detectedObject.labels){
            print('${label.text} ${label.confidence}');
            if(listName.contains(label.text)){
            } else {
              listName.add(label.text);
            }
          }
        }
        // _text = text;
        print(_text);
        _isBusy = false;
        if (mounted) {
          setState(() {});
        }
      }
      break;
    }
  }

  Future<String> _getModel(String assetPath) async {
    if (io.Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(dirname(path)).create(recursive: true);
    final file = io.File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }
}
