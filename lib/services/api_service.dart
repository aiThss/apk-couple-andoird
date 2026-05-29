import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/couple_photo.dart';
import '../models/random_event.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  bool get requiresEmailCode => code == 'EMAIL_CODE_REQUIRED';

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AppUser user;
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.couple.babyress.games/api',
  );

  static const _tokenKey = 'couple_snap_token';
  static const _baseUrlKey = 'couple_snap_api_base_url';
  static const _deviceIdKey = 'couple_snap_device_id';

  final http.Client _client;

  String _baseUrl = _defaultBaseUrl;
  String? _token;
  String? _deviceId;

  String get baseUrl => _baseUrl;
  bool get hasToken => _token != null && _token!.isNotEmpty;
  String get deviceId => _deviceId ?? '';

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBaseUrl = prefs.getString(_baseUrlKey);
    _baseUrl = _normalizeBaseUrl(
      _shouldMigrateBaseUrl(savedBaseUrl)
          ? _defaultBaseUrl
          : savedBaseUrl ?? _defaultBaseUrl,
    );
    await prefs.setString(_baseUrlKey, _baseUrl);
    _token = prefs.getString(_tokenKey);

    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null || _deviceId!.isEmpty) {
      _deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
  }

  Future<void> setBaseUrl(String value) async {
    _baseUrl = _normalizeBaseUrl(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _baseUrl);
  }

  Future<AuthSession> start({
    required String displayName,
    required String partnerName,
    required String coupleCode,
    required DateTime loveStartDate,
    String? email,
    String? password,
    String? emailCode,
  }) async {
    final payload = await _jsonRequest(
      'POST',
      '/auth/start',
      body: {
        'displayName': displayName,
        'partnerName': partnerName,
        'coupleCode': coupleCode,
        'loveStartDate': loveStartDate.toIso8601String(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (password != null && password.isNotEmpty) 'password': password,
        if (email != null && email.trim().isNotEmpty) 'deviceId': deviceId,
        if (emailCode != null && emailCode.trim().isNotEmpty)
          'emailCode': emailCode.trim(),
      },
      authenticated: false,
    );

    return _saveSession(payload);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    String? emailCode,
  }) async {
    final payload = await _jsonRequest(
      'POST',
      '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
        'deviceId': deviceId,
        if (emailCode != null && emailCode.trim().isNotEmpty)
          'emailCode': emailCode.trim(),
      },
      authenticated: false,
    );

    return _saveSession(payload);
  }

  Future<void> requestAuthCode({required String email}) async {
    await _jsonRequest(
      'POST',
      '/auth/request-code',
      body: {'email': email.trim(), 'deviceId': deviceId},
      authenticated: false,
    );
  }

  Future<AppUser?> restoreSession() async {
    await loadSettings();
    if (!hasToken) {
      return null;
    }

    try {
      return await currentUser();
    } on ApiException {
      await signOut();
      return null;
    }
  }

  Future<AppUser> currentUser() async {
    final payload = await _jsonRequest('GET', '/me');
    return AppUser.fromJson(payload['user'] as Map<String, dynamic>);
  }

  Future<AppUser> updateProfile({
    required String displayName,
    required String partnerName,
    required DateTime loveStartDate,
  }) async {
    final payload = await _jsonRequest(
      'PATCH',
      '/me',
      body: {
        'displayName': displayName,
        'partnerName': partnerName,
        'loveStartDate': loveStartDate.toIso8601String(),
      },
    );
    return AppUser.fromJson(payload['user'] as Map<String, dynamic>);
  }

  Future<AppUser> uploadAvatar({
    required File file,
    required bool partner,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri(partner ? '/me/partner-avatar' : '/me/avatar'),
    );
    request.headers.addAll(_headers(authenticated: true, json: false));
    request.files.add(
      await http.MultipartFile.fromPath(
        'avatar',
        file.path,
        contentType: _contentTypeFor(file.path),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final payload = _decodeResponse(response);
    return AppUser.fromJson(payload['user'] as Map<String, dynamic>);
  }

  Future<CouplePhoto?> latestPhoto() async {
    final payload = await _jsonRequest('GET', '/photos/latest');
    final photo = payload['photo'];
    if (photo == null) {
      return null;
    }
    return CouplePhoto.fromJson(photo as Map<String, dynamic>);
  }

  Future<CouplePhoto?> latestPartnerPhoto() => latestPhoto();

  Future<List<CouplePhoto>> memories() async {
    final payload = await _jsonRequest('GET', '/photos');
    final photos = payload['photos'] as List<dynamic>? ?? const [];
    return photos
        .map((photo) => CouplePhoto.fromJson(photo as Map<String, dynamic>))
        .toList();
  }

  Future<List<RandomCategory>> randomCategories() async {
    final payload = await _jsonRequest('GET', '/random/categories');
    final categories = payload['categories'] as List<dynamic>? ?? const [];
    return categories
        .map(
          (category) =>
              RandomCategory.fromJson(category as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<RandomEvent>> randomHistory() async {
    final payload = await _jsonRequest('GET', '/random/history');
    final events = payload['events'] as List<dynamic>? ?? const [];
    return events
        .map((event) => RandomEvent.fromJson(event as Map<String, dynamic>))
        .toList();
  }

  Future<RandomEvent> drawRandom({required String category}) async {
    final payload = await _jsonRequest(
      'POST',
      '/random/draw',
      body: {'category': category},
    );
    return RandomEvent.fromJson(payload['event'] as Map<String, dynamic>);
  }

  Future<CouplePhoto> uploadPhoto({
    required File file,
    required String caption,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/photos'));
    request.headers.addAll(_headers(authenticated: true, json: false));
    request.fields['caption'] = caption;
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        file.path,
        contentType: _contentTypeFor(file.path),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final payload = _decodeResponse(response);
    return CouplePhoto.fromJson(payload['photo'] as Map<String, dynamic>);
  }

  Future<void> signOut() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<AuthSession> _saveSession(Map<String, dynamic> payload) async {
    final token = payload['token'] as String? ?? '';
    if (token.isEmpty) {
      throw const ApiException('API did not return a token');
    }

    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    return AuthSession(
      token: token,
      user: AppUser.fromJson(payload['user'] as Map<String, dynamic>),
    );
  }

  Future<Map<String, dynamic>> _jsonRequest(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final request = http.Request(method, _uri(path));
    request.headers.addAll(_headers(authenticated: authenticated));
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    return _decodeResponse(response);
  }

  Map<String, String> _headers({bool authenticated = true, bool json = true}) {
    return {
      if (json) 'Content-Type': 'application/json',
      if (authenticated && _token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final dynamic decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);

    final payload = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        payload['error'] as String? ?? 'Request failed',
        code: payload['code'] as String?,
        statusCode: response.statusCode,
      );
    }

    return payload;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  MediaType _contentTypeFor(String filePath) {
    final lower = filePath.toLowerCase();
    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }
    return MediaType('image', 'jpeg');
  }

  String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return _defaultBaseUrl;
    }
    return trimmed.replaceAll(RegExp(r'/+$'), '');
  }

  bool _shouldMigrateBaseUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return true;
    }
    final lower = value.toLowerCase();
    return lower.contains('10.0.2.2') ||
        lower.contains('localhost') ||
        lower.contains('127.0.0.1');
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
