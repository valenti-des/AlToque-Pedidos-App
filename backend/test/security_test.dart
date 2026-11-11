import 'package:al_toque_local_api/security.dart';
import 'package:test/test.dart';

void main() {
  test('password hashes verify the password but reject a different one', () {
    final hash = hashPassword('correct horse battery staple');

    expect(verifyPassword('correct horse battery staple', hash), isTrue);
    expect(verifyPassword('different password', hash), isFalse);
    expect(verifyPassword('anything', 'not-a-valid-hash'), isFalse);
  });

  test('session tokens are signed and resolve only before tampering', () {
    final token = createSessionToken(42, 'a sufficiently long test secret');

    expect(readSessionUserId(token, 'a sufficiently long test secret'), 42);
    expect(
      readSessionUserId(token, 'another sufficiently long secret'),
      isNull,
    );
    expect(
      readSessionUserId('$token-x', 'a sufficiently long test secret'),
      isNull,
    );
  });
}
