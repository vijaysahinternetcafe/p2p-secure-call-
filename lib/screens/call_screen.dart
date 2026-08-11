import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import '../core/call_manager.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    final callManager = context.read<CallManager>();
    callManager.onLocalStream = (stream) {
      if (mounted) setState(() => _localRenderer.srcObject = stream);
    };
    callManager.onRemoteStream = (stream) {
      if (mounted) setState(() => _remoteRenderer.srcObject = stream);
    };

    if (callManager.localStream != null) {
      _localRenderer.srcObject = callManager.localStream;
    }
    if (callManager.remoteStream != null) {
      _remoteRenderer.srcObject = callManager.remoteStream;
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final callManager = context.watch<CallManager>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: RTCVideoView(
              _remoteRenderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            ),
          ),
          Positioned(
            right: 16,
            top: 48,
            width: 120,
            height: 160,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 48,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    callManager.state == CallState.connected
                        ? Icons.circle
                        : Icons.pending,
                    color: callManager.state == CallState.connected
                        ? Colors.green
                        : Colors.orange,
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    callManager.state.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildButton(icon: Icons.mic_off, color: Colors.grey, onPressed: () {}),
                _buildButton(icon: Icons.videocam_off, color: Colors.grey, onPressed: () {}),
                _buildButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  size: 64,
                  onPressed: () {
                    callManager.endCall();
                    Navigator.pop(context);
                  },
                ),
                _buildButton(icon: Icons.cameraswitch, color: Colors.grey, onPressed: () {}),
                _buildButton(icon: Icons.volume_up, color: Colors.grey, onPressed: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required Color color,
    double size = 56,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: Colors.white), onPressed: onPressed),
    );
  }
}
