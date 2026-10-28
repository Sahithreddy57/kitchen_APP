import 'package:flutter/material.dart';
import 'tap_cursor.dart';
import 'package:flutter/services.dart';
import '../core/app_core.dart';

const kNavy = Color(0xFF2D3E50);
const kBorder = Color(0xFFE6DFD3);
const kErrorRed = Color(0xFFD64545);

class SectionHeader extends StatelessWidget {
  final int number;
  final String title;
  const SectionHeader({super.key, required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 14),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(color: kNavy, shape: BoxShape.circle),
            child: Text('$number',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: kNavy)),
        ],
      ),
    );
  }
}

/// Radio-style card (Pickup / Delivery / Order now / address ...).
class OptionCard extends StatelessWidget {
  final bool selected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool enabled;
  const OptionCard({
    super.key,
    required this.selected,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: TapCursor(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFDEEE6) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? AppColors.primary : kBorder,
              width: selected ? 1.6 : 1.2),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : const Color(0xFFC9C3B8),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kNavy)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF55606B))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// Small selectable chip (tabs, banks, dates, time slots).
/// expand=true fills its parent (use inside Expanded); false hugs its text.
class SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool expand;
  final IconData? icon;
  final double fontSize;
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.expand = true,
    this.icon,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : kNavy;
    return TapCursor(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        padding: EdgeInsets.symmetric(horizontal: expand ? 6 : 18),
        decoration: BoxDecoration(
          color: selected ? kNavy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? kNavy : kBorder, width: 1.4),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fg),
              if (label.isNotEmpty) const SizedBox(width: 6),
            ],
            if (label.isNotEmpty)
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: fg)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rows of 3 equal chips (banks, UPI apps).
class ChipGrid extends StatelessWidget {
  final List<Widget> chips; // each is a SelectChip(expand: true)
  final int columns;
  const ChipGrid({super.key, required this.chips, this.columns = 3});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < chips.length; i += columns) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            for (int j = 0; j < columns; j++) ...[
              if (j > 0) const SizedBox(width: 10),
              Expanded(
                  child: i + j < chips.length ? chips[i + j] : const SizedBox()),
            ],
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}

class DashedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const DashedButton({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapCursor(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedPainter(),
        child: Container(
          height: 54,
          alignment: Alignment.center,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: kNavy)),
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCFC7B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(14)));
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Label above a rounded text box. Red border + message when [error] is set.
class LabeledField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? error;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final String? prefixText;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final bool obscure;
  final bool enabled;
  final TextCapitalization capitalization;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '',
    this.error,
    this.keyboard,
    this.formatters,
    this.prefixText,
    this.onChanged,
    this.trailing,
    this.obscure = false,
    this.enabled = true,
    this.capitalization = TextCapitalization.none,
  });

  OutlineInputBorder _b(Color c, [double w = 1.3]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF55606B))),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                obscureText: obscure,
                keyboardType: keyboard,
                inputFormatters: formatters,
                onChanged: onChanged,
                textCapitalization: capitalization,
                style: const TextStyle(fontSize: 16, color: kNavy),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  errorText: error,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: prefixText == null
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: Center(
                              widthFactor: 1,
                              child: Text(prefixText!,
                                  style: const TextStyle(
                                      fontSize: 16, color: kNavy))),
                        ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  border: _b(kBorder),
                  enabledBorder: _b(kBorder),
                  disabledBorder: _b(kBorder),
                  focusedBorder: _b(AppColors.primary, 1.6),
                  errorBorder: _b(kErrorRed, 1.6),
                  focusedErrorBorder: _b(kErrorRed, 1.6),
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
          ],
        ),
      ],
    );
  }
}

/// Date card like the design: small day name on top, big date number below
/// ("Tomorrow" / 2). With [icon] it becomes the calendar button.
class DateChip extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool disabled; // greyed out + not tappable (e.g. Today for Hundi)
  const DateChip({
    super.key,
    required this.title,
    this.subtitle = '',
    required this.selected,
    required this.onTap,
    this.icon,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : kNavy;
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: TapCursor(
        onTap: disabled ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 72,
          constraints: BoxConstraints(minWidth: icon != null ? 66 : 76),
          padding: EdgeInsets.symmetric(horizontal: icon != null ? 0 : 12),
          decoration: BoxDecoration(
            color: selected ? kNavy : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? kNavy : kBorder, width: 1.4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 26, color: fg),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(title,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: fg)),
                ],
              ] else ...[
                Text(title,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: fg)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: fg)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small peach info box (pre-order messages).
class PreOrderNote extends StatelessWidget {
  final String text;
  final bool showIcon;
  const PreOrderNote({super.key, required this.text, this.showIcon = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8DD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showIcon) ...[
            const Icon(Icons.event_available_outlined,
                size: 20, color: Color(0xFFB23A12)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13.5, height: 1.35, color: Color(0xFF9A3412))),
          ),
        ],
      ),
    );
  }
}