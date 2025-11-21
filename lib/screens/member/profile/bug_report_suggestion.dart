import 'package:flutter/material.dart';

class BugReport extends StatefulWidget {
  const BugReport({super.key});

  @override
  State<StatefulWidget> createState() => _BugReport();
}

class _BugReport extends State<BugReport> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Bugs & Suggestions'),
        backgroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bug_report,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16,),
            Text('Please Send ',style: TextStyle(fontSize: 18),),
            SizedBox(height: 16,),
            Text('romizdev1@gmail.com',style: TextStyle(fontSize: 24,fontWeight: FontWeight.bold),),
          ],
        ),
      ),
    );
  }
}
