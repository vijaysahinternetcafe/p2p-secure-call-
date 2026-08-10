import 'package:json_annotation/json_annotation.dart';

part 'signaling_message.g.dart';

@JsonSerializable()
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

  factory SignalingMessage.fromJson(Map<String, dynamic> json) =>
      _\$SignalingMessageFromJson(json);

  Map<String, dynamic> toJson() => _\$SignalingMessageToJson(this);
}
