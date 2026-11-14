class ALLThreads {
  GetAllThreadItems? getAllThreadItems;

  ALLThreads({this.getAllThreadItems});

  ALLThreads.fromJson(Map<String, dynamic> json) {
    getAllThreadItems = json['getAllThreadItems'] != null
        ? new GetAllThreadItems.fromJson(json['getAllThreadItems'])
        : null;
  }

}

class GetAllThreadItems {
  int? status;
  Null errorMessage;
  Result? result;
  int? count;

  GetAllThreadItems({this.status, this.errorMessage, this.result, this.count});

  GetAllThreadItems.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    errorMessage = json['errorMessage'];
    result =
        json['result'] != null ? new Result.fromJson(json['result']) : null;
    count = json['count'];
  }

}

class Result {
  List<ThreadItems>? threadItems;
  UserDetails? userDetails;
  int? currentPage;
  UserDetails? senderDetails;


  Result.fromJson(Map<String, dynamic> json) {
    if (json['threadItems'] != null) {
      threadItems = [];
      json['threadItems'].forEach((v) {
        threadItems?.add(new ThreadItems.fromJson(v));
      });
    }
    userDetails = json['userDetails'] != null
        ? new UserDetails.fromJson(json['userDetails'])
        : null;

    senderDetails = json['senderDetails'] != null
        ? new UserDetails.fromJson(json['senderDetails'])
        : null;
    currentPage = json['currentPage'];
  }

}

class ThreadItems {
  int? id;
  String? threadId;
  bool? isRead;
  String? authorId;
  String? userId;
  String? message;
  String? messageType;
  String? createdAt;
  int? voiceDuration;
  String? audioName;
  String? originalText;
  String? originalAudioLanguageCode;
  String? originalAudioLanguage;


  ThreadItems.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    threadId = json['threadId'];
    isRead = json['isRead'];
    authorId = json['authorId'];
    userId = json['userId'];
    message = json['message'];
    messageType = json["messageType"];
    createdAt = json['createdAt'];
    voiceDuration = json["voiceDuration"];
    audioName = json["audioName"];
    originalText = json["originalText"];
    originalAudioLanguageCode = json['originalAudioLanguageCode'];
    originalAudioLanguage = json['originalAudioLanguage'];
  }

}

class UserDetails {
  String? id;
  String? email;
  Profile? profile;


  UserDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    email = json['email'];
    profile =
        json['profile'] != null ? new Profile.fromJson(json['profile']) : null;
  }

}

class Profile {
  String? firstName;
  String? picture;
  String? aiPreferredLanguage;


  Profile.fromJson(Map<String, dynamic> json) {
    firstName = json['firstName'];
    picture = json['picture'];
    aiPreferredLanguage = json['aiPreferredLanguage'];
  }

}