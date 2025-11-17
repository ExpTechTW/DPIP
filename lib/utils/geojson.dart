/// GeoJSON geometry types supported by the builder classes.
///
/// These types correspond to the geometry types defined in the GeoJSON specification:
/// - [Point]: A single coordinate point
/// - [Polygon]: A closed area defined by one or more linear rings
/// - [LineString]: A sequence of connected points forming a line
enum GeoJsonFeatureType {
  /// A single coordinate point.
  ///
  /// Represents a single geographic location defined by a coordinate pair `[longitude, latitude]`.
  /// This is the simplest geometry type in GeoJSON, typically used for markers, pins, or point
  /// locations on a map.
  ///
  /// When using this type with [GeoJsonFeatureBuilder], the coordinates should be a single
  /// coordinate pair: `[longitude, latitude]`.
  Point,

  /// A closed area defined by one or more linear rings.
  ///
  /// Represents a polygon geometry, which is a closed area bounded by linear rings. The first
  /// linear ring defines the exterior boundary, and any additional rings define holes within the
  /// polygon.
  ///
  /// When using this type with [GeoJsonFeatureBuilder], the coordinates should be an array of
  /// linear rings, where each linear ring is an array of coordinate pairs. The first ring is the
  /// exterior boundary, and subsequent rings are holes.
  Polygon,

  /// A sequence of connected points forming a line.
  ///
  /// Represents a line geometry, which is a sequence of connected points forming a continuous
  /// path. This is typically used for roads, paths, boundaries, or any linear features on a map.
  ///
  /// When using this type with [GeoJsonFeatureBuilder], the coordinates should be an array of
  /// coordinate pairs: `[[lon1, lat1], [lon2, lat2], ...]`.
  LineString,
}

/// Builder class for constructing GeoJSON FeatureCollection objects.
///
/// This class provides a fluent interface for building GeoJSON FeatureCollections, which are collections
/// of GeoJSON features. All methods return the builder instance to support method chaining.
///
/// Example:
/// ```dart
/// final builder = GeoJsonBuilder()
///   ..addFeature(pointFeature)
///   ..addFeature(polygonFeature);
/// final geoJson = builder.build();
/// ```
class GeoJsonBuilder {
  /// The list of features in this FeatureCollection.
  List<GeoJsonFeatureBuilder> features = [];

  /// Creates a new [GeoJsonBuilder] instance.
  GeoJsonBuilder();

  /// Returns an empty GeoJSON FeatureCollection.
  ///
  /// This is a convenience getter that returns a valid but empty FeatureCollection map.
  static Map<String, dynamic> get empty => GeoJsonBuilder().build();

  /// Sets all features at once, replacing any existing features.
  ///
  /// The [features] parameter is converted to a list. This method clears any previously added features
  /// and replaces them with the provided features.
  ///
  /// Returns this builder for method chaining.
  GeoJsonBuilder setFeatures(Iterable<GeoJsonFeatureBuilder> features) {
    this.features = features.toList();
    return this;
  }

  /// Adds a single feature to this FeatureCollection.
  ///
  /// The [feature] is appended to the list of features. Multiple features can be added by calling
  /// this method multiple times.
  ///
  /// Returns this builder for method chaining.
  GeoJsonBuilder addFeature(GeoJsonFeatureBuilder feature) {
    features.add(feature);
    return this;
  }

  /// Removes all features from this builder.
  ///
  /// Clears the features list, effectively resetting the builder to an empty state.
  ///
  /// Returns this builder for method chaining.
  GeoJsonBuilder clearFeatures() {
    features = [];
    return this;
  }

  /// Builds and returns the GeoJSON FeatureCollection map.
  ///
  /// Returns a map representing a complete GeoJSON FeatureCollection, ready to be serialized to JSON.
  /// The map contains a 'type' field set to 'FeatureCollection' and a 'features' array containing
  /// all added features.
  Map<String, dynamic> build() {
    return {
      'type': 'FeatureCollection',
      'features': features.map((f) => f.build()).toList(),
    };
  }
}

/// Builder class for constructing GeoJSON Feature objects.
///
/// This class provides a fluent interface for building individual GeoJSON features, which consist of
/// a geometry type, coordinates, optional ID, and properties. All methods return the builder instance
/// to support method chaining.
///
/// The geometry type is specified at construction time and determines how coordinates are interpreted:
/// - [GeoJsonFeatureType.Point]: Coordinates should be a single coordinate pair `[longitude, latitude]`
/// - [GeoJsonFeatureType.Polygon]: Coordinates should be an array of linear rings (arrays of coordinate pairs)
/// - [GeoJsonFeatureType.LineString]: Coordinates should be an array of coordinate pairs
///
/// Example:
/// ```dart
/// final feature = GeoJsonFeatureBuilder(GeoJsonFeatureType.Point)
///   ..setGeometry([121.5, 25.0])
///   ..setProperty('name', 'Taipei')
///   ..setId(1);
/// final geoJson = feature.build();
/// ```
class GeoJsonFeatureBuilder<T extends GeoJsonFeatureType> {
  /// The geometry type of this feature.
  T type;

  /// Optional feature ID.
  int? id;

  /// The coordinates for this feature's geometry.
  ///
  /// The format depends on the [type]:
  /// - For [GeoJsonFeatureType.Point]: `[longitude, latitude]`
  /// - For [GeoJsonFeatureType.LineString]: `[[lon1, lat1], [lon2, lat2], ...]`
  /// - For [GeoJsonFeatureType.Polygon]: `[[[lon1, lat1], [lon2, lat2], ...]]` (array of linear rings)
  List<dynamic> coordinates = [];

  /// Custom properties associated with this feature.
  ///
  /// Properties can contain any additional metadata about the feature, such as names, values, or
  /// other attributes.
  Map<String, dynamic> properties = {};

  /// Creates a new [GeoJsonFeatureBuilder] with the specified geometry [type].
  GeoJsonFeatureBuilder(this.type);

  /// Sets the optional feature ID.
  ///
  /// The [id] is included in the built feature if provided. Feature IDs are useful for identifying
  /// features in GeoJSON data.
  ///
  /// Returns this builder for method chaining.
  GeoJsonFeatureBuilder setId(int id) {
    this.id = id;
    return this;
  }

  /// Sets the geometry coordinates for this feature.
  ///
  /// The format of [coordinates] depends on the feature [type]:
  /// - For [GeoJsonFeatureType.Point]: A single coordinate pair `[longitude, latitude]`
  /// - For [GeoJsonFeatureType.LineString]: An array of coordinate pairs
  /// - For [GeoJsonFeatureType.Polygon]: An array of linear rings (arrays of coordinate pairs)
  ///
  /// The method automatically handles coordinate wrapping for Polygon and LineString types. If all
  /// elements in [coordinates] are lists, it wraps them in an additional array level for Polygon types.
  ///
  /// Returns this builder for method chaining.
  GeoJsonFeatureBuilder setGeometry(List<dynamic> coordinates) {
    if (type == GeoJsonFeatureType.Point) {
      this.coordinates = coordinates;
      return this;
    }

    if (coordinates.every((element) => element is List)) {
      this.coordinates = [coordinates];
    } else {
      this.coordinates = coordinates;
    }
    return this;
  }

  /// Sets a property value for this feature.
  ///
  /// Properties are key-value pairs that provide additional metadata about the feature. Multiple
  /// properties can be set by calling this method multiple times.
  ///
  /// Returns this builder for method chaining.
  GeoJsonFeatureBuilder setProperty(String key, dynamic value) {
    properties[key] = value;
    return this;
  }

  /// Builds and returns the GeoJSON Feature map.
  ///
  /// Returns a map representing a complete GeoJSON Feature, ready to be serialized to JSON.
  /// The map contains 'type', 'geometry', and 'properties' fields. The 'id' field is included only
  /// if it was set via [setId].
  Map<String, dynamic> build() {
    final result = <String, dynamic>{
      'type': 'Feature',
      'properties': properties,
      'geometry': {'type': type.name, 'coordinates': coordinates},
    };
    if (id != null) {
      result['id'] = id;
    }
    return result;
  }
}
