enum GeoJsonFeatureType {
  // ignore: constant_identifier_names
  Point,
  // ignore: constant_identifier_names
  Polygon,
  // ignore: constant_identifier_names
  LineString,
}

class GeoJsonBuilder {
  List<GeoJsonFeatureBuilder> features = [];

  GeoJsonBuilder();

  static Map<String, dynamic> get empty => GeoJsonBuilder().build();

  GeoJsonBuilder setFeatures(Iterable<GeoJsonFeatureBuilder> features) {
    this.features = features.toList();
    return this;
  }

  GeoJsonBuilder addFeature(GeoJsonFeatureBuilder feature) {
    features.add(feature);
    return this;
  }

  GeoJsonBuilder clearFeatures() {
    features = [];
    return this;
  }

  Map<String, dynamic> build() {
    return {'type': 'FeatureCollection', 'features': features.map((f) => f.build()).toList()};
  }
}

class GeoJsonFeatureBuilder<T extends GeoJsonFeatureType> {
  T type;
  int? id;
  List<dynamic> coordinates = [];
  Map<String, dynamic> properties = {};

  GeoJsonFeatureBuilder(this.type);

  GeoJsonFeatureBuilder setId(int id) {
    this.id = id;
    return this;
  }

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

  GeoJsonFeatureBuilder setProperty(String key, dynamic value) {
    this.properties[key] = value;
    return this;
  }

  Map<String, dynamic> build() {
    return {
      'type': 'Feature',
      'properties': properties,
      'geometry': {'type': type.name, 'coordinates': coordinates},
    };
  }
}
