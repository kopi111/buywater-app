import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../utils/helpers.dart';
import '../checkout/add_address_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;

          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Please sign in',
                    style: AppTheme.heading3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profile header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          Helpers.getInitials(user.fullName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              style: AppTheme.heading3,
                            ),
                            Text(
                              user.email,
                              style: AppTheme.bodySmall,
                            ),
                            if (user.phone != null)
                              Text(
                                user.phone!,
                                style: AppTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          // TODO: Navigate to edit profile
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Menu items
              _buildMenuSection('Account', [
                _buildMenuItem(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  title: 'My Orders',
                  onTap: () => Navigator.pushNamed(context, '/orders'),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.favorite_outline,
                  title: 'Wishlist',
                  onTap: () {
                    // TODO: Navigate to wishlist
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.location_on_outlined,
                  title: 'Addresses',
                  onTap: () => _showAddresses(context, auth),
                ),
              ]),
              const SizedBox(height: 16),

              _buildMenuSection('Settings', [
                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {
                    // TODO: Navigate to notifications settings
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {
                    // TODO: Navigate to change password
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.nfc_outlined,
                  title: 'NFC Settings',
                  onTap: () {
                    // TODO: Navigate to NFC settings
                  },
                ),
              ]),
              const SizedBox(height: 16),

              _buildMenuSection('Support', [
                _buildMenuItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {
                    // TODO: Navigate to help
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.policy_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    // TODO: Navigate to privacy policy
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () {
                    // TODO: Navigate to terms
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // Logout button
              OutlinedButton(
                onPressed: () async {
                  final confirm = await Helpers.showConfirmDialog(
                    context,
                    title: 'Logout',
                    message: 'Are you sure you want to logout?',
                    confirmText: 'Logout',
                    isDestructive: true,
                  );
                  if (confirm) {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Logout'),
              ),
              const SizedBox(height: 16),

              // App version
              Center(
                child: Text(
                  'NCB Shop v1.0.0',
                  style: AppTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showAddresses(BuildContext context, AuthProvider auth) {
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
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Addresses', style: AppTheme.heading3),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddAddressScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New'),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: auth.addresses.isEmpty
                    ? const Center(child: Text('No addresses saved'))
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: auth.addresses.length,
                        itemBuilder: (context, index) {
                          final address = auth.addresses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.location_on),
                              title: Row(
                                children: [
                                  Text(address.fullName),
                                  if (address.isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Default',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Text(
                                address.shortAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  if (!address.isDefault)
                                    const PopupMenuItem(
                                      value: 'default',
                                      child: Text('Set as Default'),
                                    ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    Navigator.pop(context);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddAddressScreen(
                                          address: address,
                                        ),
                                      ),
                                    );
                                  } else if (value == 'default') {
                                    await auth.setDefaultAddress(address.id);
                                  } else if (value == 'delete') {
                                    final confirm =
                                        await Helpers.showConfirmDialog(
                                      context,
                                      title: 'Delete Address',
                                      message:
                                          'Are you sure you want to delete this address?',
                                      confirmText: 'Delete',
                                      isDestructive: true,
                                    );
                                    if (confirm) {
                                      await auth.deleteAddress(address.id);
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
