import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:app_name/app/enums/button_state.dart';
import 'package:app_name/utils/globals.dart' as globals;

import '../utils/globals.dart';

class GraphQlObject {
  late GraphQLClient graphQLClient;
  late GraphQLClient graphQLClientWithHeader;
  Map<String, dynamic>? _graphql_query;
  final GraphQLCache memorycache = GraphQLCache();

  ValueNotifier<GraphQLClient> getGraphQlClient() {
    graphQLClient = GraphQLClient(
      cache: memorycache,
      link: HttpLink(globals.GRAPHQL_DOMAIN,
        defaultHeaders: <String, String>{
          'language': globals.preferredLanguage ?? "",
        },),
      queryRequestTimeout: Duration(seconds: 30),
    );
    ValueNotifier<GraphQLClient> client = ValueNotifier(
      graphQLClient!,
    );

    return client;
  }

  ValueNotifier<GraphQLClient> getGraphQlClientWithHeader() {
    HttpLink httpLink = HttpLink(
      globals.GRAPHQL_DOMAIN,
      defaultHeaders: <String, String>{
        'auth': globals.authToken!,
        'language': globals.preferredLanguage ?? "",
      },
    );

    graphQLClientWithHeader = GraphQLClient(
      cache: memorycache,
      queryRequestTimeout: Duration(seconds: 30),
      link: httpLink,

    );
    ValueNotifier<GraphQLClient> client = ValueNotifier(
      graphQLClientWithHeader!,
    );
    return client;
  }


  Future<Map<String, dynamic>?> getQueryValues(GraphQLClient graphQLClient,
      String query, [Map<String, dynamic>? variables,FetchPolicy? fetch]) async {
    debugPrint("query variables: ${jsonEncode(variables)} --- ${query}");
    if (isLoaderShow)
      buttonState.value=ButtonState.loading;
    else
      isLoaderShow = true;
    Map<String, dynamic>? data1 = (await graphQLClient.query(
      QueryOptions(
        fetchPolicy: fetch,
          document: gql(graphQlObject.getGraphqlQuery(query)),
          variables: variables ?? {}),
    ))
        .data;
    debugPrint("Query response: ${data1}--${query}");
    if (!isContinuousLoading)
      buttonState.value=ButtonState.idle;

    else
      isContinuousLoading = false;
    return data1;
  }

  Future<Map<String, dynamic>?> getMutationValues(GraphQLClient graphQLClient,
      String mutation, [Map<String, dynamic>? variables]) async {
    debugPrint(
        "Mutation variables: ${jsonEncode(variables)} --- ${isLoaderShow} -- ${mutation}");
    if (isLoaderShow)
      buttonState.value=ButtonState.loading;
    else
      isLoaderShow = true;
    Map<String, dynamic>? data = (await graphQLClient.mutate(
      MutationOptions(
          document: gql(graphQlObject.getGraphqlQuery(mutation)),
          variables: variables ??  {}),
    ))
        .data;
    debugPrint("Mutation response: ${data}");
    if (!isContinuousLoading)
      buttonState.value=ButtonState.idle;
    else
      isContinuousLoading = false;
    return data;
  }

  Future<void> loadGraphQLJson(String res) async {
    if (res.toString().split("_").contains("graphql")) {
      String data = await rootBundle.loadString("res/graphql/${res}.json");
      _graphql_query = json.decode(data);
    }
  }

  String getGraphqlQuery(String key) {
    return _graphql_query?[key];
  }
}

GraphQlObject graphQlObject = new GraphQlObject();