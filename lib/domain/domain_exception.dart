/// Thrown by a Domain class when a business rule stops an action.
///
/// Presentation catches this and shows [message] to the user.
class DomainException implements Exception {
  const DomainException(this.message);

  /// A readable explanation that is safe to show to the user.
  final String message;

  @override
  String toString() => message;
}