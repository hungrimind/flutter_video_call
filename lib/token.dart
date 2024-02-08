import "dart:convert";

import "package:flutter_video_call/consts.dart";
import "package:http/http.dart";

Future<String> fetchToken(int uid, String channelName) async {
  String url =
      '$tokenUrl/rtc/$channelName/publisher/uid/${uid.toString()}?expiry=45';

  final response = await get(Uri.parse(url));

  if (response.statusCode == 200) {
    Map<String, dynamic> json = jsonDecode(response.body);
    return json['rtcToken'];
  } else {
    throw Exception(
        'Failed to fetch a token. Make sure that your server URL is valid');
  }
}
