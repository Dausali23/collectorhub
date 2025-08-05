class ProductModel {
  final String id;
  final String name;
  final double price;
  final String description;
  final String sellerId;
  
  ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.sellerId,
  });
  
  factory ProductModel.fromMap(Map<String, dynamic> data, String id) {
    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      sellerId: data['sellerId'] ?? '',
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'sellerId': sellerId,
    };
  }
} 