import 'dart:developer';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:folder_file_saver/folder_file_saver.dart';
import 'package:path_provider/path_provider.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:smartchat/providers/textToImage_provider.dart';
import 'package:flutter/rendering.dart';
import '../constants/constants.dart';
import '../widgets/text_widget.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:core';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';

class TextToImageScreen extends StatefulWidget {
  const TextToImageScreen({super.key});

  @override
  State<TextToImageScreen> createState() => _TextToImageScreenState();
}

class _TextToImageScreenState extends State<TextToImageScreen> {
  bool _isTyping = false;
  late FocusNode focusNode;
  late TextEditingController textEditingController;
  late ScrollController _listScrollController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void scrollListToEND() {
    _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 2),
        curve: Curves.easeOut);
  }

  Future crateImage({required TextToImageProvider textToImageProvider}) async {
    if (_isTyping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "You cant send multiple messages at a time",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (textEditingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "Please type a message",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      String msg = textEditingController.text;
      setState(() {
        _isTyping = true;
        // chatList.add(ChatModel(msg: textEditingController.text, chatIndex: 0));

        textEditingController.clear();
        focusNode.unfocus();
      });
      await textToImageProvider.CreateImage(
        msg: msg,
      );

      setState(() {});
    } catch (error) {
      log("error $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: TextWidget(
          label: error.toString(),
        ),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        // scrollListToEND();
        _isTyping = false;
      });
    }
  }

  _requestPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();

    final info = statuses[Permission.storage].toString();
    print(info);
    _toastInfo(info);
  }

  String progress = "0";
  bool _isLoading = false;

  final Dio dio = Dio();

  final myCustomDir = 'My Custom Directory';

  void _saveImage({String? imageUrl}) async {
    try {
      // get status permission
      final status = await Permission.storage.status;

      // check status permission
      if (status.isDenied) {
        // request permission
        await Permission.storage.request();
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // do save
      await _doSaveImage(urlImage:imageUrl);
    } catch (e) {
      print(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Don't forget to check
  // device permission
  Future<void> _doSaveImage({String? urlImage}) async {
    final dir = await p.getTemporaryDirectory();
    final pathImage = dir.path +
        ('/your_image_named ${DateTime.now().millisecondsSinceEpoch}.png');
    await dio.download(urlImage!, pathImage, onReceiveProgress: (rec, total) {
      setState(() {
        progress = ((rec / total) * 100).toStringAsFixed(0) + "%";
      });
    });
    // if you want to get original of Image
    // don't give a value of width or height
    // cause default is return width = 0, height = 0
    // which will make it to get the original image
    // just write like this
    // remove originFile default = false
    final result = await FolderFileSaver.saveImage(
      pathImage: pathImage,
      removeOriginFile: true,
    );
    print(result);
  }

  @override
  Widget build(BuildContext context) {
    final imagesProvider = Provider.of<TextToImageProvider>(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
          child: Column(
        children: [

          Flexible(child: Consumer<TextToImageProvider>(
            // Set listen to false
            builder: (context, myData, _) {
              // This builder function will only be called once
              // and won't rebuild when MyDataProvider changes
              return ListView.builder(
                itemBuilder: (context, index) {
                  return Stack(
                    children: [

                      Image.network(myData.imagesList[index]["url"]),
                      ElevatedButton(
                        onPressed: ()async{
                          var response = await http.get(Uri.parse(myData.imagesList[index]["url"]));
                          Directory docDir = await getApplicationDocumentsDirectory();
                          File file =  File(path.join(docDir.path,path.basename(myData.imagesList[index]["url"])));
                          await file.writeAsBytes(response.bodyBytes);

                          showDialog(context: context, builder: (context)=>AlertDialog(title: Text("image saved"),content: Image.file(file),));
                 // _isLoading ? null : _saveImage(imageUrl:myData.imagesList[index]["url"]);
                  },
                        child: Text(_isLoading
                            ? 'Downloading $progress'
                            : 'Download Image and Resize'),
                      ),
                    ],
                  );
                },
                itemCount: imagesProvider.getImagesList.length,
              );
            },
          )),
          if (_isTyping) ...[
            const SpinKitThreeBounce(
              color: Colors.white,
              size: 18,
            ),
          ],
          const SizedBox(
            height: 15,
          ),
          Material(
            color: cardColor,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: focusNode,
                      style: const TextStyle(color: Colors.white),
                      controller: textEditingController,
                      onSubmitted: (value) async {},
                      decoration: const InputDecoration.collapsed(
                          hintText: "How can I help you",
                          hintStyle: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  IconButton(
                      onPressed: () async {
                       
                        crateImage(textToImageProvider: imagesProvider);
                      },
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ))
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }



  _toastInfo(String info) {
    Fluttertoast.showToast(msg: info, toastLength: Toast.LENGTH_LONG);
  }
}
