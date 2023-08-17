import 'package:flutter/material.dart';
import 'package:insta_feed/screens/feed/video/feed_video_integration_global.dart';

List<Widget> items = [
  const FeedVideoIntegrationGlobal(
      autoplay: true, render: true, controls: true),
  const FeedVideoIntegrationGlobal(
      autoplay: true, render: false, controls: true),
  const FeedVideoIntegrationGlobal(
      autoplay: false, render: true, controls: true),
  const FeedVideoIntegrationGlobal(
      autoplay: false, render: false, controls: true),
];
