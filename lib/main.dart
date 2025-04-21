import 'package:flutter/material.dart';
import 'package:task_management/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:task_management/home_screen.dart';
import 'package:task_management/login_screen.dart';
import 'package:task_management/signup_screen.dart';
import 'package:task_management/welcome_screen.dart';
void main ()async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(Myapp());
}
class Myapp extends StatefulWidget {
  const Myapp({super.key});

  @override
  State<Myapp> createState() => _MyappState();
}

class _MyappState extends State<Myapp> {
  @override
  Widget build(BuildContext context) {
    return  GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/start",
      getPages: [
        GetPage(name: "/start", page:()=>WelcomeScreen()),
        GetPage(name: "/signup", page: ()=>SignupScreen()),
        GetPage(name: "/signin", page: ()=>LoginScreen()),
        GetPage(name:"/home",page: ()=>HomeScreen()),
      ],
    );
  }
}
