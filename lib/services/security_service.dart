import 'package:encrypt/encrypt.dart' as encrypt;

class SecurityService {
  // ====================
  // Constants
  // ====================

  static const String _encryptionKey = 'NandaCellCikandeSuksesSelalu2026';
  static const String _initializationVector =
      'NandaCellInitVec'; // 16 characters
  static const String _emptyString = '';
  static const int _keyLength = 32; // AES-256 requires 32-byte key

  // ====================
  // Encryption Instance
  // ====================

  static final encrypt.Encrypter _encrypter = _createEncrypter();

  // ====================
  // Public Methods
  // ====================

  static String encryptData(String plainText) {
    if (plainText.isEmpty) return plainText;

    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (error) {
      return plainText;
    }
  }

  static String decryptData(String encryptedText) {
    if (encryptedText.isEmpty) return _emptyString;

    try {
      final decrypted = _encrypter.decrypt64(encryptedText, iv: _iv);
      return decrypted;
    } catch (error) {
      return _emptyString;
    }
  }

  // ====================
  // Private Helpers
  // ====================

  static encrypt.Encrypter _createEncrypter() {
    final key = _createEncryptionKey();
    return encrypt.Encrypter(encrypt.AES(key));
  }

  static encrypt.Key _createEncryptionKey() {
    final keyUtf8 = _encryptionKey.runes.toList();

    if (keyUtf8.length == _keyLength) {
      return encrypt.Key.fromUtf8(_encryptionKey);
    }

    final paddedKey = _padOrTruncateKey(keyUtf8);
    return encrypt.Key.fromUtf8(paddedKey);
  }

  static String _padOrTruncateKey(List<int> keyBytes) {
    final paddedKey = StringBuffer();

    for (int i = 0; i < _keyLength; i++) {
      if (i < keyBytes.length) {
        paddedKey.writeCharCode(keyBytes[i]);
      } else {
        paddedKey.write('0'); // Padding dengan karakter '0'
      }
    }

    return paddedKey.toString();
  }

  static encrypt.IV get _iv => encrypt.IV.fromUtf8(_initializationVector);
}
