class UploadModel {
  int? status;
  List<Files>? files;
  String? fileName;


  UploadModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    fileName=json['fileName'];
    if (json['files'] != null) {
      files = [];
      json['files'].forEach((v) {
        files?.add(new Files.fromJson(v));
      });
    }
  }

}

class Files {
  String? fieldname;
  String? originalname;
  String? encoding;
  String? mimetype;
  String? destination;
  String? filename;
  String? path;
  int? size;


  Files.fromJson(Map<String, dynamic> json) {
    fieldname = json['fieldname'];
    originalname = json['originalname'];
    encoding = json['encoding'];
    mimetype = json['mimetype'];
    destination = json['destination'];
    filename = json['filename'];
    path = json['path'];
    size = json['size'];
  }

}