import 'package:flutter/material.dart';

class ExpenseInputScreen extends StatefulWidget {
  const ExpenseInputScreen({super.key});

  @override
  State<ExpenseInputScreen> createState() => _ExpenseInputScreenState();
}

class _ExpenseInputScreenState extends State<ExpenseInputScreen> {
  String _amount = '0';
  String _category = 'Shopping';
  String _paymentMethod = 'Cash';

  void _updateAmount(String value) {
    setState(() {
      if (_amount == '0') {
        _amount = value;
      } else {
        _amount += value;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Text(
                  'New Expense',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    // TODO: Save expense
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Category and Payment Method Selectors
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.payment, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(_paymentMethod),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.category, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(_category),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Amount Display
                  Text(
                    '\$$_amount',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Number Pad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Main number pad column
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 1; i <= 3; i++)
                                Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: _NumberButton(
                                    label: '$i',
                                    onTap: () => _updateAmount('$i'),
                                    colorScheme: colorScheme,
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 4; i <= 6; i++)
                                Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: _NumberButton(
                                    label: '$i',
                                    onTap: () => _updateAmount('$i'),
                                    colorScheme: colorScheme,
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 7; i <= 9; i++)
                                Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: _NumberButton(
                                    label: '$i',
                                    onTap: () => _updateAmount('$i'),
                                    colorScheme: colorScheme,
                                  ),
                                ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: _NumberButton(
                                  label: '\$',
                                  onTap: () {},
                                  colorScheme: colorScheme,
                                  backgroundColor:
                                      colorScheme.primary.withOpacity(0.1),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: _NumberButton(
                                  label: '0',
                                  onTap: () => _updateAmount('0'),
                                  colorScheme: colorScheme,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: _NumberButton(
                                  label: '.',
                                  onTap: () => _updateAmount('.'),
                                  colorScheme: colorScheme,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Side column with additional buttons
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.backspace_outlined),
                                  color: colorScheme.onPrimary,
                                  onPressed: _backspace,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.calendar_today),
                                  color: colorScheme.onPrimary,
                                  onPressed: () {
                                    // TODO: Add calendar functionality
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(32),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.check),
                                  color: colorScheme.onPrimary,
                                  onPressed: () {
                                    // TODO: Save expense
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ColorScheme colorScheme;
  final Color? backgroundColor;

  const _NumberButton({
    required this.label,
    required this.onTap,
    required this.colorScheme,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
