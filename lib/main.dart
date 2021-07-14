import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'widget/widget_to_picture.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  runApp(CameraApp());
}

class CameraApp extends StatefulWidget {
  @override
  _CameraAppState createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  CameraController? controller;
  bool _toggleCamera = false;
  bool filter = false;
  Color filterColor = Colors.red;
  GlobalKey? photoKey;
  Uint8List? pht;

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras![0], ResolutionPreset.max);
    _toggleCamera = false;
    filter = false;
    filterColor = Colors.red;
    pht = null;
    controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Widget largePreview() {
    if (!filter) {
      return WidgetToPicture(builder: (key) {
        // ignore: unnecessary_this
        this.photoKey = key;

        return CameraPreview(controller!);
      });
    } else {
      return WidgetToPicture(builder: (key) {
        // ignore: unnecessary_this
        this.photoKey = key;

        return ColorFiltered(
          colorFilter: ColorFilter.mode(filterColor, BlendMode.color),
          child: CameraPreview(controller!),
        );
      });
    }
  }

  Widget filterButton(Color? color) {
    return AspectRatio(
        aspectRatio: 1,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: () {
                  setState(() {
                    if (color != null) {
                      filter = true;
                      filterColor = color;
                    } else {
                      filter = false;
                    }
                  });
                },
                borderRadius: const BorderRadius.all(Radius.circular(40.0)),
                child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(40.0)),
                    child: color != null
                        ? ColorFiltered(
                            colorFilter:
                                ColorFilter.mode(color, BlendMode.darken),
                            child: CameraPreview(controller!))
                        : CameraPreview(controller!)))));
  }

  @override
  Widget build(BuildContext context) {
    if (controller != null) {
      if (!controller!.value.isInitialized) {
        return Container();
      }
      return MaterialApp(
          home: AspectRatio(
        aspectRatio: controller!.value.aspectRatio,
        child: Container(
          padding: const EdgeInsets.all(0),
          child: Stack(
            children: [
              largePreview(),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: 200.0,
                  padding: const EdgeInsets.all(5.0),
                  color: const Color.fromRGBO(0, 0, 0, 0.7),
                  child: Stack(
                    children: [
                      Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: 80.0,
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 10.0,
                                ),
                                filterButton(null),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                filterButton(Colors.red),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                filterButton(Colors.green),
                                const SizedBox(
                                  width: 10.0,
                                ),
                                filterButton(Colors.blue),
                                const SizedBox(
                                  width: 10.0,
                                ),
                              ],
                            ),
                          )),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(50.0)),
                            onTap: () async {
                              // final image = await capture(photoKey);
                              // saveFile(image);
                              final image = await controller!.takePicture();
                              setState(() async {
                                pht = await image.readAsBytes();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10.0),
                              child: Image.asset(
                                "assets/images/ic_shutter.png",
                                width: 72.0,
                                height: 72.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Container(
                          height: 72,
                          width: 72,
                          padding: const EdgeInsets.all(10.0),
                          child: pht != null
                              ? Image.memory(pht!)
                              : Image.asset(
                                  "assets/images/ic_shutter.png",
                                ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(50.0)),
                            onTap: () {
                              if (!_toggleCamera) {
                                onCameraSelected(cameras![1]);

                                setState(() {
                                  _toggleCamera = true;
                                });
                              } else {
                                onCameraSelected(cameras![0]);

                                setState(() {
                                  _toggleCamera = false;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10.0),
                              child: Image.asset(
                                "assets/images/ic_switch_camera.png",
                                width: 72.0,
                                height: 72.0,
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ));
    }
    return Container();
  }

  Future<Uint8List?> capture(GlobalKey? key) async {
    if (key == null) return null;

    RenderRepaintBoundary boundary =
        photoKey!.currentContext?.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    return pngBytes;
  }

  Future<String> getFilePath(String filename) async {
    Directory? appDocDir = await getDownloadsDirectory();
    String appDocumentsPath = appDocDir!.path;
    String filePath = '$appDocumentsPath/$filename';

    return filePath;
  }

  void saveFile(Uint8List? photo) async {
    var now = DateTime.now();
    File file = File(await getFilePath('${now.toIso8601String()}.png'));
    if (photo != null) {
      file.writeAsBytes(photo);
    } else {
      showMessage('message');
    }
  }

  void onCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller!.dispose();
    }

    controller = CameraController(cameraDescription, ResolutionPreset.medium);

    controller!.addListener(() {
      if (mounted) setState(() {});
      if (controller!.value.hasError) {
        showMessage('Camera Error: ${controller!.value.errorDescription}');
      }
    });

    try {
      await controller!.initialize();
    } on CameraException catch (e) {
      showMessage(e.description.toString());
    }

    if (mounted) setState(() {});
  }

  void showMessage(String message) {
    print(message);
  }
}
