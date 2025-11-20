
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../login_screen.dart';
import '../member/member_dashboard.dart';
import '../superadmin/superadmin_dashboard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white, // Pure white background
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green), // Green accent
              ),
            ),
          );
        }
        if (snapshot.hasData) {
          return FutureBuilder<String?>(
            future: authService.getUserRole(snapshot.data!.uid),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.white, // Pure white background
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green), // Green accent
                    ),
                  ),
                );
              }
              if (roleSnapshot.hasError || roleSnapshot.data == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  authService.signOut();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                });
                return const Scaffold(
                  backgroundColor: Colors.white, // Pure white background
                  body: Center(
                    child: Text(
                      "User role not found. Redirecting...",
                      style: TextStyle(
                        color: Colors.black, // Black text
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }
              final role = roleSnapshot.data!;
              switch (role) {
                case 'Member':
                  return const MemberDashboard();
                case 'Admin':
                  return const AdminDashboard();
                case 'SuperAdmin':
                  return const SuperAdminDashboard();
                default:
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    authService.signOut();
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  });
                  return const Scaffold(
                    backgroundColor: Colors.white, // Pure white background
                    body: Center(
                      child: Text(
                        "Unknown role. Redirecting...",
                        style: TextStyle(
                          color: Colors.black, // Black text
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
              }
            },
          );
        }
        return const LoginScreen();
      },
    );
  }
}
