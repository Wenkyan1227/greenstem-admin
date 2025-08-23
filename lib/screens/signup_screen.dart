import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/admin_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adminService = AdminService();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Create admin using AdminService
      await _adminService.createAdmin(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Success - navigate to dashboard
      Navigator.pushReplacementNamed(context, '/dashboard');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Sign up failed. Please try again.';

      switch (e.code) {
        case 'weak-password':
          errorMessage =
              'Password is too weak. Please choose a stronger password.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account with this email already exists.';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
      }

      setState(() {
        _error = errorMessage;
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF29A87A), Color(0xFF20B2AA), Color(0xFF48D1CC)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo section with modern styling
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                Icons.person_add,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join us and start your journey',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form container with glassmorphism effect
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Name field
                              _buildModernTextField(
                                controller: _nameController,
                                labelText: 'Full Name',
                                icon: Icons.person_outline,
                                validator:
                                    (v) =>
                                        v == null || v.isEmpty
                                            ? 'Please enter your name'
                                            : null,
                              ),
                              const SizedBox(height: 20),

                              // Email field
                              _buildModernTextField(
                                controller: _emailController,
                                labelText: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator:
                                    (v) =>
                                        v == null || !v.contains('@')
                                            ? 'Enter a valid email'
                                            : null,
                              ),
                              const SizedBox(height: 20),

                              // Password field
                              _buildModernTextField(
                                controller: _passwordController,
                                labelText: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF29A87A),
                                  ),
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscurePassword =
                                                !_obscurePassword,
                                      ),
                                ),
                                validator:
                                    (v) =>
                                        v == null || v.length < 6
                                            ? 'Password must be at least 6 characters'
                                            : null,
                              ),
                              const SizedBox(height: 20),

                              // Confirm Password field
                              _buildModernTextField(
                                controller: _confirmPasswordController,
                                labelText: 'Confirm Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscureConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: const Color(0xFF29A87A),
                                  ),
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword,
                                      ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (v != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),

                              // Error message
                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade600,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),

                              // Sign up button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF29A87A),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    shadowColor: const Color(
                                      0xFF29A87A,
                                    ).withOpacity(0.3),
                                  ),
                                  onPressed:
                                      _loading
                                          ? null
                                          : () {
                                            if (_formKey.currentState!
                                                .validate())
                                              _signUp();
                                          },
                                  child:
                                      _loading
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Login link
                              TextButton(
                                onPressed:
                                    () => Navigator.pushReplacementNamed(
                                      context,
                                      '/login',
                                    ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF29A87A),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                                child: RichText(
                                  text: TextSpan(
                                    text: "Already have an account? ",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 15,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'Sign In',
                                        style: TextStyle(
                                          color: Color(0xFF29A87A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: const Color(0xFF29A87A)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF29A87A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
      ),
    );
  }
}
