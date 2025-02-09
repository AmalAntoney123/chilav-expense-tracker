import 'package:flutter_reorderable_grid_view/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeScreenCustomization extends StatefulWidget {
  final List<Map<String, dynamic>> initialCategories;
  final String initialBudget;

  const HomeScreenCustomization({
    super.key,
    required this.initialCategories,
    required this.initialBudget,
  });

  // Update default categories to use null color
  static List<Map<String, dynamic>> get defaultCategories => [
        {
          'icon': Icons.shopping_bag,
          'label': 'Shopping',
          'visible': true,
          'color': null,
        },
        {
          'icon': Icons.restaurant,
          'label': 'Food',
          'visible': true,
          'color': null,
        },
        {
          'icon': Icons.directions_car,
          'label': 'Transport',
          'visible': true,
          'color': null,
        },
        {
          'icon': Icons.movie,
          'label': 'Entertainment',
          'visible': true,
          'color': null,
        },
        {
          'icon': Icons.receipt_long,
          'label': 'Bills',
          'visible': true,
          'color': null,
        },
        {
          'icon': Icons.medical_services,
          'label': 'Health',
          'visible': true,
          'color': null,
        },
        {
          'icon': Icons.school,
          'label': 'Education',
          'visible': true,
          'color': null,
        },
        {
          'icon': Icons.category,
          'label': 'Others',
          'visible': true,
          'color': null,
        },
      ];

  static const String defaultBudget = '5000';

  @override
  State<HomeScreenCustomization> createState() =>
      _HomeScreenCustomizationState();
}

// Custom class to handle color equality
class CustomColor {
  final Color? color;

  const CustomColor(this.color);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CustomColor) return false;
    if (color == null && other.color == null) return true;
    if (color == null || other.color == null) return false;
    return color!.value == other.color!.value;
  }

  @override
  int get hashCode => color?.value.hashCode ?? 0;

  // Add toString for debugging
  @override
  String toString() => 'CustomColor(${color?.value})';
}

class _HomeScreenCustomizationState extends State<HomeScreenCustomization> {
  final _scrollController = ScrollController();
  final _gridViewKey = GlobalKey();
  final _budgetController = TextEditingController();

  // Update available colors list with your specific colors
  final List<CustomColor> _availableColors = [
    const CustomColor(null), // Default
    const CustomColor(Color.fromARGB(255, 101, 150, 248)), // Blue
    const CustomColor(Color.fromARGB(255, 211, 80, 70)), // Red
    const CustomColor(Color.fromARGB(255, 86, 168, 111)), // Green
    const CustomColor(Color.fromARGB(255, 139, 65, 152)), // Purple
    const CustomColor(Color.fromARGB(255, 215, 136, 18)), // Orange
    const CustomColor(Colors.teal), // Teal
    const CustomColor(Color.fromARGB(255, 190, 48, 95)), // Pink
    const CustomColor(Color.fromARGB(255, 124, 64, 181)), // Deep Purple
  ];

  late List<Map<String, dynamic>> _categories;

  @override
  void initState() {
    super.initState();
    // Initialize with the passed values
    _categories = List<Map<String, dynamic>>.from(widget.initialCategories);
    _budgetController.text = widget.initialBudget;

    // Validate all category colors
    for (var category in _categories) {
      final currentColor = CustomColor(category['color']);
      if (!_availableColors.contains(currentColor)) {
        category['color'] = null;
      }
    }

    // Still load from preferences as fallback
    if (_categories.isEmpty) {
      _loadCustomization();
    }
  }

  Future<void> _loadCustomization() async {
    final prefs = await SharedPreferences.getInstance();
    final String? categoriesJson = prefs.getString('categories');
    final String? budget = prefs.getString('budget');

    if (categoriesJson != null) {
      final List<dynamic> decodedCategories = jsonDecode(categoriesJson);
      setState(() {
        _categories = decodedCategories.map((category) {
          // Convert color from string back to Color object
          Color? color;
          if (category['color'] != null) {
            final colorValue = int.tryParse(category['color']);
            if (colorValue != null) {
              color = Color(colorValue);
            }
          }
          return {
            'icon': IconData(category['icon'], fontFamily: 'MaterialIcons'),
            'label': category['label'],
            'visible': category['visible'],
            'color': color,
          };
        }).toList();
      });
    }

    if (budget != null) {
      _budgetController.text = budget;
    }
  }

  Future<void> _saveCustomization() async {
    final prefs = await SharedPreferences.getInstance();

    // Convert categories to JSON-compatible format
    final List<Map<String, dynamic>> jsonCategories =
        _categories.map((category) {
      return {
        'icon': (category['icon'] as IconData).codePoint,
        'label': category['label'],
        'visible': category['visible'],
        'color': category['color']?.value?.toString(),
      };
    }).toList();

    await prefs.setString('categories', jsonEncode(jsonCategories));
    await prefs.setString('budget', _budgetController.text);
  }

  // Update color names map with your specific colors
  final Map<CustomColor, String> _colorNames = {
    const CustomColor(null): 'Default',
    const CustomColor(Color.fromARGB(255, 101, 150, 248)): 'Blue',
    const CustomColor(Color.fromARGB(255, 211, 80, 70)): 'Red',
    const CustomColor(Color.fromARGB(255, 86, 168, 111)): 'Green',
    const CustomColor(Color.fromARGB(255, 139, 65, 152)): 'Purple',
    const CustomColor(Color.fromARGB(255, 215, 136, 18)): 'Orange',
    const CustomColor(Colors.teal): 'Teal',
    const CustomColor(Color.fromARGB(255, 190, 48, 95)): 'Pink',
    const CustomColor(Color.fromARGB(255, 124, 64, 181)): 'Deep Purple',
  };

  String _getColorName(CustomColor customColor) {
    return _colorNames[customColor] ?? 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Home Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Budget',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              decoration: const InputDecoration(
                prefixText: '\$',
                hintText: 'Enter your monthly budget',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            Text(
              'Category Cards (drag to reorder)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableBuilder(
                scrollController: _scrollController,
                onReorder: (ReorderedListFunction reorderedListFunction) {
                  setState(() {
                    _categories = reorderedListFunction(_categories)
                        as List<Map<String, dynamic>>;
                  });
                },
                children: _categories.map((category) {
                  return _buildCategoryCard(category);
                }).toList(),
                builder: (children) {
                  return GridView(
                    key: _gridViewKey,
                    controller: _scrollController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 12,
                    ),
                    children: children,
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _saveCustomization();
                  if (mounted) {
                    Navigator.pop(context, {
                      'categories': _categories,
                      'budget': _budgetController.text,
                    });
                  }
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return Card(
      key: ValueKey(category['label']),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: category['color'] ??
                      Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Icon(
                        category['icon'],
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 32,
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(
                          category['visible']
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: category['visible']
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey,
                          size: 24,
                        ),
                        onPressed: () {
                          setState(() {
                            category['visible'] = !category['visible'];
                          });
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        category['label'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 32,
              child: _buildColorDropdown(category),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorDropdown(Map<String, dynamic> category) {
    // Create a CustomColor instance for the current category color
    final currentColor = CustomColor(category['color']);

    // Verify the current color exists in available colors
    final validColor = _availableColors.contains(currentColor)
        ? currentColor
        : const CustomColor(null);

    return DropdownButtonHideUnderline(
      child: DropdownButton<CustomColor>(
        value: validColor,
        isDense: true,
        isExpanded: true,
        hint: const Text('Default Color'),
        items: _availableColors.map((CustomColor customColor) {
          return DropdownMenuItem<CustomColor>(
            value: customColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: customColor.color ??
                        Theme.of(context).colorScheme.surface,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _getColorName(customColor),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: (CustomColor? newCustomColor) {
          setState(() {
            category['color'] = newCustomColor?.color;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
