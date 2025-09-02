// filepath: /Users/sarawutpromdee/Documents/Sellstoory/mobile-sellstory/lib/models/canned_responses.dart

class CannedResponseGroup {
  final String id;
  String name;
  final List<CannedResponse> responses;

  CannedResponseGroup({required this.id, required this.name, required this.responses});

  factory CannedResponseGroup.fromJson(Map<String, dynamic> json) {
    return CannedResponseGroup(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      responses: (json['responses'] as List<dynamic>? ?? [])
          .map((e) => CannedResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CannedResponse {
  final String id;
  String title;
  String type; // 'text' | 'image' | 'file' | others
  String? text;
  String? imageUrl;
  String? fileUrl;
  String? fileName;

  CannedResponse({
    required this.id,
    required this.title,
    required this.type,
    this.text,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
  });

  factory CannedResponse.fromJson(Map<String, dynamic> json) {
    return CannedResponse(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      type: json['type'] as String? ?? 'text',
      text: json['text'] as String?,
      imageUrl: json['imageUrl'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
    };
  }
}
