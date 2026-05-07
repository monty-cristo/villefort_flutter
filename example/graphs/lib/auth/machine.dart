import 'package:villefort/villefort.dart';

sealed class AuthState {
  const AuthState();

  @override
  bool operator ==(Object other) => switch ((this, other)) {
    (AuthStateLoggedOut(), AuthStateLoggedOut()) => true,
    (AuthStateLoggingIn(), AuthStateLoggingIn()) => true,
    (
      AuthStateLoggedIn(userId: final a),
      AuthStateLoggedIn(userId: final b),
    ) =>
      a == b,
    (
      AuthStateLoginFailed(reason: final a),
      AuthStateLoginFailed(reason: final b),
    ) =>
      a == b,
    (
      AuthStateRefreshingToken(userId: final a),
      AuthStateRefreshingToken(userId: final b),
    ) =>
      a == b,
    (AuthStateLoggingOut(), AuthStateLoggingOut()) => true,
    _ => false,
  };

  @override
  int get hashCode => switch (this) {
    AuthStateLoggedOut() => 1,
    AuthStateLoggingIn() => 2,
    AuthStateLoggedIn(:final userId) => Object.hash(3, userId),
    AuthStateLoginFailed(:final reason) => Object.hash(4, reason),
    AuthStateRefreshingToken(:final userId) => Object.hash(5, userId),
    AuthStateLoggingOut() => 6,
  };
}

final class AuthStateLoggedOut extends AuthState {
  const AuthStateLoggedOut();
}

final class AuthStateLoggingIn extends AuthState {
  const AuthStateLoggingIn();
}

final class AuthStateLoggedIn extends AuthState {
  final String userId;
  const AuthStateLoggedIn({required this.userId});
}

final class AuthStateLoginFailed extends AuthState {
  final String reason;
  const AuthStateLoginFailed({required this.reason});
}

final class AuthStateRefreshingToken extends AuthState {
  final String userId;
  const AuthStateRefreshingToken({required this.userId});
}

final class AuthStateLoggingOut extends AuthState {
  const AuthStateLoggingOut();
}

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthEventLogin extends AuthEvent {
  const AuthEventLogin();
}

final class AuthEventLoginOk extends AuthEvent {
  final String userId;
  const AuthEventLoginOk({required this.userId});
}

final class AuthEventLoginFail extends AuthEvent {
  final String reason;
  const AuthEventLoginFail({required this.reason});
}

final class AuthEventRetry extends AuthEvent {
  const AuthEventRetry();
}

final class AuthEventRefreshToken extends AuthEvent {
  const AuthEventRefreshToken();
}

final class AuthEventRefreshOk extends AuthEvent {
  const AuthEventRefreshOk();
}

final class AuthEventRefreshFail extends AuthEvent {
  const AuthEventRefreshFail();
}

final class AuthEventLogout extends AuthEvent {
  const AuthEventLogout();
}

final class AuthEventLogoutOk extends AuthEvent {
  const AuthEventLogoutOk();
}

List<AuthEvent> generateAuth(AuthState state) => switch (state) {
  AuthStateLoggedOut() => [const AuthEventLogin()],
  AuthStateLoggingIn() => [
    AuthEventLoginOk(userId: 'user_123'),
    AuthEventLoginFail(reason: 'Invalid credentials'),
  ],
  AuthStateLoggedIn() => [
    const AuthEventRefreshToken(),
    const AuthEventLogout(),
  ],
  AuthStateLoginFailed() => [
    const AuthEventRetry(),
  ],
  AuthStateRefreshingToken() => [
    const AuthEventRefreshOk(),
    const AuthEventRefreshFail(),
  ],
  AuthStateLoggingOut() => [const AuthEventLogoutOk()],
};

Option<AuthState> authTransition(AuthState state, AuthEvent event) =>
    switch ((state, event)) {
      (AuthStateLoggedOut(), AuthEventLogin()) => const Some(
        AuthStateLoggingIn(),
      ),
      (AuthStateLoggingIn(), AuthEventLoginOk(:final userId)) => Some(
        AuthStateLoggedIn(userId: userId),
      ),
      (AuthStateLoggingIn(), AuthEventLoginFail(:final reason)) => Some(
        AuthStateLoginFailed(reason: reason),
      ),
      (AuthStateLoginFailed(), AuthEventRetry()) => const Some(
        AuthStateLoggingIn(),
      ),
      (AuthStateLoggedIn(:final userId), AuthEventRefreshToken()) => Some(
        AuthStateRefreshingToken(userId: userId),
      ),
      (AuthStateRefreshingToken(:final userId), AuthEventRefreshOk()) => Some(
        AuthStateLoggedIn(userId: userId),
      ),
      (AuthStateRefreshingToken(), AuthEventRefreshFail()) => const Some(
        AuthStateLoggedOut(),
      ),
      (AuthStateLoggedIn(), AuthEventLogout()) => const Some(
        AuthStateLoggingOut(),
      ),
      (AuthStateLoggingOut(), AuthEventLogoutOk()) => const Some(
        AuthStateLoggedOut(),
      ),
      _ => const None(),
    };
