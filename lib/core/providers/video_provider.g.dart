// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$videoStateHash() => r'b547a57e864eab9f3711fa1f364257eb63e51b4f';

/// See also [VideoState].
@ProviderFor(VideoState)
final videoStateProvider =
    AutoDisposeAsyncNotifierProvider<VideoState, List<VideoInfo>>.internal(
  VideoState.new,
  name: r'videoStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$videoStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$VideoState = AutoDisposeAsyncNotifier<List<VideoInfo>>;
String _$currentVideoHash() => r'1ccf888d44394072117995637b9cc4f2252b8552';

/// See also [CurrentVideo].
@ProviderFor(CurrentVideo)
final currentVideoProvider =
    AutoDisposeNotifierProvider<CurrentVideo, VideoInfo?>.internal(
  CurrentVideo.new,
  name: r'currentVideoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentVideoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CurrentVideo = AutoDisposeNotifier<VideoInfo?>;
String _$streamStateHash() => r'8a951e91f5fa2cc62045a4487566449b84e63c3a';

/// See also [StreamState].
@ProviderFor(StreamState)
final streamStateProvider =
    AutoDisposeAsyncNotifierProvider<StreamState, StreamInfo?>.internal(
  StreamState.new,
  name: r'streamStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$streamStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$StreamState = AutoDisposeAsyncNotifier<StreamInfo?>;
String _$playbackStateHash() => r'0ee0dca3722d08f0dbf756a52cc7d392d6579cc8';

/// See also [PlaybackState].
@ProviderFor(PlaybackState)
final playbackStateProvider = AutoDisposeNotifierProvider<PlaybackState,
    ({bool isPlaying, Duration position, Duration duration})>.internal(
  PlaybackState.new,
  name: r'playbackStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$playbackStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$PlaybackState = AutoDisposeNotifier<
    ({bool isPlaying, Duration position, Duration duration})>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
