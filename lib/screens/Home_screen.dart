import 'package:flutter/material.dart';
import 'package:ideamagix_assign/screens/products_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pie_chart/pie_chart.dart';
import 'category_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, double> categoryData = {};
  List<String> categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCategories = prefs.getStringList('categories') ?? [];

    final Map<String, double> data = {};
    for (var category in storedCategories) {
      final products = prefs.getStringList(category) ?? [];
      data[category] = products.length.toDouble();
    }

    setState(() {
      categories = storedCategories;
      categoryData = data;
    });
  }

  Future<void> _logUserAction(String action) async {
    final prefs = await SharedPreferences.getInstance();
    final userActions = prefs.getStringList('user_actions') ?? [];

    final now = DateTime.now();
    final timestamp = '${now.day}-${now.month}-${now.year} ${now.hour}:${now.minute}:${now.second}';

    final logEntry = '$timestamp: $action';

    userActions.add(logEntry);
    await prefs.setStringList('user_actions', userActions);
  }



  Future<void> _addNewCategory() async {
    final newCategory = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add New Category'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter category name'),
          ),
          actions: [
            TextButton(
              onPressed: () async{
                Navigator.of(context).pop(controller.text);
                await _logUserAction('Created a Category name: ("${controller.text}")');
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (newCategory != null && newCategory.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final storedCategories = prefs.getStringList('categories') ?? [];
      storedCategories.add(newCategory);
      await prefs.setStringList('categories', storedCategories);
      await prefs.setStringList(newCategory, []);

      setState(() {
        categories.add(newCategory);
        categoryData[newCategory] = 0; // Initialize with zero products
      });
    }
  }

  Future<void> _deleteCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCategories = prefs.getStringList('categories') ?? [];
    storedCategories.remove(category);
    await prefs.setStringList('categories', storedCategories);
    await prefs.remove(category);
    await _logUserAction('Deleted Category name: ("${category}")');

    setState(() {
      categories.remove(category);
      categoryData.remove(category);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to the HistoryScreen when the icon is tapped
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ActionHistoryScreen()),
              );
            },
          ),
        ],
        title: const Text('Beauty Store Inventory'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: categoryData.isEmpty
                  ? const Center(child: Text('No data available'))
                  : PieChart(
                dataMap: categoryData,
                chartType: ChartType.ring,
                colorList: const [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple],
                legendOptions: const LegendOptions(
                  showLegends: true,
                  legendPosition: LegendPosition.right,
                ),
                chartValuesOptions: const ChartValuesOptions(
                  showChartValues: true,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(categoryData.isNotEmpty?
              'Categories':'',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10.0,
                  mainAxisSpacing: 10.0,
                  childAspectRatio: 1.5, // Adjust this for box aspect ratio
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final productCount = categoryData[category]?.toInt() ?? 0;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductListScreen(category: category),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(8.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '$category ($productCount)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 1,
                            right: 1,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmationDialog(category);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCategorySelectionDialog(context);
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategorySelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CategorySelectionDialog(
        categories: categories,
        onAddCategory: _addNewCategory,
      ),
    );
  }

  void _showDeleteConfirmationDialog(String category) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Are you sure you want to delete the category "$category"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCategory(category);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class CategorySelectionDialog extends StatefulWidget {
  final List<String> categories;
  final Future<void> Function() onAddCategory;

  CategorySelectionDialog({required this.categories, required this.onAddCategory});

  @override
  _CategorySelectionDialogState createState() => _CategorySelectionDialogState();
}

class _CategorySelectionDialogState extends State<CategorySelectionDialog> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select a Category'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...widget.categories.map((category) {
            return ListTile(
              title: Text(category),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(category: category),
                  ),
                );
              },
            );
          }).toList(),
          ListTile(
            title: const Text('Add New Category'),
            onTap: () {
              Navigator.of(context).pop();
              widget.onAddCategory();
            },
          ),
        ],
      ),
    );
  }
}
