import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reqres_user_management/services/auth_service.dart';
import 'package:reqres_user_management/services/user_service.dart';
import 'package:reqres_user_management/utils/toast_util.dart';
import 'package:reqres_user_management/views/user_form_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;
  
  const UserDetailScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late UserService _userService;
  
  @override
  void initState() {
    super.initState();
    _userService = Provider.of<UserService>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserDetails();
    });
  }
  
  Future<void> _fetchUserDetails() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await _userService.getUserById(widget.userId, token: authService.token);
  }

  void _showDeleteConfirmation() {
    final user = _userService.selectedUser;
    if (user == null) return;
    
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
                if (!mounted) return;
                Navigator.pop(context); // Return to user list
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
        title: const Text('User Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              if (_userService.selectedUser != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserFormScreen(user: _userService.selectedUser!),
                  ),
                ).then((_) => _fetchUserDetails());
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: Consumer<UserService>(
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
                    onPressed: _fetchUserDetails,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          final user = userService.selectedUser;
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: NetworkImage(user.avatar),
                ),
                const SizedBox(height: 24),
                Text(
                  '${user.firstName} ${user.lastName}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                const Divider(),
                _buildInfoItem('ID', '${user.id}'),
                _buildInfoItem('First Name', user.firstName),
                _buildInfoItem('Last Name', user.lastName),
                _buildInfoItem('Email', user.email),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}