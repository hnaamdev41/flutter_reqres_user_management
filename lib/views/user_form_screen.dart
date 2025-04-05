import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reqres_user_management/models/user_model.dart';
import 'package:reqres_user_management/services/auth_service.dart';
import 'package:reqres_user_management/services/user_service.dart';
import 'package:reqres_user_management/utils/toast_util.dart';

class UserFormScreen extends StatefulWidget {
  final User? user;
  
  const UserFormScreen({Key? key, this.user}) : super(key: key);

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  
  bool get _isEditing => widget.user != null;
  
  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _firstNameController.text = widget.user!.firstName;
      _lastNameController.text = widget.user!.lastName;
      _emailController.text = widget.user!.email;
    }
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userService = Provider.of<UserService>(context, listen: false);
      
      bool success;
      
      if (_isEditing) {
        // Update existing user
        final updatedUser = widget.user!.copyWith(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
        );
        
        success = await userService.updateUser(updatedUser, token: authService.token);
        
        if (success) {
          ToastUtil.showSuccess('User updated successfully');
          if (!mounted) return;
          Navigator.pop(context);
        } else {
          ToastUtil.showError(userService.error ?? 'Failed to update user');
        }
      } else {
        // Create new user with a placeholder ID and avatar
        // ReqRes API will assign a real ID on the server
        final newUser = User(
          id: 0, // Placeholder, will be replaced by API
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          avatar: 'https://reqres.in/img/faces/1-image.jpg', // Placeholder
        );
        
        success = await userService.createUser(newUser, token: authService.token);
        
        if (success) {
          ToastUtil.showSuccess('User created successfully');
          if (!mounted) return;
          Navigator.pop(context);
        } else {
          ToastUtil.showError(userService.error ?? 'Failed to create user');
        }
      }
    }
  }

  void _showDiscardConfirmation() {
    // Check if form has changes
    bool hasChanges = false;
    
    if (_isEditing) {
      hasChanges = _firstNameController.text != widget.user!.firstName ||
                  _lastNameController.text != widget.user!.lastName ||
                  _emailController.text != widget.user!.email;
    } else {
      hasChanges = _firstNameController.text.isNotEmpty ||
                  _lastNameController.text.isNotEmpty ||
                  _emailController.text.isNotEmpty;
    }
    
    if (!hasChanges) {
      Navigator.pop(context);
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes'),
        content: const Text('Are you sure you want to discard your changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close form
            },
            child: const Text('DISCARD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userService = Provider.of<UserService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit User' : 'Create User'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _showDiscardConfirmation,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(widget.user!.avatar),
                    ),
                  ),
                ),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'First name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Last name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: userService.isLoading ? null : _saveUser,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: userService.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditing ? 'UPDATE' : 'CREATE',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}