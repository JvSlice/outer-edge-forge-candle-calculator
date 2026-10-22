import 'package:flutter/material.dart';

import 'candle_calculator.dart';

void main() => runApp(const CandleApp());

class AppColors {
  static const background = Color(0xFF17191A);
  static const surface = Color(0xFF222424);
  static const input = Color(0xFF191B1B);
  static const border = Color(0xFF484640);
  static const copper = Color(0xFFDA9B6D);
  static const copperDark = Color(0xFFA6653E);
  static const text = Color(0xFFF3F0E9);
  static const muted = Color(0xFFB7B2AA);
  static const error = Color(0xFFF0ABA5);
}

class CandleApp extends StatelessWidget {
  const CandleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Outer Edge Forge Candle Calculator',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.copper,
        secondary: AppColors.copper,
        surface: AppColors.surface,
        onSurface: AppColors.text,
        error: AppColors.error,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.input,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.copper, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
    ),
    home: const CandleHome(),
  );
}

class CandleHome extends StatefulWidget {
  const CandleHome({super.key});

  @override
  State<CandleHome> createState() => _CandleHomeState();
}

class _CandleHomeState extends State<CandleHome> {
  final _waxController = TextEditingController();
  final _containerController = TextEditingController(text: '1');
  bool _started = false;
  bool _showSplit = false;
  int _loadPercent = 8;
  int _fragranceCount = 1;

  @override
  void dispose() {
    _waxController.dispose();
    _containerController.dispose();
    super.dispose();
  }

  void _refresh(String _) => setState(() {});

  @override
  Widget build(BuildContext context) =>
      _started ? _buildCalculator() : _buildWelcome();

  Widget _buildWelcome() => Scaffold(
    body: Semantics(
      button: true,
      label:
          'Welcome to Outer Edge Forge Candle Calculator. Tap anywhere to begin.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('welcome-screen'),
          autofocus: true,
          onTap: () => setState(() => _started = true),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 0.95,
                colors: [Color(0xFF31302C), AppColors.background],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Eyebrow('Outer Edge Forge'),
                  const SizedBox(height: 32),
                  Container(width: 56, height: 2, color: AppColors.copper),
                  const SizedBox(height: 32),
                  Text.rich(
                    const TextSpan(
                      children: [
                        TextSpan(text: 'Welcome to\n'),
                        TextSpan(
                          text: 'Outer Edge Forge\n',
                          style: TextStyle(color: AppColors.copper),
                        ),
                        TextSpan(text: 'Candle Calculator'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: MediaQuery.sizeOf(context).width < 420
                          ? 32
                          : 52,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Tap anywhere to begin.  ↗',
                    style: TextStyle(color: AppColors.text, fontSize: 17),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _buildCalculator() {
    final wax = CandleCalculator.parseWaxGrams(_waxController.text);
    final containers = CandleCalculator.parseContainerCount(
      _containerController.text,
    );
    CandleAmounts? amounts;
    String? amountError;
    if (wax != null && containers != null) {
      try {
        amounts = CandleCalculator.calculate(
          waxGrams: wax,
          loadPercent: _loadPercent,
          containerCount: containers,
          fragranceCount: _fragranceCount,
        );
      } on ArgumentError {
        amountError = 'Amounts are too large to calculate.';
      }
    }
    final perContainer = wax == null
        ? null
        : CandleCalculator.fragrancePerContainer(wax, _loadPercent);
    if (perContainer != null &&
        (!perContainer.isFinite || perContainer >= 1e21)) {
      amountError = 'Amounts are too large to calculate.';
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 34, 16, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Eyebrow('Outer Edge Forge  /  Studio tool'),
                  const SizedBox(height: 14),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Candle '),
                        TextSpan(
                          text: 'Calculator',
                          style: TextStyle(color: AppColors.copper),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'A clear measure for every pour.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 30),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final inputPanel = _buildInputPanel(
                        wax,
                        containers,
                        perContainer,
                        amountError,
                      );
                      final resultsPanel = Column(
                        children: [
                          _buildBatchPanel(amounts),
                          const SizedBox(height: 18),
                          _buildSplitPanel(amounts, perContainer),
                        ],
                      );
                      if (constraints.maxWidth < 760) {
                        return Column(
                          children: [
                            inputPanel,
                            const SizedBox(height: 18),
                            resultsPanel,
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 11, child: inputPanel),
                          const SizedBox(width: 20),
                          Expanded(flex: 9, child: resultsPanel),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  const Center(
                    child: Text(
                      'Measure carefully. Make something good.',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputPanel(
    double? wax,
    int? containers,
    double? perContainer,
    String? amountError,
  ) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeading('01', 'Start with one', 'Per container'),
        const SizedBox(height: 26),
        const _FieldLabel('Wax weight per container'),
        const SizedBox(height: 9),
        TextField(
          key: const Key('wax-weight'),
          controller: _waxController,
          onChanged: _refresh,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'e.g. 100',
            suffixText: 'g',
            errorText: wax == null
                ? (_waxController.text.trim().isEmpty
                      ? 'Enter a wax weight.'
                      : 'Enter a wax weight greater than zero.')
                : amountError,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Enter wax weight alone, before fragrance.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 25),
        const _FieldLabel('Fragrance load'),
        const SizedBox(height: 9),
        DropdownButtonFormField<int>(
          key: const Key('fragrance-load'),
          isExpanded: true,
          initialValue: _loadPercent,
          decoration: const InputDecoration(),
          items: [6, 7, 8, 9, 10]
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text('$value%')),
              )
              .toList(),
          onChanged: (value) => setState(() => _loadPercent = value ?? 8),
        ),
        const SizedBox(height: 24),
        _ResultRow(
          label: 'Fragrance per container',
          amount: perContainer,
          emphasized: true,
          valueKey: const Key('fragrance-per-container'),
        ),
        const SizedBox(height: 30),
        const Divider(color: AppColors.border),
        const SizedBox(height: 24),
        const _SectionHeading('02', 'Scale your pour', 'Full batch'),
        const SizedBox(height: 24),
        const _FieldLabel('Number of containers'),
        const SizedBox(height: 9),
        TextField(
          key: const Key('container-count'),
          controller: _containerController,
          onChanged: _refresh,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            errorText: containers == null
                ? (_containerController.text.trim().isEmpty
                      ? 'Enter a number of containers.'
                      : 'Enter a positive whole number of containers.')
                : null,
          ),
        ),
      ],
    ),
  );

  Widget _buildBatchPanel(CandleAmounts? amounts) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SimpleHeading('Your totals', 'Batch overview'),
        const SizedBox(height: 24),
        const Divider(color: AppColors.border, height: 1),
        _ResultRow(
          label: 'Total wax',
          amount: amounts?.totalWax,
          valueKey: const Key('total-wax'),
        ),
        const Divider(color: AppColors.border, height: 1),
        _ResultRow(
          label: 'Total fragrance',
          amount: amounts?.totalFragrance,
          valueKey: const Key('total-fragrance'),
        ),
      ],
    ),
  );

  Widget _buildSplitPanel(CandleAmounts? amounts, double? perContainer) =>
      _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SimpleHeading('Blending', 'Split fragrances'),
            const SizedBox(height: 13),
            const Text(
              'Divide the fragrance evenly across your chosen scents.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                key: const Key('split-button'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.copperDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                onPressed: () => setState(() => _showSplit = !_showSplit),
                child: const Text('Split Fragrances'),
              ),
            ),
            if (_showSplit) ...[
              const SizedBox(height: 24),
              const _FieldLabel('Number of fragrances'),
              const SizedBox(height: 9),
              DropdownButtonFormField<int>(
                key: const Key('fragrance-count'),
                isExpanded: true,
                initialValue: _fragranceCount,
                decoration: const InputDecoration(),
                items: [1, 2, 3]
                    .map(
                      (count) => DropdownMenuItem(
                        value: count,
                        child: Text('$count fragrance${count == 1 ? '' : 's'}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _fragranceCount = value ?? 1),
              ),
              const SizedBox(height: 18),
              const Divider(color: AppColors.border, height: 1),
              _ResultRow(
                label: 'Each fragrance · per container',
                amount: perContainer == null
                    ? null
                    : CandleCalculator.eachFragrance(
                        perContainer,
                        _fragranceCount,
                      ),
                valueKey: const Key('split-per-container'),
              ),
              const Divider(color: AppColors.border, height: 1),
              _ResultRow(
                label: 'Each fragrance · full batch',
                amount: amounts?.eachFragranceForBatch,
                valueKey: const Key('split-per-batch'),
              ),
            ],
          ],
        ),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: AppColors.copper,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2.4,
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.number, this.eyebrow, this.title);
  final String number;
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.copperDark),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(number, style: const TextStyle(color: AppColors.copper)),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Eyebrow(eyebrow),
            const SizedBox(height: 3),
            _Heading(title),
          ],
        ),
      ),
    ],
  );
}

class _SimpleHeading extends StatelessWidget {
  const _SimpleHeading(this.eyebrow, this.title);
  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_Eyebrow(eyebrow), const SizedBox(height: 4), _Heading(title)],
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  );
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.amount,
    required this.valueKey,
    this.emphasized = false,
  });

  final String label;
  final double? amount;
  final Key valueKey;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final value = amount == null || !amount!.isFinite || amount! >= 1e21
        ? '—'
        : '${amount!.toStringAsFixed(2)} g';
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 2),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          Text(
            value,
            key: valueKey,
            style: const TextStyle(
              color: AppColors.copper,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (!emphasized) return content;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF382E28),
        border: Border.all(color: AppColors.copperDark),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }
}
