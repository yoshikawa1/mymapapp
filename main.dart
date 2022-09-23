import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  MobileAds.instance.initialize();
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
  late LatLng _initialPosition;
  late bool _loading;
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
  String _drawer_quote = "";
  static const double textSmall = 8;
  static const double textMedium = 12;
  static const double textLarge = 18;
  late BannerAd myBanner;

  @override
  void initState() {
    super.initState();
    _loading = true;
    _setBanner();
    _getUserLocation();
    _createMarkers(marker_tapped);
  }

  void _setBanner() async {
    // バナー広告をインスタンス化
    myBanner = BannerAd(
        adUnitId:
            "ca-app-pub-3940256099942544/2934735716", // Androidのデモ用バナー広告ID
        size: AdSize.banner,
        request: const AdRequest(),
        listener: const BannerAdListener());
    // バナー広告の読み込み
    myBanner.load();
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
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: MapDrawer(),
      body: _loading
          ? const CircularProgressIndicator()
          : SafeArea(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialPosition,
                      zoom: 15,
                    ),
                    markers: _markers,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapToolbarEnabled: false,
                    buildingsEnabled: true,
                  ),
                  AdWidget(ad: myBanner)
                ],
              ),
            ),
    );
  }

  MapDrawer() {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.only(top: 18),
        children: [
          ListTile(
            title: Text(
              _drawer_name,
              style: const TextStyle(fontSize: textLarge),
            ),
          ),
          ListTile(
            title: Text(
              '''設置場所
$_drawer_place''',
            ),
          ),
          ListTile(
            title: Text('''営業時間
月曜日 : $_drawer_monday
火曜日 : $_drawer_tuesday
水曜日 : $_drawer_wednesday
木曜日 : $_drawer_thursday
金曜日 : $_drawer_friday
土曜日 : $_drawer_saturday
日曜日 : $_drawer_sunday'''),
          ),
          ListTile(
            title: Text('''住所
$_drawer_address'''),
          ),
          ListTile(
            title: Text('''電話番号
$_drawer_tel'''),
          ),
          ListTile(
            title: Text('''備考
$_drawer_note'''),
          ),
          ListTile(
            title: Text('''引用
$_drawer_quote'''),
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
      _drawer_quote = place.quote;
    });
    _scaffoldKey.currentState?.openDrawer();
  }

  void _createMarkers(void Function(Place) callback) async {
    final storesStream =
        await FirebaseFirestore.instance.collection('maps').get();
    Set<Marker> __markers = {};
    int key = 0;
    for (var document in storesStream.docs) {
      var now = DateTime.now();
      String businessHours = "";
      double makerColor;

      switch (now.weekday) {
        case 0:
          businessHours = document['sunday'];
          break;
        case 1:
          businessHours = document['monday'];
          break;
        case 2:
          businessHours = document['tuesday'];
          break;
        case 3:
          businessHours = document['wednesday'];
          break;
        case 4:
          businessHours = document['thursday'];
          break;
        case 5:
          businessHours = document['friday'];
          break;
        case 6:
          businessHours = document['saturday'];
          break;
        default:
      }

      //営業中か判定
      if (businessHours == "-") {
        makerColor = BitmapDescriptor.hueAzure;
      } else if (businessHours == "") {
        makerColor = BitmapDescriptor.hueGreen;
      } else {
        var businessHourSplit = businessHours.split(",");
        makerColor = BitmapDescriptor.hueAzure;
        for (var businessHour in businessHourSplit) {
          var splitTime = businessHour.split("～");
          String openHour = splitTime[0].split(":")[0];
          String openMinute = splitTime[0].split(":")[1];
          String closeHour = splitTime[1].split(":")[0];
          String closeMinute = splitTime[1].split(":")[1];
          DateTime openTime = DateTime(now.year, now.month, now.day,
              int.parse(openHour), int.parse(openMinute));
          DateTime closeTime = DateTime(now.year, now.month, now.day,
              int.parse(closeHour), int.parse(closeMinute));

          if (openTime.isBefore(now) & now.isBefore(closeTime)) {
            makerColor = BitmapDescriptor.hueRed;
            break;
          }
        }
      }

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
        quote: document['quote'],
      );

      __markers.add(Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(makerColor),
        markerId: MarkerId(key.toString()),
        position: LatLng(document['lat'], document['lng']),
        onTap: () => callback(place),
      ));
      key++;
    }
    setState(() {
      _markers = __markers;
    });
  }
}

//ドロワーで使用
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
  String quote;
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
      this.note = "",
      this.quote = ""});
}
