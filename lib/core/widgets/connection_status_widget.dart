import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

class ConnectionStatusWidget extends StatefulWidget {
  final Widget child;
  const ConnectionStatusWidget({super.key, required this.child});

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  late StreamSubscription<List<ConnectivityResult>> _sub;
  bool _isOffline = false;
  bool _showBanner = false;

  @override
  void initState() {
    super.initState();
    _sub = Connectivity().onConnectivityChanged.listen(_onChanged);
    // Check current status immediately
    Connectivity()
        .checkConnectivity()
        .then((results) => _onChanged(results));
  }

  void _onChanged(List<ConnectivityResult> results) {
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (offline == _isOffline) return;
    setState(() {
      _isOffline   = offline;
      _showBanner  = true;
    });
    // Hide the "back online" banner after 3 seconds
    if (!offline) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showBanner = false);
      });
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: _OfflineBanner(isOffline: _isOffline)
                .animate()
                .slideY(begin: -0.5, end: 0, duration: 300.ms,
                    curve: Curves.easeOut)
                .fadeIn(duration: 250.ms),
          ),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  final bool isOffline;
  const _OfflineBanner({required this.isOffline});

  @override
  Widget build(BuildContext context) {
    final color = isOffline ? AppColors.error : AppColors.success;
    final icon  = isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded;
    final msg   = isOffline
        ? 'لا يوجد اتصال بالإنترنت'
        : 'تم استعادة الاتصال';

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
