import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/practice_audio.dart';

/// Speaker output shared by the drone and the metronome.
final practiceAudioProvider = Provider<PracticeAudio>((ref) {
  final audio = PracticeAudio();
  ref.onDispose(audio.dispose);
  return audio;
});
