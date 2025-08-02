import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class SOSButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isActive;
  final String? label;
  final double size;
  final bool showPulse;

  const SOSButton({
    super.key,
    this.onPressed,
    this.isActive = true,
    this.label,
    this.size = 200.0,
    this.showPulse = true,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.showPulse && widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePress() async {
    if (!widget.isActive || widget.onPressed == null) return;

    // Haptic feedback
    HapticFeedback.heavyImpact();

    setState(() {
      _isPressed = true;
    });

    // Visual feedback delay
    await Future.delayed(const Duration(milliseconds: 150));

    setState(() {
      _isPressed = false;
    });

    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: GestureDetector(
                onTapDown: (_) => setState(() => _isPressed = true),
                onTapUp: (_) => setState(() => _isPressed = false),
                onTapCancel: () => setState(() => _isPressed = false),
                onTap: _handlePress,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isActive
                          ? [
                              AppTheme.primaryRed,
                              AppTheme.secondaryRed,
                            ]
                          : [
                              Colors.grey.shade400,
                              Colors.grey.shade500,
                            ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isActive
                            ? AppTheme.primaryRed.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                        blurRadius: _isPressed ? 8 : 20,
                        spreadRadius: _isPressed ? 2 : 4,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isActive
                            ? [
                                _isPressed
                                    ? AppTheme.secondaryRed
                                    : AppTheme.primaryRed,
                                _isPressed
                                    ? AppTheme.primaryRed
                                    : AppTheme.secondaryRed,
                              ]
                            : [
                                Colors.grey.shade400,
                                Colors.grey.shade500,
                              ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.emergency,
                            size: widget.size * 0.3,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'SOS',
                            style: TextStyle(
                              fontSize: widget.size * 0.15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.label != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class EmergencyActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;

  const EmergencyActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.infoBlue,
          foregroundColor: textColor ?? Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
} 