import 'package:flutter/material.dart';

import '../services/api_service.dart';

class TextToImageProvider extends ChangeNotifier {
  List imagesList = [];
  List get getImagesList {
    return imagesList;
  }

  Future CreateImage({required String msg}) async {
    var result = await ApiService.createImage(msg: msg);
    print("------------------- ${result}");

    imagesList.add(result["data"][0]);
    notifyListeners();
  }
}
