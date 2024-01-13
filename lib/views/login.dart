import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:haulier_tracking/models/driver.dart';
import 'package:haulier_tracking/models/manager.dart';
import 'package:haulier_tracking/models/delivery.dart';
import 'package:haulier_tracking/provider/driver_provider.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();

  static Future<void> logout(BuildContext context) async {
    // Show a confirmation dialog
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Log Out'),
          content: Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text('Log Out'),
            ),
          ],
        );
      },
    );

    // Check the user's choice
    if (confirmLogout == true) {
      // Navigate back to the login screen
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _userType = "manager";
  String _email = "";
  String _password = "";
  bool _isLoading = false;

  // Get the DriverProvider instance
  final DriverProvider _driverProvider = DriverProvider();
  DatabaseReference _databaseReference = FirebaseDatabase.instance.reference();

  String? validateEmail(String? value) {
    Pattern pattern = r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
    RegExp regex = RegExp(pattern as String);
    return (value == null || value.isEmpty)
        ? 'Please enter your email'
        : (!regex.hasMatch(value))
            ? 'Invalid email format'
            : null;
  }

  Future<void> loginUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        DatabaseEvent snapshot = await _databaseReference
            .child(_userType)
            .orderByChild('email')
            .equalTo(_email)
            .once();

        if (snapshot.snapshot.value != null) {
          Map<dynamic, dynamic> data =
              (snapshot.snapshot.value as Map).values.first;
          String userId = (snapshot.snapshot.value as Map).keys.first;

          if (_userType == "manager") {
            Manager manager = Manager.fromMap(data, userId);

            if (_password == manager.password) {
              // Valid login, navigate accordingly
              Navigator.pushNamed(context, '/truckInfo');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User found')),
              );
            } else {
              // Invalid password
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid password')),
              );
            }
          } else if (_userType == "driver") {
            Driver driver = Driver.fromMap(data, userId);

            // Set driver data to the provider
            _driverProvider.setDriver(driver);

            // Retrieve and set delivery history data
            List<Delivery> deliveryHistory =
                await _fetchDriverDeliveryHistory(driver.id);
            _driverProvider.setDeliveryHistory(deliveryHistory);

            if (_password == driver.password) {
              // Valid login, navigate accordingly
              // Print the state of DriverProvider
              print(
                  'DriverProvider state after login: ${Provider.of<DriverProvider>(context, listen: false).driver}');

              // Now, update the DriverProvider with the driver's information
              Provider.of<DriverProvider>(context, listen: false)
                  .setDriverInfo(driver);

              // Print the state of DriverProvider after updating
              print(
                  'DriverProvider state after updating: ${Provider.of<DriverProvider>(context, listen: false).driver}');

              Navigator.pushNamed(context, '/driverPage');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('User found')),
              );
            } else {
              // Invalid password
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invalid password')),
              );
            }
          }
        } else {
          // User not found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User not found')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Delivery>> _fetchDriverDeliveryHistory(String driverId) async {
    List<Delivery> deliveryHistory = [];

    try {
      DatabaseReference databaseReference =
          FirebaseDatabase.instance.reference();
      DatabaseEvent event = await databaseReference
          .child('truck')
          .orderByChild('driverId')
          .equalTo(driverId)
          .once();
      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic> trucksData =
            (snapshot.value as Map<dynamic, dynamic>);

        // Iterate through each truck
        trucksData.forEach((truckId, truckData) {
          // Check if the truck has a 'delivery' node
          if (truckData['delivery'] != null) { 
            Map<dynamic, dynamic> deliveriesMap =
                (truckData['delivery'] as Map<dynamic, dynamic>);

            // Iterate through each delivery in the truck
            deliveriesMap.forEach((deliveryId, deliveryData) {
              // Convert the deliveryData into a Delivery object and add it to the list
              Delivery delivery = Delivery.fromJson(deliveryData);
              deliveryHistory.add(delivery);
            });
          }
        });
      }
    } catch (error) {
      print('Error fetching driver delivery history: $error');
    }

    return deliveryHistory;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'XYZ Haulier Tracking App',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[900]),
                  ),
                  Lottie.asset('assets/animations/LoginAnimation.json',
                      width: 250, height: 250),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: TextFormField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: Icon(Icons.email),
                              filled: true,
                              fillColor: Colors.grey[200],
                              labelText: 'Email',
                            ),
                            validator: validateEmail,
                            onChanged: (value) {
                              setState(() {
                                _email = value;
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(10.0),
                          child: TextFormField(
                            obscureText: true,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: Icon(Icons.lock),
                              filled: true,
                              fillColor: Colors.grey[200],
                              labelText: 'Password',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                _password = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Manager'),
                      Radio<String>(
                        value: "manager",
                        groupValue: _userType,
                        onChanged: (String? value) {
                          setState(() {
                            _userType = value!;
                          });
                        },
                      ),
                      Text('Driver'),
                      Radio<String>(
                        value: "driver",
                        groupValue: _userType,
                        onChanged: (String? value) {
                          setState(() {
                            _userType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : loginUser,
                    child: _isLoading
                        ? CircularProgressIndicator() // Show a loading indicator
                        : Text('Login'),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blueGrey[800],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
