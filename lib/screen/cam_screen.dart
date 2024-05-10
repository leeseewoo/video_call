import 'package:flutter/material.dart';

class CamScreen extends StatelessWidget {
  const CamScreen({Key? key}) : super(key: key);

  @override
  _CamScreenState createState() => _CamScreenState();
}

class _CanScreenState extends State<CamScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LIVE'),
      ),
      body: Center(
        child: Text('Cam Screen'),
      ),
    );
  }
}