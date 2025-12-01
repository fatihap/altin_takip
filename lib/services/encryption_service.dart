import 'dart:convert';
import 'package:crypto/crypto.dart';

class EncryptionService {
  // Basit bir şifreleme anahtarı (production'da daha güvenli bir yöntem kullanılmalı)
  static const String _key = 'altin_takip_secret_key_2024';

  static String encrypt(String plainText) {
    final key = utf8.encode(_key);
    final bytes = utf8.encode(plainText);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static String encryptData(String data) {
    // Veriyi base64 ile encode et (basit şifreleme)
    // Production'da daha güvenli bir yöntem kullanılmalı (AES gibi)
    final bytes = utf8.encode(data);
    return base64.encode(bytes);
  }

  static String decryptData(String encryptedData) {
    try {
      final bytes = base64.decode(encryptedData);
      return utf8.decode(bytes);
    } catch (e) {
      return '';
    }
  }
}

