abstract interface class ConnectionRepository {
  Stream<bool> watchConnection();

  Future<void> dispose();
}
