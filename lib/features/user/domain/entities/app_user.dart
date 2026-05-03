class AppUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final List<String> modules;
  final DateTime createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.modules = const [],
    required this.createdAt,
  });

  AppUser copyWith({String? displayName, String? photoUrl, List<String>? modules}) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      modules: modules ?? this.modules,
      createdAt: createdAt,
    );
  }
}
