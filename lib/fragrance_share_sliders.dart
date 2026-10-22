import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'candle_calculator.dart';
import 'fragrance_ratios.dart';

class FragranceShareSliders extends StatelessWidget {
  const FragranceShareSliders({
    super.key,
    required this.entries,
    required this.keyPrefix,
    required this.onChanged,
  });

  final List<String> entries;
  final String keyPrefix;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = CandleCalculator.parseBlendPercentages(entries);
    if (values == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blend shares must be positive and add up to 100%.',
            style: TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: Key('$keyPrefix-reset'),
            onPressed: () => onChanged(FragranceRatios.equal(entries.length)),
            child: const Text('Set equal shares'),
          ),
        ],
      );
    }
    if (values.length == 1) {
      return const Text(
        'Fragrance 1 share: 100%',
        style: TextStyle(color: AppColors.muted),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < values.length; index++) ...[
          Row(
            children: [
              Expanded(child: Text('Fragrance ${index + 1} share')),
              Text(
                '${FragranceRatios.display(values[index])}%',
                key: Key('$keyPrefix-value-$index'),
                style: const TextStyle(
                  color: AppColors.copper,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Slider(
            key: Key('$keyPrefix-$index'),
            min: 0.1,
            max: values.length == 2 ? 99.9 : 99.8,
            divisions: values.length == 2 ? 998 : 997,
            value: values[index]
                .clamp(0.1, values.length == 2 ? 99.9 : 99.8)
                .toDouble(),
            label: '${FragranceRatios.display(values[index])}%',
            semanticFormatterCallback: (value) =>
                'Fragrance ${index + 1}, ${FragranceRatios.display(value)} percent',
            onChanged: (value) =>
                onChanged(FragranceRatios.adjust(values, index, value)),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
