import 'package:flutter/material.dart';
import 'package:haulier_tracking/models/driver.dart';
import 'package:haulier_tracking/models/delivery.dart';

class DriverProvider extends ChangeNotifier {
  Driver? _driver;
  List<Delivery> _deliveryHistory = [];

  Driver? get driver => _driver;
  List<Delivery> get deliveryHistory => _deliveryHistory;

  void setDriver(Driver driver) {
    _driver = driver;
    notifyListeners();
  }

  void setDeliveryHistory(List<Delivery> deliveryHistory) {
    _deliveryHistory = deliveryHistory;
    notifyListeners();
  }

  void setDriverInfo(Driver driver) {
    _driver = driver;
    notifyListeners();
  }
}
