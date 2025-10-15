import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/news_detail_screen.dart';
import '../providers/theme_provider.dart';

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
  bool _isSelectMode = false;
  final Set<int> _selectedBookmarks = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
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
    final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        title: Text(
          'Sign Out',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
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

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsScreen(
        isSignedIn: _authService.isSignedIn,
      ),
    );
  }

  void _openBookmarkedNews(Map<String, dynamic> bookmark) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(
          newsUrl: bookmark['news_url'],
          title: bookmark['title'] ?? 'News',
          imageUrl: bookmark['image_url'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;
        
        if (_isLoading) {
          return Scaffold(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            body: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2196F3),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: isDarkMode ? Colors.black : Colors.white,
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
            elevation: 0,
            actions: [
              if (_authService.isSignedIn) ...[
                TextButton(
                  onPressed: _openSettings,
                  child: Text(
                    'Feedback',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 0),
              ],
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: _openSettings,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                
                _authService.isSignedIn
                    ? _buildUserProfileCard(isDarkMode)
                    : _buildSignInCard(isDarkMode),
                
                const SizedBox(height: 20),
                
                _buildBookmarksSection(isDarkMode),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSignInCard(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!),
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
              Expanded(
                child: Text(
                  'Get personalized feed on any device',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
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
              Expanded(
                child: Text(
                  'Access Bookmarks on any device',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
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

  Widget _buildUserProfileCard(bool isDarkMode) {
    final user = _authService.currentUser;
    final fullName = user?.userMetadata?['full_name'];
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';
    final displayName = (fullName != null && fullName.toString().isNotEmpty)
        ? fullName
        : (email.isNotEmpty ? email : (phone.isNotEmpty ? phone : 'Guest'));

    return Container(
      margin: const EdgeInsets.all(18),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
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
          
          Text(
            displayName,
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
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

// Replace the _buildBookmarksSection method
Widget _buildBookmarksSection(bool isDarkMode) {
  return Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDarkMode ? Colors.grey[900]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bookmark_border,
                    color: isDarkMode ? Colors.white : Colors.black,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Saved',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (_bookmarks.isNotEmpty)
                _isSelectMode
                    ? IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: _selectedBookmarks.isEmpty
                            ? null
                            : () => _deleteSelectedBookmarks(isDarkMode),
                      )
                    : Container(
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
      
      _authService.isSignedIn
          ? (_bookmarks.isEmpty
              ? _buildEmptyBookmarksState(isDarkMode)
              : _buildBookmarksList(isDarkMode))
          : _buildSignInPromptForBookmarks(isDarkMode),
    ],
  );
}

// Add this new method for deleting selected bookmarks
Future<void> _deleteSelectedBookmarks(bool isDarkMode) async {
  if (_selectedBookmarks.isEmpty) return;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      title: Text(
        'Delete Bookmarks',
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      content: Text(
        'Are you sure you want to delete ${_selectedBookmarks.length} bookmark(s)?',
        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            'Delete',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (confirm == true) {
    final selectedIndices = _selectedBookmarks.toList();
    for (final index in selectedIndices) {
      if (index < _bookmarks.length) {
        try {
          await _authService.removeBookmark(_bookmarks[index]['news_url']);
        } catch (_) {}
      }
    }
    
    setState(() {
      _selectedBookmarks.clear();
      _isSelectMode = false;
    });
    
    await _loadUserData();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedIndices.length} bookmark(s) removed'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// Replace the _buildBookmarksList method
Widget _buildBookmarksList(bool isDarkMode) {
  return Column(
    children: [
      if (_isSelectMode)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (_selectedBookmarks.length == _bookmarks.length) {
                      _selectedBookmarks.clear();
                    } else {
                      _selectedBookmarks.addAll(
                        List.generate(_bookmarks.length, (index) => index),
                      );
                    }
                  });
                },
                icon: Icon(
                  _selectedBookmarks.length == _bookmarks.length
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  color: const Color(0xFF2196F3),
                ),
                label: Text(
                  _selectedBookmarks.length == _bookmarks.length
                      ? 'Deselect All'
                      : 'Select All',
                  style: const TextStyle(color: Color(0xFF2196F3)),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isSelectMode = false;
                    _selectedBookmarks.clear();
                  });
                },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _bookmarks.length,
        itemBuilder: (context, index) {
          final bookmark = _bookmarks[index];
          final isSelected = _selectedBookmarks.contains(index);

          return GestureDetector(
            onTap: () {
              if (_isSelectMode) {
                setState(() {
                  if (isSelected) {
                    _selectedBookmarks.remove(index);
                  } else {
                    _selectedBookmarks.add(index);
                  }
                });
              } else {
                _openBookmarkedNews(bookmark);
              }
            },
            onLongPress: () {
              if (!_isSelectMode) {
                setState(() {
                  _isSelectMode = true;
                  _selectedBookmarks.add(index);
                });
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.black.withOpacity(0.25) 
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(14),
                border: isSelected
                    ? Border.all(color: const Color(0xFF2196F3), width: 2)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSelectMode)
                          Container(
                            width: 40,
                            height: 80,
                            child: Center(
                              child: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                color: isSelected
                                    ? const Color(0xFF2196F3)
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            height: 80,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  bookmark['title'] ?? 'Untitled',
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getTimeAgo(bookmark['bookmarked_at']),
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white70 : Colors.black54,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 120,
                          height: 80,
                          padding: const EdgeInsets.all(6),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: bookmark['image_url'] != null
                                ? Image.network(
                                    bookmark['image_url'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : Icon(
                                    Icons.image,
                                    color: isDarkMode ? Colors.grey : Colors.grey[600],
                                    size: 40,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}

  Widget _buildEmptyBookmarksState(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: [
          const SizedBox(height: 60),
          // Text(
          //   'Its Empty Here',
          //   style: TextStyle(
          //     color: isDarkMode ? Colors.white : Colors.black,
          //     fontSize: 24,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          const SizedBox(height: 12),
          Text(
            'Tap on the bookmark icon to save a story',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInPromptForBookmarks(bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const SizedBox(height: 60),
          // Icon(
          //   Icons.bookmark_border,
          //   size: 60,
          //   color: isDarkMode ? Colors.grey[700] : Colors.grey[400],
          // ),
          const SizedBox(height: 16),
          Text(
            'Sign In to Save Stories',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Access your saved stories across all devices',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

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