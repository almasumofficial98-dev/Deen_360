import 'package:flutter/material.dart';
import '../core/theme.dart';

class PillButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPress;
  final Color? color;
  final bool darkText;
  final TextStyle? textStyle;

  const PillButton({
    super.key,
    required this.title,
    this.onPress,
    this.color,
    this.darkText = false,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppTheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onPress,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: darkText ? AppTheme.text : AppTheme.white,
              ).merge(textStyle),
            ),
          ),
        ),
      ),
    );
  }
}
