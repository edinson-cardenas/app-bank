import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get uid => _auth.currentUser?.uid;

  // Stream of user data
  Stream<DocumentSnapshot> get userData {
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots();
  }

  // Stream of transactions (savings, expenses, investments)
  Stream<QuerySnapshot> get transactions {
    if (uid == null) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Add a new transaction
  Future<void> addTransaction({
    required double amount,
    required String type, // 'ahorro', 'gasto', 'inversion'
    required String category,
    required DateTime date,
    required String currency,
    String? description,
  }) async {
    if (uid == null) return;

    final batch = _db.batch();
    final userRef = _db.collection('users').doc(uid);
    final transactionRef = userRef.collection('transactions').doc();

    batch.set(transactionRef, {
      'amount': amount,
      'type': type,
      'category': category,
      'date': Timestamp.fromDate(date),
      'currency': currency,
      'description': description,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Update user totals
    Map<String, dynamic> updates = {};
    if (type == 'ahorro') {
      updates['totalSavings'] = FieldValue.increment(amount);
    } else if (type == 'gasto') {
      updates['totalExpenses'] = FieldValue.increment(amount);
    } else if (type == 'inversion') {
      updates['totalInvestments'] = FieldValue.increment(amount);
    }
    
    // Update balance
    double balanceChange = (type == 'gasto') ? -amount : amount;
    updates['balance'] = FieldValue.increment(balanceChange);

    // Usamos set con merge: true para que cree los campos si no existen
    batch.set(userRef, updates, SetOptions(merge: true));

    await batch.commit();
  }
}
