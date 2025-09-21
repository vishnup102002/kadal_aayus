import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  Future<void> createOrUpdateUserProfile(User user) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final userData = {
      'phone': user.phoneNumber ?? '',
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'registeredAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      // Add other fields as needed
    };

    await userRef.set(userData, SetOptions(merge: true));
  }
}
