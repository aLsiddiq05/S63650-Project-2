import 'delivery.dart';

class Truck {
  String id;
  String plateNumber;
  String model;
  String driverId;
  String imagePath;
  String vehicleRegFileUrl;
  String insuranceFileUrl;
  List<Delivery> deliveries;

  Truck({
    required this.id,
    required this.plateNumber,
    required this.model,
    required this.driverId,
    required this.imagePath,
    required this.vehicleRegFileUrl,
    required this.insuranceFileUrl,
    this.deliveries = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Truck && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  // Factory constructor to create a Truck object from a JSON map
  factory Truck.fromJson(Map<dynamic, dynamic> json) {
    return Truck(
      id: json['id'] ?? '',
      plateNumber: json['plateNumber'] ?? '',
      model: json['model'] ?? '',
      driverId: json['driverId'] ?? '',
      imagePath: json['imagePath'] ?? '',
      vehicleRegFileUrl: json['vehicleRegFileUrl'] ?? '',
      insuranceFileUrl: json['insuranceFileUrl'] ?? '',
      deliveries: json['deliveries'] != null
          ? List<Delivery>.from(json['deliveries']
              .map((dynamic deliveryJson) => Delivery.fromJson(deliveryJson)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    // Sanitize the ID by removing invalid characters
    String sanitizedId = id.replaceAll(RegExp(r'[\[\]\#\$\/]'), '');
    return {
      'id': sanitizedId,
      'plateNumber': plateNumber,
      'model': model,
      'driverId': driverId,
      'imagePath': imagePath,
      'vehicleRegFileUrl': vehicleRegFileUrl,
      'insuranceFileUrl': insuranceFileUrl,
      'deliveries': deliveries.map((delivery) => delivery.toJson()).toList(),
    };
  }
}
