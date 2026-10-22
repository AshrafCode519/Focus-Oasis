import 'dart:math';
import 'dart:typed_data';

/// Pure Dart offline audio synthesizer that produces valid WAV byte buffers
/// without any external dependencies, network connectivity, or external assets.
class OfflineAudioHelper {
  static const int sampleRate = 22050;

  /// Generates a standard WAV file header for 16-bit Mono PCM
  static Uint8List _createWav(List<double> samples) {
    final int numSamples = samples.length;
    final int subChunk2Size = numSamples * 2; // 16-bit = 2 bytes per sample
    final int chunkSize = 36 + subChunk2Size;
    final int byteRate = sampleRate * 2; // mono 16-bit

    final ByteData byteData = ByteData(44 + subChunk2Size);

    // RIFF header
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, chunkSize, Endian.little);
    byteData.setUint8(8, 0x57);  // 'W'
    byteData.setUint8(9, 0x41);  // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // fmt subchunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size (16 for PCM)
    byteData.setUint16(20, 1, Endian.little);  // AudioFormat (1 = PCM)
    byteData.setUint16(22, 1, Endian.little);  // NumChannels (1 = Mono)
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, byteRate, Endian.little);
    byteData.setUint16(32, 2, Endian.little);  // BlockAlign (2 bytes)
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample

    // data subchunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, subChunk2Size, Endian.little);

    // Write 16-bit PCM samples
    int offset = 44;
    for (int i = 0; i < numSamples; i++) {
      final double clamped = samples[i].clamp(-1.0, 1.0);
      final int intSample = (clamped * 32767).toInt();
      byteData.setInt16(offset, intSample, Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }

  /// Synthesizes a tranquil Tibetan Singing Bowl Bell Chime (528 Hz Solfeggio Love/Focus tone)
  static Uint8List generateTibetanBell({double durationSeconds = 2.4}) {
    final int totalSamples = (sampleRate * durationSeconds).toInt();
    final List<double> samples = List<double>.filled(totalSamples, 0.0);

    const double baseFreq = 528.0; // Sacred Solfeggio frequency for transformation & mental clarity
    const double harmonic2 = baseFreq * 2.0;
    const double harmonic3 = baseFreq * 3.0;

    for (int i = 0; i < totalSamples; i++) {
      final double t = i / sampleRate;
      final double envelope = exp(-1.7 * t); // smooth exponential decay

      // Harmonic bell overtone mixture
      final double tone = 0.65 * sin(2 * pi * baseFreq * t) +
          0.25 * sin(2 * pi * harmonic2 * t) +
          0.10 * sin(2 * pi * harmonic3 * t);

      samples[i] = tone * envelope;
    }

    return _createWav(samples);
  }

  /// Synthesizes a gentle sad descending chime for wilted sessions
  static Uint8List generateWiltedTone({double durationSeconds = 1.6}) {
    final int totalSamples = (sampleRate * durationSeconds).toInt();
    final List<double> samples = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final double t = i / sampleRate;
      final double progress = i / totalSamples;
      // Frequency glides gently downwards from 320 Hz to 210 Hz
      final double freq = 320.0 - (110.0 * progress);
      final double envelope = exp(-2.2 * t);
      samples[i] = 0.5 * sin(2 * pi * freq * t) * envelope;
    }

    return _createWav(samples);
  }

  /// Synthesizes a gentle soft transition click / wooden chime for breathing cues
  static Uint8List generateGentleCueTone({double freq = 440.0, double duration = 0.35}) {
    final int totalSamples = (sampleRate * duration).toInt();
    final List<double> samples = List<double>.filled(totalSamples, 0.0);

    for (int i = 0; i < totalSamples; i++) {
      final double t = i / sampleRate;
      final double envelope = exp(-8.0 * t);
      samples[i] = 0.4 * sin(2 * pi * freq * t) * envelope;
    }

    return _createWav(samples);
  }

  /// Generates soothing brown noise (Brownian noise) simulating distant waterfall / rain
  static Uint8List generateBrownNoise({double durationSeconds = 4.0}) {
    final int totalSamples = (sampleRate * durationSeconds).toInt();
    final List<double> samples = List<double>.filled(totalSamples, 0.0);
    final Random random = Random(42);

    double lastVal = 0.0;
    for (int i = 0; i < totalSamples; i++) {
      final double white = (random.nextDouble() * 2.0) - 1.0;
      // Integrate white noise with leaky integrator
      lastVal = (lastVal + (0.02 * white)) / 1.02;
      samples[i] = (lastVal * 2.8).clamp(-0.85, 0.85);
    }

    return _createWav(samples);
  }
}
