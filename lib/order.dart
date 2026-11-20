import 'package:cloud_firestore/cloud_firestore.dart';

enum CodOrderStatus {
  pendingConfirmation,
  confirmed,
  preparing,
  shipped,
  delivered,
  canceled,
}

extension CodOrderStatusExtension on CodOrderStatus {
  String get code {
    switch (this) {
      case CodOrderStatus.pendingConfirmation:
        return 'pending_confirmation';
      case CodOrderStatus.confirmed:
        return 'confirmed';
      case CodOrderStatus.preparing:
        return 'preparing';
      case CodOrderStatus.shipped:
        return 'shipped';
      case CodOrderStatus.delivered:
        return 'delivered';
      case CodOrderStatus.canceled:
        return 'canceled';
    }
  }

  String get labelFr {
    switch (this) {
      case CodOrderStatus.pendingConfirmation:
        return 'Nouvelle (À confirmer)';
      case CodOrderStatus.confirmed:
        return 'Confirmée';
      case CodOrderStatus.preparing:
        return 'En préparation';
      case CodOrderStatus.shipped:
        return 'Expédiée';
      case CodOrderStatus.delivered:
        return 'Livrée & Encaissée';
      case CodOrderStatus.canceled:
        return 'Annulée / Retour';
    }
  }

  static CodOrderStatus fromString(String val) {
    return CodOrderStatus.values.firstWhere(
      (e) => e.code == val,
      orElse: () => CodOrderStatus.pendingConfirmation,
    );
  }
}

class CustomerDetails {
  final String fullName;
  final String phone;
  final String city;
  final String address;

  CustomerDetails({
    required this.fullName,
    required this.phone,
    required this.city,
    required this.address,
  });

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'phone': phone,
        'city': city,
        'address': address,
      };

  factory CustomerDetails.fromMap(Map<String, dynamic> map) {
    return CustomerDetails(
      fullName: map['fullName'] ?? '',
      phone: map['phone'] ?? '',
      city: map['city'] ?? '',
      address: map['address'] ?? '',
    );
  }
}

class OrderItem {
  final String productId;
  final String title;
  final String color;
  final String size;
  final double price;

  OrderItem({
    required this.productId,
    required this.title,
    required this.color,
    required this.size,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'title': title,
        'color': color,
        'size': size,
        'price': price,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      color: map['color'] ?? '',
      size: map['size'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
    );
  }
}

class CodOrder {
  final String id;
  final String trackingNumber;
  final CustomerDetails customer;
  final List<OrderItem> items;
  final double totalAmount;
  final CodOrderStatus status;
  final DateTime createdAt;

  CodOrder({
    required this.id,
    required this.trackingNumber,
    required this.customer,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory CodOrder.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CodOrder(
      id: doc.id,
      trackingNumber: data['trackingNumber'] ?? doc.id.substring(0, 6).toUpperCase(),
      customer: CustomerDetails.fromMap(data['customer'] ?? {}),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      status: CodOrderStatusExtension.fromString(data['status'] ?? ''),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}