import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  String? validatePassword(String? value) {
    Pattern pattern =
        r'^(?=.*[0-9]+.*)(?=.*[a-zA-Z]+.*)(?=.*[A-Z]+.*)(?=.*[^a-zA-Z0-9]+.*)[0-9a-zA-Z!@#\$&*~]{8,}$';
    RegExp regex = new RegExp(pattern as String);
    if (!regex.hasMatch(value!))
      return 'Invalid Password';
    else
      return null;
  }

  String? validateEmail(String? value) {
    Pattern pattern = r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
    RegExp regex = new RegExp(pattern as String);
    if (!regex.hasMatch(value!))
      return 'Invalid email format';
    else
      return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            "Signup Page",
            style: TextStyle(
              color: Colors.white, // Set the color of the title
              fontSize: 24, // Set the font size
              fontWeight: FontWeight.bold, // Set the font weight
            ),
          ),
          backgroundColor: Colors.blueGrey[900], // Set the background color
          elevation: 0, // Remove the shadow
          centerTitle: true, // Center the title
        ),
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
              physics:
                  NeverScrollableScrollPhysics(), // make the screen non-draggable
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Center(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        Lottie.asset('assets/animations/register.json',
                            width: 200, height: 200),
                        Container(
                          width: 300,
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon:
                                  Icon(Icons.person), // Icon at the start
                              filled: true,
                              fillColor: Colors.grey[200], // Fill color
                            ),
                            style: TextStyle(
                              fontSize: 18, // Text size
                              color: Colors.black, // Text color
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          width: 300, // Set the width as per your requirement
                          child: TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: Icon(Icons.email),
                              filled: true,
                              fillColor: Colors.grey[200],
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                            ),
                            validator: validateEmail,
                          ),
                        ),
                        SizedBox(height: 10),
                        Container(
                          width: 300, // Set the width as per your requirement
                          child: TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              prefixIcon: Icon(Icons.lock),
                              filled: true,
                              fillColor: Colors.grey[200],
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureText
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureText = !_obscureText;
                                  });
                                },
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                            ),
                            validator: validatePassword,
                            obscureText: _obscureText,
                          ),
                        ),
                        SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Password must contain:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text('• At least one numeric character'),
                              Text('• At least one lowercase character'),
                              Text('• At least one uppercase character'),
                              Text('• At least one special character'),
                              Text('• Minimum length of 8 characters'),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Processing Data')));
                            }
                          },
                          child: Text('Submit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Colors.blueGrey[800], // Set the button color
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ));
  }
}
