import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_model.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  bool _isSaving = false;

  late AnimationController _iconAnimController;
  late Animation<double> _iconScaleAnim;

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _iconScaleAnim = CurvedAnimation(
      parent: _iconAnimController,
      curve: Curves.elasticOut,
    );
    _iconAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _budgetController.dispose();
    _iconAnimController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage == 1 && _nameController.text.trim().isEmpty) {
      _showSnack('Please enter your name to continue');
      return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
      // Re-trigger icon animation for next page
      _iconAnimController.reset();
      _iconAnimController.forward();
    } else {
      _saveAndComplete();
    }
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _saveAndComplete() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final budget =
          double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0.0;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name.isNotEmpty ? name : 'there');
      await prefs.setBool('onboarding_complete', true);

      if (budget > 0) {
        final budgetBox = await Hive.openBox<BudgetModel>('budget');
        final existing = budgetBox.get('current_budget');
        if (existing != null) {
          existing.totalBalance = budget;
          existing.balance = budget;
          await budgetBox.put('current_budget', existing);
        }
      }

      if (mounted) widget.onComplete();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnack('Something went wrong. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 12),
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 28 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? colorScheme.primary
                        : colorScheme.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            // Back button row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      onPressed: _goBack,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(
                    colorScheme: colorScheme,
                    scaleAnim: _iconScaleAnim,
                  ),
                  _NamePage(
                    controller: _nameController,
                    colorScheme: colorScheme,
                    scaleAnim: _iconScaleAnim,
                  ),
                  _BudgetPage(
                    controller: _budgetController,
                    colorScheme: colorScheme,
                    scaleAnim: _iconScaleAnim,
                  ),
                ],
              ),
            ),
            // CTA button
            AnimatedPadding(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.fromLTRB(
                  24, 8, 24, viewInsets.bottom + 32),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: _isSaving ? null : _goToNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    disabledBackgroundColor:
                        colorScheme.primary.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _currentPage == 0
                              ? 'Get Started  →'
                              : _currentPage == _totalPages - 1
                                  ? "Let's Go! 🚀"
                                  : 'Continue  →',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 1: Welcome ────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final ColorScheme colorScheme;
  final Animation<double> scaleAnim;

  const _WelcomePage({
    required this.colorScheme,
    required this.scaleAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: scaleAnim,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.3),
                    colorScheme.primary.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 36),
          const Text(
            'Welcome to\nChilav',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Track spending, stick to your budget,\nand grow your savings — effortlessly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.5),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          // Feature pills
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _FeaturePill(icon: Icons.bar_chart_rounded, label: 'Analytics', color: colorScheme.primary),
              _FeaturePill(icon: Icons.savings_rounded, label: 'Budget Tracking', color: colorScheme.secondary),
              _FeaturePill(icon: Icons.history_rounded, label: 'Expense History', color: colorScheme.primary),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _FeaturePill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 2: Name ────────────────────────────────────────────────────────────

class _NamePage extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;
  final Animation<double> scaleAnim;

  const _NamePage({
    required this.controller,
    required this.colorScheme,
    required this.scaleAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ScaleTransition(
            scale: scaleAnim,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.waving_hand_rounded,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "What should\nwe call you?",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "We'll use your name to personalise\nyour experience.",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.45),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            onSubmitted: (_) {},
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 20),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(Icons.person_outline_rounded,
                    color: colorScheme.primary, size: 24),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 3: Budget ──────────────────────────────────────────────────────────

class _BudgetPage extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;
  final Animation<double> scaleAnim;

  const _BudgetPage({
    required this.controller,
    required this.colorScheme,
    required this.scaleAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          ScaleTransition(
            scale: scaleAnim,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                Icons.savings_rounded,
                size: 36,
                color: colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Your monthly\nbudget?",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Set how much you plan to spend\nthis month. You can adjust it anytime.",
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.45),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.25)),
              prefixText: '₹  ',
              prefixStyle: TextStyle(
                color: colorScheme.primary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.07),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide:
                    BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 20),
            ),
          ),
          const SizedBox(height: 16),
          // Quick presets
          Text(
            'Quick select',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: ['5,000', '10,000', '20,000', '50,000']
                .map((amount) => GestureDetector(
                      onTap: () {
                        controller.text = amount.replaceAll(',', '');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: colorScheme.primary.withOpacity(0.25)),
                        ),
                        child: Text(
                          '₹$amount',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          Text(
            'You can skip this and set it later from the edit screen.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
