import 'dart:async';
import 'package:get/get.dart';
import 'package:app_name/app/app.dart';
import 'package:app_name/graphql/graphql_config.dart';
import 'package:app_name/utils/globals.dart' as globals;

import '../utils/globals.dart' as globals;
import 'base_controller.dart';

class StaticPageController extends BaseController{
  Future<String> getStaticPageContent(int staticPageContentId) async {
    try {
      graphQlObject.graphQLClientWithHeader.cache.store.reset();
      var variables = <String, dynamic>{"id": staticPageContentId};
      Map<String, dynamic>? result = await graphQlObject.getQueryValues(
          graphQlObject.graphQLClient, "getStaticPageContent", variables);
      globals.setButtonIdle();
      if (result?["getStaticPageContent"]["status"] == 200) {
        if (result?["getStaticPageContent"]["result"]["pageContent"] != null) {
          String content = "";
          final List<dynamic> response = result?["getStaticPageContent"]["result"]["pageContent"];
          for(final item in response){
            if(item["language"] == globals.preferredLanguage){
              if(item["content"] != null){
                content = item["content"];
              } else{
                content = result?["getStaticPageContent"]["result"]["content"];
              }
            }
          }
          if(content.isEmpty){
            content = result?["getStaticPageContent"]["result"]["content"];
          }
          return content;
        }
        else if(result?["getStaticPageContent"]["result"]["content"] != null) {
          return result?["getStaticPageContent"]["result"]["content"];
        }
        else {
          return "<p><strong>Privacy Policy</strong></p>";
        }
      } else if (result?["getStaticPageContent"]["status"] == 400) {
        return result?["getStaticPageContent"]["errorMessage"];
      } else {
        return "<p><strong>Privacy Policy</strong></p>";
      }
    } on Exception catch (e) {
      return "<p><strong>Privacy Policy</strong></p>";
    }
  }

}