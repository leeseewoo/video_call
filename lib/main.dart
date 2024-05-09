import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

late List<CameraDescription> _cameras;

Future<void> main() async {
  // 1) Flutter 앱이 실핼될 준비가 되었는지 확인
  WidgetsFlutterBinding.ensureInitialized();

  // 2) 핸드폰에 있는 카메라를 가져오기
  _cameras = await availableCameras();
  runApp(const CameraApp());
}

class CameraApp extends StatefulWidget {
  const CameraApp({Key? key}) : super(key: key);

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {

  late CameraController controller;

  @override
  void initState() {
    super.initState();

    initializeCamera();
  }

  initializeCamera() async {
    try{
      controller = CameraController( _cameras[0], ResolutionPreset.max);

      await controller.initialize();

      setState(() {

      });
    } catch (e) {

      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('User denied camera access');
            break;
          default:
            print('Handle other errors.');
            break;
        }
      }
    }
  }

  @override
  void dispose() {

    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (!controller.value.isInitialized) {
      return Container();
    }
    return MaterialApp(
      home: CameraPreview(controller),
    );
  }
}
