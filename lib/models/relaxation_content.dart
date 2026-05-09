class RelaxationContent {
  const RelaxationContent({
    required this.id,
    required this.title,
    required this.category,
    this.description,
    this.imageUrl,
    this.audioUrl,
    this.duration,
    this.instructorName,
    this.difficulty,
    this.rating,
    this.reviewCount,
    this.createdAt,
  });

  final String id;
  final String title;
  final String category;
  final String? description;
  final String? imageUrl;
  final String? audioUrl;
  final int? duration;
  final String? instructorName;
  final String? difficulty;
  final double? rating;
  final int? reviewCount;
  final DateTime? createdAt;

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'title': title,
      'category': category,
      'description': description,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'duration': duration,
      'instructorName': instructorName,
      'difficulty': difficulty,
      'rating': rating,
      'reviewCount': reviewCount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory RelaxationContent.fromFirestore(
    Map<String, dynamic> data,
    String id,
  ) {
    return RelaxationContent(
      id: id,
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? '',
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      audioUrl: data['audioUrl'] as String?,
      duration: data['duration'] as int?,
      instructorName: data['instructorName'] as String?,
      difficulty: data['difficulty'] as String?,
      rating: (data['rating'] as num?)?.toDouble(),
      reviewCount: data['reviewCount'] as int?,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : null,
    );
  }
}
