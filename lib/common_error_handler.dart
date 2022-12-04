import 'dart:developer';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum ErrorStatus { success, failure, unknown }

class ErrorHandler {
  static final ErrorHandler _singleton = ErrorHandler._internal();

  factory ErrorHandler() {
    return _singleton;
  }

  ErrorHandler._internal();

  ErrorStatus _errorStatus = ErrorStatus.unknown;

  Future<void> handlerMethod({
    required Function onTryFunction,
    required Function onExecutionSuccessfullyCompleted,
    required Function(Exception, StackTrace) onExceptionCaught,
    required Function(Object, StackTrace) onErrorOccurred,
    required Function(ErrorStatus) onFinallyCalled,
    required bool shouldSendReportToSentry,
    required bool shouldSendReportToCrashlytics,
  }) async {
    // try to execute
    try {
      log('handlerMethod : try to execute function.');
      _errorStatus = ErrorStatus.unknown;
      await onTryFunction();

      // only executed if above function run without any kind of crash
      log('handlerMethod : execution completed without crash.');
      _errorStatus = ErrorStatus.success;
      await onExecutionSuccessfullyCompleted();
    }

    // only executed if error is of type Exception
    on Exception catch (exception, stackTrace) {
      log('handlerMethod : Exception caught : ${exception.toString()}');
      _errorStatus = ErrorStatus.failure;
      await sendToCrashlyticsAndSentry(
        exception: exception,
        stackTrace: stackTrace,
        hint: 'Exception caught',
        onError: false,
        shouldSendReportToSentry: shouldSendReportToSentry,
        shouldSendReportToCrashlytics: shouldSendReportToCrashlytics,
      );
      await onExceptionCaught(exception, stackTrace);
    }

    // executed for errors of all types other than Exception
    catch (exception, stackTrace) {
      log('handlerMethod : Error occurred : ${exception.toString()}');
      _errorStatus = ErrorStatus.failure;
      await sendToCrashlyticsAndSentry(
        exception: exception,
        stackTrace: stackTrace,
        hint: 'Error occurred',
        onError: false,
        shouldSendReportToSentry: shouldSendReportToSentry,
        shouldSendReportToCrashlytics: shouldSendReportToCrashlytics,
      );
      await onErrorOccurred(exception, stackTrace);
    }

    // always execute
     finally {
      log('handlerMethod : finally called.');
      await onFinallyCalled(_errorStatus);
    }

    return Future.value();
  }

  Future<void> sendToCrashlyticsAndSentry({
    required dynamic exception,
    required StackTrace stackTrace,
    required String hint,
    required bool onError,
    required bool shouldSendReportToSentry,
    required bool shouldSendReportToCrashlytics,
  }) async {
    if (shouldSendReportToCrashlytics) {
      if (onError) {
        FlutterErrorDetails details = FlutterErrorDetails(
          exception: exception,
          stack: stackTrace,
          library: hint,
        );
        await FirebaseCrashlytics.instance.recordFlutterFatalError(
          details,
        );
      } else {
        await FirebaseCrashlytics.instance.recordError(
          exception,
          stackTrace,
          fatal: true,
          reason: hint,
          printDetails: false,
        );
      }
    } else {}

    if (shouldSendReportToSentry) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
        hint: hint,
      );
    } else {}

    return Future.value();
  }
}
