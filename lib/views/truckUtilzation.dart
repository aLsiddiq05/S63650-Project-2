import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:haulier_tracking/models/truck.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:haulier_tracking/models/delivery.dart';
import 'delivery_history_page.dart';
import 'login.dart';

class TruckUtilizationPage extends StatefulWidget {
  @override
  _TruckUtilizationPageState createState() => _TruckUtilizationPageState();
}

class _TruckUtilizationPageState extends State<TruckUtilizationPage> {
  int _statusIndex = 0;
  String _currentDeliveryStatus = 'No current delivery';
  int _numDeliveries = 0;
  bool _isLoading = false;

  final List<String> _lottieFiles = [
    'animations/task_received.json',
    'animations/on_destination.json',
    'animations/arrived.json',
    'animations/unloading.json',
    'animations/free.json',
    'animations/TaskComplete.json'
  ];

  final TextEditingController _newDeliveryArrivalEstimationController =
      TextEditingController();
  DateTime? _selectedDate; 
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _selectedSource;
  String? _selectedDestination;
  final List<String> _hubList = [
    'Kedah Hub',
    'Kelantan Hub',
    'Terengganu Hub',
    'Perlis Hub',
    'Perak Hub',
    'Penang Hub',
    'Johor Hub',
    'Selangor Hub',
    'Pahang Hub',
    'N9 Hub',
    'Melaka Hub',
  ];

  String? _validateHubSelection(String? selectedHub, String? otherHub) {
    if (selectedHub == null || otherHub == null) {
      return 'Please select a hub';
    }

    if (selectedHub == otherHub) {
      return 'Same source & destination hub';
    }

    return null;
  }

  // Firebase Database reference
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference().child('truck');

  int _getStatusIndexByStatus(String status) {
    switch (status) {
      case 'Task Received':
        return 0;
      case 'On Destination':
        return 1;
      case 'Arrived':
        return 2;
      case 'Unloading':
        return 3;
      case 'Completed':
        return 5;
      default:
        return 4;
    }
  }

  double _getProgressByStatus(String status) {
    // Define the progress for each status
    switch (status) {
      case 'Task Received':
        return 0.2;
      case 'On Destination':
        return 0.4;
      case 'Arrived':
        return 0.6;
      case 'Unloading':
        return 0.8;
      case 'Completed':
        return 1.0;
      default:
        return 0.0; // Default to 0.0 if status is not recognized
    }
  }

  IconData _getIconByStatus(String status) {
    switch (status) {
      case 'Task Received':
        return Icons.assignment;
      case 'On Destination':
        return Icons.location_on;
      case 'Arrived':
        return Icons.check_circle;
      case 'Unloading':
        return Icons.download_rounded;
      case 'Completed':
        return Icons.done;
      default:
        return Icons.assignment; // Default icon
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve the passed truck data
    Truck selectedTruck = ModalRoute.of(context)!.settings.arguments as Truck;
    // Get the list of deliveries
    List<Delivery> deliveries = selectedTruck.deliveries ?? [];
    // Check for the current delivery by comparing the estimated arrival date
    Delivery? currentDelivery;
    DateTime currentDate = DateTime.now();
    DateTime? longestArrivalDate;

    for (Delivery delivery in deliveries) {
      DateTime? estimatedArrivalDate =
          DateFormat('dd/MM/yyyy').parse(delivery.dateDelivered ?? '');
      if (estimatedArrivalDate != null) {
        // Check if the estimated arrival date is after the current date
        if (estimatedArrivalDate.isAfter(currentDate)) {
          // If there is no current delivery or this delivery has a longer estimated arrival date, update currentDelivery
          if (currentDelivery == null ||
              estimatedArrivalDate.isAfter(longestArrivalDate!)) {
            currentDelivery = delivery;
            longestArrivalDate = estimatedArrivalDate;
          }
        }
      }
    }
    // Listen for changes in the delivery node under the specific truck
    _databaseReference.child('${selectedTruck.id}/delivery').onValue.listen(
      (event) {
        DataSnapshot snapshot = event.snapshot;
        Map<dynamic, dynamic> deliveriesMap =
            (snapshot.value as Map<dynamic, dynamic>?) ?? {};

        List<Delivery> deliveries = deliveriesMap.values
            .map((dynamic deliveryJson) => Delivery.fromJson(deliveryJson))
            .toList();

        for (Delivery delivery in deliveries) {
          DateTime? estimatedArrivalDate =
              DateFormat('dd/MM/yyyy').parse(delivery.dateDelivered ?? '');
          if (estimatedArrivalDate != null &&
              estimatedArrivalDate.isAfter(currentDate)) {
            currentDelivery = delivery;
            break;
          }
        }

        setState(() {
          // Trigger a rebuild with the updated current delivery status
          _currentDeliveryStatus =
              currentDelivery?.status ?? 'No current delivery';

          // Update the number of deliveries
          _numDeliveries = deliveries.length;
        });
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Truck Utilization'),
        centerTitle: true,
        backgroundColor: Colors.grey[500],
        actions: [
          // Logout button in the AppBar
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              // Call the logout method from the LoginPage
              LoginPage.logout(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Truck ID: ${selectedTruck.id}',
                style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            Text('Number of Deliveries: $_numDeliveries',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text('Delivery Status: $_currentDeliveryStatus',
                style: TextStyle(fontSize: 16)),
            // Linear progress indicator with icon
            LinearProgressIndicator(
              value: _getProgressByStatus(_currentDeliveryStatus),
              color: Colors.blue, // Customize the progress color
              backgroundColor: Colors.grey, // Customize the background color
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icon(
                  _getIconByStatus('Task Received'),
                  color: _getProgressByStatus(_currentDeliveryStatus) >= 0.2
                      ? Colors.blue // Color when completed or in progress
                      : Colors.grey, // Color when not started
                  size: 32,
                ),
                Icon(
                  _getIconByStatus('On Destination'),
                  color: _getProgressByStatus(_currentDeliveryStatus) >= 0.4
                      ? Colors.blue
                      : Colors.grey,
                  size: 32,
                ),
                Icon(
                  _getIconByStatus('Arrived'),
                  color: _getProgressByStatus(_currentDeliveryStatus) >= 0.6
                      ? Colors.blue
                      : Colors.grey,
                  size: 32,
                ),
                Icon(
                  _getIconByStatus('Unloading'),
                  color: _getProgressByStatus(_currentDeliveryStatus) >= 0.8
                      ? Colors.blue
                      : Colors.grey,
                  size: 32,
                ),
                Icon(
                  _getIconByStatus('Completed'),
                  color: _getProgressByStatus(_currentDeliveryStatus) == 1.0
                      ? Colors.blue
                      : Colors.grey,
                  size: 32,
                ),
              ],
            ),
            Lottie.asset(
                'assets/${_lottieFiles[_getStatusIndexByStatus(_currentDeliveryStatus)]}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Show the dialog only if the delivery status allows
                    if (_currentDeliveryStatus == 'No current delivery' ||
                        _currentDeliveryStatus == 'Completed') {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return Dialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Container(
                              padding: EdgeInsets.all(16),
                              child: StatefulBuilder(
                                builder: (BuildContext context,
                                    StateSetter setState) {
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        'Assign New Delivery',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Form(
                                        key: _formKey,
                                        child: Column(
                                          children: <Widget>[
                                            DropdownButtonFormField<String>(
                                              value: _selectedSource,
                                              items: _hubList.map((String hub) {
                                                return DropdownMenuItem<String>(
                                                  value: hub,
                                                  child: Text(hub),
                                                );
                                              }).toList(),
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _selectedSource = value;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                  labelText: 'Enter Source'),
                                              validator: (value) =>
                                                  _validateHubSelection(value,
                                                      _selectedDestination),
                                            ),
                                            DropdownButtonFormField<String>(
                                              value: _selectedDestination,
                                              items: _hubList.map((String hub) {
                                                return DropdownMenuItem<String>(
                                                  value: hub,
                                                  child: Text(hub),
                                                );
                                              }).toList(),
                                              onChanged: (String? value) {
                                                setState(() {
                                                  _selectedDestination = value;
                                                });
                                              },
                                              decoration: InputDecoration(
                                                  labelText:
                                                      'Enter Destination'),
                                              validator: (value) =>
                                                  _validateHubSelection(
                                                      value, _selectedSource),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                // Show Date Picker on tap
                                                showDatePicker(
                                                  context: context,
                                                  initialDate: DateTime.now(),
                                                  firstDate: DateTime.now(),
                                                  lastDate: DateTime(
                                                      DateTime.now().year + 5),
                                                ).then((pickedDate) {
                                                  if (pickedDate != null) {
                                                    setState(() {
                                                      _selectedDate =
                                                          pickedDate;
                                                      _newDeliveryArrivalEstimationController
                                                          .text = DateFormat(
                                                              'dd/MM/yyyy')
                                                          .format(pickedDate);
                                                    });
                                                  }
                                                });
                                              },
                                              child: IgnorePointer(
                                                child: TextFormField(
                                                  controller:
                                                      _newDeliveryArrivalEstimationController,
                                                  decoration: InputDecoration(
                                                      labelText:
                                                          "Arrival Estimation"),
                                                  validator: (value) {
                                                    if (_selectedDate == null) {
                                                      return 'Please select an arrival estimation date';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          ElevatedButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () async {
                                                    if (_formKey.currentState!
                                                        .validate()) {
                                                      setState(() {
                                                        _isLoading = true;
                                                      });

                                                      // Proceed with assigning the new delivery
                                                      String deliveryId =
                                                          _databaseReference
                                                                  .child(
                                                                      'delivery')
                                                                  .push()
                                                                  .key ??
                                                              '';

                                                      Delivery newDelivery =
                                                          Delivery(
                                                        id: deliveryId,
                                                        status: 'Task Received',
                                                        source:
                                                            _selectedSource!,
                                                        destination:
                                                            _selectedDestination!,
                                                        dateDelivered: _selectedDate !=
                                                                null
                                                            ? DateFormat(
                                                                    'dd/MM/yyyy')
                                                                .format(
                                                                    _selectedDate!)
                                                            : '',
                                                      );

                                                      await _databaseReference
                                                          .child(
                                                              '${selectedTruck.id}/delivery/$deliveryId')
                                                          .set(newDelivery
                                                              .toJson());

                                                      setState(() {
                                                        _statusIndex =
                                                            0; // Set status to "Task Received"
                                                        _isLoading = false;
                                                      });
                                                      Navigator.of(context)
                                                          .pop();
                                                    }
                                                  },
                                            child: Text('Assign'),
                                          ),
                                          SizedBox(width: 10),
                                          TextButton(
                                            onPressed: _isLoading
                                                ? null
                                                : () {
                                                    Navigator.of(context).pop();
                                                  },
                                            child: Text('Cancel'),
                                          ),
                                        ],
                                      ),
                                      if (_isLoading)
                                        CircularProgressIndicator(),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                  child: Text('Assign New Delivery'),
                  style: ElevatedButton.styleFrom(
                    // Disable the button if the condition is not met
                    onPrimary:
                        _currentDeliveryStatus == 'No current delivery' ||
                                _currentDeliveryStatus == 'Completed'
                            ? Colors.blue
                            : Colors.grey,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeliveryHistoryPage(
                          truckId: selectedTruck.id,
                        ),
                      ),
                    );
                  },
                  child: Text('View Delivery History'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
