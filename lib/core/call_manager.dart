import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/permission_service.dart';
import 'crypto_manager.dart';
import 'signaling_client.dart';
import 'media_config.dart';

enum CallState {
  idle,
  connecting,
  ringing,
  connected,
  failed,
  disconnected,
}

class CallManager extends ChangeNotifier {
  static final CallManager _instance = CallManager._internal();
  factory CallManager() => _instance;
  CallManager._internal();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  CallState _state = CallState.idle;
  CallState get state => _state;

  bool _isPreWarmed = false;
  bool get isPreWarmed => _isPreWarmed;

  String? _currentCallId;
  String? _remoteDeviceId;

  void Function(MediaStream?)? onLocalStream;
  void Function(MediaStream?)? onRemoteStream;
  void Function(CallState)? onStateChange;

  final CryptoManager _crypto = CryptoManager();
  late SignalingClient _signaling;
  final _config = MediaConfig();

  RTCPeerConnection? get peerConnection => _peerConnection;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  String? get currentCallId => _currentCallId;
  String? get remoteDeviceId => _remoteDeviceId;

  Future<void> initialize() async {
    debugPrint('[CallManager] Initializing...');
    await _crypto.initialize();
    final permissionsGranted = await PermissionService.requestAllPermissions();
    if (!permissionsGranted) {
      throw Exception('Critical permissions denied');
    }
    _signaling = SignalingClient(
      serverUrl: 'wss://your-server.com/signaling',
      cryptoManager: _crypto,
      onMessage: _handleSignalingMessage,
      onConnected: _onSignalingConnected,
    );
    await _signaling.connect();
    debugPrint('[CallManager] Initialized');
  }

  Future<void> preWarmConnection() async {
    if (_peerConnection != null) return;
    debugPrint('[CallManager] Pre-warming...');

    final configuration = <String, dynamic>{
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'iceTransportPolicy': 'all',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require',
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);
    _peerConnection!.onIceCandidate = _onIceCandidate;
    _peerConnection!.onIceConnectionState = _onIceConnectionState;
    _peerConnection!.onTrack = _onTrack;
    _peerConnection!.onConnectionState = _onConnectionState;
    await _createLocalStream(startCamera: false);

    _isPreWarmed = true;
    notifyListeners();
    debugPrint('[CallManager] Pre-warmed');
  }

  Future<void> _createLocalStream({required bool startCamera}) async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': startCamera
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };

    _localStream = await navigator.mediaDevices.getUserMedia(constraints);

    if (_peerConnection != null) {
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }
    onLocalStream?.call(_localStream);
  }

  Future<void> startCall(String remoteDeviceId) async {
    if (_state != CallState.idle) throw Exception('Already in a call');

    _remoteDeviceId = remoteDeviceId;
    _currentCallId = '${DateTime.now().millisecondsSinceEpoch}_${_crypto.deviceId}';
    _updateState(CallState.connecting);

    if (!_isPreWarmed) await preWarmConnection();
    await _enableMedia();

    final offer = await _peerConnection!.createOffer(_config.offerConstraints);
    await _peerConnection!.setLocalDescription(offer);

    await _signaling.send({
      'type': 'offer',
      'callId': _currentCallId,
      'from': _crypto.deviceId,
      'to': remoteDeviceId,
      'sdp': offer.sdp,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    _updateState(CallState.ringing);
  }

  Future<void> answerCall(String callId, String fromDeviceId) async {
    if (_state != CallState.idle) throw Exception('Cannot answer');
    _currentCallId = callId;
    _remoteDeviceId = fromDeviceId;
    _updateState(CallState.connecting);
    if (!_isPreWarmed) await preWarmConnection();
    await _enableMedia();
  }

  Future<void> proceedAnswer() async {
    final answer = await _peerConnection!.createAnswer(_config.answerConstraints);
    await _peerConnection!.setLocalDescription(answer);

    await _signaling.send({
      'type': 'answer',
      'callId': _currentCallId,
      'from': _crypto.deviceId,
      'to': _remoteDeviceId,
      'sdp': answer.sdp,
    });

    _updateState(CallState.connected);
  }

  Future<void> declineCall() async {
    await _signaling.send({
      'type': 'decline',
      'callId': _currentCallId,
      'from': _crypto.deviceId,
      'to': _remoteDeviceId,
    });
    await _cleanup();
  }

  Future<void> endCall() async {
    await _signaling.send({
      'type': 'bye',
      'callId': _currentCallId,
      'from': _crypto.deviceId,
      'to': _remoteDeviceId,
    });
    await _cleanup();
  }

  void _onSignalingConnected() {
    debugPrint('[CallManager] Signaling connected');
    preWarmConnection();
  }

  Future<void> _handleSignalingMessage(Map<String, dynamic> message) async {
    final type = message['type'];
    switch (type) {
      case 'offer':
        await _handleOffer(message);
        break;
      case 'answer':
        await _handleAnswer(message);
        break;
      case 'ice-candidate':
        await _handleIceCandidate(message);
        break;
      case 'bye':
      case 'decline':
        await _cleanup();
        break;
    }
  }

  Future<void> _handleOffer(Map<String, dynamic> message) async {
    final sdp = message['sdp'];
    final from = message['from'];
    final callId = message['callId'];
    await answerCall(callId, from);
    final desc = RTCSessionDescription(sdp, 'offer');
    await _peerConnection!.setRemoteDescription(desc);
  }

  Future<void> _handleAnswer(Map<String, dynamic> message) async {
    final sdp = message['sdp'];
    final desc = RTCSessionDescription(sdp, 'answer');
    await _peerConnection!.setRemoteDescription(desc);
    _updateState(CallState.connected);
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> message) async {
    final candidate = RTCIceCandidate(
      message['candidate'],
      message['sdpMid'],
      message['sdpMLineIndex'],
    );
    await _peerConnection!.addCandidate(candidate);
  }

  void _onIceCandidate(RTCIceCandidate candidate) {
    if (candidate.candidate != null) {
      _signaling.send({
        'type': 'ice-candidate',
        'callId': _currentCallId,
        'to': _remoteDeviceId,
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    }
  }

  void _onIceConnectionState(RTCIceConnectionState state) {
    debugPrint('[CallManager] ICE State: $state');
    if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
      _updateState(CallState.connected);
    } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
      _updateState(CallState.failed);
    } else if (state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
      _updateState(CallState.disconnected);
    }
  }

  void _onTrack(RTCTrackEvent event) {
    if (event.streams.isNotEmpty) {
      _remoteStream = event.streams[0];
      onRemoteStream?.call(_remoteStream);
    }
  }

  void _onConnectionState(RTCPeerConnectionState state) {
    debugPrint('[CallManager] Connection State: $state');
  }

  Future<void> _enableMedia() async {
    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        track.enabled = true;
      }
    }
  }

  Future<void> _cleanup() async {
    _updateState(CallState.idle);
    for (final track in _localStream?.getTracks() ?? []) {
      track.stop();
    }
    await _localStream?.dispose();
    _localStream = null;
    await _peerConnection?.close();
    _peerConnection = null;
    _remoteStream = null;
    _currentCallId = null;
    _remoteDeviceId = null;
    _isPreWarmed = false;
    preWarmConnection();
  }

  void _updateState(CallState newState) {
    _state = newState;
    onStateChange?.call(newState);
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
