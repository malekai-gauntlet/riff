// Main container for the profile video grid with tab selection
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../domain/video/video_repository.dart';
import '../../../../../domain/video/video_model.dart';
import '../../../../screens/saved_videos/saved_video_view_screen.dart';
import 'video_thumbnail.dart';

class ProfileVideoGrid extends StatefulWidget {
  const ProfileVideoGrid({super.key});

  @override
  State<ProfileVideoGrid> createState() => _ProfileVideoGridState();
}

class _ProfileVideoGridState extends State<ProfileVideoGrid> {
  // Track which tab is selected (0 = Saved Recordings, 1 = Tutorials)
  int _selectedTabIndex = 0;
  
  // Repository instance
  final VideoRepository _videoRepository = VideoRepository();
  
  // Store videos
  List<Video> _savedVideos = [];
  bool _isLoading = false;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadSavedVideos();
  }
  
  // Load saved videos for current user
  Future<void> _loadSavedVideos() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final videos = await _videoRepository.getSavedVideos(userId);
      setState(() {
        _savedVideos = videos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load saved videos';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab selector
        Container(
          color: Colors.white,
          child: Row(
            children: [
              _buildTab(0, 'Saved Recordings'),
              _buildTab(1, 'Tutorials'),
            ],
          ),
        ),

        // Video grid
        Expanded(
          child: _selectedTabIndex == 0
              ? _buildSavedRecordingsGrid()
              : _buildTutorialsGrid(),
        ),
      ],
    );
  }
  
  Widget _buildSavedRecordingsGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSavedVideos,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (_savedVideos.isEmpty) {
      return const Center(
        child: Text(
          'No saved videos yet',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadSavedVideos,
      child: GridView.builder(
        padding: const EdgeInsets.all(1),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1 / 1.5,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: _savedVideos.length,
        itemBuilder: (context, index) {
          final video = _savedVideos[index];
          return VideoThumbnail(
            thumbnailUrl: video.thumbnailUrl,
            likeCount: video.likeCount,
            onTap: () {
              print('Grid item tapped! Video ID: ${video.id}'); // Debug print
              // Navigate to SavedVideoViewScreen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    print('Building SavedVideoViewScreen...'); // Debug print
                    return SavedVideoViewScreen(
                      initialVideo: video,
                      savedVideos: _savedVideos,
                      initialIndex: index,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildTutorialsGrid() {
    // TODO: Implement tutorials grid
    return const Center(
      child: Text(
        'Tutorials coming soon',
        style: TextStyle(color: Colors.black54),
      ),
    );
  }

  // Helper method to build individual tabs
  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.black54,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
} 