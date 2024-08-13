import 'dart:convert';
import 'package:http/http.dart' as http;

class STTClient {
  // token 有效期限 113/3/25 ~ 113/9/1
  final String token = "5FcW6E8HcOUNyRcfxFJe8H0J4AudU8wWqPGqka5gPmNTSWQwGGRfENaTCL8qyd8W";

  Future<String> askForService(String base64String, String language) async {

    Map<String, String> language2ServiceID = {
      "華語": "A017",
      "台語": "A018",
      "客語": "A020",
      "英語": "A021",
      "印尼語": "A022",
      "粵語": "A023"
    };

    final response = await http.post(
      Uri.parse('http://140.116.245.149:2802/asr'),
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        "audio_data": base64String,
        "token": token,
        "service_id": language2ServiceID[language]!,
        "audio_format": "wav",
        "mode": "General"
      }),
    );

    if (response.statusCode == 200) {
      print(response.statusCode.toString());
      Map<String, dynamic> resultMap = jsonDecode(response.body);
      String sentence = resultMap['words_list'][0].replaceAll(RegExp(r'\([^)]*\)'), "").replaceAll(" ", "");
      return sentence;
    } else {
      print(response.statusCode.toString());
      throw Exception('Failed to request server.');
    }
  }
}