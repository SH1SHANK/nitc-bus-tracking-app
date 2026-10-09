/// Typed application exceptions for domain, service, and network failures.
sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' ($cause)' : ''}';
}

final class LocationException extends AppException {
  const LocationException(super.message, [super.cause]);
}

final class LocationPermissionDeniedException extends LocationException {
  const LocationPermissionDeniedException([
    super.message = 'Location permission was denied.',
  ]);
}

final class LocationPermissionPermanentlyDeniedException
    extends LocationException {
  const LocationPermissionPermanentlyDeniedException([
    super.message =
        'Location permission is permanently denied. Please enable it in system settings.',
  ]);
}

final class LocationServiceDisabledException extends LocationException {
  const LocationServiceDisabledException([
    super.message = 'Location services are disabled on this device.',
  ]);
}

final class TransitException extends AppException {
  const TransitException(super.message, [super.cause]);
}

final class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

final class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);
}
