// File: app/lib/zone_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
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
  String? _selectedZone;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isInitialSetup) {
      _requestLocationPermission();
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() => _isLoading = true);
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => _isLoading = false);
      return;
    }

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
      appBar: AppBar(
        title: Text(
            widget.isInitialSetup ? 'Select Your Zone' : 'Change Your Zone'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedZone != null && widget.isInitialSetup)
                    Text(
                      'Recommended zone based on your location: $_selectedZone',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  SizedBox(height: 16),
                  Text(
                    'Please select your command zone:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        RadioListTile<String?>(
                          title: Text('No Zone'),
                          value: null,
                          groupValue: _selectedZone,
                          onChanged: (value) {
                            setState(() => _selectedZone = value);
                          },
                        ),
                        ...AppState.zones.keys
                            .map((zone) => RadioListTile<String>(
                                  title: Text(zone),
                                  value: zone,
                                  groupValue: _selectedZone,
                                  onChanged: (value) {
                                    setState(() => _selectedZone = value);
                                  },
                                ))
                            .toList(),
                      ],
                    ),
                  ),
                  Center(
                    child: ElevatedButton(
                      child: Text('Confirm'),
                      onPressed: () async {
                        await appState.setUserCommand(_selectedZone);
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
    );
  }
}
