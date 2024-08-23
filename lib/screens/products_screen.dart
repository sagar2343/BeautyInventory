import 'package:flutter/material.dart';
import 'package:ideamagix_assign/screens/product_detail_scree.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'category_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String category;

  const ProductListScreen({Key? key, required this.category}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final productJsons = prefs.getStringList(widget.category) ?? [];

    setState(() {
      _products = productJsons
          .map((json) => jsonDecode(json))
          .cast<Map<String, dynamic>>()
          .toList();
    });
  }

  Future<void> _deleteProduct(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final productJsons = prefs.getStringList(widget.category) ?? [];

    productJsons.removeAt(index);
    await prefs.setStringList(widget.category, productJsons);

    setState(() {
      _products.removeAt(index);
    });

    _showMessage('Product deleted successfully!');
  }

  Future<void> _editProduct(int index) async {
    final product = _products[index];

    // Show a dialog to edit the product
    final updatedProduct = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: product['title']),
              decoration: const InputDecoration(labelText: 'Product Title'),
              onChanged: (value) => product['title'] = value,
            ),
            TextField(
              controller: TextEditingController(text: product['description']),
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) => product['description'] = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(product);
            },
            child: const Text('Save'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(null);
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (updatedProduct != null) {
      final prefs = await SharedPreferences.getInstance();
      final productJsons = prefs.getStringList(widget.category) ?? [];

      productJsons[index] = jsonEncode(updatedProduct);
      await prefs.setStringList(widget.category, productJsons);

      setState(() {
        _products[index] = updatedProduct;
      });

      _showMessage('Product updated successfully!');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryScreen(category: widget.category),
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text('${widget.category} Products'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _products.isEmpty
          ? const Center(child: Text('No products available'))
          : ListView.builder(
        itemCount: _products.length,
        itemBuilder: (context, index) {
          final product = _products[index];
          return ListTile(
            title: Text(product['title'] ?? 'No Title'),
            subtitle: Text(product['description'] ?? 'No Description'),
            leading: product['image'] != null
                ? Image.memory(
              base64Decode(product['image']),
              height: 50,
              width: 50,
              fit: BoxFit.cover,
            )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editProduct(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteProduct(index),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    title: product['title'],
                    description: product['description'],
                    imageBase64: product['image'],
                    weight: product['weight'],  // Pass the weight
                    quantity: product['quantity'],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
