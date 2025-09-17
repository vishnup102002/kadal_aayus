import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream alerts collection ordered by recent
  Stream<QuerySnapshot> streamAlerts() {
    return _db.collection('alerts').orderBy('timestamp', descending: true).snapshots();
  }

  // Stream SOS collection ordered by recent
  Stream<QuerySnapshot> streamSOS() {
    return _db.collection('sos').orderBy('timestamp', descending: true).snapshots();
  }

  // Add a new alert document
  Future<void> addAlert(Map<String, dynamic> alertData) async {
    await _db.collection('alerts').add(alertData);
  }

  // Add a new SOS document
  Future<void> addSOS(Map<String, dynamic> sosData) async {
    await _db.collection('sos').add(sosData);
  }
}
