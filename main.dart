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

  void createMarkers() async {
    final storesStream =
        await FirebaseFirestore.instance.collection('maps').get();
    Set<Marker> __markers = {};
    int key = 0;
    for (var document in storesStream.docs) {
      //現在曜日時間を取得
      //現在曜日のフィールドを取得
      //閉鎖
      GeoPoint latLng = document['latLng'];
      __markers.add(Marker(
        markerId: MarkerId(key.toString()),
        position: LatLng(latLng.latitude, latLng.longitude),
        infoWindow:
            InfoWindow(title: document['name'], snippet: document['note']),
      ));
      key++;
    }
    setState(() {
      _markers = __markers;
    });
  }
}
