class UserModel {
  final int id;
  final String name;
  final String username;
  final String? email;
  final int? employeeId;
  final int? departmentId;
  final String userType;
  final bool isInterviewer;
  final String? interviewerType;
  final bool status;
  final bool verified;
  final String? roleLabel;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    this.email,
    this.employeeId,
    this.departmentId,
    required this.userType,
    required this.isInterviewer,
    this.interviewerType,
    required this.status,
    required this.verified,
    this.roleLabel,
  });

  UserModel copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    int? employeeId,
    int? departmentId,
    String? userType,
    bool? isInterviewer,
    String? interviewerType,
    bool? status,
    bool? verified,
    String? roleLabel,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      employeeId: employeeId ?? this.employeeId,
      departmentId: departmentId ?? this.departmentId,
      userType: userType ?? this.userType,
      isInterviewer: isInterviewer ?? this.isInterviewer,
      interviewerType: interviewerType ?? this.interviewerType,
      status: status ?? this.status,
      verified: verified ?? this.verified,
      roleLabel: roleLabel ?? this.roleLabel,
    );
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      employeeId: _parseInt(json['employee_id']),
      departmentId: _parseInt(json['department_id']),
      userType: json['user_type']?.toString() ?? 'regular_user',
      isInterviewer: json['is_interviewer'] == 1 || json['is_interviewer'] == true || json['is_interviewer']?.toString() == 'true' || json['is_interviewer']?.toString() == '1',
      interviewerType: json['interviewer_type']?.toString(),
      status: json['status'] == 1 || json['status'] == true || json['status']?.toString() == 'true' || json['status']?.toString() == '1',
      verified: json['verified'] == 1 || json['verified'] == true || json['verified']?.toString() == 'true' || json['verified']?.toString() == '1',
      roleLabel: json['role_label']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'employee_id': employeeId,
      'department_id': departmentId,
      'user_type': userType,
      'is_interviewer': isInterviewer,
      'interviewer_type': interviewerType,
      'status': status,
      'verified': verified,
      'role_label': roleLabel,
    };
  }
}

class RoleModel {
  final int id;
  final String name;
  final String? type;

  RoleModel({required this.id, required this.name, this.type});

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
    };
  }
}

class LoginResponse {
  final String token;
  final UserModel user;
  final List<RoleModel> roles;
  final List<String> permissions;

  LoginResponse({
    required this.token,
    required this.user,
    required this.roles,
    required this.permissions,
  });

  LoginResponse copyWith({
    String? token,
    UserModel? user,
    List<RoleModel>? roles,
    List<String>? permissions,
  }) {
    return LoginResponse(
      token: token ?? this.token,
      user: user ?? this.user,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
    );
  }

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final rolesList = (json['roles'] as List? ?? [])
        .map((role) => RoleModel.fromJson(role as Map<String, dynamic>))
        .toList();
    final permsList = (json['permissions'] as List? ?? [])
        .map((perm) => perm.toString())
        .toList();

    return LoginResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      roles: rolesList,
      permissions: permsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
      'roles': roles.map((r) => r.toJson()).toList(),
      'permissions': permissions,
    };
  }
}
