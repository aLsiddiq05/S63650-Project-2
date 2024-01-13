import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:haulier_tracking/models/truck.dart';
import 'package:haulier_tracking/models/driver.dart';

import 'login.dart';

class RegisterTruckPage extends StatefulWidget {
  final Truck? updateTruck;
  RegisterTruckPage({Key? key, this.updateTruck}) : super(key: key);
  @override
  _RegisterTruckPageState createState() => _RegisterTruckPageState();
}

bool _isLoading = false;

class _RegisterTruckPageState extends State<RegisterTruckPage> {
  final _formKey = GlobalKey<FormState>();
  String? _vehicleRegFileName;
  String? _insuranceFileName;
  String? _imagePath;
  String? _selectedDriver;
  String? _selectedTruckType;
  List<Driver> _drivers = [];
  String? imageUrl;
  String? vehicleRegFileUrl;
  String? insuranceFileUrl;

  @override
  void initState() {
    super.initState();

    // Fetch the list of drivers when the page is loaded
    _fetchDriversAndTrucks();

    // Populate form fields with the selected truck data
    if (widget.updateTruck != null) {
      imageUrl = widget.updateTruck!.imagePath;
      _plateNumberController.text = widget.updateTruck!.plateNumber;
      _selectedTruckType = widget.updateTruck!.model;
      _selectedDriver = widget.updateTruck!.driverId;
      vehicleRegFileUrl = widget.updateTruck!.vehicleRegFileUrl;
      insuranceFileUrl = widget.updateTruck!.insuranceFileUrl;
    }
  }

  final DatabaseReference _database =
      FirebaseDatabase.instance.reference().child('truck');

  final Reference _imageStorageRef =
      FirebaseStorage.instance.ref().child('images');
  final Reference _vehicleRegStorageRef =
      FirebaseStorage.instance.ref().child('vehicle_registration');
  final Reference _insuranceStorageRef =
      FirebaseStorage.instance.ref().child('insurance');

  TextEditingController _plateNumberController = TextEditingController();

  Future<String?> uploadFileToStorage(Reference storageRef, File file) async {
    try {
      TaskSnapshot taskSnapshot =
          await storageRef.child(file.path.split('/').last).putFile(file);
      return await taskSnapshot.ref.getDownloadURL();
    } catch (error) {
      print('Error uploading file to storage: $error');
      return null;
    }
  }

  Map<String, String> driverTruckMapping = {};

  Future<void> _fetchDriversAndTrucks() async {
    try {
      // Load drivers
      DatabaseReference driversRef =
          FirebaseDatabase.instance.reference().child('driver');
      DatabaseEvent driversEvent = await driversRef.once();
      Map<dynamic, dynamic>? driversData =
          driversEvent.snapshot.value as Map<dynamic, dynamic>?;

      // Load trucks
      DatabaseReference trucksRef =
          FirebaseDatabase.instance.reference().child('truck');
      DatabaseEvent trucksEvent = await trucksRef.once();
      Map<dynamic, dynamic>? trucksData =
          trucksEvent.snapshot.value as Map<dynamic, dynamic>?;

      // Build the mapping between drivers and their associated trucks
      driverTruckMapping.clear();
      if (trucksData != null) {
        trucksData.forEach((key, value) {
          String driverId = value['driverId'] ?? '';
          if (driverId.isNotEmpty) {
            driverTruckMapping[driverId] = key;
          }
        });
      }

      List<Driver> driversList = [];

      if (driversData != null) {
        driversData.forEach((key, value) {
          Driver driver = Driver(
            id: key,
            name: value['name'] ?? '',
            email: value['email'] ?? '',
            password: value['password'] ?? '',
          );

          driversList.add(driver);
        });
      }

      setState(() {
        _drivers = driversList;
      });
    } catch (error) {
      print('Error fetching drivers and trucks: $error');
    }
  }

  Future<void> _uploadImagesAndFiles() async {
    if (_imagePath != null) {
      setState(() {
        _isLoading = true; // Set the flag to true while uploading
      });
      imageUrl = await uploadFileToStorage(_imageStorageRef, File(_imagePath!));
      setState(() {
        _isLoading = false; // Set the flag back to false after uploading
      });
    }

    if (_vehicleRegFileName != null) {
      vehicleRegFileUrl = await uploadFileToStorage(
          _vehicleRegStorageRef, File(_vehicleRegFileName!));
    }

    if (_insuranceFileName != null) {
      insuranceFileUrl = await uploadFileToStorage(
          _insuranceStorageRef, File(_insuranceFileName!));
    }
  }

  Future<void> saveDataToFirebase(String plateNumber, String truckType) async {
    try {
      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Upload images and files to storage
      await _uploadImagesAndFiles();

      // Check if the selected driver is already associated with a truck
      if (widget.updateTruck == null && _selectedDriver != null) {
        String selectedDriverId = _selectedDriver!;
        if (driverTruckMapping.containsKey(selectedDriverId)) {
          // The selected driver already has a truck
          // Display an error message or handle the case accordingly
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected driver already has a truck')),
          );
          return;
        }
      }

      // Check if updating and the driver is changed
      if (widget.updateTruck != null &&
          _selectedDriver != widget.updateTruck!.driverId) {
        // Driver is changed, check if the new driver already has a truck
        String selectedDriverId = _selectedDriver ?? '';
        if (driverTruckMapping.containsKey(selectedDriverId)) {
          // The selected driver already has a truck
          // Display an error message or handle the case accordingly
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected driver already has a truck')),
          );
          return;
        }
      }

      // Create a new Truck object with the entered data
      String truckId = widget.updateTruck != null
          ? widget.updateTruck!.id
          : _database.push().key ?? '';

      Truck updatedTruck = Truck(
        id: truckId,
        plateNumber: plateNumber,
        model: truckType,
        driverId: _selectedDriver ?? '',
        imagePath: imageUrl ?? '',
        vehicleRegFileUrl: vehicleRegFileUrl ?? '',
        insuranceFileUrl: insuranceFileUrl ?? '',
      );

      // Save the truck data to Firebase
      await _database.child(truckId).set(updatedTruck.toJson());

      // Show a success message or navigate to another screen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Truck Registered/Updated successfully')),
      );

      // Navigate to TruckInfoPage
      Navigator.pushReplacementNamed(context, '/truckInfo');
    } catch (error) {
      // Handle any errors that occurred during the save process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to register/update truck: $error')),
      );
    } finally {
      // Hide loading indicator after completion
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register Truck'),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0)),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Placeholder(
                          color: Colors.grey,
                          fallbackHeight: 150.0,
                          fallbackWidth: double.infinity,
                        ),
                      if (_isLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 10.0),
                ElevatedButton.icon(
                  onPressed: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['jpg', 'png', 'jpeg'],
                    );

                    if (result != null) {
                      PlatformFile file = result.files.first;

                      // Display the file name in your UI
                      setState(() {
                        _imagePath = file.path;
                        _isLoading = true;
                      });
                      // Upload the image
                      String? uploadedImageUrl = await uploadFileToStorage(
                          _imageStorageRef, File(_imagePath!));

                      // Update the UI with the uploaded image URL
                      setState(() {
                        imageUrl = uploadedImageUrl;
                        _isLoading = false;
                      });
                    } else {
                      // User canceled the picker
                    }
                  },
                  icon: Icon(Icons.file_upload),
                  label: Text('Choose Image'),
                ),
                SizedBox(height: 10.0),
                TextFormField(
                  controller: _plateNumberController,
                  decoration: InputDecoration(
                    labelText: 'Truck Plate Number',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the Plate Number';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10.0),
                DropdownButtonFormField<String>(
                  value: _selectedDriver,
                  hint: Text('Select Driver'),
                  items: _drivers.map((Driver driver) {
                    return DropdownMenuItem<String>(
                      value: driver.name,
                      child: Text(driver.name),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDriver = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a Driver';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10.0),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Truck Type',
                  ),
                  readOnly: true,
                  controller:
                      TextEditingController(text: _selectedTruckType ?? ''),
                  onTap: () async {
                    String? type = await showDialog<String>(
                      context: context,
                      builder: (BuildContext context) {
                        return SimpleDialog(
                          title: const Text('Select Truck Type'),
                          children: <Widget>[
                            SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, 'Light');
                              },
                              child: const Text('Light'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, 'Medium');
                              },
                              child: const Text('Medium'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                Navigator.pop(context, 'Heavy');
                              },
                              child: const Text('Heavy'),
                            ),
                          ],
                        );
                      },
                    );
                    if (type != null) {
                      setState(() {
                        _selectedTruckType = type;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a Truck Type';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ElevatedButton.icon(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'], // Only allow PDF files
                        );

                        if (result != null) {
                          PlatformFile file = result.files.first;

                          // Display the file name in your UI
                          setState(() {
                            _vehicleRegFileName = file.path;
                          });
                        } else {
                          // User canceled the picker
                        }
                      },
                      icon: Icon(Icons.file_upload),
                      label: Text('Vehicle Registration'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['pdf'], // Only allow PDF files
                        );

                        if (result != null) {
                          PlatformFile file = result.files.first;

                          // Display the file name in your UI
                          setState(() {
                            _insuranceFileName = file.path;
                          });
                        } else {
                          // User canceled the picker
                        }
                      },
                      icon: Icon(Icons.file_upload),
                      label: Text('Insurance'),
                    ),
                  ],
                ),
                SizedBox(height: 10.0),
                if (_vehicleRegFileName != null)
                  Text('Vehicle Registration: $_vehicleRegFileName'),
                if (_insuranceFileName != null)
                  Text('Insurance file: $_insuranceFileName'),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            // If the form is valid, save data to Firebase
                            saveDataToFirebase(_plateNumberController.text,
                                _selectedTruckType!);
                          }
                        },
                  child: _isLoading
                      ? CircularProgressIndicator() // Show loading indicator
                      : Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
