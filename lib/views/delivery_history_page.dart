import 'package:flutter/material.dart';
import 'package:haulier_tracking/models/delivery.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

import 'login.dart';

class DeliveryHistoryPage extends StatefulWidget {
  final String truckId;

  const DeliveryHistoryPage({Key? key, required this.truckId})
      : super(key: key);

  @override
  _DeliveryHistoryPageState createState() => _DeliveryHistoryPageState();
}

List<Delivery> _deliveryHistory = [];

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.reference().child('truck');

  @override
  void initState() {
    super.initState();
    _fetchDeliveryHistory();
  }

  void _fetchDeliveryHistory() async {
    try {
      DatabaseEvent event =
          await _databaseReference.child('${widget.truckId}/delivery').once();
      DataSnapshot snapshot = event.snapshot;

      Map<dynamic, dynamic> deliveriesMap =
          (snapshot.value as Map<dynamic, dynamic>?) ?? {};
      List<Delivery> deliveries = deliveriesMap.values
          .map((dynamic deliveryJson) => Delivery.fromJson(deliveryJson))
          .toList();

      setState(() {
        deliveries.sort((a, b) {
          DateTime? dateA =
              DateFormat('dd/MM/yyyy').parse(a.dateDelivered ?? '');
          DateTime? dateB =
              DateFormat('dd/MM/yyyy').parse(b.dateDelivered ?? '');

          if (dateA != null && dateB != null) {
            return dateB.compareTo(dateA);
          }

          return 0;
        });

        _deliveryHistory = deliveries;
      });
    } catch (error) {
      print('Error fetching delivery history: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery History'),
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
      body: _deliveryHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/empty_delivery.png'),
                  SizedBox(height: 16),
                  Text("There is no delivery made by this truck yet."),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _deliveryHistory.length,
              itemBuilder: (context, index) {
                Delivery delivery = _deliveryHistory[index];

                Color tileColor = delivery.status == 'Completed'
                    ? Colors.greenAccent
                    : Colors.grey;

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2.0,
                    horizontal: 8.0,
                  ),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      tileColor: tileColor,
                      leading: Icon(Icons.local_shipping),
                      title: Text(
                        delivery.dateDelivered ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${delivery.source} to ${delivery.destination}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      trailing: Text(
                        delivery.status,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
