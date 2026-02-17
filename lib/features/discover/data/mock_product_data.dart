import 'package:swipe/features/discover/domain/entities/product.dart';

/// Mock Product Data for testing the discover feed
/// TODO: Replace with real API data
class MockProductData {
  static List<Product> getMockProducts() {
    return [
      Product(
        id: '1',
        brand: 'ZARA',
        title: 'Floral Summer Dress',
        description:
            'Beautiful floral print dress perfect for summer occasions',
        price: 450000,
        images: [
          'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=800',
          'https://images.unsplash.com/photo-1612336307429-8a898d10e223?w=800',
        ],
        rating: 4.5,
        reviewCount: 127,
        category: 'Dresses',
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['Blue', 'Pink', 'White'],
        isNew: true,
        fitMatch: 'Perfect fit for your size!',
        styleMatch: 'Matches your style',
        inStock: true,
      ),
      Product(
        id: '2',
        brand: 'H&M',
        title: 'Classic White Sneakers',
        description: 'Comfortable casual sneakers for everyday wear',
        price: 350000,
        images: [
          'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=800',
        ],
        rating: 4.8,
        reviewCount: 234,
        category: 'Shoes',
        sizes: ['38', '39', '40', '41', '42'],
        colors: ['White'],
        fitMatch: 'True to size',
        inStock: true,
      ),
      Product(
        id: '3',
        brand: 'MANGO',
        title: 'Leather Crossbody Bag',
        description: 'Elegant leather bag with adjustable strap',
        price: 750000,
        originalPrice: 950000,
        discountPercentage: 21,
        images: [
          'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=800',
        ],
        rating: 4.6,
        reviewCount: 89,
        category: 'Bags',
        colors: ['Black', 'Brown', 'Beige'],
        styleMatch: 'Complements your wardrobe',
        inStock: true,
      ),
      Product(
        id: '4',
        brand: 'UNIQLO',
        title: 'Oversized Denim Jacket',
        description: 'Trendy oversized denim jacket with vintage wash',
        price: 550000,
        images: [
          'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=800',
        ],
        rating: 4.7,
        reviewCount: 156,
        category: 'Jackets',
        sizes: ['S', 'M', 'L'],
        colors: ['Light Blue', 'Dark Blue'],
        isNew: true,
        fitMatch: 'Oversized fit as intended',
        styleMatch: 'Trending in your preferences',
        inStock: true,
      ),
      Product(
        id: '5',
        brand: 'MASSIMO DUTTI',
        title: 'Linen Wide-Leg Pants',
        description: 'Comfortable linen pants with wide-leg silhouette',
        price: 650000,
        images: [
          'https://images.unsplash.com/photo-1594633313593-bab3825d0caf?w=800',
        ],
        rating: 4.4,
        reviewCount: 78,
        category: 'Pants',
        sizes: ['XS', 'S', 'M', 'L'],
        colors: ['Beige', 'White', 'Black'],
        inStock: true,
      ),
      Product(
        id: '6',
        brand: 'PULL&BEAR',
        title: 'Graphic Print T-Shirt',
        description: 'Casual cotton t-shirt with artistic graphic print',
        price: 180000,
        images: [
          'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800',
        ],
        rating: 4.3,
        reviewCount: 312,
        category: 'T-Shirts',
        sizes: ['S', 'M', 'L', 'XL'],
        colors: ['White', 'Black', 'Gray'],
        styleMatch: 'Fits your casual style',
        inStock: true,
      ),
      Product(
        id: '7',
        brand: 'BERSHKA',
        title: 'High-Waist Mom Jeans',
        description: 'Classic mom jeans with high waist and relaxed fit',
        price: 420000,
        images: [
          'https://images.unsplash.com/photo-1542272454315-7f6f6c1f37c6?w=800',
        ],
        rating: 4.6,
        reviewCount: 198,
        category: 'Jeans',
        sizes: ['26', '28', '30', '32'],
        colors: ['Blue'],
        fitMatch: 'Perfect for your body type',
        inStock: true,
      ),
      Product(
        id: '8',
        brand: 'STRADIVARIUS',
        title: 'Satin Midi Skirt',
        description: 'Elegant satin skirt with midi length',
        price: 380000,
        images: [
          'https://images.unsplash.com/photo-1583496661160-fb5886a0aaaa?w=800',
        ],
        rating: 4.5,
        reviewCount: 134,
        category: 'Skirts',
        sizes: ['XS', 'S', 'M', 'L'],
        colors: ['Black', 'Burgundy', 'Emerald'],
        styleMatch: 'Elegant choice for you',
        inStock: true,
      ),
      Product(
        id: '9',
        brand: 'COS',
        title: 'Minimalist Blazer',
        description: 'Structured blazer with clean lines and modern fit',
        price: 890000,
        images: [
          'https://images.unsplash.com/photo-1591369822096-ffd140ec948f?w=800',
        ],
        rating: 4.8,
        reviewCount: 95,
        category: 'Blazers',
        sizes: ['S', 'M', 'L'],
        colors: ['Black', 'Navy', 'Beige'],
        isNew: true,
        fitMatch: 'Tailored to perfection',
        styleMatch: 'Professional look you love',
        inStock: true,
      ),
      Product(
        id: '10',
        brand: '& OTHER STORIES',
        title: 'Knit Cardigan',
        description: 'Cozy knit cardigan with button closure',
        price: 580000,
        images: [
          'https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=800',
        ],
        rating: 4.7,
        reviewCount: 167,
        category: 'Knitwear',
        sizes: ['XS', 'S', 'M', 'L', 'XL'],
        colors: ['Cream', 'Gray', 'Camel'],
        styleMatch: 'Cozy and chic',
        inStock: true,
      ),
    ];
  }

  /// Get a single product by ID
  static Product? getProductById(String id) {
    try {
      return getMockProducts().firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get products by category
  static List<Product> getProductsByCategory(String category) {
    return getMockProducts()
        .where((product) => product.category == category)
        .toList();
  }

  /// Get new arrivals
  static List<Product> getNewArrivals() {
    return getMockProducts().where((product) => product.isNew).toList();
  }
}
