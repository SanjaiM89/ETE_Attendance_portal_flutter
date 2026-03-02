import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  final _mfaOtpController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.requiresMfa) {
        // Step 2: Verify MFA
        if (_mfaOtpController.text.isEmpty) {
          throw Exception("Please enter the authenticator code");
        }
        await authProvider.verifyMfa(
          _mfaOtpController.text.trim(),
        );
      } else {
        // Step 1: Initial Login
        if (_adminEmailController.text.isEmpty || _adminPasswordController.text.isEmpty) {
           throw Exception("Email and password are required.");
        }
        await authProvider.loginAdmin(
          _adminEmailController.text.trim(),
          _adminPasswordController.text,
        );
      }

      if (authProvider.isAuthenticated && mounted) {
        context.go('/admin');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Center(
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(40.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                spreadRadius: 8,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hub, size: 40, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Text(
                          'FODSE',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Admin Portal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  letterSpacing: 1.2,
                ),
              ),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.requiresMfa) {
                    return _buildMfaStep(isDark, authProvider);
                  }
                  return _buildLoginStep(isDark);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginStep(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 36),
        TextField(
          controller: _adminEmailController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: const InputDecoration(
            labelText: 'Admin Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _adminPasswordController,
          obscureText: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock_outline),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildMfaStep(bool isDark, AuthProvider authProvider) {
    return Column(
      children: [
        const SizedBox(height: 24),
        if (authProvider.mfaIsSetup && authProvider.mfaQrCode != null) ...[
          const Text(
            'Admin Two-Factor Authentication Setup',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Scan this QR code with your Authenticator app (Google Authenticator, Authy, etc.), then enter the generated code below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Image.memory(
              base64Decode(authProvider.mfaQrCode!.split(',').last),
              width: 180,
              height: 180,
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          const Icon(Icons.security, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Two-Factor Authentication',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Enter the 6-digit code from your Authenticator app.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
        ],
        TextField(
          controller: _mfaOtpController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 24,
            letterSpacing: 4,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: 'Authenticator Code',
            prefixIcon: Icon(Icons.password),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Verify Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
