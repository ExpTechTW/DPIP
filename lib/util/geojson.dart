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

  GeoJsonBuilder setFeatures(List<GeoJsonFeatureBuilder> features) {
    this.features = features;
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
    return {
      "type": "FeatureCollection",
      "features": features.map((f) => f.build()).toList(),
    };
  }
}

class GeoJsonFeatureBuilder<T extends GeoJsonFeatureType> {
  T type;
  int? id;
  List<dynamic> coordinates = [];
  Map<String, dynamic> properties = {};

  GeoJsonFeatureBuilder(this.type);

  GeoJsonFeatureBuilder setGeometry(List<dynamic> coordinates) {
    this.coordinates = coordinates;
    return this;
  }

  GeoJsonFeatureBuilder setProperty(String key, value) {
    this.properties[key] = value;
    return this;
  }

  Map<String, dynamic> build() {
    return {
      "type": "Feature",
      "properties": properties,
      "geometry": {
        "type": type.name,
        "coordinates": coordinates,
      }
    };
  }
}
