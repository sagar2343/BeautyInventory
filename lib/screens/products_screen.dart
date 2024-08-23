import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ideamagix_assign/screens/product_detail_scree.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'category_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String category;

  const ProductListScreen({Key? key, required this.category}) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Map<String, dynamic>> _products = [];
  final ImagePicker _picker = ImagePicker();

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
    final updatedProduct = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditProductDialog(product: product),
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
                    sku: product['sku'],
                    dimension: product['dimension'],
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

class EditProductDialog extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductDialog({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductDialogState createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _skuController;
  late TextEditingController _weightController;
  late TextEditingController _quantityController;
  late TextEditingController _dimensionController;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product['title']);
    _descriptionController = TextEditingController(text: widget.product['description']);
    _skuController = TextEditingController(text: widget.product['sku']);
    _weightController = TextEditingController(text: widget.product['weight']?.toString());
    _quantityController = TextEditingController(text: widget.product['quantity']?.toString());
    _dimensionController = TextEditingController(text: widget.product['dimension']);
    if (widget.product['image'] != null) {
      _image = File.fromUri(Uri.parse(widget.product['image']));
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final croppedFile = await _cropImage(File(pickedFile.path));
      if (croppedFile != null) {
        final compressedFile = await _compressImage(croppedFile);
        setState(() {
          _image = compressedFile;
        });
      }
    }
  }

  Future<File?> _cropImage(File file) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
          ],
        ),
      ],
    );
    return croppedFile != null ? File(croppedFile.path) : null;
  }

  Future<File> _compressImage(File file) async {
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      file.path,
      '${file.parent.path}/compressed_${file.uri.pathSegments.last}',
      quality: 80,
    );
    return compressedFile!;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _image == null
                ? Image.file(
              _image!,
              height: 100,
              width: 100,
              fit: BoxFit.cover,
            )
                : const Icon(Icons.person),
            TextButton(
              onPressed: _pickImage,
              child: const Text('Select Image'),
            ),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Product Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _skuController,
              decoration: const InputDecoration(labelText: 'SKU'),
            ),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Weight'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _dimensionController,
              decoration: const InputDecoration(labelText: 'Dimension'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final updatedProduct = {
              'title': _titleController.text,
              'description': _descriptionController.text,
              'sku': _skuController.text,
              'weight': _weightController.text.isNotEmpty ? double.parse(_weightController.text) : null,
              'quantity': _quantityController.text.isNotEmpty ? int.parse(_quantityController.text) : null,
              'dimension': _dimensionController.text,
              'image': _image != null ? base64Encode(_image!.readAsBytesSync()) : widget.product['image'],
            };

            Navigator.of(context).pop(updatedProduct);
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
    );
  }
}
