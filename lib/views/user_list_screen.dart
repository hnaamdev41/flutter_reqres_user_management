import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reqres_user_management/models/user_model.dart';
import 'package:reqres_user_management/services/auth_service.dart';
import 'package:reqres_user_management/services/user_service.dart';
import 'package:reqres_user_management/utils/toast_util.dart';
import 'package:reqres_user_management/views/login_screen.dart';
import 'package:reqres_user_management/views/user_detail_screen.dart';
import 'package:reqres_user_management/views/user_form_screen.dart';
import 'package:reqres_user_management/widgets/user_list_item.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late UserService _userService;
  List<User> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _userService = Provider.of<UserService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsers();
    });
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterUsers);
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _userService.users;
      } else {
        _filteredUsers = _userService.searchUsers(query);
      }
    });
  }

  Future<void> _fetchUsers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await _userService.fetchUsers(token: authService.token);
    _filteredUsers = _userService.users;
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    ToastUtil.showInfo('Logged out successfully');
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.firstName} ${user.lastName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService = Provider.of<AuthService>(context, listen: false);
              final success = await _userService.deleteUser(user.id, token: authService.token);
              
              if (success) {
                ToastUtil.showSuccess('User deleted successfully');
                setState(() {
                  _filteredUsers = _userService.users;
                });
              } else {
                ToastUtil.showError(_userService.error ?? 'Failed to delete user');
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmation,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<UserService>(
              builder: (context, userService, child) {
                if (userService.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (userService.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          userService.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchUsers,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (_filteredUsers.isEmpty) {
                  return Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'No users found'
                          : 'No users match your search',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _fetchUsers,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return UserListItem(
                        user: user,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserDetailScreen(userId: user.id),
                            ),
                          );
                        },
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserFormScreen(user: user),
                            ),
                          ).then((_) {
                            setState(() {
                              _filteredUsers = _userService.users;
                            });
                          });
                        },
                        onDelete: () => _showDeleteConfirmation(user),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserFormScreen()),
          ).then((_) {
            setState(() {
              _filteredUsers = _userService.users;
            });
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}