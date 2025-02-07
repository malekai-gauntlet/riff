import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../domain/video/video_model.dart';
import '../../../domain/video/video_repository.dart';
import '../../widgets/video/video_action_buttons.dart';
import '../../../domain/video/electric_video_sequence.dart';
import '../../physics/one_page_scroll_physics.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  // Repository to fetch videos
  final VideoRepository _videoRepository = VideoRepository();
  
  // Electric video sequence handler
  final ElectricVideoSequence _electricSequence = ElectricVideoSequence();
  
  // List to store fetched videos
  List<Video> _videos = [];
  
  // Loading state
  bool _isLoading = false;

  // Add PageController
  late final PageController _pageController;
  // Track current page
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 1.0,
      keepPage: true,
    );
    // Set up callback for when electric suppression changes
    _electricSequence.onSuppressStateChanged = () {
      print('🔄 Filtering out electric videos from current feed');
      setState(() {
        // Filter existing videos without reloading
        if (_electricSequence.suppressElectric) {
          _videos = _videos.where((video) => !video.tags.contains('electric')).toList();
          print('🎸 Removed electric videos. ${_videos.length} videos remaining');
        }
      });
    };
    _loadVideos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  // Load initial videos
  Future<void> _loadVideos() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final videos = await _videoRepository.getVideoFeed();
      
      // Filter out electric videos if they should be suppressed
      final filteredVideos = _electricSequence.suppressElectric
          ? videos.where((video) => !video.tags.contains('electric')).toList()
          : videos;
          
      print('🎸 Loaded ${filteredVideos.length} videos (suppressing electric: ${_electricSequence.suppressElectric})');
      
      setState(() {
        _videos = filteredVideos;
      });
      
      // Remove initial tracking - will be handled by _VideoItem
    } catch (e) {
      print('Error loading videos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle page changes and electric video sequence
  void _handlePageChange(int index) async {
    // Stop tracking previous video
    await _electricSequence.stopWatching();
    
    setState(() {
      _currentPage = index;
    });

    // Check if we should show an electric video
    if (_electricSequence.shouldShowElectricNext()) {
      final nextElectricVideo = await _electricSequence.getNextElectricVideo();
      if (nextElectricVideo != null) {
        // Convert Firestore document to Video model
        final video = Video.fromFirestore(nextElectricVideo);
        
        // Insert the electric video as the next video
        setState(() {
          _videos.insert(index + 1, video);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const OnePageScrollPhysics().applyTo(
                const ClampingScrollPhysics(),
              ),
              itemCount: _videos.length + 1, // Add 1 for end screen
              onPageChanged: _handlePageChange,
              itemBuilder: (context, index) {
                // Show end screen if we're at the last index
                if (index == _videos.length) {
                  return Container(
                    color: Colors.black,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "That's all the riffs!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "More coming tomorrow.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                final video = _videos[index];
                return _VideoItem(
                  video: video,
                  isVisible: index == _currentPage,
                  onVisibilityChanged: (isVisible) {
                    if (isVisible) {
                      _electricSequence.startWatching(video.id);
                    }
                  },
                );
              },
            ),
    );
  }
}

// Individual video item widget
class _VideoItem extends StatefulWidget {
  final Video video;
  final bool isVisible;
  final Function(bool isVisible) onVisibilityChanged;

  const _VideoItem({
    required this.video,
    required this.isVisible,
    required this.onVisibilityChanged,
  });

  @override
  State<_VideoItem> createState() => _VideoItemState();
}

class _VideoItemState extends State<_VideoItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    // Start tracking if this is the first visible video
    if (widget.isVisible) {
      widget.onVisibilityChanged(true);
    }
  }

  @override
  void didUpdateWidget(_VideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible) {
      widget.onVisibilityChanged(widget.isVisible);
      if (widget.isVisible) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.network(widget.video.url);
    
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  void _togglePlayPause() async {
    print('Tap detected!'); // Debug print
    if (!_isInitialized) return;

    try {
      if (_controller.value.isPlaying) {
        print('Pausing video...'); // Debug print
        await _controller.pause();
      } else {
        print('Playing video...'); // Debug print
        await _controller.play();
      }
      // Force rebuild to update UI
      setState(() {});
    } catch (e) {
      print('Error toggling play/pause: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // Make sure tap is detected anywhere
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          if (widget.isVisible && _isInitialized)
            VideoPlayer(_controller)
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
            
          // Play/Pause indicator overlay
          if (widget.isVisible && _isInitialized)
            AnimatedOpacity(
              opacity: _controller.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(),
              ),
            ),
            
          // Action buttons (right side)
          Positioned(
            right: 8,
            bottom: 80, // Moved 25 pixels lower (was 80)
            child: VideoActionButtons(
              video: widget.video,
              controller: _controller,
            ),
          ),
            
          // Video info overlay (bottom)
          Positioned(
            left: 0,
            right: 70, // Make room for action buttons
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.video.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 