import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPinService {
  static Future<String> generateUniquePin(String uid) async {
    final firestore = FirebaseFirestore.instance;
    String pin;

    while (true) {
      final randomNumber = (100000 + Random.secure().nextInt(900000))
          .toString()
          .padLeft(6, '0');
      // Use ${} for string interpolation to append 'M' after the variable
      pin = 'CV${randomNumber}M';

      try {
        await firestore.runTransaction((transaction) async {
          final pinRef = firestore.collection('pins').doc(pin);
          final pinDoc = await transaction.get(pinRef);

          if (pinDoc.exists) {
            throw Exception('PIN already exists');
          }

          final userRef = firestore.collection('users').doc(uid);

          transaction.set(pinRef, {
            'uid': uid,
            'createdAt': FieldValue.serverTimestamp(),
          });

          transaction.set(
            userRef,
            {
              'chatPin': pin,
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

    return pin;
  }
}
