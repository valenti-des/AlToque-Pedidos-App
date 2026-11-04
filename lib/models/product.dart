import 'package:flutter/material.dart';

class Product {
  Product({
    this.name = '',
    this.description = '',
    this.price = '',
    this.category = '',
    this.emoji = '',
    this.color = Colors.white,
  });

  String name;
  String description;
  String price;
  String category;
  String emoji;
  Color color;
}
