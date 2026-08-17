import '../models/user_profile.dart';

abstract interface class UserProfileRepository {
  Stream<UserProfile?> watchProfile(String uid);

  Future<void> createProfile(UserProfile profile);

  Future<void> updateProfile(String uid, Map<String, dynamic> values);

  Future<void> dispose();
}
