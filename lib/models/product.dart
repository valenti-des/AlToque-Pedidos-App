import 'package:flutter/material.dart';

class Product {
  Product({
    this.id,
    this.name = '',
    this.description = '',
    this.price = '',
    this.category = '',
    this.emoji = '',
    this.color = Colors.white,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final color = json['color'] as String;
    final price = (json['price'] as num).toInt().toString();
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      price:
          '\$ ${price.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}',
      category: json['category'] as String,
      emoji: json['emoji'] as String,
      color: Color(int.parse(color.substring(1), radix: 16) | 0xFF000000),
    );
  }

  final int? id;
  String name;
  String description;
  String price;
  String category;
  String emoji;
  Color color;
}
