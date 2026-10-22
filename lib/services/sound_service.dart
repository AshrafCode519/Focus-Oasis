import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'offline_audio_helper.dart';

class AmbientSoundOption {
  final String id;
  final String nameAr;
  final String nameEn;
  final String icon;
  final String audioUrl;
  final bool isOfflineSynthesized;

  const AmbientSoundOption({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.audioUrl,
    this.isOfflineSynthesized = false,
  });

  String name(String langCode) => langCode == 'ar' ? nameAr : nameEn;
}

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  AudioPlayer? _ambientPlayer;
  AudioPlayer? _sfxPlayer;
  String _currentAmbientId = 'none';
  bool _isPlaying = false;

  Uint8List? _cachedTibetanBell;
  Uint8List? _cachedWiltedTone;
  Uint8List? _cachedBrownNoise;

  static const List<AmbientSoundOption> options = [
    AmbientSoundOption(
      id: 'none',
      nameAr: 'بدون صوت (صامت)',
      nameEn: 'Silent',
      icon: '🔇',
      audioUrl: '',
    ),
    AmbientSoundOption(
      id: 'offline_brown',
      nameAr: 'ضوضاء بنية دافئة (أوفلاين ⚡)',
      nameEn: 'Warm Brown Noise',
      icon: '🪐',
      audioUrl: '',
      isOfflineSynthesized: true,
    ),
    AmbientSoundOption(
      id: 'offline_zen',
      nameAr: 'رنين زن نقي 528Hz (أوفلاين ⚡)',
      nameEn: 'Pure 528Hz Bell',
      icon: '🔔',
      audioUrl: '',
      isOfflineSynthesized: true,
    ),
    AmbientSoundOption(
      id: 'rain',
      nameAr: 'مطر هادئ',
      nameEn: 'Gentle Rain',
      icon: '🌧️',
      audioUrl: 'https://cdn.freesound.org/previews/531/531947_11861866-lq.mp3',
    ),
    AmbientSoundOption(
      id: 'forest',
      nameAr: 'طيور الغابة والنسيم',
      nameEn: 'Forest Birds',
      icon: '🍃',
      audioUrl: 'https://cdn.freesound.org/previews/517/517765_649468-lq.mp3',
    ),
    AmbientSoundOption(
      id: 'waves',
      nameAr: 'أمواج البحر',
      nameEn: 'Ocean Waves',
      icon: '🌊',
      audioUrl: 'https://cdn.freesound.org/previews/412/412308_8043-lq.mp3',
    ),
    AmbientSoundOption(
      id: 'fire',
      nameAr: 'موقد دافئ',
      nameEn: 'Campfire',
      icon: '🔥',
      audioUrl: 'https://cdn.freesound.org/previews/475/475347_9849182-lq.mp3',
    ),
  ];

  String get currentAmbientId => _currentAmbientId;
  bool get isPlaying => _isPlaying;
  double _volume = 0.5;
  double get volume => _volume;

  Future<void> init({double initialVolume = 0.5}) async {
    try {
      _volume = initialVolume;
      _ambientPlayer = AudioPlayer();
      _sfxPlayer = AudioPlayer();
      await _ambientPlayer?.setReleaseMode(ReleaseMode.loop);
      await _ambientPlayer?.setVolume(_volume);
      await _sfxPlayer?.setVolume(0.85);

      // Pre-cache synthesized tones asynchronously
      _cachedTibetanBell ??= OfflineAudioHelper.generateTibetanBell();
      _cachedWiltedTone ??= OfflineAudioHelper.generateWiltedTone();
      _cachedBrownNoise ??= OfflineAudioHelper.generateBrownNoise();
    } catch (e) {
      debugPrint('SoundService init error: $e');
    }
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    try {
      await _ambientPlayer?.setVolume(_volume);
    } catch (_) {}
  }

  Future<void> playAmbient(String id) async {
    _currentAmbientId = id;
    if (id == 'none' || _ambientPlayer == null) {
      await stopAmbient();
      return;
    }

    final opt = options.firstWhere((o) => o.id == id, orElse: () => options.first);

    try {
      await _ambientPlayer?.stop();

      if (opt.id == 'offline_brown') {
        _cachedBrownNoise ??= OfflineAudioHelper.generateBrownNoise();
        await _ambientPlayer?.play(BytesSource(_cachedBrownNoise!));
        _isPlaying = true;
      } else if (opt.id == 'offline_zen') {
        _cachedTibetanBell ??= OfflineAudioHelper.generateTibetanBell(durationSeconds: 3.5);
        await _ambientPlayer?.play(BytesSource(_cachedTibetanBell!));
        _isPlaying = true;
      } else if (opt.audioUrl.isNotEmpty) {
        await _ambientPlayer?.play(UrlSource(opt.audioUrl));
        _isPlaying = true;
      } else {
        await stopAmbient();
      }
    } catch (e) {
      debugPrint('Error playing ambient: $e');
      _isPlaying = false;
    }
  }

  Future<void> stopAmbient() async {
    try {
      await _ambientPlayer?.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error stopping ambient: $e');
    }
  }

  Future<void> playSessionComplete() async {
    try {
      // Offline synthesized Tibetan chime for guaranteed instant feedback
      _cachedTibetanBell ??= OfflineAudioHelper.generateTibetanBell();
      await _sfxPlayer?.stop();
      await _sfxPlayer?.play(BytesSource(_cachedTibetanBell!));
    } catch (e) {
      debugPrint('Falling back to URL bell: $e');
      try {
        await _sfxPlayer?.play(
          UrlSource('https://cdn.freesound.org/previews/320/320655_5260872-lq.mp3'),
        );
      } catch (_) {}
    }
  }

  Future<void> playTreeWithered() async {
    try {
      _cachedWiltedTone ??= OfflineAudioHelper.generateWiltedTone();
      await _sfxPlayer?.stop();
      await _sfxPlayer?.play(BytesSource(_cachedWiltedTone!));
    } catch (e) {
      debugPrint('Falling back to URL withered sound: $e');
      try {
        await _sfxPlayer?.play(
          UrlSource('https://cdn.freesound.org/previews/142/142608_2615119-lq.mp3'),
        );
      } catch (_) {}
    }
  }

  Future<void> playCueSound({double freq = 440.0}) async {
    try {
      final cueBytes = OfflineAudioHelper.generateGentleCueTone(freq: freq);
      await _sfxPlayer?.stop();
      await _sfxPlayer?.play(BytesSource(cueBytes));
    } catch (_) {}
  }

  void dispose() {
    _ambientPlayer?.dispose();
    _sfxPlayer?.dispose();
  }
}
