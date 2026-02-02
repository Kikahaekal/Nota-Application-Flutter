class ProductModel {
  final String id;
  final String name;
  final int price;
  final String category;

  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
  });

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      name: map['name'] ?? 'Tanpa Nama',
      price: map['price'] ?? 0,
      category: map['category'] ?? 'Produk Lain',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'category': category,
    };
  }
}