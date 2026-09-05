import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login.dart';
import 'dashboard.dart';

final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://bubutwlfitvwcqxczeoe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1YnV0d2xmaXR2d2NxeGN6ZW9lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc0NzQwNzIsImV4cCI6MjEwMzA1MDA3Mn0.ZqWk48L6fsuaegWvmV5pulcmMhLJ4tmlqzHzeWAjxZo',
  );

  runApp(const SvaneyaAdminApp());
}

class SvaneyaAdminApp extends StatelessWidget {
  const SvaneyaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Svaneya Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pink, brightness: Brightness.light),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    supabase.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final session = supabase.auth.currentSession;
    if (session == null) {
      return const LoginScreen();
    } else {
      return const DashboardScreen();
    }
  }
}
