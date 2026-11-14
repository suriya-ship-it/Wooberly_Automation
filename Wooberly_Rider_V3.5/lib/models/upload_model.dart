class UploadModel {
  int? status;
  List<Files>? files;

  UploadModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
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

  Files(
      {this.fieldname,
        this.originalname,
        this.encoding,
        this.mimetype,
        this.destination,
        this.filename,
        this.path,
        this.size});

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