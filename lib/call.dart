import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_video_call/buttons.dart';
import 'package:flutter_video_call/consts.dart';
import 'package:flutter_video_call/token.dart';
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
  final RtcEngine _engine = createAgoraRtcEngine();

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  @override
  void dispose() {
    super.dispose();
    disposeAgora();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          switch (_remoteUsers.length) {
            0 => localVideo(),
            1 => Stack(
                children: [
                  remoteVideo(_remoteUsers[0]),
                  miniLocalVideo(),
                ],
              ),
            2 => Stack(
                children: [
                  Column(
                    children: [
                      Expanded(child: remoteVideo(_remoteUsers[0])),
                      Expanded(child: remoteVideo(_remoteUsers[1])),
                    ],
                  ),
                  miniLocalVideo(),
                ],
              ),
            _ => const Center(
                child: Text("This app supports up to 3 people in a call"),
              ),
          },
          CallButtons(engine: _engine)
        ],
      ),
    );
  }

  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();

    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUser = connection.localUid;
          });
        },
        onError: (ErrorCodeType code, String message) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $code, $message")),
          );
          Navigator.pop(context);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUsers.add(remoteUid);
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUsers.remove(remoteUid);
          });
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          renewToken();
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();

    await _engine.joinChannel(
      token: await fetchToken(0, widget.roomName),
      channelId: widget.roomName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  Future<void> disposeAgora() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  Future<void> renewToken() async {
    String token = await fetchToken(0, widget.roomName);
    _engine.renewToken(token);
  }

  Widget miniLocalVideo() {
    return SafeArea(
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
          child: localVideo(),
        ),
      ),
    );
  }

  Widget localVideo() {
    return _localUser != null
        ? AgoraVideoView(
            controller: VideoViewController(
              rtcEngine: _engine,
              canvas: const VideoCanvas(uid: 0),
            ),
          )
        : const Center(child: CircularProgressIndicator());
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
