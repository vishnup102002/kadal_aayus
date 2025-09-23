// lib/screens/alerts_feed.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:translator/translator.dart';
import 'package:flutter/foundation.dart';
import '../utils/tts_service.dart';
import '../services/notification_service.dart';

enum PlaybackState { idle, processing, playing }

class AlertsFeedScreen extends StatefulWidget {
  const AlertsFeedScreen({super.key});

  @override
  State<AlertsFeedScreen> createState() => _AlertsFeedScreenState();
}

class _AlertsFeedScreenState extends State<AlertsFeedScreen> {
  late Box _alertsBox;
  List<Map<String, dynamic>> _cachedAlerts = [];
  final Map<String, ValueNotifier<PlaybackState>> _alertStates = {};
  final GoogleTranslator _translator = GoogleTranslator();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _alertsBox = Hive.box('alertsBox');
    _loadCachedAlerts();

    _notificationService.initNotifications();

    // TTS completion handler
    TtsService().setCompletionHandler(() {
      final playingEntry = _alertStates.entries.firstWhere(
            (entry) => entry.value.value == PlaybackState.playing,
        orElse: () => MapEntry("", ValueNotifier(PlaybackState.idle)),
      );
      if (playingEntry.key.isNotEmpty) {
        playingEntry.value.value = PlaybackState.idle;
      }
    });
  }

  @override
  void dispose() {
    TtsService().stop();
    for (var notifier in _alertStates.values) {
      notifier.dispose();
    }
    super.dispose();
  }

  Future<void> _handleLivePlayback(Map<String, dynamic> alertData) async {
    final alertId = alertData['id'] as String;
    final stateNotifier = _alertStates[alertId]!;

    if (stateNotifier.value == PlaybackState.playing) {
      await TtsService().stop();
      stateNotifier.value = PlaybackState.idle;
      return;
    }

    stateNotifier.value = PlaybackState.processing;
    final originalBody = alertData['body'] ?? 'No content available.';

    try {
      final translation = await _translator.translate(originalBody, to: 'ml');
      stateNotifier.value = PlaybackState.playing;
      await TtsService().speak(translation.text);
      stateNotifier.value = PlaybackState.idle;
    } catch (_) {
      stateNotifier.value = PlaybackState.idle;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Could not translate or speak. Check internet."),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _loadCachedAlerts() {
    final data = _alertsBox.get('cachedAlerts', defaultValue: []);
    final alerts = List<Map<String, dynamic>>.from(
        data.map((item) => Map<String, dynamic>.from(item)));

    for (var alert in alerts) {
      _alertStates.putIfAbsent(alert['id'], () => ValueNotifier(PlaybackState.idle));
    }

    if (mounted) setState(() => _cachedAlerts = alerts);
  }

  Future<void> _cacheAlerts(List<Map<String, dynamic>> alerts) async {
    // Deduplicate by ID
    final Map<String, Map<String, dynamic>> uniqueAlerts = {
      for (var alert in alerts) alert['id']: alert
    };

    final dedupedAlerts = uniqueAlerts.values.toList();

    final currentIds = _cachedAlerts.map((e) => e['id']).toList();
    final newIds = dedupedAlerts.map((e) => e['id']).toList();

    if (!listEquals(currentIds, newIds)) {
      await _alertsBox.put('cachedAlerts', dedupedAlerts);
      if (mounted) setState(() => _cachedAlerts = dedupedAlerts);

      for (var alert in dedupedAlerts) {
        _alertStates.putIfAbsent(alert['id'], () => ValueNotifier(PlaybackState.idle));
      }
    }
  }

  Widget _buildAlertTile(Map<String, dynamic> data) {
    final alertId = data['id'] as String;
    final stateNotifier = _alertStates[alertId]!;
    final title = data['title'] ?? 'Alert';
    final body = data['body'] ?? 'No content';
    final severity = data['severity'] ?? 'Medium';
    final timestampMillis = data['timestamp'] as int?;
    final formattedTime = timestampMillis != null
        ? DateFormat('hh:mm a, dd MMM')
        .format(DateTime.fromMillisecondsSinceEpoch(timestampMillis))
        : '';

    Color severityColor;
    IconData severityIcon;
    switch (severity.toLowerCase()) {
      case 'high':
        severityColor = Colors.red.shade700;
        severityIcon = Icons.error;
        break;
      case 'medium':
        severityColor = Colors.orange.shade700;
        severityIcon = Icons.warning_amber_rounded;
        break;
      default:
        severityColor = Colors.blue.shade700;
        severityIcon = Icons.info;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: severityColor.withOpacity(0.5), width: 1),
      ),
      child: ListTile(
        leading: Icon(severityIcon, color: severityColor, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 48,
              height: 32,
              child: ValueListenableBuilder<PlaybackState>(
                valueListenable: stateNotifier,
                builder: (context, state, _) => _buildTrailingIcon(state, data),
              ),
            ),
            const SizedBox(height: 4),
            Text(formattedTime,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildTrailingIcon(PlaybackState state, Map<String, dynamic> data) {
    switch (state) {
      case PlaybackState.processing:
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case PlaybackState.playing:
        return IconButton(
          icon: const Icon(Icons.stop_circle_outlined, color: Colors.red, size: 30),
          onPressed: () => _handleLivePlayback(data),
        );
      default:
        return IconButton(
          icon: Icon(Icons.volume_up, color: Colors.grey[600]),
          onPressed: () => _handleLivePlayback(data),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No alerts at the moment.'));
        }

        final alerts = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'title': data['title'] ?? data['message'] ?? 'Alert',
            'body': data['body'] ?? data['message'] ?? 'No content',
            'severity': data['severity'] ?? 'Medium',
            'timestamp': (data['timestamp'] as Timestamp?)?.millisecondsSinceEpoch,
          };
        }).toList();

        _cacheAlerts(alerts);

        return ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) => _buildAlertTile(alerts[index]),
        );
      },
    );
  }
}
