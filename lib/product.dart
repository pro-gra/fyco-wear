import 'package:flutter/material.dart';

class ProductColorOption {
  final String name;
  final Color previewColor;

  const ProductColorOption({
    required this.name,
    required this.previewColor,
  });
}

class Product {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final double priceMad;
  final String imageUrl;
  final List<String> sizes;
  final List<ProductColorOption> colors;

  const Product({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.priceMad,
    required this.imageUrl,
    required this.sizes,
    required this.colors,
  });
}