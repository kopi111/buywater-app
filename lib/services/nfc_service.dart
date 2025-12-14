import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:nfc_manager/nfc_manager.dart';

enum NFCStatus {
  available,
  notAvailable,
  disabled,
  unknown,
}

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
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (isAvailable) {
        return NFCStatus.available;
      } else {
        return NFCStatus.notAvailable;
      }
    } catch (e) {
      debugPrint('NFC availability check error: $e');
      return NFCStatus.unknown;
    }
  }

  // Start NFC session for reading
  Future<void> startNFCSession({
    required Function(String data) onDataReceived,
    required Function(String error) onError,
  }) async {
    final status = await checkNFCAvailability();

    if (status != NFCStatus.available) {
      onError('NFC is not available on this device');
      return;
    }

    if (_isScanning) {
      onError('NFC session already in progress');
      return;
    }

    _isScanning = true;

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            // Read NDEF data
            final ndef = Ndef.from(tag);
            if (ndef != null) {
              final ndefMessage = await ndef.read();
              if (ndefMessage.records.isNotEmpty) {
                for (final record in ndefMessage.records) {
                  final payload = String.fromCharCodes(record.payload);
                  _nfcDataController.add(payload);
                  onDataReceived(payload);
                }
              }
            }

            // Get tag identifier as fallback
            final tagData = tag.data;
            if (tagData.containsKey('nfca')) {
              final nfcaData = tagData['nfca'] as Map<String, dynamic>?;
              if (nfcaData != null && nfcaData.containsKey('identifier')) {
                final identifier = (nfcaData['identifier'] as List<dynamic>)
                    .map((e) => (e as int).toRadixString(16).padLeft(2, '0'))
                    .join(':')
                    .toUpperCase();
                _nfcDataController.add(identifier);
                onDataReceived(identifier);
              }
            }
          } catch (e) {
            onError('Error reading NFC tag: $e');
          }
        },
        onError: (error) async {
          onError(error.message);
        },
      );
    } catch (e) {
      _isScanning = false;
      onError('Failed to start NFC session: $e');
    }
  }

  // Stop NFC session
  Future<void> stopNFCSession() async {
    if (_isScanning) {
      try {
        await NfcManager.instance.stopSession();
      } catch (e) {
        debugPrint('Error stopping NFC session: $e');
      }
      _isScanning = false;
    }
  }

  // Write data to NFC tag
  Future<bool> writeToNFCTag({
    required String data,
    required Function(String error) onError,
  }) async {
    final status = await checkNFCAvailability();

    if (status != NFCStatus.available) {
      onError('NFC is not available on this device');
      return false;
    }

    Completer<bool> completer = Completer();

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            final ndef = Ndef.from(tag);

            if (ndef == null) {
              onError('Tag is not NDEF compatible');
              completer.complete(false);
              return;
            }

            if (!ndef.isWritable) {
              onError('Tag is not writable');
              completer.complete(false);
              return;
            }

            final message = NdefMessage([
              NdefRecord.createText(data),
            ]);

            await ndef.write(message);
            completer.complete(true);

            await NfcManager.instance.stopSession();
          } catch (e) {
            onError('Error writing to NFC tag: $e');
            completer.complete(false);
          }
        },
        onError: (error) async {
          onError(error.message);
          completer.complete(false);
        },
      );
    } catch (e) {
      onError('Failed to start NFC write session: $e');
      return false;
    }

    return completer.future;
  }

  // Process NFC payment (tap to pay)
  Future<Map<String, dynamic>?> processNFCPayment({
    required double amount,
    required String orderId,
    required Function(String status) onStatusUpdate,
    required Function(String error) onError,
  }) async {
    final status = await checkNFCAvailability();

    if (status != NFCStatus.available) {
      onError('NFC is not available on this device');
      return null;
    }

    Completer<Map<String, dynamic>?> completer = Completer();

    onStatusUpdate('Ready to tap card...');

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          try {
            onStatusUpdate('Card detected, processing...');

            // Check for ISO-DEP (contactless payment cards)
            final tagData = tag.data;

            if (tagData.containsKey('isodep')) {
              // This is where you would implement EMV payment processing
              // For actual implementation, you would need to:
              // 1. Select payment application (AID)
              // 2. Read card data
              // 3. Generate cryptogram
              // 4. Send to payment processor

              // Placeholder for NFC payment data
              final cardData = {
                'type': 'nfc_payment',
                'amount': amount,
                'order_id': orderId,
                'timestamp': DateTime.now().toIso8601String(),
                // In real implementation, this would contain encrypted card data
              };

              onStatusUpdate('Payment processing...');

              await NfcManager.instance.stopSession();
              completer.complete(cardData);
            } else {
              onError('Unsupported card type');
              completer.complete(null);
            }
          } catch (e) {
            onError('Error processing NFC payment: $e');
            completer.complete(null);
          }
        },
        onError: (error) async {
          onError(error.message);
          completer.complete(null);
        },
      );
    } catch (e) {
      onError('Failed to start NFC payment session: $e');
      return null;
    }

    return completer.future;
  }

  // Dispose
  void dispose() {
    stopNFCSession();
    _nfcDataController.close();
  }
}
