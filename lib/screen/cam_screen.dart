import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:video_call/const/apiKey.dart';  // API Key < .gitignore에 기술

class CamScreen extends StatefulWidget {
  const CamScreen({Key? key}) : super(key: key);

  @override
  _CamScreenState createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {
  RtcEngine? engine; // Agora 엔진을 저장할 변수
  int? uid; // 내  ID
  int? otherUid; // 상대방 ID

  Future<bool> init() async {
    final resp = await [Permission.camera, Permission.microphone].request();

    final cameraPermission = resp[Permission.camera];
    final micPermission = resp[Permission.microphone];

    if (cameraPermission != PermissionStatus.granted ||
        micPermission != PermissionStatus.granted) {
      throw '카메라 또는 마이크 권한이 없습니다.';
    }

    if (engine == null) {
      // 엔진이 정의되어 있지 않으면
      engine = createAgoraRtcEngine();

      await engine!.initialize(
        // 아고라 엔진을 초기화 합니다.
        RtcEngineContext(
          appId: APP_ID,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      engine!.registerEventHandler(RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        print('채널에 입장했습니다. uid : ${connection.localUid}');
        setState(() {
          this.uid = connection.localUid;
        });
      }, onLeaveChannel: (RtcConnection connection, RtcStats stats) {
        print('채널 퇴장');
        setState(() {
          uid = null;
        });
      }, onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        print('상대차 채널에 입장했습니다. uid : $remoteUid');
        setState(() {});
      }, onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
        print('상대가 채널에서 나갔습니다. uid : $uid');
        setState(() {
          otherUid = null;
        });
      }));

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
            if (snapshot.hasError) {
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

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      renderMainView(),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          color: Colors.grey,
                          height: 160,
                          width: 120,
                          child: renderSubView(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (engine != null) {
                        await engine!.leaveChannel();
                      }

                      Navigator.of(context).pop();
                    },
                    child: Text('채널 나가기'),
                  ),
                ),
              ],
            );
          }),
    );
  }

  Widget renderSubView() {
    if (uid != null) {
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: engine!,
          canvas: const VideoCanvas(uid: 0),
        ),
      );
    } else {
      return CircularProgressIndicator();
    }
  }

  Widget renderMainView() {
    if (otherUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: engine!,
          canvas: VideoCanvas(uid: otherUid),
          connection: const RtcConnection(channelId: CHANNEL_NAME),
        ),
      );
    } else {
      return Center(
        child: const Text(
          '다른 사용자가 입장할 때까지 대기해 주세요',
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}

