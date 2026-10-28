
import 'package:flutter/material.dart';
import '../core/app_core.dart';
import 'checkout_widgets.dart';

/// Male / Female / Other chips. [value] is 'male', 'female', 'other' or ''.
/// Gender is optional. Tapping the selected chip again clears it.
class GenderPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const GenderPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      ['male', 'genderMale'],
      ['female', 'genderFemale'],
      ['other', 'other'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('gender'),
          style: const TextStyle(
            fontSize: 12.5,
            color: Color(0xFF55606B),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: SelectChip(
                  label: context.tr(options[i][1]),
                  selected: value == options[i][0],
                  onTap: () => onChanged(
                    value == options[i][0] ? '' : options[i][0],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
