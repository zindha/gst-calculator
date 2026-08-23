import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Handles deep link parsing across web, Android, and iOS.
///
/// On web, parses query parameters from `Uri.base`.
/// On native platforms, uses a MethodChannel to receive initial route data
/// from the platform's intent/NSUserActivity handler.
class DeepLinkHandler {
  DeepLinkHandler._();

  static const _channel = MethodChannel('com.zindha.gst_calculator/deep_links');

  /// Parses the initial deep link from the app's launch.
  ///
  /// Returns a [DeepLinkParams] with the parsed amount and rate,
  /// or null values if no valid parameters were found.
  static Future<DeepLinkParams> parseInitial() async {
    // On web, use Uri.base directly.
    if (Platform.isAndroid || Platform.isIOS) {
      return _parseNative();
    }
    return _parseWeb();
  }

  /// Parses deep link from web query parameters.
  static DeepLinkParams _parseWeb() {
    final uri = Uri.base;
    final amount = _parseDouble(uri.queryParameters['amount']);
    final rate = _parseDouble(uri.queryParameters['rate']);
    return DeepLinkParams(
      amount: amount != null && amount > 0 ? amount : null,
      rate: rate != null && rate >= 0 && rate <= 100 ? rate : null,
    );
  }

  /// Parses deep link from native platform via MethodChannel.
  ///
  /// Times out after 2 seconds so the app never hangs waiting for a
  /// platform handler that may not be registered yet.
  static Future<DeepLinkParams> _parseNative() async {
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('getInitialLink')
          .timeout(const Duration(seconds: 2));
      if (result == null) return DeepLinkParams.empty;

      final amount = _parseDouble(result['amount']?.toString());
      final rate = _parseDouble(result['rate']?.toString());
      return DeepLinkParams(
        amount: amount != null && amount > 0 ? amount : null,
        rate: rate != null && rate >= 0 && rate <= 100 ? rate : null,
      );
    } on PlatformException {
      return DeepLinkParams.empty;
    } on TimeoutException {
      return DeepLinkParams.empty;
    }
  }

  static double? _parseDouble(String? value) {
    if (value == null || value.isEmpty) return null;
    return double.tryParse(value);
  }
}

/// Parsed deep link parameters.
class DeepLinkParams {
  final double? amount;
  final double? rate;

  const DeepLinkParams({this.amount, this.rate});

  static const empty = DeepLinkParams();

  bool get hasAny => amount != null || rate != null;
}
