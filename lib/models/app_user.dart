class AppUser {
  const AppUser({
    required this.uid,
    required this.displayName,
    required this.partnerName,
    required this.coupleId,
    required this.loveStartDate,
    required this.createdAt,
    required this.status,
    this.email,
    this.avatarUrl,
    this.partnerAvatarUrl,
  });

  final String uid;
  final String displayName;
  final String partnerName;
  final String coupleId;
  final DateTime loveStartDate;
  final DateTime createdAt;
  final String status;
  final String? email;
  final String? avatarUrl;
  final String? partnerAvatarUrl;

  bool get isBlocked => status == 'blocked';

  int get daysInLove {
    final now = DateTime.now();
    final start = DateTime(
      loveStartDate.year,
      loveStartDate.month,
      loveStartDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return today.difference(start).inDays + 1;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final couple = json['couple'] as Map<String, dynamic>?;
    return AppUser(
      uid: json['id'] as String? ?? '',
      displayName: json['displayName'] as String? ?? 'Ban',
      partnerName: json['partnerName'] as String? ?? 'Nguoi ay',
      email: json['email'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      partnerAvatarUrl: json['partnerAvatarUrl'] as String?,
      coupleId: couple?['code'] as String? ?? '',
      loveStartDate: _dateFrom(couple?['loveStartDate']) ?? DateTime.now(),
      createdAt: _dateFrom(json['createdAt']) ?? DateTime.now(),
      status: json['status'] as String? ?? 'active',
    );
  }

  AppUser copyWith({
    String? displayName,
    String? partnerName,
    DateTime? loveStartDate,
    String? status,
    String? avatarUrl,
    String? partnerAvatarUrl,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      partnerName: partnerName ?? this.partnerName,
      coupleId: coupleId,
      loveStartDate: loveStartDate ?? this.loveStartDate,
      createdAt: createdAt,
      status: status ?? this.status,
      email: email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      partnerAvatarUrl: partnerAvatarUrl ?? this.partnerAvatarUrl,
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
