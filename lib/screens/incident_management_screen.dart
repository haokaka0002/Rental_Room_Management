// lib/screens/incident_management_screen.dart

import 'package:flutter/material.dart';

import '../database/incident_database.dart';
import '../models/incident.dart';
import 'tenant_incident_screen.dart';

class IncidentManagementScreen extends StatefulWidget {
  const IncidentManagementScreen({super.key});

  @override
  State<IncidentManagementScreen> createState() =>
      _IncidentManagementScreenState();
}

class _IncidentManagementScreenState
    extends State<IncidentManagementScreen> {
  List<Incident> _incidents = [];
  bool _loading = true;
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, pending, in_progress, resolved

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    try {
      final list = await IncidentDatabase.instance.getAllIncidents();
      if (!mounted) return;
      setState(() {
        _incidents = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showMessage('Không thể tải danh sách sự cố: $e');
    }
  }

  List<Incident> get _filteredIncidents {
    return _incidents.where((incident) {
      final matchesSearch = incident.roomNumber
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          incident.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          incident.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesStatus =
          _filterStatus == 'all' || incident.status == _filterStatus;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  int get _pendingCount =>
      _incidents.where((i) => i.status == 'pending').length;
  int get _inProgressCount =>
      _incidents.where((i) => i.status == 'in_progress').length;
  int get _resolvedCount =>
      _incidents.where((i) => i.status == 'resolved').length;

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'in_progress':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã xử lý';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Khẩn cấp':
        return Colors.red;
      case 'Trung bình':
        return Colors.amber.shade800;
      case 'Thấp':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _openIncidentForm({Incident? incident}) async {
    final result = await showDialog<Incident>(
      context: context,
      builder: (_) => IncidentFormDialog(incident: incident),
    );

    if (result == null || !mounted) return;

    try {
      if (incident == null) {
        await IncidentDatabase.instance.insertIncident(result);
        _showMessage('Thêm báo cáo sự cố thành công!');
      } else {
        await IncidentDatabase.instance.updateIncident(result);
        _showMessage('Cập nhật sự cố thành công!');
      }
      await _loadIncidents();
    } catch (e) {
      _showMessage('Lỗi: $e');
    }
  }

  Future<void> _deleteIncident(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa báo cáo sự cố này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await IncidentDatabase.instance.deleteIncident(id);
        _showMessage('Đã xóa sự cố.');
        await _loadIncidents();
      } catch (e) {
        _showMessage('Không thể xóa: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredIncidents;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý Sự cố & Bảo trì (Landlord)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Xem giao diện Tenant (Kiểm tra đã xử lý hay chưa)',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TenantIncidentScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidents,
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Header Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Chờ xử lý',
                    _pendingCount.toString(),
                    Colors.orange,
                    Icons.hourglass_empty,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Đang xử lý',
                    _inProgressCount.toString(),
                    Colors.blue,
                    Icons.engineering,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Đã xử lý',
                    _resolvedCount.toString(),
                    Colors.green,
                    Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
          ),

          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Tìm kiếm theo phòng, tiêu đề...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tất cả trạng thái')),
                    DropdownMenuItem(value: 'pending', child: Text('Chờ xử lý')),
                    DropdownMenuItem(value: 'in_progress', child: Text('Đang xử lý')),
                    DropdownMenuItem(value: 'resolved', child: Text('Đã xử lý')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _filterStatus = val);
                  },
                ),
              ],
            ),
          ),

          // List of Incidents
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(
                        child: Text(
                          'Không có báo cáo sự cố nào.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: list.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(
                                              item.roomNumber,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                          ),
                                          const SizedBox(width: 8),
                                          Chip(
                                            label: Text(item.category),
                                            backgroundColor: Colors.grey.shade200,
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(item.status)
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: _statusColor(item.status)),
                                        ),
                                        child: Text(
                                          _statusLabel(item.status),
                                          style: TextStyle(
                                            color: _statusColor(item.status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.description,
                                    style: TextStyle(
                                        color: Colors.grey.shade700),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text('Ngày báo: ${item.reportedDate}',
                                          style: const TextStyle(
                                              fontSize: 13, color: Colors.grey)),
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _severityColor(item.severity)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Mức độ: ${item.severity}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: _severityColor(item.severity),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.resolutionNote.isNotEmpty) ...[
                                    const Divider(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.green.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Kết quả xử lý / Phản hồi:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                                fontSize: 12),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(item.resolutionNote,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: const Text('Cập nhật / Xử lý'),
                                        onPressed: () =>
                                            _openIncidentForm(incident: item),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete,
                                            size: 16, color: Colors.red),
                                        label: const Text('Xóa',
                                            style: TextStyle(color: Colors.red)),
                                        onPressed: () =>
                                            _deleteIncident(item.id!),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openIncidentForm(),
        icon: const Icon(Icons.add_alert),
        label: const Text('Báo cáo sự cố mới'),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(count,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

// Dialog for Adding or Editing Incident
class IncidentFormDialog extends StatefulWidget {
  final Incident? incident;

  const IncidentFormDialog({super.key, this.incident});

  @override
  State<IncidentFormDialog> createState() => _IncidentFormDialogState();
}

class _IncidentFormDialogState extends State<IncidentFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _roomNumber;
  late String _title;
  late String _description;
  late String _category;
  late String _severity;
  late String _status;
  late String _reportedDate;
  late String _resolutionNote;

  final List<String> _roomsList = [
    'Phòng 101',
    'Phòng 102',
    'Phòng 201',
    'Phòng 202',
    'Phòng 301'
  ];

  @override
  void initState() {
    super.initState();
    final inc = widget.incident;
    _roomNumber = inc?.roomNumber ?? 'Phòng 101';
    _title = inc?.title ?? '';
    _description = inc?.description ?? '';
    _category = inc?.category ?? 'Thiết bị';
    _severity = inc?.severity ?? 'Trung bình';
    _status = inc?.status ?? 'pending';
    _reportedDate = inc?.reportedDate ??
        '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
    _resolutionNote = inc?.resolutionNote ?? '';
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final incident = Incident(
        id: widget.incident?.id,
        roomNumber: _roomNumber,
        title: _title,
        description: _description,
        category: _category,
        severity: _severity,
        status: _status,
        reportedDate: _reportedDate,
        resolutionNote: _resolutionNote,
      );
      Navigator.pop(context, incident);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.incident == null
          ? 'Báo cáo sự cố mới'
          : 'Cập nhật sự cố & Trạng thái xử lý'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _roomNumber,
                  decoration: const InputDecoration(labelText: 'Phòng xảy ra sự cố'),
                  items: _roomsList
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) => setState(() => _roomNumber = val!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _title,
                  decoration: const InputDecoration(labelText: 'Tiêu đề sự cố'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                  onSaved: (val) => _title = val!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _description,
                  decoration: const InputDecoration(labelText: 'Mô tả chi tiết'),
                  maxLines: 3,
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Vui lòng nhập mô tả' : null,
                  onSaved: (val) => _description = val!,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(labelText: 'Danh mục'),
                        items: ['Điện', 'Nước', 'Thiết bị', 'Khác']
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (val) => setState(() => _category = val!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _severity,
                        decoration: const InputDecoration(labelText: 'Mức độ'),
                        items: ['Thấp', 'Trung bình', 'Khẩn cấp']
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (val) => setState(() => _severity = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(labelText: 'Trạng thái xử lý'),
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Chờ xử lý')),
                    DropdownMenuItem(value: 'in_progress', child: Text('Đang xử lý')),
                    DropdownMenuItem(value: 'resolved', child: Text('Đã xử lý')),
                  ],
                  onChanged: (val) => setState(() => _status = val!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _reportedDate,
                  decoration: const InputDecoration(labelText: 'Ngày báo cáo'),
                  onSaved: (val) => _reportedDate = val ?? '',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _resolutionNote,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú / Kết quả xử lý của Landlord',
                    hintText: 'VD: Thợ đã sửa xong vào ngày...',
                  ),
                  maxLines: 2,
                  onSaved: (val) => _resolutionNote = val ?? '',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}
