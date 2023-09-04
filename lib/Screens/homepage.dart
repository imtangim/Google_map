// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_tutorial/Services/map_services.dart';
import 'package:map_tutorial/models/autocomplete.dart';
import 'package:map_tutorial/providers/searchplaces.dart';

class Homepage extends ConsumerStatefulWidget {
  const Homepage({super.key});

  @override
  ConsumerState<Homepage> createState() => _HomepageState();
}

class _HomepageState extends ConsumerState<Homepage> {
  // default location
  LatLng _userLocation = const LatLng(37.42796133580664, -122.085749655962);
  final List _location = [];
//phone location
  Location location = Location();
  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<dynamic> _requestLocationPermissions() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      // Location permissions have been denied, handle this case.

      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Location Permissions Required"),
            content: const Text(
                "To use this feature, please enable location permissions in your device settings."),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _getLocation() async {
    Location location = Location();

    _requestLocationPermissions();

    // Get the current location
    try {
      LocationData locationData = await location.getLocation();
      double? latitude = locationData.latitude;
      double? longitude = locationData.longitude;
      if (kDebugMode) {
        print("Before update: $_userLocation");
      }
      _userLocation = LatLng(latitude!, longitude!);
      _updateCameraPosition();

      if (kDebugMode) {
        print("After update: $_userLocation");
      }
      // You can store the location or use it as needed here.
    } catch (e) {
      // Handle location retrieval error
    }
  }

  //debouncer
  Timer? _debouncer;

  //Marker set
  Set<Marker> _marker = <Marker>{};
  int markerIdCounter = 1;

  TextEditingController searchController = TextEditingController();
  late GoogleMapController _controller;

  // Update the camera position with the user's location.
  void _updateCameraPosition() {
    final CameraPosition newPosition = CameraPosition(
      target: _userLocation,
      zoom: 14.0,
    );
    _controller.animateCamera(CameraUpdate.newCameraPosition(newPosition));
  }

  final Completer<GoogleMapController> _controler = Completer();
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  void setMarker(point) {
    var counter = markerIdCounter++;
    final Marker marker = Marker(
        markerId: MarkerId("marker_$counter"),
        position: point,
        onTap: () {},
        icon: BitmapDescriptor.defaultMarker);

    setState(() {
      _marker.add(marker);
    });
  }

  Future<BitmapDescriptor> createBlueDotIcon() async {
    const double iconSize = 30.0; // Set the size of the icon
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(
        pictureRecorder,
        Rect.fromPoints(
            const Offset(0.0, 0.0), const Offset(iconSize, iconSize)));

    final Paint paintCircle = Paint()
      ..color = Colors.blue // Set the color to blue
      ..style = PaintingStyle.fill;

    // Draw a blue circle on a transparent background
    canvas.drawCircle(
        const Offset(iconSize / 2, iconSize / 2), iconSize / 2, paintCircle);

    final img = await pictureRecorder
        .endRecording()
        .toImage(iconSize.toInt(), iconSize.toInt());
    final data = await img.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(
        Uint8List.sublistView(data!.buffer.asUint8List()));
  }

  void setUserMarker(point) async {
    final BitmapDescriptor blueDotIcon = await createBlueDotIcon();
    var counter = markerIdCounter++;
    final Marker marker = Marker(
        markerId: MarkerId("marker_$counter"),
        position: point,
        onTap: () {},
        icon: blueDotIcon);

    setState(() {
      _marker.add(marker);
    });
  }

  bool searchToggle = false;
  bool radiusSlider = false;
  bool pressedNear = false;
  bool cardTapped = false;
  bool getDirection = false;

//initial map position

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final allSearchResult = ref.watch(placeResultsProvider);
    final searchFlag = ref.watch(searchToggleProvider);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                SizedBox(
                  height: screenHeight,
                  width: screenWidth,
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _kGooglePlex,
                    onMapCreated: (GoogleMapController controller) {
                      if (!_controler.isCompleted) {
                        _controler.complete(controller);
                        _controller = controller;
                        // print("The marker: ${_marker}");
                      }
                    },
                    zoomControlsEnabled: false,
                    markers: _marker,
                  ),
                ),
                searchToggle
                    ? SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 10, 15, 5),
                          child: Column(
                            children: [
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: Colors.white,
                                ),
                                child: TextFormField(
                                  controller: searchController,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 15),
                                    border: InputBorder.none,
                                    hintText: "Search",
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          searchToggle = false;
                                          searchController.clear();
                                          _marker = {};
                                          if (searchFlag.searchToggle) {
                                            searchFlag.toggleSearch();
                                            print(
                                                "Hey : ${searchFlag.searchToggle}");
                                          }
                                        });
                                      },
                                      icon: const Icon(Icons.close),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    if (_debouncer?.isActive ?? false) {
                                      _debouncer?.cancel();
                                    }

                                    _debouncer = Timer(
                                      const Duration(milliseconds: 700),
                                      () async {
                                        if (value.length > 2) {
                                          searchFlag.toggleSearch();
                                          _marker = {};

                                          List<AutoCompleteResult>
                                              searchResults =
                                              await MapServices()
                                                  .searchplaces(value);

                                          allSearchResult
                                              .setResults(searchResults);
                                        } else {
                                          List<AutoCompleteResult> emptyList =
                                              [];
                                          allSearchResult.setResults(emptyList);
                                        }
                                      },
                                    );
                                  },
                                ),
                              )
                            ],
                          ),
                        ),
                      )
                    : Container(),
                searchFlag.searchToggle
                    ? allSearchResult.allReturns.isNotEmpty
                        ? Positioned(
                            top: 120,
                            left: 15,
                            child: Container(
                              height: 200,
                              width: screenWidth - 30.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withOpacity(0.9),
                              ),
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 3),
                                children: [
                                  ...allSearchResult.allReturns
                                      .map((e) => buildListItem(e, searchFlag))
                                ],
                              ),
                            ),
                          )
                        : Positioned(
                            top: 100,
                            left: 15,
                            child: Container(
                              height: 200,
                              width: screenWidth - 30.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withOpacity(0.7),
                              ),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Text(
                                      "No Search Results",
                                      style: TextStyle(
                                        fontFamily: 'WorkSans',
                                        fontWeight: FontWeight.w200,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    SizedBox(
                                      width: 125.0,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          searchFlag.toggleSearch();
                                        },
                                        child: const Center(
                                          child: Text(
                                            "Close This",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w300),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          )
                    : Container(),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: InkWell(
                    onTap: () {
                      _getLocation();
                      setUserMarker(_userLocation);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 5),
                      height: MediaQuery.of(context).size.height * 0.07,
                      width: MediaQuery.of(context).size.width * 0.14,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.gps_fixed_sharp,
                          size: 40,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
      floatingActionButton: FabCircularMenu(
        alignment: Alignment.bottomLeft,
        fabColor: Colors.blue.shade50,
        fabOpenColor: Colors.red.shade100,
        ringDiameter: 250.0,
        ringColor: Colors.blue.shade50,
        ringWidth: 60.0,
        fabSize: 60.0,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                searchToggle = true;
                radiusSlider = false;
                pressedNear = false;
                cardTapped = false;
                getDirection = false;
              });
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.navigation),
          )
        ],
      ),
    );
  }

  Future<void> gotoSearchedPlace(double lat, double long) async {
    final GoogleMapController controller = await _controler.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, long), zoom: 12),
      ),
    );
    setMarker(LatLng(lat, long));
    // print("lat and long: ${lat} , ${long}");
  }

  Widget buildListItem(AutoCompleteResult placeitem, searchFlag) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: GestureDetector(
        onTapDown: (_) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        onTap: () async {
          var place = await MapServices().getPlace(placeitem.placeId);
          gotoSearchedPlace(place['geometry']['location']['lat'],
              place['geometry']['location']['lng']);
          searchFlag.toggleSearch();

          searchFlag.toggleSearch();
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.green,
              size: 24,
            ),
            const SizedBox(
              width: 4.0,
            ),
            SizedBox(
              height: 40,
              width: MediaQuery.of(context).size.width - 75,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(placeitem.description ?? ""),
              ),
            )
          ],
        ),
      ),
    );
  }
}
