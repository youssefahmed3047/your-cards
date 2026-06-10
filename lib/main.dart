import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:krotak/home.dart';

void main() async {
  await Hive.initFlutter();
  await Hive.openBox('Cards');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(500, 1000),
      builder: (context, child) => MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 26, 65, 27),
            brightness: Brightness.dark,
          ),
          brightness: Brightness.dark,
          textTheme: GoogleFonts.cairoTextTheme(),
        ),
        home: Home(),
      ),
    );
  }
}
