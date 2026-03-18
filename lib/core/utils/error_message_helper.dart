import 'package:flutter/material.dart';
import 'package:swipe/l10n/app_localizations.dart';
import 'package:swipe/core/network/api_client.dart';

/// Helper to get localized error messages from ApiException
class ErrorMessageHelper {
  ErrorMessageHelper._();

  /// Get a user-friendly localized error message from an ApiException
  static String getLocalizedMessage(
    BuildContext context,
    ApiException exception,
  ) {
    final l10n = AppLocalizations.of(context)!;

    // Map status codes to localized messages
    switch (exception.statusCode) {
      case 502:
        return l10n.serverError502;
      case 503:
        return l10n.serverError503;
      case 504:
        return l10n.serverError504;
      case 500:
        return l10n.serverError500;
      case 400:
      case 401:
      case 403:
      case 404:
      case 429:
        // For 4xx errors, use the message from the exception
        // as it may contain specific server-provided details
        return exception.message;
      default:
        // For any other 5xx errors
        if (exception.statusCode >= 500) {
          return l10n.serverErrorGeneric;
        }
        // For other errors, use the exception message
        return exception.message;
    }
  }

  /// Get a user-friendly localized error message from any error
  static String getLocalizedErrorMessage(BuildContext context, dynamic error) {
    if (error is ApiException) {
      return getLocalizedMessage(context, error);
    }
    // For non-ApiException errors, return the error string
    return error.toString();
  }
}
