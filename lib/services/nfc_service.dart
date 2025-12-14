import 'dart:async';
import 'package:flutter/foundation.dart';

enum NFCStatus {
  available,
  notAvailable,
  disabled,
  unknown,
}

/// NFC Service - Placeholder implementation
/// NFC functionality requires the nfc_manager package
/// which has compatibility issues with current Flutter version.
/// This stub allows the app to build without NFC support.
class NFCService {
  static final NFCService _instance = NFCService._internal();
  factory NFCService() => _instance;
  NFCService._internal();

  final StreamController<String> _nfcDataController = StreamController<String>.broadcast();
  Stream<String> get nfcDataStream => _nfcDataController.stream;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  // Check if NFC is available on the device
  Future<NFCStatus> checkNFCAvailability() async {
    // NFC not available in this build
    return NFCStatus.notAvailable;
  }

  // Start NFC session for reading
  Future<void> startNFCSession({
    required Function(String data) onDataReceived,
    required Function(String error) onError,
  }) async {
    onError('NFC is not available in this version of the app');
  }

  // Stop NFC session
  Future<void> stopNFCSession() async {
    _isScanning = false;
  }

  // Write data to NFC tag
  Future<bool> writeToNFCTag({
    required String data,
    required Function(String error) onError,
  }) async {
    onError('NFC is not available in this version of the app');
    return false;
  }

  // Process NFC payment (tap to pay)
  Future<Map<String, dynamic>?> processNFCPayment({
    required double amount,
    required String orderId,
    required Function(String status) onStatusUpdate,
    required Function(String error) onError,
  }) async {
    onError('NFC payments are not available in this version of the app');
    return null;
  }

  // Dispose
  void dispose() {
    stopNFCSession();
    _nfcDataController.close();
  }
}
