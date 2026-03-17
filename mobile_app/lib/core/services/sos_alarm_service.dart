import 'package:audioplayers/audioplayers.dart';

class SOSAlarmService {

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playAlarm() async {

    try {

      await _player.setReleaseMode(ReleaseMode.stop);

      await _player.play(
        AssetSource('sounds/sos_alarm.mp3'),
        volume: 1.0,
      );

    } catch (e) {
      print("SOS Alarm Error: $e");
    }
  }

  static Future<void> stopAlarm() async {
    try {
      await _player.stop();
    } catch (e) {
      print("SOS Stop Error: $e");
    }
  }
}