import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPinService {
  static Future<String> generateUniquePin(String uid) async {
    final firestore = FirebaseFirestore.instance;
    String pin;
    String normPin = '';

    while (true) {
      final randomNumber = (100000 + Random.secure().nextInt(900000))
          .toString()
          .padLeft(6, '0');
      // Use ${} for string interpolation to append 'M' after the variable
      pin = 'CV${randomNumber}M';
      normPin = pin.replaceAll(RegExp(r'\s+'), '').toUpperCase();

      try {
        await firestore.runTransaction((transaction) async {
          final pinRef = firestore.collection('pins').doc(normPin);
          final pinDoc = await transaction.get(pinRef);

          if (pinDoc.exists) {
            throw Exception('PIN already exists');
          }

          final userRef = firestore.collection('users').doc(uid);

          // Create reserved entry in pins/{PIN}
          transaction.set(pinRef, {
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Save into users doc with multiple field aliases for easier lookup
          transaction.set(
            userRef,
            {
              'chatPin': normPin,  // existing field
              'pin': normPin,      // alias for lookup
              'userPin': normPin,  // alias for lookup variations
              'pinAssignedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        });

        break;
      } catch (_) {
        // PIN already exists, retry
      }
    }

    return normPin;
  }
}
