import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tapni_app/helper/log_helper.dart';
import 'package:tapni_app/utils/api_handler.dart';
import 'package:tapni_app/widgets/alert.dart';

class ErrorHandler {
  static catchException(BuildContext context, dynamic e) {
    String errorMessage;

    if (e is SocketException) {
      errorMessage = "Internet connection issue. Please check your connection.";
    } else if (e is TimeoutException) {
      errorMessage = "The request timed out. Please try again.";
    } else if (e is FormatException) {
      errorMessage = "Data format error occurred. Please try again.";
    } else if (e is ApiException) {
      errorMessage = e.message;
    } else if (e is Exception) {
      errorMessage = "An error occurred. Please try again.";
    } else if (e is Error) {
      errorMessage = "A system error occurred. Please restart the app.";
    } else {
      errorMessage = "An unexpected issue occurred.";
    }

    // showSnackBar(context, errorMessage);
    ShowAlert.error(message: errorMessage, context: context);
    PrintLog.logMessage('Error: $e');
    return Future.error(errorMessage);
  }

  static catchExceptionMessage(BuildContext context, dynamic e) {
    String errorMessage;

    if (e is SocketException) {
      errorMessage = "Internet connection issue. Please check your connection.";
    } else if (e is TimeoutException) {
      errorMessage = "The request timed out. Please try again.";
    } else if (e is FormatException) {
      errorMessage = "Data format error occurred. Please try again.";
    } else if (e is ApiException) {
      errorMessage = e.message;
    } else if (e is Exception) {
      errorMessage = "An error occurred. Please try again.";
    } else if (e is Error) {
      errorMessage = "A system error occurred. Please restart the app.";
    } else {
      errorMessage = "An unexpected issue occurred.";
    }

    // showSnackBar(context, errorMessage);
    ShowAlert.error(message: errorMessage, context: context);

    PrintLog.logMessage('Error: $e');
    return errorMessage;
  }

  static apiException(BuildContext context, dynamic e) {
    // showSnackBar(context, e);
    ShowAlert.error(message: e, context: context);
    PrintLog.logMessage('Error: $e');
  }

  static exceptionFuture(BuildContext context, dynamic e) {
    String errorMessage = e.toString();

    if (e is TimeoutException) {
      errorMessage = "The request timed out. Please try again.";
    } else if (e is ApiException) {
      errorMessage = e.message;
    }

    // showSnackBar(context, errorMessage);
    ShowAlert.error(message: errorMessage, context: context);

    PrintLog.logMessage('Error: $errorMessage');
    return Future.error(errorMessage);
  }

  static String catchExceptionFuture(String e) {
    String errorMessage;

    if (e is SocketException) {
      errorMessage = "Internet connection issue. Please check your connection.";
    } else if (e is TimeoutException) {
      errorMessage = "The request timed out. Please try again.";
    } else if (e is FormatException) {
      errorMessage = "Data format error occurred. Please try again.";
    } else if (e is Exception) {
      errorMessage = "An error occurred. Please try again.";
    } else if (e is Error) {
      errorMessage = "A system error occurred. Please restart the app.";
    } else {
      errorMessage = "An unexpected issue occurred.";
    }

    return errorMessage;
  }
}
