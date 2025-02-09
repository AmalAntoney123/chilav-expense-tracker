import 'package:flutter/material.dart';

class HomeScreenCustomization extends StatefulWidget {
  const HomeScreenCustomization({super.key});

  @override
  State<HomeScreenCustomization> createState() =>
      _HomeScreenCustomizationState();
}

class _HomeScreenCustomizationState extends State<HomeScreenCustomization> {
  final _budgetController = TextEditingController();
  List<Map<String, dynamic>> _categories = [
    {
      'icon': Icons.shopping_bag,
      'label': 'Shopping',
      'visible': true,
      'color': null
    },
    {
      'icon': Icons.restaurant,
      'label': 'Food',
      'visible': true,
      'color': Colors.deepPurple
    },
    {
      'icon': Icons.directions_car,
      'label': 'Transport',
      'visible': true,
      'color': null
    },
    {
      'icon': Icons.movie,
      'label': 'Entertainment',
      'visible': true,
      'color': null
    },
    {
      'icon': Icons.receipt_long,
      'label': 'Bills',
      'visible': true,
      'color': Colors.blue
    },
    {
      'icon': Icons.medical_services,
      'label': 'Health',
      'visible': true,
      'color': null
    },
    {
      'icon': Icons.school,
      'label': 'Education',
      'visible': true,
      'color': null
    },
    {'icon': Icons.category, 'label': 'Others', 'visible': true, 'color': null},
  ];

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
              child: ReorderableListView.builder(
                itemCount: _categories.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _categories.removeAt(oldIndex);
                    _categories.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Card(
                    key: ValueKey(category['label']),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Icon(Icons.drag_handle),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.5,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                      category['color'] ?? colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  children: [
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: Icon(
                                        category['icon'],
                                        color: colorScheme.onSurface,
                                        size: 32,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.topRight,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: category['color'] ==
                                                  colorScheme.tertiary
                                              ? Colors.white
                                              : Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                        padding: EdgeInsets.all(5),
                                        child: Icon(
                                          Icons.arrow_outward,
                                          color: category['color'] ==
                                                  colorScheme.tertiary
                                              ? Colors.black
                                              : Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomLeft,
                                      child: Text(
                                        category['label'],
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: Icon(
                              category['visible']
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: category['visible']
                                  ? Colors.blue
                                  : Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                category['visible'] = !category['visible'];
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Save changes and update home screen
                  Navigator.pop(context, {
                    'categories': _categories,
                    'budget': _budgetController.text,
                  });
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }
}
