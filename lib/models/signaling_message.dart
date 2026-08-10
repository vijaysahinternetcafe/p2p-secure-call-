class SignalingMessage {
  final String type;
  final String? callId;
  final String? from;
  final String? to;
  final String? sdp;
  final String? candidate;
  final String? sdpMid;
  final int? sdpMLineIndex;
  final int? timestamp;

  SignalingMessage({
    required this.type,
    this.callId,
    this.from,
    this.to,
    this.sdp,
    this.candidate,
    this.sdpMid,
    this.sdpMLineIndex,
    this.timestamp,
  });

  factory SignalingMessage.fromJson(Map<String, dynamic> json) {
    return SignalingMessage(
      type: json['type'] ?? '',
      callId: json['callId'],
      from: json['from'],
      to: json['to'],
      sdp: json['sdp'],
      candidate: json['candidate'],
      sdpMid: json['sdpMid'],
      sdpMLineIndex: json['sdpMLineIndex'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (callId != null) 'callId': callId,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
      if (sdp != null) 'sdp': sdp,
      if (candidate != null) 'candidate': candidate,
      if (sdpMid != null) 'sdpMid': sdpMid,
      if (sdpMLineIndex != null) 'sdpMLineIndex': sdpMLineIndex,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }
}
