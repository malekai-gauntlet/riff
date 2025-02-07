// This class handles the logic for showing electric guitar videos in sequence
// when a user shows interest in an electric guitar video

import 'package:cloud_firestore/cloud_firestore.dart';

class ElectricVideoSequence {
  // Singleton instance
  static final ElectricVideoSequence _instance = ElectricVideoSequence._internal();
  factory ElectricVideoSequence() => _instance;
  ElectricVideoSequence._internal() {
    print('🎸 ElectricVideoSequence initialized');
  }

  // Track if we should show electric videos next
  bool _shouldShowElectric = false;
  
  // Track if we should suppress electric videos (accessible from outside)
  bool _suppressElectric = false;
  bool get suppressElectric => _suppressElectric;
  
  // Callback for when suppress state changes
  Function? onSuppressStateChanged;
  
  // Setter for suppressElectric that triggers callback
  set suppressElectric(bool value) {
    if (_suppressElectric != value) {
      _suppressElectric = value;
      onSuppressStateChanged?.call();
      print('🔄 Electric videos suppression changed to: $value');
    }
  }

  // Current video being watched
  String? _currentVideoId;
  
  // Last shown electric video
  String? _lastShownElectricId;
  
  // Track all played videos
  final Set<String> _playedVideos = {};
  
  // Timer for tracking watch time
  DateTime? _watchStartTime;

  // Start tracking watch time for a video
  void startWatching(String videoId) {
    _currentVideoId = videoId;
    _watchStartTime = DateTime.now();
    _playedVideos.add(videoId);  // Add to played videos
    print('🎸 Started watching video: $videoId at ${_watchStartTime!.toIso8601String()}');
    print('📝 Total played videos: ${_playedVideos.length}');
  }

  // Stop tracking watch time and process the result
  Future<void> stopWatching() async {
    if (_currentVideoId == null || _watchStartTime == null) {
      print('❌ stopWatching called but no video was being tracked');
      return;
    }

    final watchDuration = DateTime.now().difference(_watchStartTime!);
    print('🎸 Stopped watching video: $_currentVideoId');
    print('⏱️ Watch duration: ${watchDuration.inSeconds} seconds');
    
    // Check if current video has electric tag
    final videoDoc = await FirebaseFirestore.instance
        .collection('videos')
        .doc(_currentVideoId)
        .get();
    
    final tags = List<String>.from(videoDoc.data()?['tags'] ?? []);
    print('🏷️ Video tags: $tags');
    
    if (tags.contains('electric')) {
      // If electric video watched for less than 3 seconds
      if (watchDuration.inSeconds < 3) {
        suppressElectric = true;
        _shouldShowElectric = false;
        print('🚫 Electric video watched for <3 seconds, suppressing all electric videos');
      }
      // If watched for more than 6 seconds
      else if (watchDuration.inSeconds > 6) {
        print('✅ Watch threshold met (> 6 seconds)');
        
        // Check if there are any unplayed electric videos
        final unplayedQuery = await FirebaseFirestore.instance
            .collection('videos')
            .where('tags', arrayContains: 'electric')
            .where(FieldPath.documentId, whereNotIn: [..._playedVideos].toList())
            .get();
            
        if (unplayedQuery.docs.isNotEmpty) {
          _shouldShowElectric = true;
          print('⚡ Unplayed electric videos found! Will show one next');
        } else {
          print('🚫 No unplayed electric videos remaining');
        }
      }
    } else {
      print('🎸 Not an electric video');
    }

    // Reset tracking
    _currentVideoId = null;
    _watchStartTime = null;
    print('🔄 Reset tracking variables');
  }

  // Check if next video should be electric
  bool shouldShowElectricNext() {
    print('🤔 Checking if should show electric next: $_shouldShowElectric');
    return _shouldShowElectric;
  }

  // Get next electric video
  Future<DocumentSnapshot?> getNextElectricVideo() async {
    if (!_shouldShowElectric || suppressElectric) {
      print('❌ Not showing electric video: shouldShow=$_shouldShowElectric, suppressed=$suppressElectric');
      return null;
    }

    print('Searching for next unplayed electric video...');
    
    // Get all unplayed electric videos
    final querySnapshot = await FirebaseFirestore.instance
        .collection('videos')
        .where('tags', arrayContains: 'electric')
        .where(FieldPath.documentId, whereNotIn: [..._playedVideos].toList())
        .get();

    if (querySnapshot.docs.isEmpty) {
      print('❌ No unplayed electric videos remaining');
      _shouldShowElectric = false;
      return null;
    }

    // Reset flag after finding next video
    _shouldShowElectric = false;
    
    // Return a random unplayed electric video
    final random = DateTime.now().millisecondsSinceEpoch % querySnapshot.docs.length;
    final selectedVideo = querySnapshot.docs[random];
    print('✨ Selected next unplayed electric video: ${selectedVideo.id}');
    return selectedVideo;
  }
} 