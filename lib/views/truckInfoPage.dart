import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:haulier_tracking/models/truck.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pdf_viewer_page.dart';
import 'registerTruck.dart';
import 'login.dart';

class TruckInfoPage extends StatefulWidget {
  @override
  _TruckInfoPageState createState() => _TruckInfoPageState();
}

class _TruckInfoPageState extends State<TruckInfoPage> {
  final DatabaseReference _database =
      FirebaseDatabase.instance.reference().child('truck');
  List<Truck> _trucks = [];

  int _currentCarouselIndex = 0;

  bool _isLoadingTrucks = true;
  String sanitizeFirebaseKey(String key) {
    return key.replaceAll(RegExp(r'[.#$/\[\]]'), '_');
  }

  @override
  void initState() {
    super.initState();
    _loadTrucks();
  }

  Future<void> _deleteTruck(String truckId) async {
    try {
      bool confirmed = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Delete Truck'),
            content: Text('Are you sure you want to delete this truck?'),
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
                child: Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        // Remove the truck from the local list
        setState(() {
          _trucks.removeWhere((truck) => truck.id == truckId);
        });

        print('Attempting to delete truck with ID: $truckId');

        // Check if the truck ID exists in the database before attempting to delete
        DatabaseEvent snapshot = await _database.once();

        if (snapshot.snapshot.value != null) {
          Map<dynamic, dynamic> rawData =
              snapshot.snapshot.value as Map<dynamic, dynamic>;

          rawData.entries.forEach((entry) async {
            if (entry.value is Map<dynamic, dynamic>) {
              Map<dynamic, dynamic> truckData =
                  entry.value as Map<dynamic, dynamic>;
              String id = truckData['id'] ?? '';

              // Check if the manually modified truckId matches the id in the database
              if (id == truckId) {
                print('Truck with ID $truckId found in the database');
                // Delete the truck from Firebase Realtime Database using remove
                await _database.child(entry.key).remove();
                print('Truck deleted from the database');
              }
            }
          });
        } else {
          print('No trucks found in the database');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Truck deleted successfully')),
        );
      }
    } catch (error, stackTrace) {
      print('Error deleting truck: $error');
      print('Stack trace: $stackTrace');
    }
  }

  void openPdfViewer(String pdfUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerPage(pdfUrl),
      ),
    );
  }

  Future<void> _loadTrucks() async {
    try {
      // Set _isLoadingTrucks to true when starting to load
      setState(() {
        _isLoadingTrucks = true;
      });

      DatabaseEvent snapshot = await _database.once();

      List<Truck> trucks = [];

      // Check if snapshot has data
      if (snapshot.snapshot.value != null) {
        // Explicitly cast snapshot.value to Map
        Map<dynamic, dynamic> data =
            (snapshot.snapshot.value as Map).cast<dynamic, dynamic>();

        // Iterate over the entries of the map
        data.entries.forEach((entry) {
          if (entry.value is Map<dynamic, dynamic>) {
            trucks.add(Truck.fromJson(entry.value));
          }
        });
      }

      setState(() {
        _trucks = trucks;
      });
    } catch (error) {
      print('Error loading trucks: $error');
      // Handle the error if needed
    } finally {
      // Set _isLoadingTrucks to false when loading is complete
      setState(() {
        _isLoadingTrucks = false;
      });
    }
  }

  void _openFile(String fileUrl) async {
    if (await canLaunch(fileUrl)) {
      await launch(fileUrl);
    } else {
      print('Could not launch $fileUrl');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Truck Information'),
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
      body: _isLoadingTrucks
          ? Center(child: CircularProgressIndicator())
          : _trucks.isEmpty
              ? _buildNoTruckView()
              : Column(
                  children: <Widget>[
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 600.0,
                        enlargeCenterPage: true,
                        onPageChanged: (index, reason) {
                          setState(() {
                            _currentCarouselIndex = index;
                          });
                        },
                      ),
                      items: _trucks.map((truck) {
                        return Builder(
                          builder: (BuildContext context) {
                            return Container(
                              width: double.infinity,
                              margin: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Card(
                                elevation: 4.0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Container(
                                      height: 200,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(16.0),
                                        ),
                                        image: DecorationImage(
                                          image: NetworkImage(truck.imagePath),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'TRUCK ${_trucks.indexOf(truck) + 1}',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 8.0),
                                          Text(
                                              'Plate Number: ${truck.plateNumber}'),
                                          SizedBox(height: 8.0),
                                          Text('Truck Type: ${truck.model}'),
                                          SizedBox(height: 8.0),
                                          Text('Driver: ${truck.driverId}'),
                                        ],
                                      ),
                                    ),
                                    Divider(height: 0),
                                    ListTile(
                                      leading: Icon(Icons.picture_as_pdf),
                                      title: Text('Vehicle Registration'),
                                      onTap: () {
                                        openPdfViewer(truck.vehicleRegFileUrl);
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.picture_as_pdf),
                                      title: Text('Insurance'),
                                      onTap: () {
                                        openPdfViewer(truck.insuranceFileUrl);
                                      },
                                    ),
                                    ListTile(
                                      leading: Icon(Icons.delete),
                                      title: Text('Delete Truck'),
                                      onTap: () {
                                        _deleteTruck(truck.id);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            // Ensure _trucks is not empty and _currentCarouselIndex is valid
                            if (_trucks.isNotEmpty &&
                                _currentCarouselIndex >= 0 &&
                                _currentCarouselIndex < _trucks.length) {
                              // Find the selected truck
                              Truck selectedTruck =
                                  _trucks[_currentCarouselIndex];

                              // Navigate to the TruckUtilizationPage and pass the selected truck data
                              Navigator.pushNamed(
                                context,
                                '/truckUtilzation',
                                arguments: selectedTruck,
                              );
                            }
                          },
                          child: Text('View Truck Utilization'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            // Ensure _trucks is not empty and _currentCarouselIndex is valid
                            if (_trucks.isNotEmpty &&
                                _currentCarouselIndex >= 0 &&
                                _currentCarouselIndex < _trucks.length) {
                              // Find the selected truck
                              Truck selectedTruck =
                                  _trucks[_currentCarouselIndex];

                              // Navigate to the update truck page and pass the selected truck data
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterTruckPage(
                                      updateTruck: selectedTruck),
                                ),
                              );
                            }
                          },
                          child: Text('Update Truck Information'),
                        ),
                      ],
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/registerTruck');
        },
        child: Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNoTruckView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'There\'s no truck available. ',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/registerTruck');
            },
            child: Text(
              'Register a truck now?',
              style: TextStyle(
                fontSize: 18,
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
