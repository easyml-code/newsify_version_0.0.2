import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/auth/auth_screen.dart';

class AccountTab extends StatefulWidget {
  const AccountTab({super.key});

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userProfile;
  List<Map<String, dynamic>> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((event) {
      if (mounted) {
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    if (_authService.isSignedIn) {
      final profile = await _authService.getUserProfile();
      final bookmarks = await _authService.getBookmarks();
      
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _bookmarks = bookmarks;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _userProfile = null;
          _bookmarks = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Sign Out',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2196F3),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_authService.isSignedIn) ...[
            TextButton(
              onPressed: () {},
              child: const Text(
                'Feedback',
                style: TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // User Profile or Sign In Card
            _authService.isSignedIn
                ? _buildUserProfileCard()
                : _buildSignInCard(),
            
            const SizedBox(height: 20),
            
            // Bookmarks Section
            _buildBookmarksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Get personalized feed on any device',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bookmark,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Access Bookmarks on any device',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => AuthScreen.showAuthBottomSheet(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign In Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard() {
    // final fullName = _userProfile?['full_name'];
    // final email = _userProfile?['email'] ?? _authService.currentUser?.email ?? '';
    // final phone = _userProfile?['phone'] ?? _authService.currentUser?.phone ?? '';
    // // final displayName = fullName?.toString().isNotEmpty == true 
    // //     ? fullName 
    // //     : (email.isNotEmpty ? email : phone);
    // final displayName = (fullName != null && fullName.toString().isNotEmpty)
    //   ? fullName
    //   : (email.isNotEmpty ? email : (phone.isNotEmpty ? phone : 'Guest'));
    final user = _authService.currentUser;

    // Supabase stores custom fields in userMetadata
    final fullName = user?.userMetadata?['full_name'];
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';

    final displayName = (fullName != null && fullName.toString().isNotEmpty)
        ? fullName
        : (email.isNotEmpty ? email : (phone.isNotEmpty ? phone : 'Guest'));

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF2196F3),
            child: Text(
              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // User Info
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Premium',
              style: TextStyle(
                color: Color(0xFF2196F3),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _handleSignOut,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[900]!, width: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bookmark_border, color: Colors.white, size: 24),
                    SizedBox(width: 16),
                    Text(
                      'Saved',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (_bookmarks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_bookmarks.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Bookmarks List or Empty State
        _authService.isSignedIn
            ? (_bookmarks.isEmpty
                ? _buildEmptyBookmarksState()
                : _buildBookmarksList())
            : _buildSignInPromptForBookmarks(),
      ],
    );
  }

  Widget _buildEmptyBookmarksState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Text(
            'Its Empty Here',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tap on the bookmark icon to save a story',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPromptForBookmarks() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Icon(Icons.bookmark_border, size: 60, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text(
            'Sign In to Save Stories',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Access your saved stories across all devices',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

Widget _buildBookmarksList() {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _bookmarks.length,
    itemBuilder: (context, index) {
      final bookmark = _bookmarks[index];
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Row(
                children: [
                  // Square Thumbnail with gradient overlay
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (bookmark['image_url'] != null)
                          Image.network(
                            bookmark['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image, color: Colors.grey, size: 40);
                            },
                          )
                        else
                          const Icon(Icons.image, color: Colors.grey, size: 40),
                        
                        // Translucent gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content Section
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            bookmark['title'] ?? 'Untitled',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          
                          // Meta data
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                _getTimeAgo(bookmark['bookmarked_at']),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Delete button overlay
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () async {
                    await _authService.removeBookmark(bookmark['news_url']);
                    _loadUserData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bookmark removed'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Add this helper method to the _AccountTabState class
String _getTimeAgo(String? timestamp) {
  if (timestamp == null) return 'Unknown';
  
  try {
    final bookmarkedDate = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(bookmarkedDate);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  } catch (e) {
    return 'Unknown';
  }
}
}