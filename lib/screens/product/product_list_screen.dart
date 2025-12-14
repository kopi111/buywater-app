import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/product_provider.dart';
import '../../config/theme.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ProductListScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  final String? title;
  final bool featured;
  final bool isSearch;

  const ProductListScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    this.title,
    this.featured = false,
    this.isSearch = false,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    if (widget.categoryId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ProductProvider>().filterByCategory(widget.categoryId);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().loadMoreProducts();
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort By', style: AppTheme.heading3),
            const SizedBox(height: 16),
            _buildSortOption('Newest', 'created_at', 'desc'),
            _buildSortOption('Price: Low to High', 'price', 'asc'),
            _buildSortOption('Price: High to Low', 'price', 'desc'),
            _buildSortOption('Most Popular', 'rating', 'desc'),
            _buildSortOption('Name: A-Z', 'name', 'asc'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String sortBy, String sortOrder) {
    final isSelected = _sortBy == sortBy && _sortOrder == sortOrder;
    return ListTile(
      title: Text(label),
      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryColor) : null,
      onTap: () {
        setState(() {
          _sortBy = sortBy;
          _sortOrder = sortOrder;
        });
        context.read<ProductProvider>().setSortOptions(
              sortBy: sortBy,
              sortOrder: sortOrder,
            );
        Navigator.pop(context);
      },
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => _FilterSheet(
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.isSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                onSubmitted: (query) {
                  context.read<ProductProvider>().searchProducts(query);
                },
              )
            : Text(widget.title ?? widget.categoryName ?? 'Products'),
        actions: [
          if (widget.isSearch)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                context.read<ProductProvider>().searchProducts(
                      _searchController.text,
                    );
              },
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortOptions,
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterOptions,
            ),
          ],
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          final products = widget.isSearch && provider.isSearching
              ? provider.searchResults
              : provider.products;

          if (provider.isLoading && products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isSearch ? Icons.search_off : Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isSearch
                        ? 'No products found'
                        : 'No products available',
                    style: AppTheme.bodyLarge,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Results count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${products.length} products',
                      style: AppTheme.bodySmall,
                    ),
                    if (provider.selectedCategoryId != null || widget.isSearch)
                      TextButton(
                        onPressed: () {
                          if (widget.isSearch) {
                            _searchController.clear();
                            provider.clearSearch();
                          } else {
                            provider.clearFilters();
                          }
                        },
                        child: const Text('Clear'),
                      ),
                  ],
                ),
              ),
              // Products grid
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: products.length + (provider.isLoadingMore ? 2 : 0),
                  itemBuilder: (context, index) {
                    if (index >= products.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }

                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(
                              productId: product.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final ScrollController scrollController;

  const _FilterSheet({required this.scrollController});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _selectedCategoryId;
  RangeValues _priceRange = const RangeValues(0, 100000);

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProductProvider>();
    _selectedCategoryId = provider.selectedCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filters', style: AppTheme.heading3),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategoryId = null;
                    _priceRange = const RangeValues(0, 100000);
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              children: [
                // Categories
                const Text('Category', style: AppTheme.bodyLarge),
                const SizedBox(height: 8),
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedCategoryId == null,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryId = null;
                            });
                          },
                        ),
                        ...provider.categories.map((category) {
                          return FilterChip(
                            label: Text(category.name),
                            selected: _selectedCategoryId == category.id,
                            onSelected: (_) {
                              setState(() {
                                _selectedCategoryId = category.id;
                              });
                            },
                          );
                        }),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Price range
                const Text('Price Range', style: AppTheme.bodyLarge),
                const SizedBox(height: 8),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 100000,
                  divisions: 100,
                  labels: RangeLabels(
                    '\$${_priceRange.start.toInt()}',
                    '\$${_priceRange.end.toInt()}',
                  ),
                  onChanged: (values) {
                    setState(() {
                      _priceRange = values;
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('\$${_priceRange.start.toInt()}'),
                    Text('\$${_priceRange.end.toInt()}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final provider = context.read<ProductProvider>();
                provider.filterByCategory(_selectedCategoryId);
                provider.setPriceRange(
                  min: _priceRange.start,
                  max: _priceRange.end,
                );
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
