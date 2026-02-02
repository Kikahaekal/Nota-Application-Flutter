import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nota_app/models/product_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Nama Collection di Firebase
  final String _collectionRef = 'products';

  Stream<List<ProductModel>> getProducts() {
    return _db.collection(_collectionRef).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        // Mengubah data JSON dari Firebase menjadi object ProductModel
        return ProductModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await _db.collection(_collectionRef).add(product.toMap());
    } catch (e) {
      print("Error menambah produk: $e");
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection(_collectionRef).doc(productId).delete();
    } catch (e) {
      print("Error menghapus produk: $e");
      rethrow;
    }
  }
}