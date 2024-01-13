import 'truck.dart';

class Delivery {
  String id;
  String status;
  String? source;
  String? destination;
  String? dateDelivered;
  Truck? truck;

  Delivery({
    required this.id,
    required this.status,
    this.source,
    this.destination,
    this.dateDelivered,
    this.truck
  });

  // Factory constructor to create a Delivery object from a JSON map
  factory Delivery.fromJson(Map<dynamic, dynamic> json) {
    return Delivery(
      id: json['id'] ?? '',
      status: json['status'] ?? 'Free',
      source: json['source'],
      destination: json['destination'],
      dateDelivered: json['dateDelivered'],
    );
  }

  Map<String, dynamic> toJson() {
    // Sanitize the ID by removing invalid characters
    String sanitizedId = id.replaceAll(RegExp(r'[\[\]\#\$\/]'), '');
    return {
      'id': sanitizedId,
      'status': status,
      'source': source,
      'destination': destination,
      'dateDelivered': dateDelivered,
    };
  }
}
