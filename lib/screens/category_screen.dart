import 'dart:convert'; // For JSON encoding and decoding
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ideamagix_assign/sharedPreference/helper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_cropper/image_cropper.dart';
import 'Home_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String category;

  CategoryScreen({required this.category});

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Products'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _image == null
                  ? Container(
                color: Colors.grey[200],
                height: 150,
                width: double.infinity,
                child: Center(
                  child: Text(
                    'No image selected.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
                  : Image.file(
                _image!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _showImageSourceDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Select Image',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Product Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'Upload Product',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

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
            CropAspectRatioPresetCustom(),
          ],
        ),
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPresetCustom(),
          ],
        ),
        WebUiSettings(
          context: context,
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

  Future<void> _uploadProduct() async {
    final title = _titleController.text;
    final description = _descriptionController.text;

    if (_image == null || title.isEmpty || description.isEmpty) {
      _showMessage('Please fill in all fields and select an image.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final categoryProducts = prefs.getStringList(widget.category) ?? [];

    final imageBytes = await _image!.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final product = {
      'title': title,
      'description': description,
      'image': base64Image,
    };

    categoryProducts.add(jsonEncode(product));
    await prefs.setStringList(widget.category, categoryProducts);

    _showMessage('Product uploaded successfully!');
    await logUserAction('Uploaded a product ("$title") in category ("${widget.category}")');

    _clearFields();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomeScreen()));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _clearFields() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _image = null;
    });
  }
}

Future<void> logUserAction(String action) async {
  final prefs = await SharedPreferences.getInstance();
  final userActions = prefs.getStringList('user_actions') ?? [];

  final now = DateTime.now();
  final timestamp = '${now.day}-${now.month}-${now.year} ${now.hour}:${now.minute}';

  final logEntry = '$timestamp: $action';

  userActions.add(logEntry);
  await prefs.setStringList('user_actions', userActions);
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}