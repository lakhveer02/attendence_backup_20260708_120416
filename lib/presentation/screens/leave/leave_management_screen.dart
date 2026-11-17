import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:intl/intl.dart';

/// Modern Leave Management Screen
/// Shows leave requests, balances, and approval workflows
class LeaveManagementScreen extends ConsumerStatefulWidget {
  final bool isAdmin;
  
  const LeaveManagementScreen({
    super.key,
    this.isAdmin = false,
  });

  @override
  ConsumerState<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends ConsumerState<LeaveManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.isAdmin ? 3 : 2,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.background,
      appBar: AppBar(
        title: const Text('Leave Management'),
        backgroundColor: ModernColors.indigo,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            const Tab(text: 'My Leaves'),
            const Tab(text: 'Apply Leave'),
            if (widget.isAdmin) const Tab(text: 'Approvals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyLeavesTab(),
          _buildApplyLeaveTab(),
          if (widget.isAdmin) _buildApprovalsTab(),
        ],
      ),
    );
  }

  Widget _buildMyLeavesTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildLeaveBalance(),
          _buildLeaveHistory(),
        ],
      ),
    );
  }

  Widget _buildLeaveBalance() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [ModernColors.indigo, ModernColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: ModernEffects.softShadow(color: ModernColors.indigo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leave Balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard('Annual', 15, 20, ModernColors.emerald),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceCard('Sick', 8, 10, ModernColors.amber),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard('Casual', 5, 10, ModernColors.cyan),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceCard('Used', 10, 0, ModernColors.rose),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String type, int available, int total, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$available',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (total > 0) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '/$total',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveHistory() {
    final leaves = _getMockLeaves();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Leaves',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...leaves.map((leave) => _buildLeaveCard(leave)).toList(),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(Map<String, dynamic> leave) {
    final statusColor = _getStatusColor(leave['status']);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ModernEffects.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                leave['type'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  leave['status'],
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('MMM dd').format(leave['startDate'])} - ${DateFormat('MMM dd, yyyy').format(leave['endDate'])}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '${leave['days']} days',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
          if (leave['reason'] != null) ...[
            const SizedBox(height: 8),
            Text(
              leave['reason'],
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApplyLeaveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apply for Leave',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildApplyLeaveForm(),
        ],
      ),
    );
  }

  Widget _buildApplyLeaveForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ModernEffects.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leave Type',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            items: ['Annual Leave', 'Sick Leave', 'Casual Leave']
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {},
          ),
          const SizedBox(height: 16),
          const Text(
            'Duration',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildDateField('Start Date'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField('End Date'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Reason',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextFormField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Enter reason for leave...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitLeaveRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: ModernColors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Submit Request',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label) {
    return TextFormField(
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onTap: () async {
        await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
      },
    );
  }

  Widget _buildApprovalsTab() {
    final pendingLeaves = _getMockPendingLeaves();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingLeaves.length,
      itemBuilder: (context, index) {
        final leave = pendingLeaves[index];
        return _buildApprovalCard(leave);
      },
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> leave) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ModernEffects.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ModernColors.indigo.withOpacity(0.1),
                child: Text(
                  leave['employee'][0],
                  style: const TextStyle(
                    color: ModernColors.indigo,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave['employee'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      leave['type'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('MMM dd').format(leave['startDate'])} - ${DateFormat('MMM dd, yyyy').format(leave['endDate'])}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const Spacer(),
              Text(
                '${leave['days']} days',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (leave['reason'] != null) ...[
            const SizedBox(height: 12),
            Text(
              leave['reason'],
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectLeave(leave),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ModernColors.rose,
                    side: const BorderSide(color: ModernColors.rose),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _approveLeave(leave),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ModernColors.emerald,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return ModernColors.emerald;
      case 'pending':
        return ModernColors.amber;
      case 'rejected':
        return ModernColors.rose;
      default:
        return Colors.grey;
    }
  }

  void _submitLeaveRequest() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Leave request submitted successfully'),
        backgroundColor: ModernColors.emerald,
      ),
    );
  }

  void _approveLeave(Map<String, dynamic> leave) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Approved leave for ${leave['employee']}'),
        backgroundColor: ModernColors.emerald,
      ),
    );
  }

  void _rejectLeave(Map<String, dynamic> leave) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rejected leave for ${leave['employee']}'),
        backgroundColor: ModernColors.rose,
      ),
    );
  }

  List<Map<String, dynamic>> _getMockLeaves() {
    return [
      {
        'type': 'Annual Leave',
        'status': 'Approved',
        'startDate': DateTime(2026, 7, 15),
        'endDate': DateTime(2026, 7, 20),
        'days': 5,
        'reason': 'Family vacation',
      },
      {
        'type': 'Sick Leave',
        'status': 'Pending',
        'startDate': DateTime(2026, 7, 10),
        'endDate': DateTime(2026, 7, 12),
        'days': 2,
        'reason': 'Medical appointment',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockPendingLeaves() {
    return [
      {
        'employee': 'John Doe',
        'type': 'Annual Leave',
        'startDate': DateTime(2026, 7, 20),
        'endDate': DateTime(2026, 7, 25),
        'days': 5,
        'reason': 'Family vacation',
      },
      {
        'employee': 'Jane Smith',
        'type': 'Sick Leave',
        'startDate': DateTime(2026, 7, 15),
        'endDate': DateTime(2026, 7, 16),
        'days': 2,
        'reason': 'Medical checkup',
      },
    ];
  }
}
