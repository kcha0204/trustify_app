import 'package:flutter/material.dart';

class CyberTrendsPage extends StatelessWidget {
  const CyberTrendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cyber Trends'),
        backgroundColor: const Color(0xFF033C5A),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics,
              size: 64,
              color: Color(0xFF033C5A),
            ),
            SizedBox(height: 20),
            Text(
              'Cyber Trends Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF033C5A),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Victoria Threat Analysis',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Coming Soon...',
              style: TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}