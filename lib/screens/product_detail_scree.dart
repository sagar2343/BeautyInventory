import 'dart:convert';
import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  final String title;
  final String description;
  final String imageBase64;
  final String weight;
  final String quantity;

  const ProductDetailScreen({
    Key? key,
    required this.title,
    required this.description,
    required this.imageBase64,
    required this.weight,
    required this.quantity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Decode image safely, handle null or empty base64 string
    final image = base64Decode(imageBase64.isNotEmpty ? imageBase64 : "");

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15.0),
                  child: Image.memory(
                    image,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Error loading image'); // Fallback if image fails to load
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Weight: ${weight.isNotEmpty ? weight : 'N/A'}', // Handle potential null values
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Quantity: ${quantity.isNotEmpty ? quantity : 'N/A'}', // Handle potential null values
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
