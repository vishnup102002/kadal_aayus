import 'package:flutter/material.dart';
import 'alerts_feed.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kadal Aayus')),
      body: Column(
        children: [
          Expanded(child: AlertsFeed()),
          // Other widgets from your teammate's code
        ],
      ),
    );
  }
}
