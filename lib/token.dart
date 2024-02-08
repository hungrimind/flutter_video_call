import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter_video_call/consts.dart";
import "package:http/http.dart";

Future<String> fetchToken(int uid, String channelName) async {
  String url = '$tokenUrl/rtc/$channelName/1/uid/${uid.toString()}?expiry=45';

  final response = await get(Uri.parse(url));

  if (response.statusCode == 200) {
    Map<String, dynamic> json = jsonDecode(response.body);
    String newToken = json['rtcToken'];
    debugPrint('Token Received: $newToken');
    return newToken;
  } else {
    throw Exception(
        'Failed to fetch a token. Make sure that your server URL is valid');
  }
}
