import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:intl/intl.dart';

/// Attendance History Screen - View detailed attendance records
class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends ConsumerState<AttendanceHistoryScreen> {
  DateTime _selectedMonth = DateTime.now();
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.background,
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: ModernColors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildSummaryCards(),
          _buildFilterChips(),
          Expanded(child: _buildAttendanceList()),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_selectedMonth),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard('Present', '20', ModernColors.emerald, Icons.check_circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard('Absent', '2', ModernColors.rose, Icons.cancel),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard('Late', '3', ModernColors.amber, Icons.access_time),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Present', 'Absent', 'Late', 'On Leave'];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _filter == filter;
          
          return FilterChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              setState(() => _filter = filter);
            },
            selectedColor: ModernColors.indigo,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceList() {
    final records = _getMockAttendanceRecords();
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildAttendanceCard(record);
      },
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> record) {
    final statusColor = _getStatusColor(record['status']);
    final statusIcon = _getStatusIcon(record['status']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ModernEffects.softShadow(),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, MMM dd').format(record['date']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (record['checkIn'] != null) ...[
                      Icon(Icons.login, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(record['checkIn']),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (record['checkOut'] != null) ...[
                      Icon(Icons.logout, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(record['checkOut']),
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
                if (record['workingHours'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Working hours: ${record['workingHours']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              record['status'],
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return ModernColors.emerald;
      case 'absent':
        return ModernColors.rose;
      case 'late':
        return ModernColors.amber;
      case 'on leave':
        return ModernColors.cyan;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.access_time;
      case 'on leave':
        return Icons.event_busy;
      default:
        return Icons.help;
    }
  }

  void _selectMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (selected != null) {
      setState(() => _selectedMonth = selected);
    }
  }

  List<Map<String, dynamic>> _getMockAttendanceRecords() {
    return List.generate(15, (index) {
      final date = DateTime.now().subtract(Duration(days: index));
      final random = index % 4;
      
      return {
        'date': date,
        'status': ['Present', 'Present', 'Late', 'Absent'][random],
        'checkIn': random != 3 ? DateTime(date.year, date.month, date.day, 9, 0 + (random * 30)) : null,
        'checkOut': random != 3 ? DateTime(date.year, date.month, date.day, 18, 0) : null,
        'workingHours': random != 3 ? '9h 0m' : null,
      };
    });
  }
}
