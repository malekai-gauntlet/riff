import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/profile/profile_view_screen.dart';
import 'presentation/screens/feed/feed_screen.dart';
import 'presentation/widgets/navigation/bottom_nav_bar.dart';
import 'presentation/widgets/navigation/feed_toggle.dart';
import 'presentation/widgets/video/video_action_buttons.dart';
import 'auth/infrastructure/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDgao37t6Nnzv3mCIrJR_A6TkPcOofz8Rw',
        appId: '1:96689107158:ios:a7ba68094857c78a239977',
        messagingSenderId: '96689107158',
        projectId: 'riff-8a2c9',
        storageBucket: 'riff-8a2c9.firebasestorage.app',
        authDomain: 'riff-8a2c9.firebaseapp.com', // Add this for web
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riff',
      theme: ThemeData(
        // Custom theme colors that feel more musical/guitar-focused
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4CE6), // Deep purple as primary
          secondary: const Color(0xFFFF8A65), // Warm orange as accent
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthRepository().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return const HomePage();
        }
        
        return const LoginScreen();
      },
    );
  }
}

// Creating a dedicated HomePage widget instead of MyHomePage
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int _selectedFeedIndex = 1; // Default to "For You"

  // Updated method to get the current screen based on selected index
  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0: // Home
        return Stack(
          children: [
            const FeedScreen(), // Use our new FeedScreen
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 0,
              right: 0,
              child: FeedToggle(
                selectedIndex: _selectedFeedIndex,
                onToggle: (index) => setState(() => _selectedFeedIndex = index),
              ),
            ),
          ],
        );
      case 3: // Profile (was previously 4)
        return const ProfileViewScreen();
      default:
        return const Center(
          child: Text(
            'Coming Soon!',
            style: TextStyle(color: Colors.white),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Remove the AppBar since we're positioning FeedToggle in the Stack
      body: _getCurrentScreen(),
      bottomNavigationBar: RiffBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
