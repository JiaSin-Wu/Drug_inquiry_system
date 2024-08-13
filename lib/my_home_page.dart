import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:number_paginator/number_paginator.dart';
import 'drug_information_page.dart';
import 'favorite_page.dart';
import 'API/STT.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';


// StatefulWidget
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

// Extend State
class _MyHomePageState extends State<MyHomePage> {
  int pageIndex = 0;
  int pagesElementNumber = 10;
  int total = 0;
  String keyWord = "";

  //favorite drugs
  List<int> favoriteDrugNames = [];

  //record initialization
  AudioEncoder encoder = AudioEncoder.wav;
  bool isRecord = false;
  String speechRecognitionAudioPath = "";
  bool isNeedSendSpeechRecognition = false;
  String base64String = "";
  final TextEditingController _textController = TextEditingController();

  // Load data
  Future<Map<String, dynamic>> loadData() async {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3009/get_drug_list'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(<String, String>{
        'keyWord': keyWord,
        'start': ((pageIndex) * pagesElementNumber).toString(),
        'end': ((pageIndex + 1) * pagesElementNumber - 1).toString(),
      }),
    );
    late dynamic data;

    if (response.statusCode == 200) {
      // Successful response
      data = json.decode(response.body)["data"];
      total = json.decode(response.body)["length"];
      log('Received data from Flask backend: $data');
    } else {
      // Error handling for unsuccessful response
      log('Failed to fetch data. Status code: ${response.statusCode}');
    }
    log('Received favorite drug IDs: $favoriteDrugNames');
    return {"data": data};
  }

  //record
  Future<String> askForService(String base64String, String language) async {
    try {
      // Assuming STTClient().askForService is a method that makes an HTTP request
      final response = await STTClient().askForService(base64String, language);
      // print('Response: $response');
      return response;
    } catch (e, stacktrace) {
      print('Error in askForService: $e');
      print('Stacktrace: $stacktrace');
      throw Exception('Failed to request server');
    }
  }

  Future<void> _startRecording() async {
    final record = Record();

    if (await record.hasPermission()) {
      Directory tempDir = await getTemporaryDirectory();
      speechRecognitionAudioPath = '${tempDir.path}/record.wav';

      await record.start(
        numChannels: 1,
        path: speechRecognitionAudioPath,
        encoder: encoder,
        bitRate: 128000,
        samplingRate: 16000,
      );

      setState(() {
        isRecord = true;
        isNeedSendSpeechRecognition = false;
      });
    } else {
      debugPrint("沒有錄音權限");
    }
  }

// Method to stop recording
  Future<void> _stopRecording() async {
    final record = Record();

    await record.stop();
    record.dispose();

    List<int> audioBytes = File(speechRecognitionAudioPath).readAsBytesSync();
    setState(() {
      base64String = base64Encode(audioBytes);
      isRecord = false;
      isNeedSendSpeechRecognition = true;
    });
  }

  // Simplified onPressed callback
  void _onMicButtonPressed() async {
    if (isRecord) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  //record
  @override
  void initState() {
    super.initState();
    // 根據設備決定錄音的 encoder
    if (Platform.isIOS) {
      encoder = AudioEncoder.pcm16bit;
    } else {
      encoder = AudioEncoder.wav;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        title: Row(
          children: [
            Text(widget.title),
            const Spacer(),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FavoritePage(
                      favoriteDrugNames: favoriteDrugNames,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.favorite, color: Colors.red),
            ),
          ],
        ),
      ),
      body: FutureBuilder(
        future: loadData(),
        builder: (BuildContext context, AsyncSnapshot<Map<String, dynamic>> snapshot) {
          if (snapshot.hasData) {
            // Get the data from the snapshot
            final data = snapshot.data;
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        // controller: _textController,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          prefixIcon: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(35, 35), // Adjust the size as needed
                              shape: CircleBorder(
                                side: BorderSide(
                                  width: 4.0,
                                  color: isRecord ? Colors.red : Colors.blue,
                                ),
                              ),
                            ),
                            onPressed: _onMicButtonPressed,
                            child: isRecord
                                ? const Icon(Icons.stop, color: Colors.red)
                                : const Icon(Icons.mic, color: Colors.blue),
                          ),
                        ),
                        onChanged: (value) {
                          pageIndex = 0;
                          keyWord = value;
                          if(keyWord==""){
                            setState(() {

                            });
                          }
                        },
                      ),
                    ),
                    if (isNeedSendSpeechRecognition)
                      FutureBuilder(
                        future: askForService(base64String, "華語"),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(
                              height: 50,
                              width: 50,
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            const errorText = '辨識失敗';
                            _textController.text = errorText;
                            _textController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _textController.text.length),
                            );
                            isNeedSendSpeechRecognition = false;
                            return const SizedBox(); // Return empty widget as we're updating the TextField
                          } else if (snapshot.hasData) {
                            final sentence = snapshot.data.toString();
                            _textController.text = sentence;
                            _textController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _textController.text.length),
                            );
                            isNeedSendSpeechRecognition = false;
                            return const SizedBox(); // Return empty widget as we're updating the TextField
                          }
                          return const SizedBox(); // Handle any unexpected state with an empty widget
                        },
                      ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          // Trigger a refresh or other action when search is pressed
                        });
                      },
                      icon: const Icon(Icons.search),
                    ),
                  ],
                ),
                Expanded(
                  // Dynamic show the drug list
                  child: ListView.builder(
                    itemCount: data!["data"].length,
                    itemBuilder: (BuildContext context, int index) {
                      String imgSrc = "";
                      String? imageLink = data["data"][index]["image_link"].toString();
                      if (imageLink != "") {
                        imgSrc = imageLink;
                      } else {
                        imgSrc = "https://cyberdefender.hk/wp-content/uploads/2021/07/404-01-scaled.jpg";
                      }

                      // ListTile show the drug info
                      return GestureDetector(
                        onTap: () async {
                          final updatedFavoriteList = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DrugInformationPage(
                                data: data['data'][index],
                                imgSrc: imgSrc,
                                favoriteDrugNames: List<int>.from(favoriteDrugNames), // Pass a copy of the list
                              ),
                            ),
                          );
                          log(updatedFavoriteList);
                          if (updatedFavoriteList != null) {
                            setState(() {
                              favoriteDrugNames = updatedFavoriteList;
                            });
                          }
                        },
                        child: Card(
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    int drugId = data["data"][index]['id'];
                                    if (favoriteDrugNames.contains(drugId)) {
                                      favoriteDrugNames.remove(drugId);
                                    } else {
                                      favoriteDrugNames.add(drugId);
                                    }
                                    log(favoriteDrugNames.toString());
                                  });
                                },
                                icon: favoriteDrugNames.contains(data["data"][index]['id'])
                                    ? const Icon(Icons.favorite, color: Colors.red)
                                    : const Icon(Icons.favorite_border),
                              ),
                              Expanded(
                                child: ListTile(
                                  title: Text(data["data"][index]["chinese_name"].toString()),
                                  subtitle: Text(data["data"][index]["indication"].toString()),
                                ),
                              ),
                              Image.network(
                                imgSrc,
                                width: 100,
                                height: 100,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                NumberPaginator(
                  numberPages: (total / 50).ceil(),
                  onPageChange: (int index) {
                    setState(() {
                      pageIndex = index;
                    });
                  },
                  config: const NumberPaginatorUIConfig(
                    height: 54.0,
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return const CircularProgressIndicator();
          }
        },
      ),
    );
  }
}
