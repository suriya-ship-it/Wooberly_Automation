import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wooberly_driver/app/app.dart';
import 'package:wooberly_driver/controller/base_controller.dart';
import 'package:wooberly_driver/graphql/graphql_config.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;

class StaticPageController extends BaseController{

  Future<String> getStaticPageContent(int staticPageContentId) async {
    try {
      graphQlObject.graphQLClientWithHeader.cache.store.reset();
      var variables = <String, dynamic>{"id": staticPageContentId};
      debugPrint("getStaticPageContent: ${variables}");
      Map<String, dynamic>? result = await graphQlObject.getQueryValues(
          globals.authToken !=null && globals.authToken!.isNotEmpty ?
          graphQlObject.graphQLClientWithHeader :
          graphQlObject.graphQLClient, "getStaticPageContent", variables);
      debugPrint("getStaticPageContent: result ${result}");
      if (result?["getStaticPageContent"]["status"] == 200) {
        if (result?["getStaticPageContent"]["result"]["content"] != null) {
          return result?["getStaticPageContent"]["result"]["content"];
        } else {
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