import 'package:flutter/material.dart';
import 'package:ideamagix_assign/screens/products_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pie_chart/pie_chart.dart';
import 'category_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'dart:io'; // Add this import for image file handling
import 'package:image_picker/image_picker.dart'; // Add this import for image picking

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, double> categoryData = {};
  List<Map<String, dynamic>> categories = [];
  int registeredUsersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
    _getRegisteredUsersCount();
  }

  Future<void> _loadCategoryData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCategories = prefs.getStringList('categories') ?? [];

    final List<Map<String, dynamic>> data = [];
    for (var category in storedCategories) {
      final products = prefs.getStringList(category) ?? [];
      final imageUrl = prefs.getString('${category}_image') ?? '';
      data.add({
        'name': category,
        'image': imageUrl,
        'productCount': products.length.toDouble(),
      });
    }

    setState(() {
      categories = data;
      categoryData = Map.fromIterable(data, key: (e) => e['name'], value: (e) => e['productCount']);
    });
  }

  Future<void> _getRegisteredUsersCount() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    int count = 0;
    for (var key in keys) {
      if (prefs.containsKey(key) && key.contains('@')) { // Assuming email contains '@'
        count++;
      }
    }
    setState(() {
      registeredUsersCount = count;
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
    final nameController = TextEditingController();
    final picker = ImagePicker();
    XFile? pickedImage;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Enter category name'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(pickedImage != null ? pickedImage!.name : 'No image selected'),
                  IconButton(
                    icon: const Icon(Icons.image),
                    onPressed: () async {
                      pickedImage = await picker.pickImage(source: ImageSource.gallery);
                      setState(() {}); // Refresh dialog state to show the selected image name
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final name = nameController.text;
                if (name.isNotEmpty && pickedImage != null) {
                  final prefs = await SharedPreferences.getInstance();
                  final storedCategories = prefs.getStringList('categories') ?? [];
                  storedCategories.add(name);
                  await prefs.setStringList('categories', storedCategories);
                  await prefs.setString('${name}_image', pickedImage!.path); // Save the image path
                  await prefs.setStringList(name, []);

                  await _logUserAction('Created a Category with name: "$name" and image: "${pickedImage!.name}"');

                  setState(() {
                    categories.add({
                      'name': name,
                      'image': pickedImage!.path,
                      'productCount': 0.0,
                    });
                    categoryData[name] = 0; // Initialize with zero products
                  });
                }
                Navigator.of(context).pop();
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
  }


  Future<void> _deleteCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final storedCategories = prefs.getStringList('categories') ?? [];
    storedCategories.remove(category);
    await prefs.setStringList('categories', storedCategories);
    await prefs.remove(category);
    await prefs.remove('${category}_image');
    await _logUserAction('Deleted Category with name: "$category"');

    setState(() {
      categories.removeWhere((item) => item['name'] == category);
      categoryData.remove(category);
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all data from SharedPreferences
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginScreen()), // Replace with your login screen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ActionHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
        title: Text('Users: $registeredUsersCount'),
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
            Text(categoryData.isNotEmpty
                ? 'Categories'
                : '',
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
                  final productCount = category['productCount']?.toInt() ?? 0;
                  final imageUrl = category['image'] as String;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductListScreen(category: category['name']),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: FileImage(File(imageUrl)), // Use FileImage to load the image
                          fit: BoxFit.cover,
                        ),
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
                              '${category['name']} ($productCount)',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                backgroundColor: Colors.black54, // To make text more readable
                              ),
                            ),
                          ),
                          // Positioned(
                          //   top: 1,
                          //   right: 25,
                          //   child: IconButton(
                          //     icon: const Icon(Icons.edit, color: Colors.white),
                          //     onPressed: () {
                          //
                          //     },
                          //   ),
                          // ),
                          Positioned(
                            top: 1,
                            right: 1,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteCategory(category['name']);
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addNewCategory,
              child: const Text('Add Category'),
            ),
          ],
        ),
      ),
    );
  }
}
