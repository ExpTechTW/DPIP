import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:flutter_map_geojson/flutter_map_geojson.dart';

// ignore: depend_on_referenced_packages
import 'package:latlong2/latlong.dart';

String testGeoJson = '''
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "geometry": {
        "type": "MultiPolygon",
        "coordinates": [
          [  
            [ 
              [ 
                14.475314661954956,
                45.99528512959203
              ],
              [
                14.48295359322937,
                45.997073943280554
              ],
              [
                14.48544268319519,
                45.99498698835544
              ],
              [
                14.485614344572143,
                45.992124750758606
              ],
              [
                14.485356852506714,
                45.99033577708827
              ],
              [
                14.478318736051635,
                45.98801002486849
              ],
              [ 
                14.475314661954956,
                45.99528512959203
              ]
            ]
          ],

          [  
            [ 
              [ 
                14.486300990079956,
                45.997670201660156
              ],
              [
                14.493510767911987,
                45.99933969094237
              ],
              [
                14.49668650338562,
                45.99361551797875
              ],
              [
                14.488532587980346,
                45.991409168229445
              ],
              [
                14.486043498014526,
                45.990872475261
              ],
              [
                14.486043498014526,
                45.99516587329015
              ],
              [ 
                14.4832110852948,
                45.99737207327347
              ],
              [ 
                14.486300990079956,
                45.997670201660156
              ]
            ],
            [
              [ 
                14.48706543480164,
                45.99650302788219
              ],
              [
                14.490992188799442,
                45.997486860913625
              ],
              [
                14.492451310503544,
                45.99505705971195
              ],
              [
                14.488138318407596,
                45.99395392456707
              ],
              [ 
                14.48706543480164,
                45.99650302788219
              ]
            ],
            [
              [ 
                14.4890395406366,
                45.99229686071988
              ],
              [
                14.493502736437382,
                45.993429843946096
              ],
              [
                14.49281609092957,
                45.99435410255712
              ],
              [
                14.488524556505741,
                45.99319132308913
              ],
              [ 
                14.4890395406366,
                45.99229686071988
              ]
            ]
          ]
        ]
      },
      "properties": {
        "gid": 14,
        "obmocje": "Test polygon"
      }
    },
    {
      "type": "Feature",
      "geometry": {
        "type": "MultiPoint",
        "coordinates": 
        [
          [14.482672, 45.989040],
          [14.489469, 45.990370]
        ]
      },
      "properties": {
        "section": "Multipoint M-10"
      }
    },    
    {
      "type": "Feature",
      "geometry": {
        "type": "Point",
        "coordinates": 
        [14.481, 45.982]
      },
      "properties": {
        "section": "Point M-4"
      }
    }
  ]
}
''';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GeoJsonParser myGeoJson = GeoJsonParser(
      defaultPolygonBorderColor: Colors.red,
      defaultPolygonFillColor: Colors.red.withOpacity(0.1));

  bool loadingData = false;

  Future<void> processData() async {
    myGeoJson.parseGeoJsonAsString(testGeoJson);
  }

  @override
  void initState() {
    loadingData = true;
    processData().then((_) {
      setState(() {
        loadingData = false;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Container(
        color: Colors.black, // 设置容器的背景色为黑色
        child: FlutterMap(
          mapController: MapController(),
          options: MapOptions(
            center: const LatLng(45.993807, 14.483972),
            //center: LatLng(45.720405218, 14.406593302),
            zoom: 14,
          ),
          children: [
                PolygonLayer(
                    polygons: myGeoJson.polygons,
                  ),
            PolylineLayer(polylines: myGeoJson.polylines),
          ],
        ),
      ),
    );
  }
}
