import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart'; 
import 'provider/driver_provider.dart'; 
import 'views/registerTruck.dart';
import 'views/signup.dart';
import 'views/login.dart';
import 'views/truckInfoPage.dart';
import 'views/truckUtilzation.dart';
import 'views/driverPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Wrap your entire app with MultiProvider
      providers: [
        ChangeNotifierProvider<DriverProvider>(
          create: (context) => DriverProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/truckInfo',
        routes: {
          '/': (context) => LoginPage(),
          '/signup': (context) => SignupPage(),
          '/registerTruck': (context) => RegisterTruckPage(),
          '/truckInfo': (context) => TruckInfoPage(),
          '/truckUtilzation': (context) => TruckUtilizationPage(),
          '/driverPage': (context) => DriverPage(),
        },
      ),
    );
  }
}
