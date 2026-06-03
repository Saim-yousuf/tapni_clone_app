import 'dart:developer';

class PrintLog {
  static logMessage(message) {
    log(message);
  }

  static printMessage(message) {
    // ignore: avoid_print
    print(message);
  }
}
