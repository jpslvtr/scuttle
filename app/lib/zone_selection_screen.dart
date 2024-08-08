import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';
import 'scuttlebutt_app.dart';

class ZoneSelectionScreen extends StatefulWidget {
  final bool isInitialSetup;

  const ZoneSelectionScreen({Key? key, this.isInitialSetup = true})
      : super(key: key);

  @override
  _ZoneSelectionScreenState createState() => _ZoneSelectionScreenState();
}

class _ZoneSelectionScreenState extends State<ZoneSelectionScreen> {
  String? _recommendedZone;
  bool _isLoading = false;
  bool _isLocationDenied = false;

  @override
  void initState() {
    super.initState();
    _initializeUserAndCheckLocation();
  }

  Future<void> _initializeUserAndCheckLocation() async {
    setState(() => _isLoading = true);

    final appState = Provider.of<AppState>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await appState.initializeUser(user.uid);
    }

    await _checkAndRequestLocationPermission();

    setState(() => _isLoading = false);
  }

  Future<void> _checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLocationDenied = true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLocationDenied = true);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLocationDenied = true);
      return;
    }

    _checkLocationAndSetZone();
  }

  Future<void> _checkLocationAndSetZone() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.setUserLocation(position);
      String? recommendedZone = appState.getRecommendedZone();
      setState(() {
        _recommendedZone = recommendedZone;
        _isLocationDenied = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLocationDenied = true);
    }
  }

  Future<void> _setZoneAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('zone_acknowledged', true);
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return WillPopScope(
      onWillPop: () async => !widget.isInitialSetup,
      child: Scaffold(
        appBar: widget.isInitialSetup
            ? null
            : AppBar(
                title: Text('Set Zone'),
              ),
        body: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),
                      if (_isLocationDenied)
                        _buildLocationDeniedWidget()
                      else if (_recommendedZone != null)
                        Text(
                          'Recommended zone based on your location: $_recommendedZone',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        )
                      else
                        _buildNoZoneWidget(),
                      SizedBox(height: 24),
                      Expanded(
                        child: ListView(
                          children: AppState.zones.keys.map((zone) {
                            bool isRecommended = zone == _recommendedZone;
                            bool isEnabled = _recommendedZone != null;
                            return ListTile(
                              title: Text(zone),
                              enabled: isEnabled,
                              selected: isRecommended,
                              tileColor: isRecommended
                                  ? Colors.blue.withOpacity(0.1)
                                  : null,
                              textColor: isEnabled ? null : Colors.grey,
                            );
                          }).toList(),
                        ),
                      ),
                      SizedBox(height: 16),
                      Center(
                        child: ElevatedButton(
                          child: Text(
                              widget.isInitialSetup ? 'Proceed' : 'Confirm'),
                          onPressed: () async {
                            if (!_isLocationDenied) {
                              await appState.setUserCommand(_recommendedZone);
                            }
                            await _setZoneAcknowledged();
                            if (widget.isInitialSetup) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => ScuttleHomePage()),
                              );
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildLocationDeniedWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location access is currently denied.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'You will only see the main feed. You can grant location permission later in the settings.',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 16),
        if (!widget.isInitialSetup)
          ElevatedButton(
            child: Text('Open Location Settings'),
            onPressed: () async {
              await Geolocator.openLocationSettings();
              _checkAndRequestLocationPermission();
            },
          ),
      ],
    );
  }

  Widget _buildNoZoneWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You are not close to any of the zones.',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'You will only have access to the main feed.',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
