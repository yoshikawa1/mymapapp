import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';

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
  LatLng _initialPosition = LatLng(34.78, 135.42);

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  String _drawer_name = "";
  String _drawer_place = "";
  String _drawer_monday = "";
  String _drawer_tuesday = "";
  String _drawer_wednesday = "";
  String _drawer_thursday = "";
  String _drawer_friday = "";
  String _drawer_saturday = "";
  String _drawer_sunday = "";
  String _drawer_address = "";
  String _drawer_tel = "";
  String _drawer_note = "";

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    createMarkers(marker_tapped);
  }

  void _getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    var position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      print(position);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      drawer: MapDrawer(),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 15,
        ),
        markers: _markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }

  MapDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ListTile(
            title: Text("${_drawer_name}"),
          ),
          ListTile(
            title: Text('''設置場所
${_drawer_place}'''),
          ),
          ListTile(
            title: Text('''営業時間
月曜日 : ${_drawer_monday}
火曜日 : ${_drawer_tuesday}
水曜日 : ${_drawer_wednesday}
木曜日 : ${_drawer_thursday}
金曜日 : ${_drawer_friday}
土曜日 : ${_drawer_saturday}
日曜日 : ${_drawer_sunday}'''),
          ),
          ListTile(
            title: Text('''住所
${_drawer_address}'''),
          ),
          ListTile(
            title: Text('''電話番号
${_drawer_tel}'''),
          ),
          ListTile(
            title: Text('''備考
${_drawer_note}'''),
          ),
        ],
      ),
    );
  }

  marker_tapped(Place place) {
    setState(() {
      _drawer_name = place.name;
      _drawer_place = place.place;
      _drawer_monday = place.monday;
      _drawer_tuesday = place.tuesday;
      _drawer_wednesday = place.wednesday;
      _drawer_thursday = place.thursday;
      _drawer_friday = place.friday;
      _drawer_saturday = place.saturday;
      _drawer_sunday = place.sunday;
      _drawer_address = place.address;
      _drawer_tel = place.tel;
      _drawer_note = place.note;
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
        place: document['place'],
        monday: document['monday'],
        tuesday: document['tuesday'],
        wednesday: document['wednesday'],
        thursday: document['thursday'],
        friday: document['friday'],
        saturday: document['saturday'],
        sunday: document['sunday'],
        address: document['address'],
        tel: document['tel'],
        note: document['note'],
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
  String name;
  String place;
  String monday;
  String tuesday;
  String wednesday;
  String thursday;
  String friday;
  String saturday;
  String sunday;
  String address;
  String tel;
  String note;
  Place(
      {this.name = "",
      this.place = "",
      this.monday = "",
      this.tuesday = "",
      this.wednesday = "",
      this.thursday = "",
      this.friday = "",
      this.saturday = "",
      this.sunday = "",
      this.address = "",
      this.tel = "",
      this.note = ""});
}
