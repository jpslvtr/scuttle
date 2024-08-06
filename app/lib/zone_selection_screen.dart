// File: app/lib/zone_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'app_state.dart';
import 'scuttlebutt_app.dart';

class ZoneSelectionScreen extends StatefulWidget {
  @override
  _ZoneSelectionScreenState createState() => _ZoneSelectionScreenState();
}

class _ZoneSelectionScreenState extends State<ZoneSelectionScreen> {
  String? _selectedZone;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permission denied, show manual selection
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied, show manual selection
      setState(() => _isLoading = false);
      return;
    }

    // Permission granted, get location
    try {
      Position position = await Geolocator.getCurrentPosition();
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.setUserLocation(position);
      String? recommendedZone = appState.getRecommendedZone();
      setState(() {
        _selectedZone = recommendedZone;
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting location: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Select Your Zone')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please select your zone:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ...AppState.zones.keys.map((zone) => RadioListTile<String>(
                        title: Text(zone),
                        value: zone,
                        groupValue: _selectedZone,
                        onChanged: (value) {
                          setState(() => _selectedZone = value);
                        },
                      )),
                  SizedBox(height: 16),
                  Center(
                    child: ElevatedButton(
                      child: Text('Confirm'),
                      onPressed: _selectedZone == null
                          ? null
                          : () async {
                              await appState.setUserCommand(_selectedZone!);
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) => ScuttleHomePage()),
                              );
                            },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
