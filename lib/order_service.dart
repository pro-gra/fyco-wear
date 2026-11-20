import 'package:cloud_firestore/cloud_firestore.dart';
import 'order.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a new COD order in Firestore
  Future<String> submitOrder({
    required CustomerDetails customer,
    required List<OrderItem> items,
    required double totalAmount,
  }) async {
    final docRef = _firestore.collection('orders').doc();
    final trackingCode = 'MA-${docRef.id.substring(0, 6).toUpperCase()}';

    await docRef.set({
      'trackingNumber': trackingCode,
      'customer': customer.toMap(),
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': CodOrderStatus.pendingConfirmation.code,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return trackingCode;
  }

  /// Real-time stream of all orders for Admin panel
  Stream<List<CodOrder>> streamAllOrders() {
    return _firestore
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => CodOrder.fromSnapshot(doc)).toList());
  }

  /// Updates status of an order
  Future<void> updateOrderStatus(String docId, CodOrderStatus newStatus) async {
    await _firestore.collection('orders').doc(docId).update({
      'status': newStatus.code,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });
  }
}