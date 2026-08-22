/// Lifecycle metadata attached to a feature flag enum value.
final class Flag {
  /// The last date on which the flag may remain in the codebase (YYYY-MM-DD).
  final String expiresAt;

  /// The team responsible for removing or extending the flag.
  final String? owner;

  const Flag({required this.expiresAt, this.owner});
}

