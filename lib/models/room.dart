
class Room {
  final int? id;
  final String roomNumber;
  final double rentPrice;
  final double area;
  final String status;
  final String description;

  const Room({
    this.id,
    required this.roomNumber,
    required this.rentPrice,
    required this.area,
    required this.status,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_number': roomNumber,
      'rent_price': rentPrice,
      'area': area,
      'status': status,
      'description': description,
    };
  }

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as int?,
      roomNumber: map['room_number'] as String,
      rentPrice: (map['rent_price'] as num).toDouble(),
      area: (map['area'] as num).toDouble(),
      status: map['status'] as String,
      description: map['description'] as String,
    );
  }
}