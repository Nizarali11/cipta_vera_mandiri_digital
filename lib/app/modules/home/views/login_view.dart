import 'dart:ui';
import 'package:flutter/material.dart';


class LoginView extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onSignUpTap;
  final VoidCallback onLoginSuccess;

  const LoginView({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.onSignUpTap,
    required this.onLoginSuccess,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007BC1), Color(0xFF6EC6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 80),
                
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [],
                      ),
                      child: Image.asset(
                        'lib/app/assets/images/cvm.png', 
                        height: 120,
                      ),
                    ),
                    const SizedBox(height: 10),

                    
                    const Text(
                      "CIPTA VERA MANDIRI\nDIGITAL",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 15),

                   
                    TextField(
                      controller: widget.usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        hintText: 'Username',
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.person, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.0)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                   
                    TextField(
                      controller: widget.passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.2),
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.0)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 187),

                   
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: 220,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.32),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.5),
                              width: 1.2,
                            ),
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              shadowColor: Colors.transparent,
                              elevation: 0,
                            ),
                            onPressed: widget.onLoginSuccess,
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 5),

                   
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.white),
                        ),
                        GestureDetector(
                          onTap: widget.onSignUpTap,
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                              color: Color.fromARGB(255, 11, 47, 110),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ],
                    ),

                    const SizedBox(height: 20),
                    const SizedBox(height: 22),
                  ],
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                   
                    const Text(
                      "Login with :",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          width: 180,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.62),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.4),
                              width: 1.2,
                            ),
                          ),
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              shadowColor: Colors.transparent,
                              elevation: 0,
                            ),
                            onPressed: () {
                            
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'lib/app/assets/images/goggle.png', // pastikan path dan nama file benar
                                  height: 24,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Google",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}