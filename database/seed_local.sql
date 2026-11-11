USE al_toque;

INSERT INTO usuarios (nombre_usuario, contrasena_hash)
VALUES ('pedido_local', SHA2(UUID(), 256))
ON DUPLICATE KEY UPDATE nombre_usuario = VALUES(nombre_usuario);

INSERT INTO categorias (nombre)
VALUES ('Comidas'), ('Bebidas'), ('Dulces')
ON DUPLICATE KEY UPDATE nombre = VALUES(nombre);

INSERT INTO productos
  (categoria_id, nombre, descripcion, precio, emoji, color)
SELECT c.id, p.nombre, p.descripcion, p.precio, p.emoji, p.color
FROM (
  SELECT 'Comidas' AS categoria, 'Hamburguesa completa' AS nombre,
    'Carne, queso, tomate y lechuga' AS descripcion, 5500.00 AS precio,
    '🍔' AS emoji, '#FFE7D1' AS color
  UNION ALL SELECT 'Comidas', 'Hamburguesa simple', 'Pan y carne',
    4000.00, '🥪', '#FFE8B8'
  UNION ALL SELECT 'Comidas', 'Papas con cheddar',
    'Papas crocantes con cheddar', 3800.00, '🍟', '#FFF0C2'
  UNION ALL SELECT 'Comidas', 'Tostado de jamón y queso',
    'Pan dorado, jamón y queso', 3200.00, '🥪', '#FFE8B8'
  UNION ALL SELECT 'Comidas', 'Empanadas', 'Carne suave o jamón y queso',
    2800.00, '🥟', '#FFE3D8'
  UNION ALL SELECT 'Bebidas', 'Gaseosa', 'Lata de 354 ml',
    1800.00, '🥤', '#DDF2FF'
  UNION ALL SELECT 'Bebidas', 'Agua mineral', 'Botella de 500 ml',
    1200.00, '💧', '#E0F4F4'
  UNION ALL SELECT 'Dulces', 'Alfajor de chocolate',
    'Relleno de dulce de leche', 1500.00, '🍫', '#F2E1D8'
  UNION ALL SELECT 'Dulces', 'Medialunas (2 unidades)',
    'Recién horneadas', 1600.00, '🥐', '#FFEBC9'
) AS p
JOIN categorias c ON c.nombre = p.categoria
WHERE NOT EXISTS (
  SELECT 1 FROM productos existing WHERE existing.nombre = p.nombre
);
