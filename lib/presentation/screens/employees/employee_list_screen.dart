import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';

/// Modern Employee List Screen
/// Shows all employees with search, filter, and management options
class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDepartment = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.background,
      appBar: AppBar(
        title: const Text('Employees'),
        backgroundColor: ModernColors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _navigateToAddEmployee(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _buildEmployeeList()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search employees...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All Departments', _selectedDepartment == 'All', () {
              setState(() => _selectedDepartment = 'All');
            }),
            const SizedBox(width: 8),
            _buildFilterChip('Engineering', _selectedDepartment == 'Engineering', () {
              setState(() => _selectedDepartment = 'Engineering');
            }),
            const SizedBox(width: 8),
            _buildFilterChip('Sales', _selectedDepartment == 'Sales', () {
              setState(() => _selectedDepartment = 'Sales');
            }),
            const SizedBox(width: 8),
            _buildFilterChip('HR', _selectedDepartment == 'HR', () {
              setState(() => _selectedDepartment = 'HR');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ModernColors.indigo : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? ModernColors.indigo : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    // Mock data - replace with actual data from provider
    final employees = _getMockEmployees();

    if (employees.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final employee = employees[index];
        return _buildEmployeeCard(employee);
      },
    );
  }

  Widget _buildEmployeeCard(Map<String, dynamic> employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ModernEffects.softShadow(),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: ModernColors.indigo.withOpacity(0.1),
          child: Text(
            employee['name'][0].toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ModernColors.indigo,
            ),
          ),
        ),
        title: Text(
          employee['name'],
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              employee['role'],
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.business, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  employee['department'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: employee['status'] == 'Active'
                    ? ModernColors.emerald.withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                employee['status'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: employee['status'] == 'Active'
                      ? ModernColors.emerald
                      : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              employee['id'],
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToEmployeeDetails(context, employee),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No employees found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add employees to get started',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddEmployee(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Employee'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernColors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Employees'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add filter options here
            const Text('Filter options coming soon...'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddEmployee(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Employee screen - Coming soon')),
    );
  }

  void _navigateToEmployeeDetails(BuildContext context, Map<String, dynamic> employee) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for ${employee['name']}')),
    );
  }

  List<Map<String, dynamic>> _getMockEmployees() {
    // Mock data - replace with actual data fetching
    return [
      {
        'id': 'EMP001',
        'name': 'Chetan Batra',
        'role': 'Company Admin',
        'department': 'Management',
        'status': 'Active',
        'email': 'chetan@squadminds.com',
      },
      {
        'id': 'EMP002',
        'name': 'John Doe',
        'role': 'Software Engineer',
        'department': 'Engineering',
        'status': 'Active',
        'email': 'john@squadminds.com',
      },
      {
        'id': 'EMP003',
        'name': 'Jane Smith',
        'role': 'HR Manager',
        'department': 'HR',
        'status': 'Active',
        'email': 'jane@squadminds.com',
      },
    ];
  }
}
