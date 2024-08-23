import 'package:flutter/material.dart';
import 'package:ideamagix_assign/screens/registration_screen.dart';
import 'screens/Home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeautyBoo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}







// this app is going to make for managing inventory of a beatuty store and store the data locally its dummy app just imagine im uploading on server so all the other user can see my products as per categories how i upload
// now just use local storage for this .
// Create this home screen where i will have a floatinigactionbutton,
// when i tap on that button i'll get popup for select various categories of beauty products use ony 5 for dummy and when i select or tap on any
// it should go on page where that category is selected and i can add products and manage them. so for this make a form that looks attractive where i can upload images of that product, title, and add description and give a upload button.
// this data should be uploaded in category wise in local storage so i can use this in other page as list


// now this my home page will be like a dashboard , this is an app for managing inventory of a beauty store & store data locally,
// create a dashboard which will show the number of categories, number of products, products low in inventory and number of users registered. use charts to display stats.
// these users can then create categories, add products and manage them.
// Each category will have an image, title and description. the image can be chosen from the gallery or can be clicked. add a cropper to crop the image to squae aspect ratio.