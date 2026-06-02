import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String message;
  final Color overlayColor;
  final Color backgroundColor;
  final double borderRadius;
  final double padding;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message = 'Memproses...',
    this.overlayColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.borderRadius = 10.0,
    this.padding = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Content
        child,

        // Loading Overlay
        if (isLoading) _buildLoadingOverlay(context),
      ],
    );
  }

  // ====================
  // Private Helpers
  // ====================

  Widget _buildLoadingOverlay(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        color: overlayColor.withOpacity(0.5),
        child: Center(child: _buildLoadingDialog(context)),
      ),
    );
  }

  Widget _buildLoadingDialog(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressIndicator(),
          const SizedBox(height: 15),
          _buildMessageText(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return const CircularProgressIndicator();
  }

  Widget _buildMessageText() {
    return Text(message, style: const TextStyle(fontWeight: FontWeight.bold));
  }
}
