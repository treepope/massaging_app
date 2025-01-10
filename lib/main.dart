import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Messaging App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MessagingScreen(),
    );
  }
}

class MessagingScreen extends StatefulWidget {
  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final List<String> _messages = [];
  HttpServer? _server;

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  void _startServer() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
    _server!.listen((HttpRequest request) async {
      if (request.method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        setState(() {
          _messages.add(content);
        });
      }
      request.response.statusCode = 200;
      await request.response.close();
    });
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    final ip = _ipController.text.trim();
    if (message.isNotEmpty && ip.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse('http://$ip:8080'),
          body: message,
        );
        if (response.statusCode == 200) {
          setState(() {
            _messages.add('You: $message');
          });
          _messageController.clear();
        }
      } catch (e) {
        print('Error sending message: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Local Messaging App'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_messages[index]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _ipController,
              decoration: InputDecoration(
                hintText: 'Enter receiver\'s IP address',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _server?.close();
    super.dispose();
  }
}