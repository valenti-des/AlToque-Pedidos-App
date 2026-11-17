enum CategoriaProducto {
  comidas('Comidas'),
  bebidas('Bebidas'),
  snacks('Snacks');

  const CategoriaProducto(this.label);

  final String label;

  static CategoriaProducto fromJson(Object? value) {
    if (value is! String) {
      throw const FormatException('La categoría del producto es inválida.');
    }
    return switch (value.trim().toLowerCase()) {
      'comidas' => CategoriaProducto.comidas,
      'bebidas' => CategoriaProducto.bebidas,
      'snacks' || 'dulces' => CategoriaProducto.snacks,
      _ => throw FormatException('Categoría de producto desconocida: $value'),
    };
  }
}

class Producto {
  const Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    this.imagenUrl,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    final id = json['id'] ?? json['productId'];
    final nombre = json['name'] ?? json['nombre'];
    final categoria = json['category'] ?? json['categoria'];
    final precio = json['price'] ?? json['precio'];
    final imagenUrl = json['imageUrl'] ?? json['imagenUrl'];
    if (id is! int || nombre is! String || precio is! num) {
      throw const FormatException('Los datos del producto son inválidos.');
    }
    if (imagenUrl != null && imagenUrl is! String) {
      throw const FormatException('La imagen del producto es inválida.');
    }
    return Producto(
      id: id,
      nombre: nombre,
      categoria: CategoriaProducto.fromJson(categoria),
      precio: precio.toDouble(),
      imagenUrl: imagenUrl as String?,
    );
  }

  final int id;
  final String nombre;
  final CategoriaProducto categoria;
  final double precio;
  final String? imagenUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': nombre,
    'category': categoria.label,
    'price': precio,
    'imageUrl': imagenUrl,
  };
}
