class Message {
  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.attachmentUrl,
    this.attachmentType,
    this.isRead = false,
    this.type = 'text',
  });

  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final String? attachmentUrl;
  final String? attachmentType;
  final bool isRead;
  final String type;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'attachmentUrl': attachmentUrl,
      'attachmentType': attachmentType,
      'isRead': isRead,
      'type': type,
    };
  }

  factory Message.fromFirestore(Map<String, dynamic> data, String id) {
    return Message(
      id: id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'] as String)
          : DateTime.now(),
      attachmentUrl: data['attachmentUrl'] as String?,
      attachmentType: data['attachmentType'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      type: data['type'] as String? ?? 'text',
    );
  }
}
