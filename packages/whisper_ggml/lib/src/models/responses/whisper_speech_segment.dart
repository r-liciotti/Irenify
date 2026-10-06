import 'package:flutter/foundation.dart';

/// Irenefy (D-61): a speech segment found by the Silero VAD, in seconds
/// from the start of the audio.
@immutable
class WhisperSpeechSegment {
  /// Segment from [start] to [end] (seconds).
  const WhisperSpeechSegment({required this.start, required this.end});

  /// Parse a native `{"start": s, "end": e}` object.
  factory WhisperSpeechSegment.fromJson(Map<String, dynamic> json) {
    return WhisperSpeechSegment(
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
    );
  }

  /// Start of the speech, in seconds.
  final double start;

  /// End of the speech, in seconds.
  final double end;

  /// Length of the segment, in seconds.
  double get duration => end - start;

  @override
  bool operator ==(Object other) =>
      other is WhisperSpeechSegment && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'WhisperSpeechSegment($start–$end s)';
}
