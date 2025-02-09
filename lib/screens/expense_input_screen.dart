import 'package:flutter/material.dart';
import 'dart:async';

class ExpenseInputScreen extends StatefulWidget {
  const ExpenseInputScreen({super.key});

  @override
  State<ExpenseInputScreen> createState() => _ExpenseInputScreenState();
}

class _ExpenseInputScreenState extends State<ExpenseInputScreen> {
  String _amount = '0';
  String _category = 'Shopping';
  String _paymentMethod = 'Cash';
  final TextEditingController _commentController = TextEditingController();

  Timer? _backspaceTimer;

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

  void _startBackspaceTimer() {
    _backspaceTimer?.cancel();
    _backspaceTimer =
        Timer.periodic(const Duration(milliseconds: 150), (timer) {
      _backspace();
    });
  }

  void _stopBackspaceTimer() {
    _backspaceTimer?.cancel();
    _backspaceTimer = null;
  }

  @override
  void dispose() {
    _backspaceTimer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                            children: [
                              Icon(Icons.payment, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_paymentMethod)),
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
                            children: [
                              Icon(Icons.category, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_category)),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Amount Display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _amount,
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Add Comment Section
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLength: 100,
                      decoration: InputDecoration(
                        hintText: 'Add comment...',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        counterText: '', // Hides the default counter
                      ),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Number Pad and side buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _NumberButton(
                                  label: '1',
                                  onTap: () => _updateAmount('1'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '2',
                                  onTap: () => _updateAmount('2'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '3',
                                  onTap: () => _updateAmount('3'),
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _NumberButton(
                                  label: '4',
                                  onTap: () => _updateAmount('4'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '5',
                                  onTap: () => _updateAmount('5'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '6',
                                  onTap: () => _updateAmount('6'),
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _NumberButton(
                                  label: '7',
                                  onTap: () => _updateAmount('7'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '8',
                                  onTap: () => _updateAmount('8'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '9',
                                  onTap: () => _updateAmount('9'),
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _NumberButton(
                                  label: '₹',
                                  onTap: () {},
                                  colorScheme: colorScheme,
                                  backgroundColor:
                                      colorScheme.primary.withOpacity(0.1),
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '0',
                                  onTap: () => _updateAmount('0'),
                                  colorScheme: colorScheme,
                                ),
                                const SizedBox(width: 2),
                                _NumberButton(
                                  label: '.',
                                  onTap: () => _updateAmount('.'),
                                  colorScheme: colorScheme,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 2),
                      Column(
                        children: [
                          _NumberButton(
                            label: '',
                            icon: Icons.backspace,
                            onTap: _backspace,
                            onLongPressStart: (_) => _startBackspaceTimer(),
                            onLongPressEnd: (_) => _stopBackspaceTimer(),
                            colorScheme: colorScheme,
                            backgroundColor:
                                colorScheme.tertiary.withOpacity(0.6),
                            textColor: Colors.white.withOpacity(0.6),
                            height: 88,
                          ),
                          const SizedBox(height: 2),
                          _NumberButton(
                            label: '',
                            icon: Icons.calendar_today,
                            onTap: () {
                              // TODO: Add calendar functionality
                            },
                            colorScheme: colorScheme,
                            backgroundColor:
                                colorScheme.primary.withOpacity(0.6),
                            textColor: colorScheme.onPrimary,
                            height: 88,
                          ),
                          const SizedBox(height: 2),
                          Container(
                            width: 88,
                            height: 178,
                            decoration: BoxDecoration(
                              color: colorScheme.background.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(
                      height: 16), // Added to ensure space at the bottom
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumberButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final void Function(LongPressStartDetails)? onLongPressStart;
  final void Function(LongPressEndDetails)? onLongPressEnd;
  final ColorScheme colorScheme;
  final Color? backgroundColor;
  final Color? textColor;
  final double? height;

  const _NumberButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    required this.colorScheme,
    this.backgroundColor,
    this.textColor,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: Container(
        width: 88,
        height: height ?? 88,
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Center(
          child: icon != null
              ? Icon(
                  icon,
                  color: textColor ?? colorScheme.onSurface,
                  size: 24,
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}
