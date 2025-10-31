import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioLayer {
  const AudioLayer({required this.asset, required this.loop});

  final String asset;
  final bool loop;
}

class AudioManager {
  AudioManager._();

  static Future<AudioManager> load() async {
    final manager = AudioManager._();
    await manager._init();
    return manager;
  }

  final _musicPlayers = <String, AudioPlayer>{};
  final _sfxPlayer = AudioPlayer(playerId: 'sfx_player');
  double _musicVolume = 0.7;
  double _sfxVolume = 0.9;

  static const _bassLayer = AudioLayer(
    asset: 'assets/audio/music_bass.mp3',
    loop: true,
  );
  static const _midLayer = AudioLayer(
    asset: 'assets/audio/music_mid.mp3',
    loop: true,
  );
  static const _leadLayer = AudioLayer(
    asset: 'assets/audio/music_lead.mp3',
    loop: true,
  );

  static const _ambientMorning = 'assets/audio/ambient_morning.mp3';
  static const _ambientEvening = 'assets/audio/ambient_evening.mp3';

  Future<void> _init() async {
    await _sfxPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playAmbient(DateTime now) async {
    final hour = now.hour;
    final asset = hour >= 6 && hour < 18 ? _ambientMorning : _ambientEvening;
    await _loopIfNeeded('ambient', asset, volume: 0.4);
  }

  Future<void> updateHarmonyLayers(int harmonyLevel, int maxHarmony) async {
    final fillRatio = harmonyLevel / maxHarmony;
    await _ensureLayer(_bassLayer, enabled: true, volume: 0.4 + fillRatio * 0.1);
    await _ensureLayer(_midLayer, enabled: fillRatio >= 0.4, volume: 0.35 + fillRatio * 0.2);
    await _ensureLayer(_leadLayer, enabled: fillRatio >= 0.75, volume: 0.3 + fillRatio * 0.25);
  }

  Future<void> playFoodPickup(int harmonyLevel) async {
    final pitch = 1.0 + (harmonyLevel * 0.05);
    await _sfxPlayer.setPlaybackRate(pitch);
    await _sfxPlayer.setVolume(_sfxVolume);
    await _sfxPlayer.play(AssetSource('audio/sfx_food.wav'));
  }

  Future<void> playHazardWarning() async {
    await _sfxPlayer.setPlaybackRate(1.0);
    await _sfxPlayer.setVolume(_sfxVolume * 0.8);
    await _sfxPlayer.play(AssetSource('audio/sfx_hazard.wav'));
  }

  Future<void> playGameOver() async {
    await _sfxPlayer.setPlaybackRate(0.95);
    await _sfxPlayer.setVolume(_sfxVolume);
    await _sfxPlayer.play(AssetSource('audio/sfx_gameover.wav'));
  }

  Future<void> pauseMusic() async {
    for (final player in _musicPlayers.values) {
      await player.pause();
    }
  }

  Future<void> resumeMusic() async {
    for (final player in _musicPlayers.values) {
      await player.resume();
    }
  }

  Future<void> dispose() async {
    for (final player in _musicPlayers.values) {
      await player.stop();
      await player.release();
    }
    await _sfxPlayer.dispose();
  }

  Future<void> _ensureLayer(
    AudioLayer layer, {
    required bool enabled,
    required double volume,
  }) async {
    final player = _musicPlayers.putIfAbsent(
      layer.asset,
      () => AudioPlayer(playerId: layer.asset),
    );
    if (enabled) {
      await player.setVolume(volume * _musicVolume);
      await player.setReleaseMode(
        layer.loop ? ReleaseMode.loop : ReleaseMode.stop,
      );
      if (player.state != PlayerState.playing) {
        await player.play(AssetSource(layer.asset.replaceFirst('assets/', '')));
      }
    } else if (player.state == PlayerState.playing) {
      await player.stop();
    }
  }

  Future<void> _loopIfNeeded(String id, String asset, {required double volume}) async {
    final player = _musicPlayers.putIfAbsent(
      id,
      () => AudioPlayer(playerId: id),
    );
    await player.setVolume(volume * _musicVolume);
    await player.setReleaseMode(ReleaseMode.loop);
    if (player.state != PlayerState.playing) {
      await player.play(AssetSource(asset.replaceFirst('assets/', '')));
    }
  }
}
