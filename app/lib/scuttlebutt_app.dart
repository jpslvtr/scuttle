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
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
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

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    MessagesScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _widgetOptions.elementAt(_selectedIndex),
          if (_selectedIndex == 0)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PostScreen()),
                  );
                },
                child: Icon(Icons.add, color: Colors.white), // Changed to white
                backgroundColor: Colors.blue[800],
              ),
            ),
        ],
      ),
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
        selectedItemColor: Colors.blue[800], // Darker shade of blue
        unselectedItemColor:
            Colors.grey, // Slightly lighter shade for unselected items
        onTap: _onItemTapped,
      ),
    );
  }
}


