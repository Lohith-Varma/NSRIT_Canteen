import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/admin_provider.dart';
import '../../utils/formatters.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  static const List<String> roles = [
    'Administrator',
    'Store Manager',
    'Cook',
    'Cashier',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProvider>(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: provider.loadAdminData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _showUserDialog(context),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Create User'),
              ),
            ),
            const SizedBox(height: 12),
            ...provider.users.map((user) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (user.displayName?.isNotEmpty == true
                              ? user.displayName!
                              : user.email)
                          .characters
                          .first
                          .toUpperCase(),
                    ),
                  ),
                  title: Text(user.displayName ?? user.email),
                  subtitle: Text(
                    '${user.email} - ${user.role} - Created ${Formatters.formatDate(user.createdAt)}',
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      Chip(
                        label: Text(user.isActive ? 'Active' : 'Inactive'),
                        backgroundColor:
                            (user.isActive ? Colors.green : Colors.red)
                                .withValues(alpha: 0.14),
                      ),
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () => _showUserDialog(context, user: user),
                      ),
                      IconButton(
                        tooltip: 'Reset Password',
                        icon: const Icon(Icons.lock_reset_rounded),
                        onPressed: () async {
                          final success = await provider.resetPassword(
                            user.email,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Password reset requested.'
                                      : provider.errorMessage ??
                                            'Reset failed.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      IconButton(
                        tooltip: 'Deactivate',
                        icon: const Icon(Icons.person_off_rounded),
                        onPressed: user.isActive
                            ? () async {
                                final success = await provider.deactivateUser(
                                  user.uid,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'User deactivated.'
                                            : provider.errorMessage ??
                                                  'Deactivate failed.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _showUserDialog(BuildContext context, {UserModel? user}) async {
    final nameController = TextEditingController(text: user?.displayName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    var role = user?.role ?? roles.first;
    var isActive = user?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(user == null ? 'Create User' : 'Edit User'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: roles
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => role = value);
                        }
                      },
                    ),
                    SwitchListTile(
                      value: isActive,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active'),
                      onChanged: (value) => setState(() => isActive = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final provider = Provider.of<AdminProvider>(
                      context,
                      listen: false,
                    );
                    final model = UserModel(
                      uid: user?.uid ?? '',
                      email: emailController.text.trim(),
                      displayName: nameController.text.trim(),
                      role: role,
                      isActive: isActive,
                      createdAt: user?.createdAt ?? DateTime.now(),
                      updatedAt: DateTime.now(),
                    );
                    final success = await provider.saveUser(model);
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'User saved.'
                              : provider.errorMessage ?? 'Save failed.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    nameController.dispose();
    emailController.dispose();
  }
}
