import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:video_call/const/apiKey.dart';


class CamScreen extends StatefulWidget {
  const CamScreen({Key? key}) : super(key: key);

  @override
  _CamScreenState createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {

  RtcEngine? engine;    // Agora 엔진을 저장할 변수
  int? uid;             // 내  ID
  int? otherUid;        // 상대방 ID

  Future<bool> init() async {
    final resp = await [Permission.camera, Permission.microphone].request();

    final cameraPermission = resp[Permission.camera];
    final micPermission = resp[Permission.microphone];

    if (cameraPermission != PermissionStatus.granted ||
        micPermission != PermissionStatus.granted) {
      throw '카메라 또는 마이크 권한이 없습니다.';
    }

    if (engine == null) { // 엔진이 정의되어 있지 않으면
      engine = createAgoraRtcEngine();


      await engine!.initialize( // 아고라 엔진을 초기화 합니다.
        RtcEngineContext(
          appId: APP_ID,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      engine!.registerEventHandler(

          RtcEngineEventHandler(
              onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
                print('채널에 입장했습니다. uid : ${connection.localUid}');
                setState(() {
                  this.uid = connection.localUid;
                });
              },
              onLeaveChannel: (RtcConnection connection, RtcStats stats) {
                print('채널 퇴장');
                setState(() {
                uid = null;
                });
              },
              onUserJoined: (RtcConnection connection, int remoteUid,
                  int elapsed) {
                print('상대차 채널에 입장했습니다. uid : $remoteUid');
                setState(() {

                });
              },
              onUserOffline: (RtcConnection connection, int remoteUid,
                  UserOfflineReasonType reason) {
                print('상대가 채널에서 나갔습니다. uid : $uid');
                setState(() {
                  otherUid = null;
                });
              }
          )
      );


      await engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine!.enableVideo();
      await engine!.startPreview();

      await engine!.joinChannel(
          token: TEMP_TOKEN,
          channelId: CHANNEL_NAME,
          uid: 0,
          options: ChannelMediaOptions(),
      );

    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LIVE'),
      ),
      body: FutureBuilder(
          future: init(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
           if(snapshot.hasError) {
             return Center(
               child: Text(
                 snapshot.error.toString(),
               ),
             );
           }

           if (!snapshot.hasData) {
             return Center(
               child: CircularProgressIndicator(),
             );
           }

           return Center(
             child: Text('모든 권한이 있습니다.'),
           );
          }
      ),
   );
  }
}