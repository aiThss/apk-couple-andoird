class CouplePhoto {
  const CouplePhoto({
    required this.id,
    required this.coupleId,
    required this.ownerId,
    required this.ownerName,
    required this.imageUrl,
    required this.storagePath,
    required this.caption,
    required this.createdAt,
  });

  final String id;
  final String coupleId;
  final String ownerId;
  final String ownerName;
  final String imageUrl;
  final String storagePath;
  final String caption;
  final DateTime createdAt;

  bool get hasImage => imageUrl.trim().isNotEmpty;

  factory CouplePhoto.fromJson(Map<String, dynamic> json) {
    return CouplePhoto(
      id: json['id'] as String? ?? '',
      coupleId: json['coupleId'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? 'Người ấy',
      imageUrl: json['imageUrl'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      caption: json['caption'] as String? ?? 'Một khoảnh khắc mới',
      createdAt: _dateFrom(json['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _dateFrom(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}
