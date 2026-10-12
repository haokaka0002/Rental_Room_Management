// lib/models/incident.dart

class Incident {
  final int? id;
  final String roomNumber;     // Phòng xảy ra sự cố (VD: Phòng 101)
  final String title;          // Tiêu đề sự cố (VD: Hỏng vòi nước, Chập điện)
  final String description;    // Mô tả chi tiết sự cố
  final String category;       // Danh mục: 'Điện', 'Nước', 'Thiết bị', 'Khác'
  final String severity;       // Mức độ: 'Thấp', 'Trung bình', 'Khẩn cấp'
  final String status;         // Trạng thái: 'pending' (Chờ xử lý), 'in_progress' (Đang xử lý), 'resolved' (Đã xử lý)
  final String reportedDate;   // Ngày báo cáo (VD: 12/10/2026)
  final String resolutionNote; // Ghi chú kết quả xử lý của Landlord

  const Incident({
    this.id,
    required this.roomNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.severity,
    required this.status,
    required this.reportedDate,
    this.resolutionNote = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_number': roomNumber,
      'title': title,
      'description': description,
      'category': category,
      'severity': severity,
      'status': status,
      'reported_date': reportedDate,
      'resolution_note': resolutionNote,
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map) {
    return Incident(
      id: map['id'] as int?,
      roomNumber: map['room_number'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      severity: map['severity'] as String,
      status: map['status'] as String,
      reportedDate: map['reported_date'] as String,
      resolutionNote: (map['resolution_note'] as String?) ?? '',
    );
  }

  Incident copyWith({
    int? id,
    String? roomNumber,
    String? title,
    String? description,
    String? category,
    String? severity,
    String? status,
    String? reportedDate,
    String? resolutionNote,
  }) {
    return Incident(
      id: id ?? this.id,
      roomNumber: roomNumber ?? this.roomNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      reportedDate: reportedDate ?? this.reportedDate,
      resolutionNote: resolutionNote ?? this.resolutionNote,
    );
  }
}
