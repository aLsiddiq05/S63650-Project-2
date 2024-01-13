import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haulier_tracking/provider/driver_provider.dart';
import 'package:haulier_tracking/models/delivery.dart';

import '../models/truck.dart';
import 'login.dart';

class DriverPage extends StatefulWidget {
  @override
  _DriverPageState createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  @override
  Widget build(BuildContext context) {
    // Use the Provider to get the DriverProvider instance
    final driverProvider = Provider.of<DriverProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Page'),
        centerTitle: true,
        backgroundColor: Colors.grey[500],
        automaticallyImplyLeading: false,
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Text(
              'Welcome ${driverProvider.driver?.name ?? ''}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Display delivery history or image if no deliveries
          FutureBuilder<List<Delivery>>(
            future:
                _fetchDriverDeliveryHistory(driverProvider.driver?.name ?? ''),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/empty_delivery.png',
                      width: 150,
                      height: 150,
                    ),
                    Text('No delivery history available.'),
                  ],
                );
              } else {
                // Sort deliveries by date in descending order
                snapshot.data!.sort(
                    (a, b) => b.dateDelivered!.compareTo(a.dateDelivered!));
                return Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      Delivery delivery = snapshot.data![index];

                      // Access the associated Truck from the Delivery object
                      Truck truck = delivery.truck ??
                          Truck(
                            id: '',
                            plateNumber: '',
                            model: '',
                            driverId: '',
                            imagePath: '',
                            vehicleRegFileUrl: '',
                            insuranceFileUrl: '',
                            deliveries: [],
                          );

                      // Set color based on delivery status
                      Color tileColor = delivery.status == 'Completed'
                          ? Colors.greenAccent
                          : Colors.grey;

                      return Card(
                        color: tileColor,
                        elevation: 3,
                        margin:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: Icon(Icons.local_shipping), // Truck icon
                          title: Text(delivery.dateDelivered ?? ''),
                          subtitle: Text(
                              '${delivery.source} to ${delivery.destination}'),
                          trailing: _buildStatusDropdown(truck, delivery),
                        ),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(Truck truck, Delivery delivery) {
    final List<String> statusOptions = [
      'On Destination',
      'Arrived',
      'Unloading',
      'Completed',
    ];

    // Enable the dropdown only if the status is not 'Completed'
    bool enableDropdown = delivery.status != 'Completed';

    print('Delivery Status: ${delivery.status}');
    print('Status Options: $statusOptions');

    List<DropdownMenuItem<String>> dropdownItems =
        statusOptions.map<DropdownMenuItem<String>>((String status) {
      return DropdownMenuItem<String>(
        value: status,
        child: Text(status),
      );
    }).toList();

    // Add 'Task Received' option only if the current status is 'Task Received'
    if (enableDropdown && delivery.status == 'Task Received') {
      dropdownItems.add(
        DropdownMenuItem<String>(
          value: 'Task Received',
          child: Text('Task Received'),
        ),
      );
    }

    return DropdownButton<String>(
      value: delivery.status,
      onChanged: enableDropdown
          ? (String? newValue) =>
              _updateDeliveryStatus(truck, delivery, newValue!)
          : null,
      items: dropdownItems,
    );
  }

  Future<List<Delivery>> _fetchDriverDeliveryHistory(String driverId) async {
    List<Delivery> deliveryHistory = [];

    try {
      DatabaseReference databaseReference =
          FirebaseDatabase.instance.reference();

      // Find the truck associated with the driver
      DatabaseEvent truckEvent = await databaseReference
          .child('truck')
          .orderByChild('driverId')
          .equalTo(driverId)
          .once();

      DataSnapshot truckSnapshot = truckEvent.snapshot;

      print('Truck Snapshot Value: ${truckSnapshot.value}');

      if (truckSnapshot.value != null) {
        // Get the first truck directly since a driver is associated with only one truck
        Map<dynamic, dynamic> truckData =
            (truckSnapshot.value as Map<dynamic, dynamic>).values.first;

        // Check if the truck has a 'delivery' node
        if (truckData['delivery'] != null) {
          // Access the 'delivery' node values
          Map<dynamic, dynamic> deliveriesMap =
              truckData['delivery'] as Map<dynamic, dynamic>;

          // Iterate through each delivery in the truck
          deliveriesMap.forEach((deliveryId, deliveryData) {
            // Convert the deliveryData into a Delivery object and add it to the list
            Delivery delivery = Delivery.fromJson(deliveryData);
            deliveryHistory.add(delivery);
          });
        }
      }
    } catch (error) {
      print('Error fetching driver delivery history: $error');
    }

    return deliveryHistory;
  }

  void _updateDeliveryStatus(
      Truck truck, Delivery delivery, String newStatus) async {
    try {
      DatabaseReference databaseReference =
          FirebaseDatabase.instance.reference().child('truck');

      // Update the status of the delivery in the database
      await databaseReference
          .child(truck.id)
          .child('delivery')
          .child(delivery.id)
          .update({'status': newStatus});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (error) {
      print('Error updating delivery status: $error');
    }
  }
}
