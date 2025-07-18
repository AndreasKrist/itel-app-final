import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../screens/login_screen.dart';

class GuestBanner extends StatelessWidget {
  const GuestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(color: Colors.blue[200]!),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[700],
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You are currently browsing as a Guest.',
              style: TextStyle(
                color: Colors.blue[800],
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                minSize: 0,
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(
                        onLoginStatusChanged: (bool isLoggedIn) {
                          // Handle login success
                        },
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Sign-in for Full Access',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontSize: 10,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}