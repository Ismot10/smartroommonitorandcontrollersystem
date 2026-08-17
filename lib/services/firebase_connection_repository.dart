import 'package:firebase_database/firebase_database.dart';

import 'connection_repository.dart';

class FirebaseConnectionRepository implements ConnectionRepository {
  FirebaseConnectionRepository({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _database;

  @override
  Stream<bool> watchConnection() {
    return _database
        .ref('.info/connected')
        .onValue
        .map((event) => event.snapshot.value == true);
  }

  @override
  Future<void> dispose() async {}
}
