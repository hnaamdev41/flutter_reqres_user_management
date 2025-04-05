import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reqres_user_management/services/auth_service.dart';
import 'package:reqres_user_management/views/login_screen.dart';
import 'package:reqres_user_management/views/user_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'ReqRes User Management',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthenticationWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/users': (context) => const UserListScreen(),
        },
      ),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This will be expanded later to check authentication status
    return const LoginScreen();
  }
}