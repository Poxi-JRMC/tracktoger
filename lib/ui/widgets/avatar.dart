import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final double size;
  final Widget? child;
  final String? imageUrl;
  final String? fallbackText;
  final Color backgroundColor;

  const Avatar({
    Key? key,
    this.size = 40.0,
    this.child,
    this.imageUrl,
    this.fallbackText,
    this.backgroundColor = const Color(0xFFE5E7EB), // equivalente a bg-muted
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(shape: BoxShape.circle),
      child: imageUrl != null
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildFallback(),
            )
          : child ?? _buildFallback(),
    );
  }

  Widget _buildFallback() {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: fallbackText != null
          ? Text(
              fallbackText!,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            )
          : const Icon(Icons.person, color: Colors.grey),
    );
  }
}
