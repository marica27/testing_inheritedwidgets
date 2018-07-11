import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class Video extends StatefulWidget {
  String url;

  Video(this.url);

  @override
  _VideoState createState() => _VideoState();
}

class _VideoState extends State<Video> {
  VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..addListener(() {
        final bool isPlaying = _controller.value.isPlaying;
        if (isPlaying != _isPlaying) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      })
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {});
      })
   ;
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.initialized) {
      return new Center(child: new Text("cannot play video"));
    }
    return AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: new Stack(children: [
          Center(child: VideoPlayer(_controller)),
          new Center(
              child: new IconButton(
                  icon: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  onPressed: _controller.value.isPlaying
                      ? _controller.pause
                      : _controller.play))
        ]));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
