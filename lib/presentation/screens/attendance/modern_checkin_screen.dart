// 📸 Modern Check-In Screen - Face detection with stunning UI
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class ModernCheckInScreen extends ConsumerStatefulWidget {
  const ModernCheckInScreen({super.key});

  @override
  ConsumerState<ModernCheckInScreen> createState() => _ModernCheckInScreenState();
}

class _ModernCheckInScreenState extends ConsumerState<ModernCheckInScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late Animation<double> _pulseAnimation;

  bool _isScanning = false;
  bool _isCheckingIn = false;
  double _scanProgress = 0.0;
  String? _locationInfo;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _getCurrentLocation();
  }

  void _initializeAnimations() {
    // Pulse animation for fingerprint
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Scan animation
    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _locationInfo = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
            'Lng: ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      setState(() {
        _locationInfo = 'Location unavailable';
      });
    }
  }

  Future<void> _startFaceScan() async {
    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
    });

    _scanController.forward();

    // Simulate face detection progress
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) {
        setState(() {
          _scanProgress = i / 100;
        });
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isScanning = false;
      });
      _scanController.reset();
      _handleCheckIn();
    }
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingIn = true);

    // Simulate check-in API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isCheckingIn = false);
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GradientCard(
          gradient: ModernColors.successGradient,
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Check-In Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome back! Have a productive day.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              AnimatedGradientButton(
                text: 'Done',
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFE0E0E0)],
                ),
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: ModernColors.primaryGradient,
        ),
        child: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // App bar
                  _buildAppBar(),

                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Title
                          _buildTitle(),

                          const SizedBox(height: 40),

                          // Fingerprint scanner
                          if (!_isScanning) _buildFingerprintScanner(),

                          // Face scanner
                          if (_isScanning) _buildFaceScanner(),

                          const SizedBox(height: 40),

                          // Location info
                          _buildLocationCard(),

                          const SizedBox(height: 24),

                          // Check-in info
                          _buildCheckInInfo(),

                          const SizedBox(height: 32),

                          // Check-in button
                          if (!_isScanning && !_isCheckingIn)
                            _buildCheckInButton(),

                          // Loading indicator
                          if (_isCheckingIn) _buildLoadingIndicator(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GlassCard(
            padding: const EdgeInsets.all(12),
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Text(
              'Check In',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          _isScanning
              ? 'Scanning Face...'
              : _isCheckingIn
                  ? 'Processing...'
                  : 'Place Your Finger',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          _isScanning
              ? 'Please look at the camera'
              : _isCheckingIn
                  ? 'Please wait...'
                  : 'Tap the button below to check in',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFingerprintScanner() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.3),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.fingerprint_rounded,
            size: 120,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildFaceScanner() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(200, 200),
          painter: _ScannerPainter(progress: _scanProgress),
        ),
        Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(
            Icons.face_rounded,
            size: 100,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${(_scanProgress * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return GlassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: Colors.white.withOpacity(0.9),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Location',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _locationInfo ?? 'Fetching location...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            color: ModernColors.emerald.withOpacity(0.8),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInInfo() {
    final now = DateTime.now();
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Current Time',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white.withOpacity(0.9),
                  size: 32,
                ),
                const SizedBox(height: 12),
                Text(
                  '${now.day}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${_getMonthName(now.month)} ${now.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInButton() {
    return AnimatedGradientButton(
      text: 'Check In Now',
      onPressed: _startFaceScan,
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFE0E0E0)],
      ),
      width: double.infinity,
      height: 60,
      icon: Icons.fingerprint_rounded,
    );
  }

  Widget _buildLoadingIndicator() {
    return const Column(
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Processing your check-in...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

// Custom painter for circular scanner
class _ScannerPainter extends CustomPainter {
  final double progress;

  _ScannerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScannerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
