// lib/screens/tenant_incident_screen.dart

import 'package:flutter/material.dart';

import '../database/incident_database.dart';
import '../models/incident.dart';

class TenantIncidentScreen extends StatefulWidget {
  const TenantIncidentScreen({super.key});

  @override
  State<TenantIncidentScreen> createState() => _TenantIncidentScreenState();
}

class _TenantIncidentScreenState extends State<TenantIncidentScreen> {
  List<Incident> _allIncidents = [];
  bool _loading = true;
  String _selectedRoom = 'Phòng 101'; // Phòng của tenant đang xem

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
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    try {
      final list = await IncidentDatabase.instance.getAllIncidents();
      if (!mounted) return;
      setState(() {
        _allIncidents = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
      );
    }
  }

  List<Incident> get _roomIncidents {
    return _allIncidents
        .where((i) => i.roomNumber == _selectedRoom)
        .toList();
  }

  int get _resolvedCount =>
      _roomIncidents.where((i) => i.status == 'resolved').length;
  int get _unresolvedCount =>
      _roomIncidents.where((i) => i.status != 'resolved').length;

  Future<void> _tenantReportIncident() async {
    final result = await showDialog<Incident>(
      context: context,
      builder: (_) => TenantReportDialog(roomNumber: _selectedRoom),
    );

    if (result == null || !mounted) return;

    try {
      await IncidentDatabase.instance.insertIncident(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi báo cáo sự cố thành công! Landlord sẽ sớm kiểm tra.')),
      );
      await _loadIncidents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _roomIncidents;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sự cố & Bảo trì - $_selectedRoom (Tenant)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: _loadIncidents,
          ),
        ],
      ),
      body: Column(
        children: [
          // Room selector & Summary for Tenant
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                const Text('Chọn phòng của bạn:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedRoom,
                  items: _roomsList
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRoom = val);
                  },
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                      const SizedBox(width: 4),
                      Text('Đã xử lý: $_resolvedCount',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      const SizedBox(width: 12),
                      const Icon(Icons.pending_actions,
                          color: Colors.orange, size: 18),
                      const SizedBox(width: 4),
                      Text('Chưa xử lý: $_unresolvedCount',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Banner explaining status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trang này giúp bạn (Tenant) theo dõi các sự cố đã báo cáo và xem Landlord đã xử lý hay chưa.',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),

          // Incident List for selected room
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.task_alt,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              '$_selectedRoom chưa có sự cố nào được báo cáo.',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: list.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final isResolved = item.status == 'resolved';

                          return Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isResolved
                                    ? Colors.green.shade300
                                    : Colors.orange.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Chip(
                                        label: Text(item.category),
                                        backgroundColor:
                                            Colors.indigo.shade50,
                                      ),
                                      // Status Badge indicating whether it's resolved or not
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isResolved
                                              ? Colors.green.shade100
                                              : item.status == 'in_progress'
                                                  ? Colors.blue.shade100
                                                  : Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isResolved
                                                  ? Icons.check_circle
                                                  : Icons.access_time_filled,
                                              size: 16,
                                              color: isResolved
                                                  ? Colors.green.shade800
                                                  : item.status == 'in_progress'
                                                      ? Colors.blue.shade800
                                                      : Colors.orange.shade800,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isResolved
                                                  ? 'ĐÃ XỬ LÝ'
                                                  : item.status == 'in_progress'
                                                      ? 'ĐANG XỬ LÝ'
                                                      : 'CHỜ XỬ LÝ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: isResolved
                                                    ? Colors.green.shade900
                                                    : item.status ==
                                                            'in_progress'
                                                        ? Colors.blue.shade900
                                                        : Colors.orange.shade900,
                                              ),
                                            ),
                                          ],
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
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ngày báo cáo: ${item.reportedDate}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Mức độ: ${item.severity}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: item.severity == 'Khẩn cấp'
                                              ? Colors.red
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.resolutionNote.isNotEmpty) ...[
                                    const Divider(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isResolved
                                            ? Colors.green.shade50
                                            : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isResolved
                                              ? Colors.green.shade200
                                              : Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.rate_review,
                                                  size: 16,
                                                  color: isResolved
                                                      ? Colors.green
                                                      : Colors.blue),
                                              const SizedBox(width: 6),
                                              Text(
                                                isResolved
                                                    ? 'Phản hồi / Kết quả từ Chủ trọ (Đã khắc phục):'
                                                    : 'Phản hồi từ Chủ trọ:',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: isResolved
                                                      ? Colors.green.shade800
                                                      : Colors.blue.shade800,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.resolutionNote,
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else ...[
                                    const Divider(height: 16),
                                    Text(
                                      isResolved
                                          ? 'Đã hoàn thành sửa chữa.'
                                          : 'Chủ trọ đang sắp xếp thời gian kiểm tra và xử lý sự cố.',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 12,
                                        color: isResolved
                                            ? Colors.green
                                            : Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
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
        onPressed: _tenantReportIncident,
        icon: const Icon(Icons.report_gmailerrorred),
        label: const Text('Báo cáo sự cố mới'),
      ),
    );
  }
}

// Dialog for Tenant to report incident
class TenantReportDialog extends StatefulWidget {
  final String roomNumber;

  const TenantReportDialog({super.key, required this.roomNumber});

  @override
  State<TenantReportDialog> createState() => _TenantReportDialogState();
}

class _TenantReportDialogState extends State<TenantReportDialog> {
  final _formKey = GlobalKey<FormState>();

  late String _title;
  late String _description;
  String _category = 'Thiết bị';
  String _severity = 'Trung bình';

  @override
  void initState() {
    super.initState();
    _title = '';
    _description = '';
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final incident = Incident(
        roomNumber: widget.roomNumber,
        title: _title,
        description: _description,
        category: _category,
        severity: _severity,
        status: 'pending', // Mới báo cáo luôn là chờ xử lý
        reportedDate:
            '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
        resolutionNote: '',
      );
      Navigator.pop(context, incident);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Báo cáo sự cố (${widget.roomNumber})'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tiêu đề sự cố (VD: Hỏng bóng đèn)',
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                  onSaved: (val) => _title = val!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Mô tả chi tiết sự cố',
                  ),
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
          onPressed: _submit,
          child: const Text('Gửi báo cáo'),
        ),
      ],
    );
  }
}
