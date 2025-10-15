import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'name_input_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String _countryCode = '+91'; // Default to India
  String _countryName = 'India';
  
  final List<Map<String, String>> _countries = [
    {'name': 'India', 'code': '+91'},
    {'name': 'United States', 'code': '+1'},
    {'name': 'United Kingdom', 'code': '+44'},
    {'name': 'Canada', 'code': '+1'},
    {'name': 'Australia', 'code': '+61'},
    {'name': 'Germany', 'code': '+49'},
    {'name': 'France', 'code': '+33'},
    {'name': 'China', 'code': '+86'},
    {'name': 'Japan', 'code': '+81'},
    {'name': 'South Korea', 'code': '+82'},
    {'name': 'Brazil', 'code': '+55'},
    {'name': 'Mexico', 'code': '+52'},
    {'name': 'Russia', 'code': '+7'},
    {'name': 'Italy', 'code': '+39'},
    {'name': 'Spain', 'code': '+34'},
    {'name': 'Netherlands', 'code': '+31'},
    {'name': 'Saudi Arabia', 'code': '+966'},
    {'name': 'UAE', 'code': '+971'},
    {'name': 'Singapore', 'code': '+65'},
    {'name': 'Malaysia', 'code': '+60'},
    {'name': 'Indonesia', 'code': '+62'},
    {'name': 'Pakistan', 'code': '+92'},
    {'name': 'Bangladesh', 'code': '+880'},
    {'name': 'Sri Lanka', 'code': '+94'},
    {'name': 'Nepal', 'code': '+977'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
  final isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
  
  showModalBottomSheet(
    context: context,
    backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Container(
      height: 400,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            'Select Country',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _countries.length,
              itemBuilder: (context, index) {
                final country = _countries[index];
                return ListTile(
                  title: Text(
                    country['name']!,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  trailing: Text(
                    country['code']!,
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    setState(() {
                      _countryCode = country['code']!;
                      _countryName = country['name']!;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}


  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();
    
    if (phone.isEmpty || phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    final fullPhone = '$_countryCode$phone';
    
    setState(() => _isLoading = true);
    
    try {
      await _authService.signInWithPhone(fullPhone);
      setState(() => _otpSent = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent to $fullPhone'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
  final phone = _phoneController.text.trim();
  final otp = _otpController.text.trim();
  if (otp.isEmpty || otp.length != 6) return _showError('Enter 6-digit OTP');

  setState(() => _isLoading = true);
  try {
    final response = await _authService.verifyPhoneOTP('$_countryCode$phone', otp);
    final user = response.user;

    if (user != null && mounted) {
      final profile = await _authService.getUserProfile();
      final needsName = profile?['full_name'] == null || profile!['full_name'].toString().isEmpty;

      if (needsName) {
        // Navigate to NameInputScreen only once
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NameInputScreen()),
        );
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully signed in!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    _showError(e.toString());
  } finally {
    setState(() => _isLoading = false);
  }
}
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


@override
Widget build(BuildContext context) {
  final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
  
  return Scaffold(
    backgroundColor: isDarkMode ? Colors.black : Colors.white,
    appBar: AppBar(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        _otpSent ? 'Verify Phone' : 'Phone Sign In',
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            if (_otpSent) ...[
              _buildOTPSection(isDarkMode),
            ] else ...[
              _buildPhoneSection(isDarkMode),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _buildPhoneSection(bool isDarkMode) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Phone Number',
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      
      // Phone Input with Country Code
      Row(
        children: [
          // Country Code Selector
          GestureDetector(
            onTap: _showCountryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    _countryCode,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.grey[600] : Colors.grey[500]),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Phone Number Input
          Expanded(
            child: TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: '9876543210',
                hintStyle: TextStyle(color: isDarkMode ? Colors.grey[600] : Colors.grey[400]),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.phone, color: isDarkMode ? Colors.grey[600] : Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 32),

      // Send OTP Button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _sendOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Send OTP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
      const SizedBox(height: 20),

      // Info Text
      Text(
        'We will send you a 6-digit verification code',
        style: TextStyle(
          color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
          fontSize: 14,
        ),
      ),
    ],
  );
}

Widget _buildOTPSection(bool isDarkMode) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Enter the 6-digit code sent to',
        style: TextStyle(
          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '$_countryCode${_phoneController.text}',
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 32),

      // OTP Input
      TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 8,
        ),
        decoration: InputDecoration(
          hintText: '000000',
          hintStyle: TextStyle(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          counterText: '',
        ),
      ),
      const SizedBox(height: 24),

      // Verify Button
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _verifyOTP,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Verify',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
      const SizedBox(height: 16),

      // Resend Code
      Center(
        child: TextButton(
          onPressed: () {
            setState(() => _otpSent = false);
            _otpController.clear();
          },
          child: const Text(
            'Resend Code',
            style: TextStyle(
              color: Color(0xFF2196F3),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );
}

}