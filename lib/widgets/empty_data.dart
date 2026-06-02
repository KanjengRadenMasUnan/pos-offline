import 'package:flutter/material.dart';

class EmptyData extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyData({
    super.key,
    this.message = "Data tidak ditemukan",
    this.icon = Icons.inbox_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 15),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
