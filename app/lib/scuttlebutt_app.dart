// File: app/lib/scuttlebutt_app.dart

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'post_screen.dart';

class ScuttlebuttApp extends StatelessWidget {
  const ScuttlebuttApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue[800],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue[800],
          unselectedItemColor: Colors.grey,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
        ),
      ),
      home: ScuttlebuttHomePage(),
    );
  }
}

class ScuttlebuttHomePage extends StatefulWidget {
  const ScuttlebuttHomePage({Key? key}) : super(key: key);

  @override
  _ScuttlebuttHomePageState createState() => _ScuttlebuttHomePageState();
}

class _ScuttlebuttHomePageState extends State<ScuttlebuttHomePage> {
  int _selectedIndex = 0;
  String _currentFeed = 'All DOD';

  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = ['Home', 'Messages', 'Profile'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _changeFeed(String feed) {
    setState(() {
      _currentFeed = feed;
    });
    Navigator.pop(context); // Close the drawer
  }

  Widget _buildFeedOption(String title) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: TextStyle(
              color: _currentFeed == title ? Colors.blue[800] : Colors.black,
              fontWeight:
                  _currentFeed == title ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: () => _changeFeed(title),
        ),
        Divider(height: 1, thickness: 1, color: Colors.grey[300]),
      ],
    );
  }

  String get _appBarTitle {
    if (_selectedIndex == 0) {
      return _currentFeed;
    } else {
      return 'Scuttlebutt';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle),
        actions: [
          if (_selectedIndex == 2) // Show settings icon only on Profile screen
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
            ),
        ],
      ),
      drawer: _selectedIndex == 0
          ? Drawer(
              child: Column(
                children: [
                  SafeArea(
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                          left: 16, bottom: 8, right: 16, top: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Divider(
                            height: 1, thickness: 1, color: Colors.grey[300]),
                        _buildFeedOption('All DOD'),
                        _buildFeedOption('All Navy'),
                        _buildFeedOption('My Command'),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostScreen(currentFeed: _currentFeed),
                  ),
                );
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}
