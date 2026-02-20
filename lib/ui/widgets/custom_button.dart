import 'package:flutter/material.dart';

enum ButtonVariant { primary, secondary, industrial, outline, danger }

enum ButtonSize { sm, md, lg, full }

class CustomButton extends StatelessWidget {
  final Widget child;
  final ButtonVariant variant;
  final ButtonSize size;
  final bool loading;
  final bool disabled;
  final VoidCallback? onPressed;
  final ButtonStyle? style;

  const CustomButton({
    super.key,
    required this.child,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.loading = false,
    this.disabled = false,
    this.onPressed,
    this.style,
  });

  Color _getBackgroundColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return Colors.yellow.shade700;
      case ButtonVariant.secondary:
        return Colors.grey.shade800;
      case ButtonVariant.industrial:
        return Colors.black87; // aproximado a industrial gradient
      case ButtonVariant.outline:
        return Colors.transparent;
      case ButtonVariant.danger:
        return Colors.red.shade600;
    }
  }

  Color _getTextColor() {
    switch (variant) {
      case ButtonVariant.primary:
        return Colors.black;
      case ButtonVariant.secondary:
        return Colors.white;
      case ButtonVariant.industrial:
        return Colors.yellow.shade700;
      case ButtonVariant.outline:
        return Colors.black;
      case ButtonVariant.danger:
        return Colors.white;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case ButtonSize.sm:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case ButtonSize.md:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case ButtonSize.lg:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
      case ButtonSize.full:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    }
  }

  double _getMinHeight() {
    switch (size) {
      case ButtonSize.sm:
        return 36;
      case ButtonSize.md:
        return 44;
      case ButtonSize.lg:
        return 48;
      case ButtonSize.full:
        return 44;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size == ButtonSize.full ? double.infinity : null,
      height: _getMinHeight(),
      child: ElevatedButton(
        onPressed: disabled || loading ? null : onPressed,
        style:
            style ??
            ElevatedButton.styleFrom(
              backgroundColor: _getBackgroundColor(),
              foregroundColor: _getTextColor(),
              padding: _getPadding(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: variant == ButtonVariant.outline
                    ? const BorderSide(color: Colors.yellow)
                    : BorderSide.none,
              ),
            ),
        child: loading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _getTextColor(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  child,
                ],
              )
            : child,
      ),
    );
  }
}
