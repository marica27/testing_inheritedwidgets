import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:instagram/instagram.dart';

import 'package:http/http.dart' as http;
import 'constants.dart';
import 'dart:convert';

class UserAndMedia {
  User user;
  List<Media> media;
  UserAndMedia(this.user, this.media);
  
  void makeBigMedia() {
    int length = 3000;
    List<Media> bigMedia = new List<Media>();
    for (int i = 0, j=0; i < length;  i++, j = i % media.length) {
      Media m = new Media(id: media[j].id,
          type: media[j].type,
          filter: media[j].filter,
          link: media[j].link,
          caption: media[j].caption,
          usersInPhoto: media[j].usersInPhoto,
          tags: media[j].tags,
          comments: media[j].comments,
          likes: media[j].likes,
          user: media[j].user,
          location: media[j].location,
          images: media[j].images,
          videos: media[j].videos,
          userHasLiked: media[j].userHasLiked,
          carouselMedia: media[j].carouselMedia,
          createdTime: new DateTime.now().subtract(new Duration(hours: i)));
      bigMedia.add(m);
    }
    this.media = bigMedia;
  }
}

class AuthService {
  static final AuthService _authService = new AuthService._internal();

  AuthService._internal();

  static AuthService get() {
    return _authService;
  }

  factory AuthService() {
    return _authService;
  }

  static const accessTokenKey = "acess_token";
  static const userKey = "user";

  InstagramApi _api;

  Future<String> getUsername() async {
    User user = await getUser();
    return user.username;
  }

  //Is it a good idea to have this logic here?
  //or put it to AsyncGridPage
  Future<User> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    String json = await prefs.getString(userKey);
    if (json != null) {
      var map = JSON.decoder.convert(json);
      User user = new User.fromJson(map);
      return user;
    } else if (_api != null) {
      User user = await _api.users.self.get();
      keepUser(user);
      return user;
    }
    return null;
  }

  Future<Null> keepToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(accessTokenKey, accessToken);
  }

  Future<Null> keepUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    String json = JSON.encoder.convert(user.toJson());
    prefs.setString(userKey, json);
  }


  // Login
  // if accessToken saved on device then return true
  // if no accessToken then proceed with authentification
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    var accessToken = prefs.getString(accessTokenKey);

    if (accessToken == null) {
      return false;
    }
    print("login: access token from disk");
    initialise(accessToken);
    return true;
  }

  void initialise(String accessToken) {
    _api = InstagramApiAuth.authorizeViaAccessToken(
        accessToken, new http.Client());
  }

  Uri getLoginUrl() {
    var auth = new InstagramApiAuth(Constants.clientId, Constants.clientSecret,
        redirectUri: Uri.parse(Constants.redirectUri),
        scopes: [
          InstagramApiScope.basic,
          InstagramApiScope.publicContent,
        ]);

    Uri igRedirectUri = auth.getImplicitRedirectUri();

    return igRedirectUri;
  }

  // Logout
  Future logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(accessTokenKey);
    _api = null;
    print("logout: access token removed");
  }

   Future<Media> getMediaById(String mediaId) {
     return _api.media.getById(mediaId);
   }


  Future<List<Media>> getMedia({int count = 20, String nextId}) {
    return _api.users.self.getRecentMedia(count: count, maxId: nextId);
  }

  Future<UserAndMedia> getUserAndMedia() async {
    //await new Future.delayed(new Duration(seconds: 2));
    return Future.wait([
      _api.users.self.get(),
      _api.users.self.getRecentMedia(count: 20)
    ]).then((List responses) {
      var userAndMedia = new UserAndMedia(responses[0], responses[1]);
      userAndMedia.makeBigMedia();
      return userAndMedia;

      //: new UserAndMedia(responses[1], responses[0]);
    }); //.catchError((e) => handleError(e));
  }
}
