import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient get _supabase => AppConfig.supabase!;
  
  User? get currentUser => _supabase.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      final result = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.newsify://login-callback/',
      );

      if (result) {
        debugPrint('✅ Google sign in initiated');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Google sign in error: $e');
      rethrow;
    }
  }
  

  // Sign in with Email (Magic Link)
  Future<void> signInWithEmail(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.vikram.newsify://login-callback/',
      );
      debugPrint('✅ Magic link sent to: $email');
    } catch (e) {
      debugPrint('❌ Email sign in error: $e');
      rethrow;
    }
  }

  // Sign up with Email & Password
Future<void> signUpWithEmail(String email, String password, String fullName) async {
  try {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
      emailRedirectTo: 'io.vikram.newsify://login-callback/',
    );

    if (response.user == null) {
      throw Exception("Sign up failed. Please try again.");
    }
    
    // Try to create profile (may fail due to RLS until email confirmed)
    await _createUserProfile(response.user!);
    
    debugPrint('✅ Sign up successful, verification email sent');
  } on AuthException catch (e) {
    debugPrint('❌ Email sign up error: $e');
    
    if (e.message.contains('already registered')) {
      throw Exception('This email is already registered');
    } else if (e.message.contains('invalid email')) {
      throw Exception('Please enter a valid email address');
    } else {
      throw Exception('Sign up failed. Please try again');
    }
  } catch (e) {
    debugPrint('❌ Email sign up error: $e');
    rethrow;
  }
}

// Sign in with Email & Password
Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
  try {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    // Check if email is confirmed
    if (response.user?.emailConfirmedAt == null) {
      await _supabase.auth.signOut();
      throw Exception('Please verify your email before signing in');
    }
    
    debugPrint('✅ Email sign in successful: ${response.user?.email}');
    return response;
  } on AuthException catch (e) {
    debugPrint('❌ Email sign in error: $e');
    
    // Convert technical errors to user-friendly messages
    if (e.message.contains('Invalid login credentials')) {
      throw Exception('Invalid email or password');
    } else if (e.message.contains('Email not confirmed')) {
      throw Exception('Please verify your email before signing in');
    } else if (e.message.contains('User not found')) {
      throw Exception('No account found with this email');
    } else {
      throw Exception('Sign in failed. Please try again');
    }
  } catch (e) {
    debugPrint('❌ Email sign in error: $e');
    rethrow;
  }
}

// Create user profile in database
Future<void> _createUserProfile(User user) async {
  try {
    final existingProfile = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existingProfile == null) {
      await _supabase.from('user_profiles').insert({
        'id': user.id,
        'email': user.email,
        'phone': user.phone,
        'full_name': user.userMetadata?['full_name'],
        'avatar_url': user.userMetadata?['avatar_url'],
      });
      debugPrint('✅ User profile created');
    }
  } on PostgrestException catch (e) {
    // Ignore RLS errors silently - profile will be created on next sign in
    if (e.code == '42501') {
      debugPrint('⚠️ Profile creation deferred (user not confirmed yet)');
    } else {
      debugPrint('❌ Error creating user profile: ${e.message}');
    }
  } catch (e) {
    debugPrint('❌ Error creating user profile: $e');
  }
}

// Verify Phone OTP
Future<AuthResponse> verifyPhoneOTP(String phone, String otp) async {
  try {
    final response = await _supabase.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
    debugPrint('✅ Phone verification successful');
    if (response.user != null) {
      await _createUserProfile(response.user!);
    }
    return response;
  } on AuthException catch (e) {
    debugPrint('❌ Phone verification error: $e');
    
    if (e.message.contains('Invalid') || e.message.contains('expired')) {
      throw Exception('Invalid or expired OTP. Please try again');
    } else {
      throw Exception('Verification failed. Please try again');
    }
  } catch (e) {
    debugPrint('❌ Phone verification error: $e');
    rethrow;
  }
}

  // Sign in with Phone
  Future<void> signInWithPhone(String phone) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
      );
      debugPrint('✅ OTP sent to: $phone');
    } catch (e) {
      debugPrint('❌ Phone sign in error: $e');
      rethrow;
    }
  }

  // Verify Email OTP
  Future<AuthResponse> verifyEmailOTP(String email, String otp) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: otp,
        type: OtpType.email,
      );
      debugPrint('✅ Email verification successful');
      if (response.user != null) {
        await _createUserProfile(response.user!);
      }
      return response;
    } catch (e) {
      debugPrint('❌ Email verification error: $e');
      rethrow;
    }
  }
  
  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
  try {
    if (!isSignedIn) return null;
    
    final response = await _supabase
        .from('user_profiles')
        .select()
        .eq('id', currentUser!.id)
        .maybeSingle();
    
    return response;
  } catch (e) {
    debugPrint('❌ Error fetching user profile: $e');
    return null;
  }
}

  // Update user profile
  Future<void> updateUserProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      if (!isSignedIn) throw Exception('Not signed in');

      await _supabase.from('user_profiles').update({
        'full_name': fullName?.toString(),
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser!.id);

      await _supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': fullName,
            'avatar_url': avatarUrl,
          },
        ));

      debugPrint('✅ User profile updated');
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
      rethrow;
    }
  }

  // Get user's bookmarks
  Future<List<Map<String, dynamic>>> getBookmarks() async {
    try {
      if (!isSignedIn) return [];

      final response = await _supabase
          .from('user_bookmarks')
          .select()
          .eq('user_id', currentUser!.id)
          .order('bookmarked_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error fetching bookmarks: $e');
      return [];
    }
  }

  // Add bookmark
  Future<void> addBookmark(String newsUrl, String title, String imageUrl) async {
    try {
      if (!isSignedIn) throw Exception('Not signed in');

      await _supabase.from('user_bookmarks').insert({
        'user_id': currentUser!.id,
        'news_url': newsUrl,
        'title': title,
        'image_url': imageUrl,
      });

      debugPrint('✅ Bookmark added');
    } catch (e) {
      debugPrint('❌ Error adding bookmark: $e');
      rethrow;
    }
  }

  // Remove bookmark
  Future<void> removeBookmark(String newsUrl) async {
    try {
      if (!isSignedIn) throw Exception('Not signed in');

      await _supabase
          .from('user_bookmarks')
          .delete()
          .eq('user_id', currentUser!.id)
          .eq('news_url', newsUrl);

      debugPrint('✅ Bookmark removed');
    } catch (e) {
      debugPrint('❌ Error removing bookmark: $e');
      rethrow;
    }
  }

  // Check if article is bookmarked
  Future<bool> isBookmarked(String newsUrl) async {
    try {
      if (!isSignedIn) return false;

      final response = await _supabase
          .from('user_bookmarks')
          .select()
          .eq('user_id', currentUser!.id)
          .eq('news_url', newsUrl)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ Error checking bookmark: $e');
      return false;
    }
  }
}