import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // Fireabse初期化
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final Completer<GoogleMapController> _controller = Completer();
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(34.78, 135.42),
    zoom: 15,
  );
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    createMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        mapContainer(),
      ],
    );
  }

  mapContainer() {
    return Expanded(
        child: SizedBox(
      width: 1000,
      height: 900,
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        body: GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: _kGooglePlex,
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
        ),
      ),
    ));
  }

  markerTapped(Place place) {
    setState(() {});
  }

  void createMarkers() async {
    Set<Marker> markers = await getMarkers(markerTapped);
    setState(() {
      _markers = markers;
    });
  }
}

Future<Set<Marker>> getMarkers(void Function(Place) callback) async {
  Set<Place> places = await getPlaces();
  Set<Marker> markers = {};
  places.toList().asMap().forEach((k, v) {
    markers.add(Marker(
      markerId: MarkerId(k.toString()),
      position: v.latlng,
      onTap: () => callback(v),
      infoWindow: InfoWindow(title: v.name, snippet: v.info),
    ));
  });
  return markers;
}

// DBから取得
Future<Set<Place>> getPlaces() async {
  final storesStream =
      await FirebaseFirestore.instance.collection('maps').get();
  Set<Place> places = {};
  for (var document in storesStream.docs) {
    GeoPoint latLng = document['latLng'];
    places.add(Place(
      name: document['name'],
      info: document['note'],
      latlng: LatLng(latLng.latitude, latLng.longitude),
    ));
  }
  return places;
}

class Place {
  LatLng latlng;
  String name;
  String info;
  Place({this.name = "", this.info = "", this.latlng = const LatLng(0, 0)});
}
