import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../services/encryption_service.dart';

class AuthProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    // Her zaman demo kullanıcıyı oluştur veya yükle
    await _createDemoUserIfNeeded();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _createDemoUserIfNeeded() async {
    const demoUsername = 'fapaydn41';
    const demoEmail = 'fapaydn41@yandex.com';
    const demoPassword = '123456';

    // Önce mevcut kullanıcıyı kontrol et
    _currentUser = await _storageService.getUser();
    
    // Eğer kullanıcı yoksa veya demo kullanıcı değilse, demo kullanıcıyı oluştur
    if (_currentUser == null || _currentUser!.username != demoUsername) {
      final hashedPassword = EncryptionService.hashPassword(demoPassword);
      final demoUser = User(
        id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
        username: demoUsername,
        email: demoEmail,
        createdAt: DateTime.now(),
      );

      await _storageService.saveUser(demoUser);
      await _storageService.savePassword(demoUsername, hashedPassword);
      _currentUser = demoUser;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Kullanıcı adı kontrolü
      final existingPassword = await _storageService.getPassword(username);
      if (existingPassword != null) {
        _isLoading = false;
        notifyListeners();
        return false; // Kullanıcı zaten var
      }

      // Yeni kullanıcı oluştur
      final hashedPassword = EncryptionService.hashPassword(password);
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        email: email,
        createdAt: DateTime.now(),
      );

      await _storageService.saveUser(user);
      await _storageService.savePassword(username, hashedPassword);
      
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Email ile giriş yapılıyorsa, username'e çevir
      String username = usernameOrEmail;
      if (usernameOrEmail.contains('@')) {
        // Email'den username çıkar (@ öncesi)
        username = usernameOrEmail.split('@')[0];
      }

      final hashedPassword = EncryptionService.hashPassword(password);
      final storedPassword = await _storageService.getPassword(username);

      if (storedPassword == null || storedPassword != hashedPassword) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Kullanıcı bilgilerini al (eğer kayıtlıysa)
      _currentUser = await _storageService.getUser();
      
      // Eğer kullanıcı bilgisi yoksa, yeni oluştur
      if (_currentUser == null) {
        final email = usernameOrEmail.contains('@') 
            ? usernameOrEmail 
            : '$usernameOrEmail@example.com';
        _currentUser = User(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          username: username,
          email: email,
          createdAt: DateTime.now(),
        );
        await _storageService.saveUser(_currentUser!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.logout();
    _currentUser = null;
    notifyListeners();
  }
}

