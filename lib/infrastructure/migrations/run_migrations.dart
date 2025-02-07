import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import '../../firebase_options.dart';
import 'fix_tutorial_thumbnails.dart';
import 'add_video_data.dart';
import 'fix_null_fields.dart';

/// Main function to run migrations
Future<void> main() async {
  try {
    // Initialize Flutter bindings
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('Running null fields fix migration...');
    
    // Run the fix null fields migration
    await fixNullFields();
    
    print('\nMigration completed successfully!');
  } catch (e) {
    print('Error running migration: $e');
    rethrow;
  }
} 