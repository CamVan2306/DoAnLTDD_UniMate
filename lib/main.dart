import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unimate_huit/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  try {
    await Firebase.initializeApp();
    debugPrint("KẾT NỐI FIREBASE THÀNH CÔNG");
  } catch (e) {
    debugPrint("LỖI KẾT NỐI FIREBASE: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UniMate',
      theme: ThemeData(
        primaryColor: const Color(0xFF00346F),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00346F)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
