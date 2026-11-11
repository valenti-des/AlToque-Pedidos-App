import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const _passwordIterations = 120000;

String hashPassword(String password) {
  final random = Random.secure();
  final salt = List<int>.generate(16, (_) => random.nextInt(256));
  final hash = _deriveKey(utf8.encode(password), salt, _passwordIterations);
  return 'pbkdf2-sha256\$$_passwordIterations\$'
      '${base64Url.encode(salt)}\$${base64Url.encode(hash)}';
}

bool verifyPassword(String password, String encoded) {
  final parts = encoded.split(r'$');
  if (parts.length != 4 || parts.first != 'pbkdf2-sha256') return false;

  final iterations = int.tryParse(parts[1]);
  if (iterations == null || iterations < 10000 || iterations > 1000000) {
    return false;
  }

  try {
    final salt = base64Url.decode(base64Url.normalize(parts[2]));
    final expected = base64Url.decode(base64Url.normalize(parts[3]));
    final actual = _deriveKey(utf8.encode(password), salt, iterations);
    return _constantTimeEquals(actual, expected);
  } on FormatException {
    return false;
  }
}

String createSessionToken(int userId, String secret) {
  final random = Random.secure();
  final payload = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'userId': userId,
            'expiresAt': DateTime.now()
                .toUtc()
                .add(const Duration(hours: 12))
                .millisecondsSinceEpoch,
            'nonce': base64Url.encode(
              List<int>.generate(16, (_) => random.nextInt(256)),
            ),
          }),
        ),
      )
      .replaceAll('=', '');
  final signature = Hmac(
    sha256,
    utf8.encode(secret),
  ).convert(utf8.encode(payload)).bytes;
  return '$payload.${base64Url.encode(signature).replaceAll('=', '')}';
}

int? readSessionUserId(String token, String secret) {
  final parts = token.split('.');
  if (parts.length != 2) return null;

  try {
    final expected = Hmac(
      sha256,
      utf8.encode(secret),
    ).convert(utf8.encode(parts[0])).bytes;
    final actual = base64Url.decode(base64Url.normalize(parts[1]));
    if (!_constantTimeEquals(actual, expected)) return null;

    final payload = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
    );
    if (payload is! Map<String, dynamic>) return null;
    final userId = payload['userId'];
    final expiresAt = payload['expiresAt'];
    if (userId is! int || expiresAt is! int) return null;
    if (expiresAt <= DateTime.now().toUtc().millisecondsSinceEpoch) {
      return null;
    }
    return userId;
  } on FormatException {
    return null;
  }
}

String createTrackingToken() {
  final random = Random.secure();
  return base64Url
      .encode(List<int>.generate(32, (_) => random.nextInt(256)))
      .replaceAll('=', '');
}

String hashTrackingToken(String token) =>
    sha256.convert(utf8.encode(token)).toString();

List<int> _deriveKey(List<int> password, List<int> salt, int iterations) {
  final hmac = Hmac(sha256, password);
  var current = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
  final result = List<int>.from(current);
  for (var iteration = 1; iteration < iterations; iteration++) {
    current = hmac.convert(current).bytes;
    for (var index = 0; index < result.length; index++) {
      result[index] ^= current[index];
    }
  }
  return result;
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var index = 0; index < left.length; index++) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}
