import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/call_manager.dart';
import 'call_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _deviceIdController = TextEditingController();
  bool _isInitializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await context.read<CallManager>().initialize();
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final callManager = context.watch<CallManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Secure Call'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Icon(Icons.security, size: 48, color: Colors.green),
                              const SizedBox(height: 8),
                              Text('Your Device ID', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              SelectableText(
                                callManager.deviceId,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              if (callManager.isPreWarmed)
                                const Chip(
                                  label: Text('Ready'),
                                  backgroundColor: Colors.green,
                                  labelStyle: TextStyle(color: Colors.white),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _deviceIdController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Remote Device ID',
                          border: OutlineInputBorder(),
                          hintText: "Paste other phone's ID here",
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: callManager.state == CallState.idle
                            ? () {
                                if (_deviceIdController.text.isNotEmpty) {
                                  _startCall(_deviceIdController.text);
                                }
                              }
                            : null,
                        icon: const Icon(Icons.call),
                        label: const Text('Start Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _preWarm(),
                        icon: const Icon(Icons.speed),
                        label: const Text('Pre-warm Connection'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Future<void> _startCall(String remoteId) async {
    await context.read<CallManager>().startCall(remoteId);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CallScreen()),
      );
    }
  }

  Future<void> _preWarm() async {
    await context.read<CallManager>().preWarmConnection();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection pre-warmed!')),
      );
    }
  }
}
