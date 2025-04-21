import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'signup_screen.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isCompleted = false;
  String? _editingTaskId;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _userName = FirebaseAuth.instance.currentUser?.displayName;
  }

  @override
  void dispose() {
    _taskController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference get _tasksCollection =>
      FirebaseFirestore.instance.collection('users').doc(_userId).collection('tasks');

  Future<void> _addTask() async {
    if (_taskController.text.isEmpty) return;

    try {
      if (_editingTaskId != null) {
        await _tasksCollection.doc(_editingTaskId).update({
          'title': _taskController.text,
          'description': _descriptionController.text,
          'dueDate': _selectedDate,
          'isCompleted': _isCompleted,
          'updatedAt': DateTime.now(),
        });
        _editingTaskId = null;
      } else {
        await _tasksCollection.add({
          'title': _taskController.text,
          'description': _descriptionController.text,
          'dueDate': _selectedDate,
          'isCompleted': false,
          'createdAt': DateTime.now(),
        });
      }

      _taskController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _isCompleted = false;
      });

      FocusScope.of(context).unfocus();
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showErrorSnackBar('Error saving task: $e');
    }
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
      _showSuccessSnackBar('Task deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Error deleting task: $e');
    }
  }

  Future<void> _toggleTaskCompletion(String taskId, bool currentStatus) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'isCompleted': !currentStatus,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      _showErrorSnackBar('Error updating task: $e');
    }
  }

  void _showAddTaskDialog({
    String? taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? completed,
  }) {
    if (taskId != null) {
      _editingTaskId = taskId;
      _taskController.text = title ?? '';
      _descriptionController.text = description ?? '';
      _selectedDate = dueDate ?? DateTime.now();
      _isCompleted = completed ?? false;
    } else {
      _editingTaskId = null;
      _taskController.clear();
      _descriptionController.clear();
      _selectedDate = DateTime.now();
      _isCompleted = false;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2F3F),
        title: Text(
          taskId != null ? 'Edit Task' : 'Add New Task',
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFC940)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFFC940)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date', style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  DateFormat('MMM dd, yyyy').format(_selectedDate),
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today, color: Color(0xFFFFC940)),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2101),
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFFFFC940),
                              onPrimary: Colors.black,
                              surface: Color(0xFF2A2F3F),
                              onSurface: Colors.white,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null && picked != _selectedDate) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                ),
              ),
              if (taskId != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Completed', style: TextStyle(color: Colors.white)),
                  value: _isCompleted,
                  activeColor: const Color(0xFFFFC940),
                  onChanged: (bool value) {
                    setState(() {
                      _isCompleted = value;
                    });
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: _addTask,
            child: Text(
              taskId != null ? 'Update' : 'Add',
              style: const TextStyle(color: Color(0xFFFFC940)),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2230),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2230),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC940),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Day Task',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_userName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Hello, $_userName!',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                        (route) => false,
                  );
                }
              } catch (e) {
                _showErrorSnackBar('Error signing out: $e');
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC940),
        onPressed: () => _showAddTaskDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _tasksCollection.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong', style: TextStyle(color: Colors.white)));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFFC940)));
          }

          final tasks = snapshot.data?.docs ?? [];

          if (tasks.isEmpty) {
            return const Center(
              child: Text('No tasks added yet.', style: TextStyle(color: Colors.white70)),
            );
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final taskData = task.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(
                  taskData['title'] ?? '',
                  style: TextStyle(
                    color: taskData['isCompleted'] ? Colors.green : Colors.white,
                    decoration: taskData['isCompleted'] ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Text(
                  taskData['description'] ?? '',
                  style: const TextStyle(color: Colors.white54),
                ),
                trailing: Wrap(
                  spacing: 12,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue.shade300),
                      onPressed: () => _showAddTaskDialog(
                        taskId: task.id,
                        title: taskData['title'],
                        description: taskData['description'],
                        dueDate: (taskData['dueDate'] as Timestamp).toDate(),
                        completed: taskData['isCompleted'],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTask(task.id),
                    ),
                  ],
                ),
                onTap: () => _toggleTaskCompletion(task.id, taskData['isCompleted']),
              );
            },
          );
        },
      ),
    );
  }
}
