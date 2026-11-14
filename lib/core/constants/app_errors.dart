abstract class Failure {
  final String message;
  Failure({required this.message});
}

class FetchDataError extends Failure {
  FetchDataError({required super.message});
}
