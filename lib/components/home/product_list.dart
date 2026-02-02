import 'package:flutter/material.dart';
import 'package:nota_app/models/product_model.dart';
import 'package:nota_app/services/database_service.dart';

class ProductList extends StatefulWidget {
  const ProductList({super.key});

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  String _selectedCategory = 'Semua';
  final List<String> _categories = ['Semua', 'Roti', 'Produk Lain'];

  String _formatCurrency(int price) {
    return "Rp ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Column(
      children: [
        Container(
          height: 50,
          margin: const EdgeInsets.only(top: 16, bottom: 8),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFA5CF61) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFA5CF61), width: 1.5),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFA5CF61),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: dbService.getProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("Belum ada produk"));
              }

              final allProducts = snapshot.data!;
              final filteredProducts = _selectedCategory == 'Semua'
                  ? allProducts
                  : allProducts.where((p) => p.category == _selectedCategory).toList();

              if (filteredProducts.isEmpty) {
                return Center(child: Text("Kosong di kategori $_selectedCategory"));
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return ProductCard(
                    productName: product.name,
                    price: _formatCurrency(product.price),
                    category: product.category,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final String productName;
  final String price;
  final String category;

  const ProductCard({
    super.key,
    required this.productName,
    required this.price,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    IconData getIcon() {
      if (category == 'Roti') return Icons.bakery_dining;
      return Icons.inventory_2;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFA5CF61).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            getIcon(),
            color: const Color(0xFFA5CF61),
            size: 30,
          ),
        ),
        title: Text(
          productName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(price, style: const TextStyle(color: Color(0xFFA5CF61), fontWeight: FontWeight.w600)),
            Text(category, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}