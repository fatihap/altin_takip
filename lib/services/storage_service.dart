import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/gold_purchase.dart';
import 'encryption_service.dart';

class StorageService {
  static const String _userKey = 'encrypted_user';
  static const String _purchasesKey = 'encrypted_purchases';
  static const String _isLoggedInKey = 'is_logged_in';

  // Kullanıcı işlemleri
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(user.toJson());
    final encrypted = EncryptionService.encryptData(userJson);
    await prefs.setString(_userKey, encrypted);
    await prefs.setBool(_isLoggedInKey, true);
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(_userKey);
    if (encrypted == null) return null;

    try {
      final decrypted = EncryptionService.decryptData(encrypted);
      final userJson = json.decode(decrypted);
      return User.fromJson(userJson);
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Şifre saklama (hash'lenmiş)
  Future<void> savePassword(String username, String hashedPassword) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password_$username', hashedPassword);
  }

  Future<String?> getPassword(String username) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('password_$username');
  }

  // Altın alış kayıtları
  Future<void> savePurchase(GoldPurchase purchase) async {
    final prefs = await SharedPreferences.getInstance();
    final purchases = await getPurchases();
    purchases.add(purchase);
    
    final purchasesJson = purchases.map((p) => p.toJson()).toList();
    final jsonString = json.encode(purchasesJson);
    final encrypted = EncryptionService.encryptData(jsonString);
    
    await prefs.setString(_purchasesKey, encrypted);
  }

  Future<List<GoldPurchase>> getPurchases() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(_purchasesKey);
    
    if (encrypted == null) return [];

    try {
      final decrypted = EncryptionService.decryptData(encrypted);
      final List<dynamic> purchasesJson = json.decode(decrypted);
      return purchasesJson.map((json) => GoldPurchase.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> deletePurchase(String id) async {
    final purchases = await getPurchases();
    purchases.removeWhere((p) => p.id == id);
    
    final prefs = await SharedPreferences.getInstance();
    if (purchases.isEmpty) {
      await prefs.remove(_purchasesKey);
    } else {
      final purchasesJson = purchases.map((p) => p.toJson()).toList();
      final jsonString = json.encode(purchasesJson);
      final encrypted = EncryptionService.encryptData(jsonString);
      await prefs.setString(_purchasesKey, encrypted);
    }
  }

  // Alış kaydını güncelle
  Future<void> updatePurchase(GoldPurchase updatedPurchase) async {
    final purchases = await getPurchases();
    final index = purchases.indexWhere((p) => p.id == updatedPurchase.id);
    
    if (index != -1) {
      purchases[index] = updatedPurchase;
      
      final prefs = await SharedPreferences.getInstance();
      final purchasesJson = purchases.map((p) => p.toJson()).toList();
      final jsonString = json.encode(purchasesJson);
      final encrypted = EncryptionService.encryptData(jsonString);
      await prefs.setString(_purchasesKey, encrypted);
    }
  }

  // Varlık görüntüleme şifresi
  static const String _assetPasswordKey = 'asset_view_password';
  static const String _assetPasswordEnabledKey = 'asset_password_enabled';

  Future<void> setAssetPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final hashed = EncryptionService.encryptData(password);
    await prefs.setString(_assetPasswordKey, hashed);
    await prefs.setBool(_assetPasswordEnabledKey, true);
  }

  Future<bool> checkAssetPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_assetPasswordKey);
    if (stored == null) return false;
    
    try {
      final decrypted = EncryptionService.decryptData(stored);
      return decrypted == password;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAssetPasswordEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_assetPasswordEnabledKey) ?? false;
  }

  Future<void> disableAssetPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_assetPasswordKey);
    await prefs.setBool(_assetPasswordEnabledKey, false);
  }
}

