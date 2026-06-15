class MessageModel {
  final int id;
  final int senderId;
  final int receiverId;
  final String? content;
  final String msgType; // text, image, voice, video
  final String? fileUrl;
  final DateTime createdAt;
  final String? senderName;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.content,
    required this.msgType,
    this.fileUrl,
    required this.createdAt,
    this.senderName,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      content: json['content'],
      msgType: json['msg_type'] ?? 'text',
      fileUrl: json['file_url'],
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender_name'],
    );
  }

  bool get isImage => msgType == 'image';
  bool get isVoice => msgType == 'voice';
  bool get isVideo => msgType == 'video';
  bool get isText => msgType == 'text';
}
