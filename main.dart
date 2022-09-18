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
  String _drawer_name = "";
  String _drawer_info = "";
  String _drawer_lat = "";
  String _drawer_lng = "";

  @override
  void initState() {
    super.initState();
    createMarkers(marker_tapped);
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
        drawer: MapDrawer(),
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

  MapDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            title: Text("name: ${_drawer_name}"),
          ),
          ListTile(
            title: Text("info: ${_drawer_info}"),
          ),
          ListTile(
            title: Text("latitude: ${_drawer_lat}"),
          ),
          ListTile(
            title: Text("longitude: ${_drawer_lng}"),
          ),
        ],
      ),
    );
  }

  marker_tapped(Place place) {
    setState(() {
      _drawer_name = place.name;
      _drawer_info = place.info;
      _drawer_lat = place.latlng.latitude.toString();
      _drawer_lng = place.latlng.longitude.toString();
    });
    _scaffoldKey.currentState?.openDrawer();
  }

  void createMarkers(void Function(Place) callback) async {
    final storesStream =
        await FirebaseFirestore.instance.collection('maps').get();
    Set<Marker> __markers = {};
    int key = 0;
    for (var document in storesStream.docs) {
      //現在曜日時間を取得
      //現在曜日のフィールドを取得
      //閉鎖
      GeoPoint latLng = document['latLng'];
      Place place = Place(
        name: document['name'],
        info: document['note'],
        latlng: LatLng(latLng.latitude, latLng.longitude),
      );

      __markers.add(Marker(
        markerId: MarkerId(key.toString()),
        position: LatLng(latLng.latitude, latLng.longitude),
        onTap: () => callback(place),
      ));
      key++;
    }
    setState(() {
      _markers = __markers;
    });
  }
}

class Place {
  LatLng latlng;
  String name;
  String info;
  Place({this.name = "", this.info = "", this.latlng = const LatLng(0, 0)});
}
