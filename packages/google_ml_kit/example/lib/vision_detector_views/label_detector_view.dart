import 'dart:async';
import 'dart:io' as io;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'attention_view.dart';
import 'camera_view.dart';
import 'painters/item_detector_painter.dart';

class ImageLabelView extends StatefulWidget {
  @override
  State<ImageLabelView> createState() => _ImageLabelViewState();
}

class _ImageLabelViewState extends State<ImageLabelView> {
  late ImageLabeler _imageLabeler;
  bool _canProcess = false;
  bool _isBusy = false;
  String? _text;
  var camDirection = CameraLensDirection.back;
  dynamic listName = [];
  CustomPaint? _customPaint;

  @override
  void initState() {
    super.initState();
    _initializeLabeler();
    Timer(const Duration(seconds: 5), () {
      setState(() {
        camDirection = CameraLensDirection.front;
      });
      //_initializeLabeler();
    });
  }

  @override
  void dispose() {
    _canProcess = false;
    _imageLabeler.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UserAttnView(
      title: 'Image Labeler',
      text: _text,
      labels: listName,
      onImage: processImage,
      initialDirection: camDirection,
    );
  }

  void _initializeLabeler() async {
    // uncomment next line if you want to use the default model
    _imageLabeler = ImageLabeler(options: ImageLabelerOptions(
      confidenceThreshold: 0.9
    ));

    // uncomment next lines if you want to use a local model
    // make sure to add tflite model to assets/ml
    // final path = 'assets/ml/lite-model_aiy_vision_classifier_birds_V1_3.tflite';
    // final path = 'assets/ml/object_labeler.tflite';
    // final modelPath = await _getModel(path);
    // final options = LocalLabelerOptions(modelPath: modelPath);
    // _imageLabeler = ImageLabeler(options: options);

    // uncomment next lines if you want to use a remote model
    // make sure to add model to firebase
    // final modelName = 'bird-classifier';
    // final response =
    //     await FirebaseImageLabelerModelManager().downloadModel(modelName);
    // print('Downloaded: $response');
    // final options =
    //     FirebaseLabelerOption(confidenceThreshold: 0.5, modelName: modelName);
    // _imageLabeler = ImageLabeler(options: options);

    _canProcess = true;
  }

  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    // if (inputImage.inputImageData?.size != null &&
    //     inputImage.inputImageData?.imageRotation != null) {
    //   //final painter = LabelDetectorPainter(labels);
    //   //_customPaint = CustomPaint(painter: painter);
    // } else {
    // String text = 'Labels found: ${labels.length}\n\n';
    // for (final label in labels) {
    //   text += 'Label: ${label.label}, '
    //       'Confidence: ${label.confidence.toStringAsFixed(2)}\n\n';
    //
    //   if(label.confidence>0.7){
    //     if(listName.contains(label.label)){
    //     } else {
    //       listName.add(label.label);
    //     }
    //   }
    //   _text = text;
    //   _customPaint = null;
    // }
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
