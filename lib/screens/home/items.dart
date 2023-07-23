import 'package:flutter/material.dart';
import 'package:insta_feed/screens/feed/video/feed_video_integration.dart';
import 'package:insta_feed/screens/feed/video/feed_video_integration_non_autoplay.dart';
import 'package:insta_feed/screens/feed/video/feed_video_integration_smooth.dart';
import 'package:insta_feed/screens/feed/video/feed_video_integration_non-image.dart';
import 'package:insta_feed/screens/feed/video/feed_video_integration_non_autoplay_render.dart';

List<Widget> items = [
  const FeedVideoIntegration(),
  const FeedVideoIntegrationSmooth(),
  const FeedVideoIntegrationNonImage(),
  const FeedVideoIntegrationNonAutoplay(),
  const FeedVideoIntegrationNonAutoplayRender(),
];
