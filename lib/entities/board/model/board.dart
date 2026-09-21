/// Board domain model representing an isolated Kanban workspace in Pin.
class Board {
  /// Default identifier for the primary personal board.
  static const String defaultPersonalId = 'personal';

  /// Default identifier for the projects board.
  static const String defaultProjectsId = 'projects';

  /// Unique board identifier (e.g., 'personal', 'projects', or UUID).
  final String id;

  /// User-visible board title (e.g., 'Personal', 'Projects').
  final String name;

  /// Icon identifier or symbol for the board.
  final String icon;

  /// Maximum number of active tasks permitted in 'Today' for this board.
  final int wipLimit;

  /// Whether this board is the primary default workspace.
  final bool isDefault;

  /// Timestamp when this board was created.
  final DateTime createdAt;

  const Board({
    required this.id,
    required this.name,
    this.icon = 'user',
    this.wipLimit = 3,
    this.isDefault = false,
    required this.createdAt,
  });

  /// The pre-configured default Personal board.
  static final Board personal = Board(
    id: defaultPersonalId,
    name: 'Personal',
    icon: 'user',
    wipLimit: 3,
    isDefault: true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// The pre-configured default Projects board.
  static final Board projects = Board(
    id: defaultProjectsId,
    name: 'Projects',
    icon: 'briefcase',
    wipLimit: 3,
    isDefault: false,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Default initial board list for new users (single board by default).
  static final List<Board> defaultBoards = [personal];

  /// Creates a copy of this board with optional parameter overrides.
  Board copyWith({
    String? id,
    String? name,
    String? icon,
    int? wipLimit,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Board(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      wipLimit: wipLimit ?? this.wipLimit,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Converts this board instance into a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'wipLimit': wipLimit,
      'isDefault': isDefault,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Deserializes a [Board] instance from a JSON map.
  factory Board.fromJson(Map<String, dynamic> json) {
    return Board(
      id: json['id'] as String? ?? defaultPersonalId,
      name: json['name'] as String? ?? 'Personal',
      icon: json['icon'] as String? ?? 'user',
      wipLimit: (json['wipLimit'] as num?)?.toInt() ?? 3,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: json['createdAt'] is num
          ? DateTime.fromMillisecondsSinceEpoch((json['createdAt'] as num).toInt())
          : DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Board &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          icon == other.icon &&
          wipLimit == other.wipLimit &&
          isDefault == other.isDefault;

  @override
  int get hashCode => Object.hash(id, name, icon, wipLimit, isDefault);
}
