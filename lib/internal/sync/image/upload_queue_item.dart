import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:mobx/mobx.dart';
import 'package:potato_notes/data/model/saved_image.dart';
import 'package:potato_notes/internal/locales/locales.g.dart';
import 'package:potato_notes/internal/providers.dart';
import 'package:potato_notes/internal/sync/image/queue_item.dart';
import 'package:worker_manager/worker_manager.dart';

import 'image_helper.dart';

class UploadQueueItem extends QueueItem {
  final String noteId;
  final String localPath;
  final SavedImage savedImage;
  final StorageLocation storageLocation;

  @observable
  double? uploadStatus;

  UploadQueueItem({
    required this.noteId,
    required this.localPath,
    required this.savedImage,
    this.storageLocation = StorageLocation.LOCAL,
  }) : super(
      localPath: localPath,
      savedImage: savedImage);

  @action
  Future<void> process(String tempDirectory) async {
    status = QueueItemStatus.ONGOING;
    Uint8List rawBytes = await File(localPath).readAsBytes();
    print("Hashing image");
    savedImage.hash = await Executor()
        .execute(fun1: ImageHelper.generateImageHash, arg1: rawBytes);
    print("Resizing image");
    Image compressedImage = await Executor()
        .execute(fun1: ImageHelper.compressImage, arg1: rawBytes);
    print("generating blurhash");
    String blurHash = ImageHelper.generateBlurHash(await Executor()
        .execute(fun1: ImageHelper.compressForBlur, arg1: compressedImage));
    savedImage.blurHash = blurHash;
    print("Saving image");
    File imageFile = await ImageHelper.saveImage(
        compressedImage, tempDirectory + "/${savedImage.hash}.jpg");
    return;
  }

  @action
  Future<Response> uploadImage({
    Map<String, dynamic> headers = const {},
  }) async {
    status = QueueItemStatus.ONGOING;
    var url = await getUploadUrl();
    var response = await Dio().request(
      await getUploadUrl(),
      data: File(localPath).openRead(),
      onSendProgress: (count, total) {
        uploadStatus = count / total;
        print(uploadStatus);
      },
      options: Options(
        method:
            savedImage.storageLocation == StorageLocation.SYNC ? "PUT" : "POST",
        headers: headers
          ..putIfAbsent(HttpHeaders.contentLengthHeader,
              () => File(localPath).lengthSync().toString()),
      ),
    );
    print(response.data);
    status = QueueItemStatus.COMPLETE;
    savedImage.uploaded = true;
    return response;
  }

  Future<String> getUploadUrl() async {
    switch (savedImage.storageLocation) {
      case StorageLocation.IMGUR:
        {
          return 'https://api.imgur.com/3/image';
        }
      case StorageLocation.SYNC:
        {
          String? token = await prefs.getToken();
          print(token);
          var url = "${prefs.apiUrl}/files/put/${savedImage.hash}.jpg";
          Response presign = await Dio().get(url,
              options: Options(
                headers: {"Authorization": "Bearer $token"},
              ));
          if (presign.statusCode == 200) {
            return presign.data;
          } else {
            throw presign.data;
          }
        }
      case StorageLocation.LOCAL:
        throw "Local images should not be uploaded";
    }
  }
}
