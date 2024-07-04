import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class ScuttlebuttApp extends StatelessWidget {
  const ScuttlebuttApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8C1515),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8C1515),
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Color(0xFF8C1515),
          unselectedItemColor: Colors.grey,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF8C1515),
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

  void _openSettings() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return const SettingsScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _openSettings,
          ),
        ],
      ),
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
        onTap: _onItemTapped,
        showUnselectedLabels: true,
      ),
    );
  }
}
