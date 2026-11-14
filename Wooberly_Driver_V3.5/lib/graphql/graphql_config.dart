import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:wooberly_driver/utils/globals.dart' as globals;
import 'package:wooberly_driver/app/app.dart' as app;
import '../utils/globals.dart';

class GraphQlObject {
  late GraphQLClient graphQLClient;
  late GraphQLClient graphQLClientWithHeader;
  Map<String, dynamic>? _graphql_query;
  GraphQLCache memorycache = GraphQLCache();

  ValueNotifier<GraphQLClient> getGraphQlClient() {
    graphQLClient = GraphQLClient(
      cache: memorycache,
      link: HttpLink(globals.GRAPHQL_DOMAIN,
        defaultHeaders: <String, String>{
          'language': globals.preferredLanguage.value ?? "",
        },),
      queryRequestTimeout: const Duration(seconds: 30),
    );
    ValueNotifier<GraphQLClient> client = ValueNotifier(
      graphQLClient,
    );

    return client;
  }

  ValueNotifier<GraphQLClient> getGraphQlClientWithHeader() {
    if (app.App().appPreference.authToken != null && app.App().appPreference.authToken != "") {
      globals.authToken = app.App().appPreference.authToken;
    }
    HttpLink httpLink = HttpLink(
      globals.GRAPHQL_DOMAIN,
      defaultHeaders: <String, String>{
        'auth': globals.authToken ?? "",
        'language': globals.preferredLanguage.value ?? "",
      },

    );

    graphQLClientWithHeader = GraphQLClient(
      cache: memorycache,
      queryRequestTimeout: const Duration(seconds: 30),
      link: httpLink,
    );
    ValueNotifier<GraphQLClient> client = ValueNotifier(
      graphQLClientWithHeader,
    );
    return client;
  }

  Future<Map<String, dynamic>?> getQueryValues(
      GraphQLClient graphQLClient, String query,
      [Map<String, dynamic>? variables,bool isLoaderEnable = true,FetchPolicy? fetch]) async {
    if (isLoaderShow) {
      if(isLoaderEnable)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          baseController.change(rxVariable: globals.rxLoadingController, value: 0);
        });
    } else
      isLoaderShow = true;
    if (globals.socket == null || !(globals.socket?.connected ?? false)) {
      app.App().reconnectSocket();
    }

    Map<String, dynamic>? data1 = (await graphQLClient.query(
      QueryOptions(
          fetchPolicy: fetch,
          document: gql(await graphQlObject.getGraphqlQuery(query)),
          variables: variables ?? {}),
    ))
        .data;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isEnableContinuousLoading) {
        if(isLoaderEnable) globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
      } else
        isEnableContinuousLoading = false;
    });
    return data1;
  }

  Future<Map<String, dynamic>?> getMutationValues(
      GraphQLClient graphQLClient, String mutation,
      [Map<String, dynamic>? variables,bool isLoaderEnable = true]) async {
    if (isLoaderShow) {
      if(isLoaderEnable) globals.baseController.change(rxVariable: globals.rxLoadingController, value: 0);
    } else {
      isLoaderShow = true;
    }

    if (globals.socket == null || !(globals.socket?.connected ?? false)) {
      app.App().reconnectSocket();
    }
    String mutationvalue = await getGraphqlQuery(mutation);
    Map<String, dynamic>? data = (await graphQLClient
            .mutate(
              MutationOptions(
                  document: gql(mutationvalue),
                  variables: variables ?? {}),
            )
            .timeout(
              const Duration(milliseconds: 50000),
            )).data;
    if (!isEnableContinuousLoading) {
      if(isLoaderEnable) globals.baseController.change(rxVariable: globals.rxLoadingController, value: 1);
    } else {
      isEnableContinuousLoading = false;
    }
    return data;
  }

  Future<void> loadGraphQLJson(String res) async {
    if (res.toString().split("_").contains("graphql")) {
      String data = await rootBundle.loadString("res/graphql/${res}.json");
      _graphql_query = json.decode(data);
    }
  }

  Future<String> getGraphqlQuery(String key) async {
    if (_graphql_query == null) {
      String data =
          await rootBundle.loadString("res/graphql/login_graphql.json");
      _graphql_query = json.decode(data);
      return _graphql_query?[key];
    }
    return _graphql_query?[key];
  }
}

GraphQlObject graphQlObject = GraphQlObject();