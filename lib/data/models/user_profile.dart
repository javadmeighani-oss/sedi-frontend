/// ============================================
/// UserProfile - User Information Model
/// ============================================
/// 
/// RESPONSIBILITY:
/// - Store user profile information
/// - Security credentials
/// - User preferences
/// ============================================

class UserProfile {
  // Basic Information
  final String? name; // User's name (for familiarity, optional)
  final String? securityPassword; // Security password (for suspicious behavior verification)
  final int? userId; // Backend user ID (for anonymous users and registration)
  
  // Preferences
  final String preferredLanguage; // 'en', 'fa', 'ar'
  
  // Security & Trust
  final bool hasSecurityPassword; // Whether user has set security password
  final DateTime? securityPasswordSetAt; // When password was set
  final int conversationCount; // Number of conversations (for familiarity tracking)
  
  // Status
  final bool isVerified; // Whether user is verified
  final bool requiresSecurityCheck; // Whether security check is needed (suspicious behavior)

  UserProfile({
    this.name,
    this.securityPassword,
    this.userId,
    this.preferredLanguage = 'en',
    this.hasSecurityPassword = false,
    this.securityPasswordSetAt,
    this.conversationCount = 0,
    this.isVerified = false,
    this.requiresSecurityCheck = false,
  });

  /// Create from JSON (for persistence)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String?,
      securityPassword: json['security_password'] as String?,
      userId: json['user_id'] as int?,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      hasSecurityPassword: json['has_security_password'] as bool? ?? false,
      securityPasswordSetAt: json['security_password_set_at'] != null
          ? DateTime.parse(json['security_password_set_at'] as String)
          : null,
      conversationCount: json['conversation_count'] as int? ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      requiresSecurityCheck: json['requires_security_check'] as bool? ?? false,
    );
  }

  /// Convert to JSON (for persistence)
  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (securityPassword != null) 'security_password': securityPassword,
      if (userId != null) 'user_id': userId,
      'preferred_language': preferredLanguage,
      'has_security_password': hasSecurityPassword,
      if (securityPasswordSetAt != null)
        'security_password_set_at': securityPasswordSetAt!.toIso8601String(),
      'conversation_count': conversationCount,
      'is_verified': isVerified,
      'requires_security_check': requiresSecurityCheck,
    };
  }

  /// Copy with method for updates
  UserProfile copyWith({
    String? name,
    String? securityPassword,
    int? userId,
    String? preferredLanguage,
    bool? hasSecurityPassword,
    DateTime? securityPasswordSetAt,
    int? conversationCount,
    bool? isVerified,
    bool? requiresSecurityCheck,
  }) {
    return UserProfile(
      name: name ?? this.name,
      securityPassword: securityPassword ?? this.securityPassword,
      userId: userId ?? this.userId,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      hasSecurityPassword: hasSecurityPassword ?? this.hasSecurityPassword,
      securityPasswordSetAt: securityPasswordSetAt ?? this.securityPasswordSetAt,
      conversationCount: conversationCount ?? this.conversationCount,
      isVerified: isVerified ?? this.isVerified,
      requiresSecurityCheck: requiresSecurityCheck ?? this.requiresSecurityCheck,
    );
  }

  /// Check if user is familiar enough (has had enough conversations)
  bool get isFamiliar => conversationCount >= 3;

  /// Check if security password is required
  bool get needsSecurityPassword => !hasSecurityPassword && isFamiliar;
}

