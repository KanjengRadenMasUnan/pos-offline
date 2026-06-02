import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_theme.dart';

class CustomButton extends StatelessWidget {
  // ====================
  // Properties
  // ====================

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;

  // ====================
  // Constructor
  // ====================

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
  });

  // ====================
  // Build Method
  // ====================

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _buttonHeight,
      child: ElevatedButton(
        style: _buildButtonStyle(),
        onPressed: _handleButtonPress,
        child: _buildButtonContent(),
      ),
    );
  }

  // ====================
  // Private Constants
  // ====================

  static const double _buttonHeight = 50.0;
  static const double _borderRadius = 12.0;
  static const double _iconSize = 20.0;
  static const double _spacing = 8.0;
  static const double _progressIndicatorSize = 24.0;
  static const double _progressStrokeWidth = 2.0;

  // ====================
  // Private Methods
  // ====================

  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? AppTheme.primaryColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
      ),
    );
  }

  VoidCallback? get _handleButtonPress {
    if (isLoading) return null;

    return onPressed != null ? _executeWithHapticFeedback : null;
  }

  void _executeWithHapticFeedback() {
    HapticFeedback.lightImpact();
    onPressed!();
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        width: _progressIndicatorSize,
        height: _progressIndicatorSize,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: _progressStrokeWidth,
        ),
      );
    }

    return _buildTextWithIcon();
  }

  Widget _buildTextWithIcon() {
    final hasIcon = icon != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (hasIcon) ...[
          Icon(icon, size: _iconSize),
          const SizedBox(width: _spacing),
        ],
        _buildButtonText(),
      ],
    );
  }

  Widget _buildButtonText() {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
    );
  }
}
