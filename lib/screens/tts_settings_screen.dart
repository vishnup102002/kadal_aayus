// lib/screens/tts_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsSettingsScreen extends StatefulWidget {
  const TtsSettingsScreen({super.key});

  @override
  State<TtsSettingsScreen> createState() => _TtsSettingsScreenState();
}

// The State class begins here
class _TtsSettingsScreenState extends State<TtsSettingsScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  List<Map> _voices = [];
  Map? _currentVoice;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    // This function fetches the voices
    try {
      var voices = await _flutterTts.getVoices;
      if (voices != null) {
        // This is a debugging step to see what voices your phone has
        print("--- AVAILABLE TTS VOICES ON THIS DEVICE ---");
        for (var voice in voices) {
          print(voice);
        }
        print("-----------------------------------------");

        setState(() {
          _voices = List<Map>.from(voices);
        });
      }
    } catch (e) {
      print("Error fetching voices: $e");
    }
  }

  void _setVoice(Map voice) async {
    // This function sets the selected voice
    try {
      final voiceToSet = {
        "name": voice['name'] as String,
        "locale": voice['locale'] as String,
      };
      await _flutterTts.setVoice(voiceToSet);
      setState(() {
        _currentVoice = voice;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice set to: ${voice['name']}')),
        );
      }
    } catch (e) {
      print("Error setting voice: $e");
    }
  }

  // --- THIS IS THE REQUIRED BUILD METHOD ---
  // The error you are seeing means this method is missing or misplaced.
  // It MUST be inside the _TtsSettingsScreenState class.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Settings'),
      ),
      body: _voices.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _voices.length,
        itemBuilder: (context, index) {
          final voice = _voices[index];
          final bool isSelected = _currentVoice != null &&
              _currentVoice!['name'] == voice['name'] &&
              _currentVoice!['locale'] == voice['locale'];

          return Container(
            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
            child: ListTile(
              title: Text(voice['name'] ?? 'Unknown Name'),
              subtitle: Text(voice['locale'] ?? 'Unknown Locale'),
              trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
              onTap: () {
                _setVoice(voice);
              },
            ),
          );
        },
      ),
    );
  }
// The State class ends here
}
