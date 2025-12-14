import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../config/theme.dart';
import '../../config/app_config.dart';
import '../../models/product.dart';
import '../../utils/helpers.dart';
import '../product/product_detail_screen.dart';
import '../product/product_list_screen.dart';
import '../../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Skip API initialization in demo mode - data is already loaded
    if (!AppConfig.isDemoMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductProvider>().initialize();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BuyWater'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProductListScreen(isSearch: true),
                ),
              );
            },
          ),
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.secondaryColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          cart.itemCount.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (!AppConfig.isDemoMode) {
            await context.read<ProductProvider>().initialize();
          }
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner carousel
              _buildBannerCarousel(),

              // Categories
              _buildCategoriesSection(),

              // Featured products
              _buildFeaturedSection(),

              // All products
              _buildAllProductsSection(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
    final banners = [
      {'color': AppTheme.primaryColor, 'title': 'Welcome to BuyWater', 'subtitle': 'Fresh water delivered to you'},
      {'color': AppTheme.secondaryColor, 'title': 'Free Delivery', 'subtitle': 'On orders over \$10,000'},
      {'color': AppTheme.accentColor, 'title': 'Premium Quality', 'subtitle': 'Water dispensers & accessories'},
    ];

    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: banners.length,
        controller: PageController(viewportFraction: 0.92),
        itemBuilder: (context, index) {
          final banner = banners[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: banner['color'] as Color,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner['title'] as String,
                    style: TextStyle(
                      color: index == 1 ? Colors.black : Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    banner['subtitle'] as String,
                    style: TextStyle(
                      color: index == 1 ? Colors.black87 : Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Categories', style: AppTheme.heading3),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListScreen(),
                        ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: provider.categories.length,
                itemBuilder: (context, index) {
                  final category = provider.categories[index];
                  return _buildCategoryItem(category);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryItem(Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductListScreen(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getCategoryIcon(category.name),
                color: AppTheme.primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    // Water-related categories
    if (name.contains('bottled') || name.contains('water')) return Icons.water_drop;
    if (name.contains('gallon') || name.contains('jug')) return Icons.local_drink;
    if (name.contains('dispenser')) return Icons.water;
    if (name.contains('filter')) return Icons.filter_alt;
    if (name.contains('accessor')) return Icons.settings;
    if (name.contains('ice')) return Icons.ac_unit;
    // General categories
    if (name.contains('electronic')) return Icons.devices;
    if (name.contains('cloth') || name.contains('fashion')) return Icons.checkroom;
    if (name.contains('home')) return Icons.home;
    if (name.contains('sport')) return Icons.sports_soccer;
    if (name.contains('book')) return Icons.book;
    if (name.contains('toy')) return Icons.toys;
    if (name.contains('beauty')) return Icons.face;
    if (name.contains('food') || name.contains('grocery')) return Icons.local_grocery_store;
    return Icons.category;
  }

  Widget _buildFeaturedSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.featuredProducts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Featured', style: AppTheme.heading3),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListScreen(
                            title: 'Featured Products',
                            featured: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 260,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: provider.featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = provider.featuredProducts[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(productId: product.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAllProductsSection() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('All Products', style: AppTheme.heading3),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProductListScreen(),
                        ),
                      );
                    },
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            if (provider.isLoading && provider.products.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (provider.products.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No products available'),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: provider.products.length > 6 ? 6 : provider.products.length,
                itemBuilder: (context, index) {
                  final product = provider.products[index];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(productId: product.id),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
