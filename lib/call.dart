import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_call/buttons.dart';
import 'package:flutter_video_call/consts.dart';
import 'package:permission_handler/permission_handler.dart';

class Call extends StatefulWidget {
  final String roomName;
  const Call({Key? key, required this.roomName}) : super(key: key);

  @override
  State<Call> createState() => _CallState();
}

class _CallState extends State<Call> {
  final List<int> _remoteUsers = [];
  int? _localUser;
  late final RtcEngine _engine = createAgoraRtcEngine();

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUser = connection.localUid;
          });
        },
        onError: (ErrorCodeType code, String message) {
          debugPrint("onError $code $message");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error: $code, $message"),
            ),
          );
          Navigator.pop(context);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUsers.add(remoteUid);
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUsers.remove(remoteUid);
          });
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: token,
      channelId: widget.roomName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    super.dispose();

    _dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  Widget _callLayout(int remoteUserCount) {
    switch (remoteUserCount) {
      case 0:
        return _localUser != null
            ? Stack(
                children: [
                  AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine,
                      canvas: const VideoCanvas(
                        uid: 0,
                      ),
                    ),
                  ),
                  CallButtons(engine: _engine),
                ],
              )
            : const Center(child: CircularProgressIndicator());
      case 1:
        return Stack(
          children: [
            remoteVideo(_remoteUsers[0]),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  width: 100,
                  height: 150,
                  child: Center(
                    child: _localUser != null
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: _engine,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : const CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
            CallButtons(engine: _engine),
          ],
        );
      case 2:
        return Stack(
          children: [
            Column(
              children: [
                Expanded(child: remoteVideo(_remoteUsers[0])),
                Expanded(child: remoteVideo(_remoteUsers[1])),
              ],
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  width: 100,
                  height: 150,
                  child: Center(
                    child: _localUser != null
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: _engine,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : const CircularProgressIndicator(),
                  ),
                ),
              ),
            ),
            CallButtons(engine: _engine),
          ],
        );
      default:
        return const Center(
          child: Text("This app supports up to 3 people in a call"),
        );
    }
  }

  // Create UI with local view and remote view
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _callLayout(_remoteUsers.length),
    );
  }

  Widget remoteVideo(int remoteUid) {
    return AgoraVideoView(
      controller: VideoViewController.remote(
        rtcEngine: _engine,
        canvas: VideoCanvas(
          uid: remoteUid,
        ),
        connection: RtcConnection(channelId: widget.roomName),
      ),
    );
  }
}
