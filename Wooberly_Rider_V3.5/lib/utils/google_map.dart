// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

export 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart'
    show
    AdvancedMarker,
    AdvancedMarkerGlyph,
    ArgumentCallback,
    ArgumentCallbacks,
    AssetMapBitmap,
    BitmapDescriptor,
    BitmapGlyph,
    BytesMapBitmap,
    CameraPosition,
    CameraPositionCallback,
    CameraTargetBounds,
    CameraUpdate,
    Cap,
    Circle,
    CircleGlyph,
    CircleId,
    Cluster,
    ClusterManager,
    ClusterManagerId,
    GroundOverlay,
    GroundOverlayId,
    Heatmap,
    HeatmapGradient,
    HeatmapGradientColor,
    HeatmapId,
    HeatmapRadius,
    InfoWindow,
    JointType,
    LatLng,
    LatLngBounds,
    MapBitmapScaling,
    MapColorScheme,
    MapStyleException,
    MapType,
    Marker,
    MarkerCollisionBehavior,
    MarkerId,
    MinMaxZoomPreference,
    PatternItem,
    PinConfig,
    Polygon,
    PolygonId,
    Polyline,
    PolylineId,
    ScreenCoordinate,
    TextGlyph,
    Tile,
    TileOverlay,
    TileOverlayId,
    TileProvider,
    WebCameraControlPosition,
    WebGestureHandling,
    WeightedLatLng;

/// Callback method for when the map is ready to be used.
///
/// Pass to [GoogleMap.onMapCreated] to receive a [GoogleMapController] when the
/// map is created.
typedef MapCreatedCallback = void Function(GoogleMapController controller);

// This counter is used to provide a stable "constant" initialization id
// to the buildView function, so the web implementation can use it as a
// cache key. This needs to be provided from the outside, because web
// views seem to re-render much more often that mobile platform views.
int _nextMapCreationId = 0;

/// Error thrown when an unknown map object ID is provided to a method.
class UnknownMapObjectIdError extends Error {
  /// Creates an assertion error with the provided [message].
  UnknownMapObjectIdError(this.objectType, this.objectId, [this.context]);

  /// The name of the map object whose ID is unknown.
  final String objectType;

  /// The unknown maps object ID.
  final MapsObjectId<Object> objectId;

  /// The context where the error occurred.
  final String? context;

  @override
  String toString() {
    if (context != null) {
      return 'Unknown $objectType ID "${objectId.value}" in $context';
    }
    return 'Unknown $objectType ID "${objectId.value}"';
  }
}

/// Android specific settings for [GoogleMap].
@Deprecated(
  'See https://pub.dev/packages/google_maps_flutter_android#display-mode',
)
class AndroidGoogleMapsFlutter {
  @Deprecated(
    'See https://pub.dev/packages/google_maps_flutter_android#display-mode',
  )
  AndroidGoogleMapsFlutter._();

  /// Whether to render [GoogleMap] with a [AndroidViewSurface] to build the Google Maps widget.
  ///
  /// This implementation uses hybrid composition to render the Google Maps
  /// Widget on Android. This comes at the cost of some performance on Android
  /// versions below 10. See
  /// https://docs.flutter.dev/platform-integration/android/platform-views#performance for more
  /// information.
  @Deprecated(
    'See https://pub.dev/packages/google_maps_flutter_android#display-mode',
  )
  static bool get useAndroidViewSurface {
    final GoogleMapsFlutterPlatform platform =
        GoogleMapsFlutterPlatform.instance;
    if (platform is GoogleMapsFlutterAndroid) {
      return platform.useAndroidViewSurface;
    }
    return false;
  }

  /// Set whether to render [GoogleMap] with a [AndroidViewSurface] to build the Google Maps widget.
  ///
  /// This implementation uses hybrid composition to render the Google Maps
  /// Widget on Android. This comes at the cost of some performance on Android
  /// versions below 10. See
  /// https://docs.flutter.dev/platform-integration/android/platform-views#performance for more
  /// information.
  @Deprecated(
    'See https://pub.dev/packages/google_maps_flutter_android#display-mode',
  )
  static set useAndroidViewSurface(bool useAndroidViewSurface) {
    final GoogleMapsFlutterPlatform platform =
        GoogleMapsFlutterPlatform.instance;
    if (platform is GoogleMapsFlutterAndroid) {
      platform.useAndroidViewSurface = useAndroidViewSurface;
    }
  }
}

/// Indicates the type of marker that the map should use.
enum GoogleMapMarkerType {
  /// Represents the default marker type, [Marker]. This marker type is
  /// deprecated on the web.
  marker,

  /// Represents the advanced marker type, [AdvancedMarker].
  advancedMarker,
}

/// A widget which displays a map with data obtained from the Google Maps service.
class GoogleMap extends StatefulWidget {
  /// Creates a widget displaying data from Google Maps services.
  ///
  /// The map's camera will start centered on [initialCameraPosition].
  const GoogleMap({
    super.key,
    required this.initialCameraPosition,
    this.style,
    this.onMapCreated,
    this.gestureRecognizers = const <Factory<OneSequenceGestureRecognizer>>{},
    this.webGestureHandling,
    this.webCameraControlPosition,
    this.webCameraControlEnabled = true,
    this.compassEnabled = true,
    this.mapToolbarEnabled = true,
    this.cameraTargetBounds = CameraTargetBounds.unbounded,
    this.mapType = MapType.normal,
    this.minMaxZoomPreference = MinMaxZoomPreference.unbounded,
    this.rotateGesturesEnabled = true,
    this.scrollGesturesEnabled = true,
    this.zoomControlsEnabled = true,
    this.zoomGesturesEnabled = true,
    this.liteModeEnabled = false,
    this.tiltGesturesEnabled = true,
    this.fortyFiveDegreeImageryEnabled = false,
    this.myLocationEnabled = false,
    this.myLocationButtonEnabled = true,
    this.layoutDirection,
    this.padding = EdgeInsets.zero,
    this.indoorViewEnabled = false,
    this.trafficEnabled = false,
    this.buildingsEnabled = true,
    this.markers = const <Marker>{},
    this.polygons = const <Polygon>{},
    this.polylines = const <Polyline>{},
    this.circles = const <Circle>{},
    this.clusterManagers = const <ClusterManager>{},
    this.heatmaps = const <Heatmap>{},
    this.onCameraMoveStarted,
    this.tileOverlays = const <TileOverlay>{},
    this.groundOverlays = const <GroundOverlay>{},
    this.onCameraMove,
    this.onCameraIdle,
    this.onTap,
    this.onLongPress,
    this.markerType = GoogleMapMarkerType.marker,
    this.colorScheme,
    String? mapId,
    @Deprecated('cloudMapId is deprecated. Use mapId instead.')
    String? cloudMapId,
  }) : assert(
  mapId == null || cloudMapId == null,
  '''A value may be provided for either mapId or cloudMapId, or neither, but not for both.''',
  ),
        mapId = mapId ?? cloudMapId;

  /// Callback method for when the map is ready to be used.
  ///
  /// Used to receive a [GoogleMapController] for this [GoogleMap].
  final MapCreatedCallback? onMapCreated;

  /// The initial position of the map's camera.
  final CameraPosition initialCameraPosition;

  /// The style for the map.
  ///
  /// Set to null to clear any previous custom styling.
  ///
  /// If problems were detected with the [mapStyle], including un-parsable
  /// styling JSON, unrecognized feature type, unrecognized element type, or
  /// invalid styler keys, the style is left unchanged, and the error can be
  /// retrieved with [GoogleMapController.getStyleError].
  ///
  /// The style string can be generated using the
  /// [map style tool](https://mapstyle.withgoogle.com/).
  final String? style;

  /// True if the map should show a compass when rotated.
  final bool compassEnabled;

  /// True if the map should show a toolbar when you interact with the map. Android only.
  final bool mapToolbarEnabled;

  /// Geographical bounding box for the camera target.
  final CameraTargetBounds cameraTargetBounds;

  /// Type of map tiles to be rendered.
  final MapType mapType;

  /// The layout direction to use for the embedded view.
  ///
  /// If this is null, the ambient [Directionality] is used instead. If there is
  /// no ambient [Directionality], [TextDirection.ltr] is used.
  final TextDirection? layoutDirection;

  /// Preferred bounds for the camera zoom level.
  ///
  /// Actual bounds depend on map data and device.
  final MinMaxZoomPreference minMaxZoomPreference;

  /// True if the map view should respond to rotate gestures.
  final bool rotateGesturesEnabled;

  /// True if the map view should respond to scroll gestures.
  final bool scrollGesturesEnabled;

  /// True if the map view should show zoom controls. This includes two buttons
  /// to zoom in and zoom out. The default value is to show zoom controls.
  ///
  /// This is only supported on Android. And this field is silently ignored on iOS.
  final bool zoomControlsEnabled;

  /// True if the map view should respond to zoom gestures.
  final bool zoomGesturesEnabled;

  /// True if the map view should be in lite mode. Android only.
  ///
  /// See https://developers.google.com/maps/documentation/android-sdk/lite#overview_of_lite_mode for more details.
  final bool liteModeEnabled;

  /// True if the map view should respond to tilt gestures.
  final bool tiltGesturesEnabled;

  /// True if 45 degree imagery should be enabled. Web only.
  final bool fortyFiveDegreeImageryEnabled;

  /// Padding to be set on map. See https://developers.google.com/maps/documentation/android-sdk/map#map_padding for more details.
  ///
  /// If no padding is specified, the default padding is 0.
  final EdgeInsets padding;

  /// Markers to be placed on the map.
  final Set<Marker> markers;

  /// Polygons to be placed on the map.
  final Set<Polygon> polygons;

  /// Polylines to be placed on the map.
  final Set<Polyline> polylines;

  /// Circles to be placed on the map.
  final Set<Circle> circles;

  /// Heatmaps to show on the map.
  final Set<Heatmap> heatmaps;

  /// Tile overlays to be placed on the map.
  final Set<TileOverlay> tileOverlays;

  /// Cluster Managers to be initialized for the map.
  ///
  /// On the web, an extra step is required to enable clusters.
  /// See https://pub.dev/packages/google_maps_flutter_web.
  final Set<ClusterManager> clusterManagers;

  /// Ground overlays to be initialized for the map.
  ///
  /// Support table for Ground Overlay features:
  /// | Feature                     | Android                  | iOS                      | Web |
  /// |-----------------------------|--------------------------|--------------------------|-----|
  /// | [GroundOverlay.image]       | Yes                      | Yes                      | Yes |
  /// | [GroundOverlay.bounds]      | Yes                      | Yes                      | Yes |
  /// | [GroundOverlay.position]    | Yes                      | Yes                      | No  |
  /// | [GroundOverlay.width]       | Yes (with position only) | No                       | No  |
  /// | [GroundOverlay.height]      | Yes (with position only) | No                       | No  |
  /// | [GroundOverlay.anchor]      | Yes                      | Yes                      | No  |
  /// | [GroundOverlay.zoomLevel]   | No                       | Yes (with position only) | No  |
  /// | [GroundOverlay.bearing]     | Yes                      | Yes                      | No  |
  /// | [GroundOverlay.transparency]| Yes                      | Yes                      | Yes |
  /// | [GroundOverlay.zIndex]      | Yes                      | Yes                      | No  |
  /// | [GroundOverlay.visible]     | Yes                      | Yes                      | Yes |
  /// | [GroundOverlay.clickable]   | Yes                      | Yes                      | Yes |
  /// | [GroundOverlay.onTap]       | Yes                      | Yes                      | Yes |
  ///
  /// - On Android, [GroundOverlay.width] is required if
  ///   [GroundOverlay.position] is set.
  /// - On iOS, [GroundOverlay.zoomLevel] is required if
  ///   [GroundOverlay.position] is set.
  /// - [GroundOverlay.image] must be a [MapBitmap]. See [AssetMapBitmap] and
  ///   [BytesMapBitmap]. [MapBitmap.bitmapScaling] must be set to
  ///   [MapBitmapScaling.none].
  final Set<GroundOverlay> groundOverlays;

  /// Called when the camera starts moving.
  ///
  /// This can be initiated by the following:
  /// 1. Non-gesture animation initiated in response to user actions.
  ///    For example: zoom buttons, my location button, or marker clicks.
  /// 2. Programmatically initiated animation.
  /// 3. Camera motion initiated in response to user gestures on the map.
  ///    For example: pan, tilt, pinch to zoom, or rotate.
  final VoidCallback? onCameraMoveStarted;

  /// Called repeatedly as the camera continues to move after an
  /// onCameraMoveStarted call.
  ///
  /// This may be called as often as once every frame and should
  /// not perform expensive operations.
  final CameraPositionCallback? onCameraMove;

  /// Called when camera movement has ended, there are no pending
  /// animations and the user has stopped interacting with the map.
  final VoidCallback? onCameraIdle;

  /// Called every time a [GoogleMap] is tapped.
  final ArgumentCallback<LatLng>? onTap;

  /// Called every time a [GoogleMap] is long pressed.
  final ArgumentCallback<LatLng>? onLongPress;

  /// True if a "My Location" layer should be shown on the map.
  ///
  /// This layer includes a location indicator at the current device location,
  /// as well as a My Location button.
  /// * The indicator is a small blue dot if the device is stationary, or a
  /// chevron if the device is moving.
  /// * The My Location button animates to focus on the user's current location
  /// if the user's location is currently known.
  ///
  /// This feature is not present in the Google Maps SDK for the web.
  ///
  /// Enabling this feature requires adding location permissions to both native
  /// platforms of your app.
  /// * On Android add either
  /// `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />`
  /// or `<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />`
  /// to your `AndroidManifest.xml` file. `ACCESS_COARSE_LOCATION` returns a
  /// location with an accuracy approximately equivalent to a city block, while
  /// `ACCESS_FINE_LOCATION` returns as precise a location as possible, although
  /// it consumes more battery power. You will also need to request these
  /// permissions during run-time. If they are not granted, the My Location
  /// feature will fail silently.
  /// * On iOS add a `NSLocationWhenInUseUsageDescription` key to your
  /// `Info.plist` file. This will automatically prompt the user for permissions
  /// when the map tries to turn on the My Location layer.
  final bool myLocationEnabled;

  /// Enables or disables the my-location button.
  ///
  /// The my-location button causes the camera to move such that the user's
  /// location is in the center of the map. If the button is enabled, it is
  /// only shown when the my-location layer is enabled.
  ///
  /// By default, the my-location button is enabled (and hence shown when the
  /// my-location layer is enabled).
  ///
  /// See also:
  ///   * [myLocationEnabled] parameter.
  final bool myLocationButtonEnabled;

  /// Enables or disables the indoor view from the map
  final bool indoorViewEnabled;

  /// Enables or disables the traffic layer of the map
  final bool trafficEnabled;

  /// Enables or disables showing 3D buildings where available
  final bool buildingsEnabled;

  /// Which gestures should be consumed by the map.
  ///
  /// It is possible for other gesture recognizers to be competing with the map on pointer
  /// events, e.g if the map is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The map will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// When this set is empty, the map will only handle pointer events for gestures that
  /// were not claimed by any other gesture recognizer.
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  /// This setting controls how the API handles gestures on the map. Web only.
  ///
  /// See [WebGestureHandling] for more details.
  final WebGestureHandling? webGestureHandling;

  /// This setting controls how the API handles cameraControl button position on the map. Web only.
  ///
  /// If null, the Google Maps API will use its default camera control position.
  ///
  /// See [WebCameraControlPosition] for more details.
  final WebCameraControlPosition? webCameraControlPosition;

  /// Enables or disables the Camera controls. Web only.
  ///
  /// See https://developers.google.com/maps/documentation/javascript/controls for more details.
  final bool webCameraControlEnabled;

  /// Identifier that's associated with a specific cloud-based map style.
  ///
  /// See https://developers.google.com/maps/documentation/get-map-id
  /// for more details.
  final String? mapId;

  /// Identifier that's associated with a specific cloud-based map style.
  ///
  /// See https://developers.google.com/maps/documentation/get-map-id
  /// for more details.
  @Deprecated('cloudMapId is deprecated. Use mapId instead.')
  String? get cloudMapId => mapId;

  /// Indicates whether map uses [AdvancedMarker]s or [Marker]s.
  ///
  /// [AdvancedMarker] and [Marker]s classes might not be related to each other
  /// in the platform implementation. It's important to set the correct
  /// [GoogleMapMarkerType] so that the platform implementation can handle the
  /// markers:
  /// * If [GoogleMapMarkerType.advancedMarker] is used, all markers must be of
  ///   type [AdvancedMarker].
  /// * If [GoogleMapMarkerType.marker] is used, markers cannot be of type
  ///   [AdvancedMarker].
  ///
  /// While some features work with either type, using the incorrect type
  /// may result in unexpected behavior.
  final GoogleMapMarkerType markerType;

  /// Color scheme for the cloud-style map. Web only.
  ///
  /// The colorScheme option can only be set when the map is initialized;
  /// setting this option after the map is created will have no effect.
  ///
  /// See https://developers.google.com/maps/documentation/javascript/mapcolorscheme for more details.
  final MapColorScheme? colorScheme;

  /// Creates a [State] for this [GoogleMap].
  @override
  State createState() => _GoogleMapState();
}

class _GoogleMapState extends State<GoogleMap> {
  final int _mapId = _nextMapCreationId++;

  final Completer<GoogleMapController> _controller =
  Completer<GoogleMapController>();

  Map<MarkerId, Marker> _markers = <MarkerId, Marker>{};
  Map<PolygonId, Polygon> _polygons = <PolygonId, Polygon>{};
  Map<PolylineId, Polyline> _polylines = <PolylineId, Polyline>{};
  Map<CircleId, Circle> _circles = <CircleId, Circle>{};
  Map<ClusterManagerId, ClusterManager> _clusterManagers =
  <ClusterManagerId, ClusterManager>{};
  Map<HeatmapId, Heatmap> _heatmaps = <HeatmapId, Heatmap>{};
  Map<GroundOverlayId, GroundOverlay> _groundOverlays =
  <GroundOverlayId, GroundOverlay>{};
  late MapConfiguration _mapConfiguration;

  @override
  Widget build(BuildContext context) {
    return GoogleMapsFlutterPlatform.instance.buildViewWithConfiguration(
      _mapId,
      onPlatformViewCreated,
      widgetConfiguration: MapWidgetConfiguration(
        textDirection:
        widget.layoutDirection ??
            Directionality.maybeOf(context) ??
            TextDirection.ltr,
        initialCameraPosition: widget.initialCameraPosition,
        gestureRecognizers: widget.gestureRecognizers,
      ),
      mapObjects: MapObjects(
        markers: widget.markers,
        polygons: widget.polygons,
        polylines: widget.polylines,
        circles: widget.circles,
        clusterManagers: widget.clusterManagers,
        heatmaps: widget.heatmaps,
        groundOverlays: widget.groundOverlays,
      ),
      mapConfiguration: _mapConfiguration,
    );
  }

  @override
  void initState() {
    super.initState();
    _mapConfiguration = _configurationFromMapWidget(widget);
    _clusterManagers = keyByClusterManagerId(widget.clusterManagers);
    _markers = keyByMarkerId(widget.markers);
    _polygons = keyByPolygonId(widget.polygons);
    _polylines = keyByPolylineId(widget.polylines);
    _circles = keyByCircleId(widget.circles);
    _heatmaps = keyByHeatmapId(widget.heatmaps);
    _groundOverlays = keyByGroundOverlayId(widget.groundOverlays);
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _disposeController() async {
    final GoogleMapController controller = await _controller.future;
    controller.dispose();
  }

  @override
  void didUpdateWidget(GoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    _refreshStateFromWidget();
  }

  Future<void> _refreshStateFromWidget() async {
    final GoogleMapController controller = await _controller.future;
    if (!mounted) {
      return;
    }

    _updateOptions(controller);
    _updateClusterManagers(controller);
    _updateMarkers(controller);
    _updatePolygons(controller);
    _updatePolylines(controller);
    _updateCircles(controller);
    _updateHeatmaps(controller);
    _updateTileOverlays(controller);
    _updateGroundOverlays(controller);
  }

  void _updateOptions(GoogleMapController controller) {
    final MapConfiguration newConfig = _configurationFromMapWidget(widget);
    final MapConfiguration updates = newConfig.diffFrom(_mapConfiguration);
    if (updates.isEmpty) {
      return;
    }
    unawaited(controller._updateMapConfiguration(updates));
    _mapConfiguration = newConfig;
  }

  void _updateMarkers(GoogleMapController controller) {
    unawaited(
      controller._updateMarkers(
        MarkerUpdates.from(_markers.values.toSet(), widget.markers),
      ),
    );
    _markers = keyByMarkerId(widget.markers);
  }

  void _updateClusterManagers(GoogleMapController controller) {
    unawaited(
      controller._updateClusterManagers(
        ClusterManagerUpdates.from(
          _clusterManagers.values.toSet(),
          widget.clusterManagers,
        ),
      ),
    );
    _clusterManagers = keyByClusterManagerId(widget.clusterManagers);
  }

  void _updateGroundOverlays(GoogleMapController controller) {
    unawaited(
      controller._updateGroundOverlays(
        GroundOverlayUpdates.from(
          _groundOverlays.values.toSet(),
          widget.groundOverlays,
        ),
      ),
    );
    _groundOverlays = keyByGroundOverlayId(widget.groundOverlays);
  }

  void _updatePolygons(GoogleMapController controller) {
    unawaited(
      controller._updatePolygons(
        PolygonUpdates.from(_polygons.values.toSet(), widget.polygons),
      ),
    );
    _polygons = keyByPolygonId(widget.polygons);
  }

  void _updatePolylines(GoogleMapController controller) {
    unawaited(
      controller._updatePolylines(
        PolylineUpdates.from(_polylines.values.toSet(), widget.polylines),
      ),
    );
    _polylines = keyByPolylineId(widget.polylines);
  }

  void _updateCircles(GoogleMapController controller) {
    unawaited(
      controller._updateCircles(
        CircleUpdates.from(_circles.values.toSet(), widget.circles),
      ),
    );
    _circles = keyByCircleId(widget.circles);
  }

  void _updateHeatmaps(GoogleMapController controller) {
    unawaited(
      controller._updateHeatmaps(
        HeatmapUpdates.from(_heatmaps.values.toSet(), widget.heatmaps),
      ),
    );
    _heatmaps = keyByHeatmapId(widget.heatmaps);
  }

  void _updateTileOverlays(GoogleMapController controller) {
    unawaited(controller._updateTileOverlays(widget.tileOverlays));
  }

  Future<void> onPlatformViewCreated(int id) async {
    final GoogleMapController controller = await GoogleMapController.init(
      id,
      widget.initialCameraPosition,
      this,
    );
    _controller.complete(controller);
    if (mounted) {
      _updateTileOverlays(controller);
      final MapCreatedCallback? onMapCreated = widget.onMapCreated;
      if (onMapCreated != null) {
        onMapCreated(controller);
      }
    }
  }

  void onMarkerTap(MarkerId markerId) {
    final Marker? marker = _markers[markerId];
    if (marker == null) {
      throw UnknownMapObjectIdError('marker', markerId, 'onTap');
    }
    final VoidCallback? onTap = marker.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onMarkerDragStart(MarkerId markerId, LatLng position) {
    final Marker? marker = _markers[markerId];
    if (marker == null) {
      throw UnknownMapObjectIdError('marker', markerId, 'onDragStart');
    }
    final ValueChanged<LatLng>? onDragStart = marker.onDragStart;
    if (onDragStart != null) {
      onDragStart(position);
    }
  }

  void onMarkerDrag(MarkerId markerId, LatLng position) {
    final Marker? marker = _markers[markerId];
    if (marker == null) {
      throw UnknownMapObjectIdError('marker', markerId, 'onDrag');
    }
    final ValueChanged<LatLng>? onDrag = marker.onDrag;
    if (onDrag != null) {
      onDrag(position);
    }
  }

  void onMarkerDragEnd(MarkerId markerId, LatLng position) {
    final Marker? marker = _markers[markerId];
    if (marker == null) {
      throw UnknownMapObjectIdError('marker', markerId, 'onDragEnd');
    }
    final ValueChanged<LatLng>? onDragEnd = marker.onDragEnd;
    if (onDragEnd != null) {
      onDragEnd(position);
    }
  }

  void onPolygonTap(PolygonId polygonId) {
    final Polygon? polygon = _polygons[polygonId];
    if (polygon == null) {
      throw UnknownMapObjectIdError('polygon', polygonId, 'onTap');
    }
    final VoidCallback? onTap = polygon.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onPolylineTap(PolylineId polylineId) {
    final Polyline? polyline = _polylines[polylineId];
    if (polyline == null) {
      throw UnknownMapObjectIdError('polyline', polylineId, 'onTap');
    }
    final VoidCallback? onTap = polyline.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onCircleTap(CircleId circleId) {
    final Circle? circle = _circles[circleId];
    if (circle == null) {
      throw UnknownMapObjectIdError('marker', circleId, 'onTap');
    }
    final VoidCallback? onTap = circle.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onGroundOverlayTap(GroundOverlayId groundOverlayId) {
    final GroundOverlay? groundOverlay = _groundOverlays[groundOverlayId];
    if (groundOverlay == null) {
      throw UnknownMapObjectIdError('groundOverlay', groundOverlayId, 'onTap');
    }
    final VoidCallback? onTap = groundOverlay.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onInfoWindowTap(MarkerId markerId) {
    final Marker? marker = _markers[markerId];
    if (marker == null) {
      throw UnknownMapObjectIdError('marker', markerId, 'InfoWindow onTap');
    }
    final VoidCallback? onTap = marker.infoWindow.onTap;
    if (onTap != null) {
      onTap();
    }
  }

  void onTap(LatLng position) {
    final ArgumentCallback<LatLng>? onTap = widget.onTap;
    if (onTap != null) {
      onTap(position);
    }
  }

  void onLongPress(LatLng position) {
    final ArgumentCallback<LatLng>? onLongPress = widget.onLongPress;
    if (onLongPress != null) {
      onLongPress(position);
    }
  }

  void onClusterTap(Cluster cluster) {
    final ClusterManager? clusterManager =
    _clusterManagers[cluster.clusterManagerId];
    if (clusterManager == null) {
      throw UnknownMapObjectIdError(
        'clusterManager',
        cluster.clusterManagerId,
        'onClusterTap',
      );
    }
    final ArgumentCallback<Cluster>? onClusterTap = clusterManager.onClusterTap;
    if (onClusterTap != null) {
      onClusterTap(cluster);
    }
  }
}

/// Builds a [MapConfiguration] from the given [map].
MapConfiguration _configurationFromMapWidget(GoogleMap map) {
  final MarkerType mapConfigurationMarkerType = switch (map.markerType) {
    GoogleMapMarkerType.marker => MarkerType.marker,
    GoogleMapMarkerType.advancedMarker => MarkerType.advancedMarker,
  };

  return MapConfiguration(
    webCameraControlPosition: map.webCameraControlPosition,
    webCameraControlEnabled: map.webCameraControlEnabled,
    webGestureHandling: map.webGestureHandling,
    compassEnabled: map.compassEnabled,
    mapToolbarEnabled: map.mapToolbarEnabled,
    cameraTargetBounds: map.cameraTargetBounds,
    mapType: map.mapType,
    minMaxZoomPreference: map.minMaxZoomPreference,
    rotateGesturesEnabled: map.rotateGesturesEnabled,
    scrollGesturesEnabled: map.scrollGesturesEnabled,
    tiltGesturesEnabled: map.tiltGesturesEnabled,
    fortyFiveDegreeImageryEnabled: map.fortyFiveDegreeImageryEnabled,
    trackCameraPosition: map.onCameraMove != null,
    zoomControlsEnabled: map.zoomControlsEnabled,
    zoomGesturesEnabled: map.zoomGesturesEnabled,
    liteModeEnabled: map.liteModeEnabled,
    myLocationEnabled: map.myLocationEnabled,
    myLocationButtonEnabled: map.myLocationButtonEnabled,
    padding: map.padding,
    indoorViewEnabled: map.indoorViewEnabled,
    trafficEnabled: map.trafficEnabled,
    buildingsEnabled: map.buildingsEnabled,
    markerType: mapConfigurationMarkerType,
    colorScheme: map.colorScheme,
    // A null mapId in the widget means no map ID, which is expressed as '' in
    // the configuration to distinguish from no change (null).
    mapId: map.mapId ?? '',
    // A null style in the widget means no style, which is expressed as '' in
    // the configuration to distinguish from no change (null).
    style: map.style ?? '',
  );
}


class GoogleMapController {
  GoogleMapController._(this._googleMapState, {required this.mapId}) {
    _connectStreams(mapId);
  }

  /// The mapId for this controller
  final int mapId;

  /// List of active stream subscriptions for map events.
  ///
  /// This list keeps track of all event subscriptions created for the map,
  /// including camera movements, marker interactions, and other map events.
  /// These subscriptions should be disposed when the controller is disposed.
  final List<StreamSubscription<dynamic>> _streamSubscriptions =
  <StreamSubscription<dynamic>>[];

  /// Initialize control of a [GoogleMap] with [id].
  ///
  /// Mainly for internal use when instantiating a [GoogleMapController] passed
  /// in [GoogleMap.onMapCreated] callback.
  static Future<GoogleMapController> init(
      int id,
      CameraPosition initialCameraPosition,
      _GoogleMapState googleMapState,
      ) async {
    await GoogleMapsFlutterPlatform.instance.init(id);
    return GoogleMapController._(googleMapState, mapId: id);
  }

  final _GoogleMapState _googleMapState;

  void _connectStreams(int mapId) {
    if (_googleMapState.widget.onCameraMoveStarted != null) {
      _streamSubscriptions.add(
        GoogleMapsFlutterPlatform.instance
            .onCameraMoveStarted(mapId: mapId)
            .listen((_) => _googleMapState.widget.onCameraMoveStarted!()),
      );
    }
    if (_googleMapState.widget.onCameraMove != null) {
      _streamSubscriptions.add(
        GoogleMapsFlutterPlatform.instance
            .onCameraMove(mapId: mapId)
            .listen(
              (CameraMoveEvent e) =>
              _googleMapState.widget.onCameraMove!(e.value),
        ),
      );
    }
    if (_googleMapState.widget.onCameraIdle != null) {
      _streamSubscriptions.add(
        GoogleMapsFlutterPlatform.instance
            .onCameraIdle(mapId: mapId)
            .listen((_) => _googleMapState.widget.onCameraIdle!()),
      );
    }
    _streamSubscriptions.add(
      GoogleMapsFlutterPlatform.instance
          .onMarkerTap(mapId: mapId)
          .listen((MarkerTapEvent e) => _googleMapState.onMarkerTap(e.value)),
    );
    _streamSubscriptions.add(
      GoogleMapsFlutterPlatform.instance
          .onMarkerDragStart(mapId: mapId)
          .listen(
            (MarkerDragStartEvent e) =>
            _googleMapState.onMarkerDragStart(e.value, e.position),
      ),
    );
    _streamSubscriptions.add(
      GoogleMapsFlutterPlatform.instance
          .onMarkerDrag(mapId: mapId)
          .listen(
            (MarkerDragEvent e) =>
            _googleMapState.onMarkerDrag(e.value, e.position),
      ),
    );
    _streamSubscriptions.add(
      GoogleMapsFlutterPlatform.instance
          .onMarkerDragEnd(mapId: mapId)
          .listen(
            (MarkerDragEndEvent e) =>
            _googleMapState.onMarkerDragEnd(e.value, e.position),
      ),
    );
    _streamSubscriptions.add(
      GoogleMapsFlutterPlatform.instance
          .onInfoWindowTap(mapId: mapId)
          .listen(
            (InfoWindowTapEvent e) => _googleMapState.onInfoWindowTap(e.value),
      ),
    );
    _streamSubscriptions.add(
      GoogleMapsFlutterPlatform.instance
          .onPolylineTap(mapId: mapId)
          .listen(
            (PolylineTapEvent e) => _googleMapState.onPolylineTap(e.value),
      ),
    );
    _streamSubscriptions.add(
      GoogleMapsFlutterPlatform.instance
          .onPolygonTap(mapId: mapId)
          .listen((PolygonTapEvent e) => _googleMapState.onPolygonTap(e.value)),
    );
    _streamSubscriptions.add(
      GoogleMapsFlutterPlatform.instance
          .onCircleTap(mapId: mapId)
          .listen((CircleTapEvent e) => _googleMapState.onCircleTap(e.value)),
    );
    _streamSubscriptions.add(
      GoogleMapsFlutterPlatform.instance
          .onTap(mapId: mapId)
          .listen((MapTapEvent e) => _googleMapState.onTap(e.position)),
    );
    _streamSubscriptions.add(
      GoogleMapsFlutterPlatform.instance
          .onLongPress(mapId: mapId)
          .listen(
            (MapLongPressEvent e) => _googleMapState.onLongPress(e.position),
      ),
    );
    _streamSubscriptions.add(
      GoogleMapsFlutterPlatform.instance
          .onClusterTap(mapId: mapId)
          .listen((ClusterTapEvent e) => _googleMapState.onClusterTap(e.value)),
    );
  }

  /// Updates configuration options of the map user interface.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateMapConfiguration(MapConfiguration update) {
    return GoogleMapsFlutterPlatform.instance.updateMapConfiguration(
      update,
      mapId: mapId,
    );
  }

  /// Updates marker configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateMarkers(MarkerUpdates markerUpdates) {
    return GoogleMapsFlutterPlatform.instance.updateMarkers(
      markerUpdates,
      mapId: mapId,
    );
  }

  /// Updates cluster manager configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateClusterManagers(
      ClusterManagerUpdates clusterManagerUpdates,
      ) {
    return GoogleMapsFlutterPlatform.instance.updateClusterManagers(
      clusterManagerUpdates,
      mapId: mapId,
    );
  }

  /// Updates ground overlay configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateGroundOverlays(
      GroundOverlayUpdates groundOverlayUpdates,
      ) {
    return GoogleMapsFlutterPlatform.instance.updateGroundOverlays(
      groundOverlayUpdates,
      mapId: mapId,
    );
  }

  /// Updates polygon configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updatePolygons(PolygonUpdates polygonUpdates) {
    return GoogleMapsFlutterPlatform.instance.updatePolygons(
      polygonUpdates,
      mapId: mapId,
    );
  }

  /// Updates polyline configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updatePolylines(PolylineUpdates polylineUpdates) {
    return GoogleMapsFlutterPlatform.instance.updatePolylines(
      polylineUpdates,
      mapId: mapId,
    );
  }

  /// Updates circle configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateCircles(CircleUpdates circleUpdates) {
    return GoogleMapsFlutterPlatform.instance.updateCircles(
      circleUpdates,
      mapId: mapId,
    );
  }

  /// Updates heatmap configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateHeatmaps(HeatmapUpdates heatmapUpdates) {
    return GoogleMapsFlutterPlatform.instance.updateHeatmaps(
      heatmapUpdates,
      mapId: mapId,
    );
  }

  /// Updates tile overlays configuration.
  ///
  /// Change listeners are notified once the update has been made on the
  /// platform side.
  ///
  /// The returned [Future] completes after listeners have been notified.
  Future<void> _updateTileOverlays(Set<TileOverlay> newTileOverlays) {
    return GoogleMapsFlutterPlatform.instance.updateTileOverlays(
      newTileOverlays: newTileOverlays,
      mapId: mapId,
    );
  }

  /// Clears the tile cache so that all tiles will be requested again from the
  /// [TileProvider].
  ///
  /// The current tiles from this tile overlay will also be
  /// cleared from the map after calling this method. The API maintains a small
  /// in-memory cache of tiles. If you want to cache tiles for longer, you
  /// should implement an on-disk cache.
  Future<void> clearTileCache(TileOverlayId tileOverlayId) async {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.clearTileCache(
      tileOverlayId,
      mapId: mapId,
    );
  }

  /// Starts an animated change of the map camera position.
  ///
  /// The [duration] parameter specifies the duration of the animation.
  /// If null, the platform will decide the default value.
  ///
  /// The returned [Future] completes after the change has been started on the
  /// platform side.
  Future<void> animateCamera(CameraUpdate cameraUpdate, {Duration? duration}) {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.animateCameraWithConfiguration(
      cameraUpdate,
      CameraUpdateAnimationConfiguration(duration: duration),
      mapId: mapId,
    );
  }

  /// Changes the map camera position.
  ///
  /// The returned [Future] completes after the change has been made on the
  /// platform side.
  Future<void> moveCamera(CameraUpdate cameraUpdate) {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.moveCamera(
      cameraUpdate,
      mapId: mapId,
    );
  }

  /// Sets the styling of the base map.
  ///
  /// Set to `null` to clear any previous custom styling.
  ///
  /// If problems were detected with the [mapStyle], including un-parsable
  /// styling JSON, unrecognized feature type, unrecognized element type, or
  /// invalid styler keys: [MapStyleException] is thrown and the current
  /// style is left unchanged.
  ///
  /// The style string can be generated using [map style tool](https://mapstyle.withgoogle.com/).
  /// Also, refer [iOS](https://developers.google.com/maps/documentation/ios-sdk/style-reference)
  /// and [Android](https://developers.google.com/maps/documentation/android-sdk/style-reference)
  /// style reference for more information regarding the supported styles.
  @Deprecated('Use GoogleMap.style instead.')
  Future<void> setMapStyle(String? mapStyle) {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.setMapStyle(
      mapStyle,
      mapId: mapId,
    );
  }

  /// Returns the last style error, if any.
  Future<String?> getStyleError() {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.getStyleError(mapId: mapId);
  }

  /// Return [LatLngBounds] defining the region that is visible in a map.
  Future<LatLngBounds> getVisibleRegion() {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.getVisibleRegion(mapId: mapId);
  }

  /// Return [ScreenCoordinate] of the [LatLng] in the current map view.
  ///
  /// A projection is used to translate between on screen location and geographic coordinates.
  /// Screen location is in screen pixels (not display pixels) with respect to the top left corner
  /// of the map, not necessarily of the whole screen.
  Future<ScreenCoordinate> getScreenCoordinate(LatLng latLng) {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.getScreenCoordinate(
      latLng,
      mapId: mapId,
    );
  }

  /// Returns [LatLng] corresponding to the [ScreenCoordinate] in the current map view.
  ///
  /// Returned [LatLng] corresponds to a screen location. The screen location is specified in screen
  /// pixels (not display pixels) relative to the top left of the map, not top left of the whole screen.
  Future<LatLng> getLatLng(ScreenCoordinate screenCoordinate) {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.getLatLng(
      screenCoordinate,
      mapId: mapId,
    );
  }

  /// Programmatically show the Info Window for a [Marker].
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [hideMarkerInfoWindow] to hide the Info Window.
  ///   * [isMarkerInfoWindowShown] to check if the Info Window is showing.
  Future<void> showMarkerInfoWindow(MarkerId markerId) {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.showMarkerInfoWindow(
      markerId,
      mapId: mapId,
    );
  }

  /// Programmatically hide the Info Window for a [Marker].
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [showMarkerInfoWindow] to show the Info Window.
  ///   * [isMarkerInfoWindowShown] to check if the Info Window is showing.
  Future<void> hideMarkerInfoWindow(MarkerId markerId) {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.hideMarkerInfoWindow(
      markerId,
      mapId: mapId,
    );
  }

  /// Returns `true` when the [InfoWindow] is showing, `false` otherwise.
  ///
  /// The `markerId` must match one of the markers on the map.
  /// An invalid `markerId` triggers an "Invalid markerId" error.
  ///
  /// * See also:
  ///   * [showMarkerInfoWindow] to show the Info Window.
  ///   * [hideMarkerInfoWindow] to hide the Info Window.
  Future<bool> isMarkerInfoWindowShown(MarkerId markerId) {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.isMarkerInfoWindowShown(
      markerId,
      mapId: mapId,
    );
  }

  /// Returns the current zoom level of the map
  Future<double> getZoomLevel() {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.getZoomLevel(mapId: mapId);
  }

  /// Returns the image bytes of the map
  Future<Uint8List?> takeSnapshot() {
    _checkWidgetMountedOrThrow();
    return GoogleMapsFlutterPlatform.instance.takeSnapshot(mapId: mapId);
  }

  /// Disposes of the platform resources
  void dispose() {
    for (final StreamSubscription<dynamic> streamSubscription
    in _streamSubscriptions) {
      streamSubscription.cancel();
    }
    _streamSubscriptions.clear();
    GoogleMapsFlutterPlatform.instance.dispose(mapId: mapId);
  }

  /// It is relatively easy to mistakenly call a method on the controller
  /// after the [GoogleMap] widget has already been disposed.
  /// Historically, this led to Platform-side errors such as
  /// `MissingPluginException` or `Unable to establish connection on channel`
  /// errors.
  ///
  /// To facilitate debugging, this guard function
  /// raises a use-after-disposed [StateError].
  void _checkWidgetMountedOrThrow() {
    if (!_googleMapState.mounted) {
      throw StateError(
        'GoogleMapController for map ID $mapId was used after '
            'the associated GoogleMap widget had already been disposed.',
      );
    }
  }
}