import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable session model
@immutable
class Session {
  final int? userId;          // set for customer/user accounts
  final int? adminId;         // set for admin accounts
  final String username;
  final String role;          // e.g. "user" or "admin"
  final String? accountType;  // optional (e.g. "basic", "pro")
  final String? email;
  final String? avatarUrl;
  final String? token;        // optional (JWT or session token if you add it later)
  final DateTime createdAt;
  final DateTime? expiresAt;  // optional TTL

  const Session({
    this.userId,
    this.adminId,
    required this.username,
    required this.role,
    this.accountType,
    this.email,
    this.avatarUrl,
    this.token,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isLoggedIn => (userId != null || adminId != null) && !isExpired;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}

/// Handles persisting and exposing the current login session.
class SessionManager {
  SessionManager._();
  static final SessionManager instance = SessionManager._();

  // Listen to changes with ValueListenableBuilder
  final ValueNotifier<Session?> session = ValueNotifier<Session?>(null);

  // Storage keys
  static const _kPrefix     = 'sess_';
  static const _kUserId     = '${_kPrefix}user_id';
  static const _kAdminId    = '${_kPrefix}admin_id';
  static const _kUsername   = '${_kPrefix}username';
  static const _kRole       = '${_kPrefix}role';
  static const _kAccType    = '${_kPrefix}account_type';
  static const _kEmail      = '${_kPrefix}email';
  static const _kAvatar     = '${_kPrefix}avatar';
  static const _kToken      = '${_kPrefix}token';
  static const _kCreatedAt  = '${_kPrefix}created_at_ms';
  static const _kExpiresAt  = '${_kPrefix}expires_at_ms';

  /// Call at app start (e.g., in main()) to load any existing session.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString(_kRole);
    final username = prefs.getString(_kUsername);

    // No saved session
    if (role == null || username == null) {
      session.value = null;
      return;
    }

    final createdMs = prefs.getInt(_kCreatedAt) ?? DateTime.now().millisecondsSinceEpoch;
    final expiresMs = prefs.getInt(_kExpiresAt);

    final s = Session(
      userId: prefs.getInt(_kUserId),
      adminId: prefs.getInt(_kAdminId),
      username: username,
      role: role,
      accountType: prefs.getString(_kAccType),
      email: prefs.getString(_kEmail),
      avatarUrl: prefs.getString(_kAvatar),
      token: prefs.getString(_kToken),
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdMs),
      expiresAt: (expiresMs != null) ? DateTime.fromMillisecondsSinceEpoch(expiresMs) : null,
    );

    // Auto-clear expired sessions
    if (s.isExpired) {
      await clear();
      return;
    }

    session.value = s;
  }

  /// Save a fresh session (call after a successful login).
  ///
  /// [ttl] optional: how long before it expires (e.g. Duration(days: 7)).
  Future<void> save({
    int? userId,
    int? adminId,
    required String username,
    required String role,
    String? accountType,
    String? email,
    String? avatarUrl,
    String? token,
    Duration? ttl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final expiresAt = ttl == null ? null : now.add(ttl);

    await prefs.setString(_kUsername, username);
    await prefs.setString(_kRole, role);
    if (accountType != null) await prefs.setString(_kAccType, accountType);
    if (email != null) await prefs.setString(_kEmail, email);
    if (avatarUrl != null) await prefs.setString(_kAvatar, avatarUrl);
    if (token != null) await prefs.setString(_kToken, token);
    if (userId != null) await prefs.setInt(_kUserId, userId);
    if (adminId != null) await prefs.setInt(_kAdminId, adminId);
    await prefs.setInt(_kCreatedAt, now.millisecondsSinceEpoch);
    if (expiresAt != null) await prefs.setInt(_kExpiresAt, expiresAt.millisecondsSinceEpoch);

    session.value = Session(
      userId: userId,
      adminId: adminId,
      username: username,
      role: role,
      accountType: accountType,
      email: email,
      avatarUrl: avatarUrl,
      token: token,
      createdAt: now,
      expiresAt: expiresAt,
    );
  }

  /// Clear the current session (logout).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kAdminId);
    await prefs.remove(_kUsername);
    await prefs.remove(_kRole);
    await prefs.remove(_kAccType);
    await prefs.remove(_kEmail);
    await prefs.remove(_kAvatar);
    await prefs.remove(_kToken);
    await prefs.remove(_kCreatedAt);
    await prefs.remove(_kExpiresAt);
    session.value = null;
  }

  // Convenience getters
  bool get isLoggedIn => session.value?.isLoggedIn == true;
  bool get isAdmin    => session.value?.isAdmin == true;
  int? get userId     => session.value?.userId;
  int? get adminId    => session.value?.adminId;
  String? get role    => session.value?.role;
  String? get username=> session.value?.username;
}
