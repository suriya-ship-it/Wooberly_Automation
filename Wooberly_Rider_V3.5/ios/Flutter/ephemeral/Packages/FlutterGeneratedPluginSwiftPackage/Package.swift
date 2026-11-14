// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
//
// Generated file. Do not edit.
//

import PackageDescription

let package = Package(
    name: "FlutterGeneratedPluginSwiftPackage",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "FlutterGeneratedPluginSwiftPackage", type: .static, targets: ["FlutterGeneratedPluginSwiftPackage"])
    ],
    dependencies: [
        .package(name: "webview_flutter_wkwebview", path: "../.packages/webview_flutter_wkwebview-3.26.1"),
        .package(name: "video_player_avfoundation", path: "../.packages/video_player_avfoundation-2.11.1"),
        .package(name: "url_launcher_ios", path: "../.packages/url_launcher_ios-6.4.2"),
        .package(name: "record_ios", path: "../.packages/record_ios-2.1.1"),
        .package(name: "permission_handler_apple", path: "../.packages/permission_handler_apple-9.6.1"),
        .package(name: "just_audio", path: "../.packages/just_audio-0.10.6"),
        .package(name: "audio_session", path: "../.packages/audio_session-0.2.4"),
        .package(name: "connectivity_plus", path: "../.packages/connectivity_plus-7.3.1"),
        .package(name: "google_maps_flutter_ios_sdk10", path: "../.packages/google_maps_flutter_ios_sdk10-2.18.9"),
        .package(name: "geolocator_apple", path: "../.packages/geolocator_apple-2.3.14"),
        .package(name: "geocoding_darwin", path: "../.packages/geocoding_darwin-1.0.3"),
        .package(name: "stripe_ios", path: "../.packages/stripe_ios-14.0.0"),
        .package(name: "flutter_local_notifications", path: "../.packages/flutter_local_notifications-22.3.0"),
        .package(name: "firebase_messaging", path: "../.packages/firebase_messaging-16.6.0"),
        .package(name: "firebase_core", path: "../.packages/firebase_core-4.14.0"),
        .package(name: "firebase_crashlytics", path: "../.packages/firebase_crashlytics-5.3.0"),
        .package(name: "file_picker_darwin", path: "../.packages/file_picker_darwin-1.0.4"),
        .package(name: "camera_avfoundation", path: "../.packages/camera_avfoundation-0.10.3"),
        .package(name: "sqflite_darwin", path: "../.packages/sqflite_darwin-2.4.3+1"),
        .package(name: "age_range_signals", path: "../.packages/age_range_signals-0.8.0"),
        .package(name: "FlutterFramework", path: "../.packages/FlutterFramework")
    ],
    targets: [
        .target(
            name: "FlutterGeneratedPluginSwiftPackage",
            dependencies: [
                .product(name: "webview-flutter-wkwebview", package: "webview_flutter_wkwebview"),
                .product(name: "video-player-avfoundation", package: "video_player_avfoundation"),
                .product(name: "url-launcher-ios", package: "url_launcher_ios"),
                .product(name: "record-ios", package: "record_ios"),
                .product(name: "permission-handler-apple", package: "permission_handler_apple"),
                .product(name: "just-audio", package: "just_audio"),
                .product(name: "audio-session", package: "audio_session"),
                .product(name: "connectivity-plus", package: "connectivity_plus"),
                .product(name: "google-maps-flutter-ios-sdk10", package: "google_maps_flutter_ios_sdk10"),
                .product(name: "geolocator-apple", package: "geolocator_apple"),
                .product(name: "geocoding-darwin", package: "geocoding_darwin"),
                .product(name: "stripe-ios", package: "stripe_ios"),
                .product(name: "flutter-local-notifications", package: "flutter_local_notifications"),
                .product(name: "firebase-messaging", package: "firebase_messaging"),
                .product(name: "firebase-core", package: "firebase_core"),
                .product(name: "firebase-crashlytics", package: "firebase_crashlytics"),
                .product(name: "file-picker-darwin", package: "file_picker_darwin"),
                .product(name: "camera-avfoundation", package: "camera_avfoundation"),
                .product(name: "sqflite-darwin", package: "sqflite_darwin"),
                .product(name: "age-range-signals", package: "age_range_signals"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ]
        )
    ]
)
