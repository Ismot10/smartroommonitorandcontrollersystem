import 'package:firebase_database/firebase_database.dart';

import '../models/user_profile.dart';
import 'user_profile_repository.dart';

class FirebaseUserProfileRepository implements UserProfileRepository {
  FirebaseUserProfileRepository({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  DatabaseReference _profile(String uid) => _database.ref('users/$uid');

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _profile(uid).onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) {
        return null;
      }
      return UserProfile.fromMap(uid, value);
    });
  }

  @override
  Future<void> createProfile(UserProfile profile) {
    return _profile(profile.uid).set(profile.toMap());
  }

  @override
  Future<void> updateProfile(String uid, Map<String, dynamic> values) {
    return _profile(
      uid,
    ).update({...values, 'updatedAt': ServerValue.timestamp});
  }

  @override
  Future<void> dispose() async {}
}
