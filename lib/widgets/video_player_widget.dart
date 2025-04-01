import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

Widget buildVideoPlayer(
  VideoPlayerController controller,
  bool isInitialized,
  bool isPlaying,
  Function() onPlayPause,
  Function() onRestart,
) {
  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.pinkAccent, width: 4),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isInitialized && controller.value.isInitialized)
            AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(controller),
                  // Add a semi-transparent overlay to make the video less distracting
                  Container(
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            )
          else
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.purpleAccent,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.music_note,
                        size: 100,
                        color: Colors.purpleAccent,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading video...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Add video controls overlay
          if (isInitialized && controller.value.isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: onPlayPause,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      onPressed: onRestart,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// New background video player function
Widget buildBackgroundVideoPlayer(
  VideoPlayerController controller,
  bool isInitialized,
  bool isPlaying,
  Function() onPlayPause,
  Function() onRestart,
) {
  if (isInitialized && controller.value.isInitialized) {
    return FittedBox(
      fit: BoxFit.cover, // Changed back to BoxFit.cover
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  } else {
    return Container(
      color: Colors.black,
      child: Center(
        child: CircularProgressIndicator(
          color: Colors.purpleAccent,
          strokeWidth: 3,
        ),
      ),
    );
  }
}
