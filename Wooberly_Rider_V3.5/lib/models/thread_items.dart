class ALLThreads {
  GetAllThreadItems? getAllThreadItems;

  ALLThreads.fromJson(Map<String, dynamic> json) {
    getAllThreadItems = json['getAllThreadItems'] != null
        ? new GetAllThreadItems.fromJson(json['getAllThreadItems'])
        : null;
  }

}

class GetAllThreadItems {
  int? status;
  String? errorMessage;
  Result? result;
  int? count;

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
    currentPage = json['currentPage'];
  }
}

class ThreadItems {
  int? id;
  String? threadId;
  bool? isRead;
  String? audioName;
  String? authorId;
  String? userId;
  String? message;
  String? originalText;
  String? messageType;
  int? voiceDuration;
  String? createdAt;
  String? originalAudioLanguageCode;
  String? originalAudioLanguage;



  ThreadItems.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    threadId = json['threadId'];
    isRead = json['isRead'];
    authorId = json['authorId'];
    userId = json['userId'];
    message = json['message'];
    originalText = json['originalText'];
    audioName = json['audioName'];
    messageType = json['messageType'];
    voiceDuration = json['voiceDuration'];
    createdAt = json['createdAt'];
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