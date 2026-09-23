int asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? fallback;
}

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.passwordHash = '',
    this.token = '',
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final String passwordHash;
  final String token;

  bool get isAdmin => role == 'administrador';

  AppUser copyWith({String? token, String? passwordHash, String? name, String? phone}) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      role: role,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      token: token ?? this.token,
    );
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'cliente',
      phone: map['phone']?.toString() ?? '',
      passwordHash: map['password_hash']?.toString() ?? '',
      token: map['token']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'password_hash': passwordHash,
        'token': token,
      };
}

class GymClass {
  GymClass({
    required this.id,
    required this.name,
    required this.description,
    required this.trainer,
    required this.startsAt,
    required this.durationMin,
    required this.capacity,
    required this.available,
    required this.room,
    required this.difficulty,
    this.syncStatus = 'synced',
  });

  final String id;
  final String name;
  final String description;
  final String trainer;
  final String startsAt;
  final int durationMin;
  final int capacity;
  final int available;
  final String room;
  final String difficulty;
  final String syncStatus;

  DateTime get date => DateTime.tryParse(startsAt)?.toLocal() ?? DateTime.now();

  factory GymClass.fromApi(Map<String, dynamic> map) {
    return GymClass(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      trainer: map['trainer']?.toString() ?? '',
      startsAt: map['startsAt']?.toString() ?? map['starts_at']?.toString() ?? '',
      durationMin: asInt(map['durationMin'] ?? map['duration_min'], 45),
      capacity: asInt(map['capacity']),
      available: asInt(map['available'] ?? map['capacity']),
      room: map['room']?.toString() ?? '',
      difficulty: map['difficulty']?.toString() ?? 'intermedio',
    );
  }

  Map<String, dynamic> toDb() => {
        'id': id,
        'name': name,
        'description': description,
        'trainer': trainer,
        'starts_at': startsAt,
        'duration_min': durationMin,
        'capacity': capacity,
        'available': available,
        'room': room,
        'difficulty': difficulty,
        'sync_status': syncStatus,
      };

  factory GymClass.fromDb(Map<String, dynamic> map) {
    return GymClass(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      trainer: map['trainer']?.toString() ?? '',
      startsAt: map['starts_at']?.toString() ?? '',
      durationMin: map['duration_min'] as int? ?? 45,
      capacity: map['capacity'] as int? ?? 0,
      available: map['available'] as int? ?? 0,
      room: map['room']?.toString() ?? '',
      difficulty: map['difficulty']?.toString() ?? 'intermedio',
      syncStatus: map['sync_status']?.toString() ?? 'synced',
    );
  }

  Map<String, dynamic> toApi() => {
        'id': id,
        'name': name,
        'description': description,
        'trainer': trainer,
        'startsAt': startsAt,
        'durationMin': durationMin,
        'capacity': capacity,
        'room': room,
        'difficulty': difficulty,
      };

  GymClass copyWith({int? available, String? syncStatus}) {
    return GymClass(
      id: id,
      name: name,
      description: description,
      trainer: trainer,
      startsAt: startsAt,
      durationMin: durationMin,
      capacity: capacity,
      available: available ?? this.available,
      room: room,
      difficulty: difficulty,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class Booking {
  Booking({
    required this.id,
    required this.userId,
    required this.classId,
    required this.status,
    this.notes = '',
    this.userName = '',
    this.userEmail = '',
    this.className = '',
    this.trainer = '',
    this.startsAt = '',
    this.room = '',
    this.syncStatus = 'synced',
  });

  final String id;
  final String userId;
  final String classId;
  final String status;
  final String notes;
  final String userName;
  final String userEmail;
  final String className;
  final String trainer;
  final String startsAt;
  final String room;
  final String syncStatus;

  DateTime get date => DateTime.tryParse(startsAt)?.toLocal() ?? DateTime.now();

  factory Booking.fromApi(Map<String, dynamic> map) {
    return Booking(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      classId: map['classId']?.toString() ?? map['class_id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pendiente',
      notes: map['notes']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      userEmail: map['userEmail']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      trainer: map['trainer']?.toString() ?? '',
      startsAt: map['startsAt']?.toString() ?? '',
      room: map['room']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toDb() => {
        'id': id,
        'user_id': userId,
        'class_id': classId,
        'status': status,
        'notes': notes,
        'user_name': userName,
        'user_email': userEmail,
        'class_name': className,
        'trainer': trainer,
        'starts_at': startsAt,
        'room': room,
        'sync_status': syncStatus,
      };

  factory Booking.fromDb(Map<String, dynamic> map) {
    return Booking(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      classId: map['class_id']?.toString() ?? '',
      status: map['status']?.toString() ?? 'pendiente',
      notes: map['notes']?.toString() ?? '',
      userName: map['user_name']?.toString() ?? '',
      userEmail: map['user_email']?.toString() ?? '',
      className: map['class_name']?.toString() ?? '',
      trainer: map['trainer']?.toString() ?? '',
      startsAt: map['starts_at']?.toString() ?? '',
      room: map['room']?.toString() ?? '',
      syncStatus: map['sync_status']?.toString() ?? 'synced',
    );
  }
}

class MembershipPlan {
  MembershipPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.durationDays,
    required this.price,
    required this.benefits,
  });

  final String id;
  final String name;
  final String description;
  final int durationDays;
  final int price;
  final List<String> benefits;

  factory MembershipPlan.fromApi(Map<String, dynamic> map) {
    final raw = map['benefits'];
    return MembershipPlan(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      durationDays: asInt(map['durationDays'] ?? map['duration_days'], 30),
      price: asInt(map['price']),
      benefits: raw is List ? raw.map((e) => e.toString()).toList() : <String>[],
    );
  }

  Map<String, dynamic> toDb() => {
        'id': id,
        'name': name,
        'description': description,
        'duration_days': durationDays,
        'price': price,
        'benefits': benefits.join('|'),
      };

  factory MembershipPlan.fromDb(Map<String, dynamic> map) {
    return MembershipPlan(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      durationDays: map['duration_days'] as int? ?? 30,
      price: map['price'] as int? ?? 0,
      benefits: (map['benefits']?.toString() ?? '').split('|').where((e) => e.isNotEmpty).toList(),
    );
  }
}

class Membership {
  Membership({
    required this.id,
    required this.userId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.planName = '',
    this.syncStatus = 'synced',
  });

  final String id;
  final String userId;
  final String planId;
  final String startDate;
  final String endDate;
  final String status;
  final String planName;
  final String syncStatus;

  factory Membership.fromApi(Map<String, dynamic> map) {
    return Membership(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? map['user_id']?.toString() ?? '',
      planId: map['planId']?.toString() ?? map['plan_id']?.toString() ?? '',
      startDate: map['startDate']?.toString() ?? map['start_date']?.toString() ?? '',
      endDate: map['endDate']?.toString() ?? map['end_date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'activa',
      planName: map['planName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toDb() => {
        'id': id,
        'user_id': userId,
        'plan_id': planId,
        'start_date': startDate,
        'end_date': endDate,
        'status': status,
        'plan_name': planName,
        'sync_status': syncStatus,
      };

  factory Membership.fromDb(Map<String, dynamic> map) {
    return Membership(
      id: map['id']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      planId: map['plan_id']?.toString() ?? '',
      startDate: map['start_date']?.toString() ?? '',
      endDate: map['end_date']?.toString() ?? '',
      status: map['status']?.toString() ?? 'activa',
      planName: map['plan_name']?.toString() ?? '',
      syncStatus: map['sync_status']?.toString() ?? 'synced',
    );
  }
}

class Routine {
  Routine({
    required this.id,
    required this.name,
    required this.goal,
    required this.level,
    required this.durationWeeks,
    required this.exercises,
  });

  final String id;
  final String name;
  final String goal;
  final String level;
  final int durationWeeks;
  final List<Map<String, dynamic>> exercises;

  factory Routine.fromApi(Map<String, dynamic> map) {
    final raw = map['exercises'];
    return Routine(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      goal: map['goal']?.toString() ?? '',
      level: map['level']?.toString() ?? '',
      durationWeeks: asInt(map['durationWeeks'] ?? map['duration_weeks'], 4),
      exercises: raw is List
          ? raw.map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[],
    );
  }

  Map<String, dynamic> toDb() => {
        'id': id,
        'name': name,
        'goal': goal,
        'level': level,
        'duration_weeks': durationWeeks,
        'exercises': exercises.map((e) => '${e['name']}|${e['sets']}|${e['reps']}|${e['rest']}').join('\n'),
      };

  factory Routine.fromDb(Map<String, dynamic> map) {
    final lines = (map['exercises']?.toString() ?? '').split('\n').where((e) => e.isNotEmpty);
    return Routine(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      goal: map['goal']?.toString() ?? '',
      level: map['level']?.toString() ?? '',
      durationWeeks: map['duration_weeks'] as int? ?? 4,
      exercises: lines.map((line) {
        final p = line.split('|');
        return {
          'name': p.isNotEmpty ? p[0] : '',
          'sets': p.length > 1 ? p[1] : '',
          'reps': p.length > 2 ? p[2] : '',
          'rest': p.length > 3 ? p[3] : '',
        };
      }).toList(),
    );
  }
}

class InventoryItem {
  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.status,
    required this.location,
    this.syncStatus = 'synced',
  });

  final String id;
  final String name;
  final String category;
  final int quantity;
  final String status;
  final String location;
  final String syncStatus;

  factory InventoryItem.fromApi(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      quantity: asInt(map['quantity']),
      status: map['status']?.toString() ?? 'operativo',
      location: map['location']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toDb() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'status': status,
        'location': location,
        'sync_status': syncStatus,
      };

  factory InventoryItem.fromDb(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      quantity: map['quantity'] as int? ?? 0,
      status: map['status']?.toString() ?? 'operativo',
      location: map['location']?.toString() ?? '',
      syncStatus: map['sync_status']?.toString() ?? 'synced',
    );
  }

  Map<String, dynamic> toApi() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'status': status,
        'location': location,
      };

  InventoryItem copyWith({String? syncStatus}) {
    return InventoryItem(
      id: id,
      name: name,
      category: category,
      quantity: quantity,
      status: status,
      location: location,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}

class QueueItem {
  QueueItem({required this.id, required this.entity, required this.operation, required this.record});

  final int id;
  final String entity;
  final String operation;
  final Map<String, dynamic> record;
}
