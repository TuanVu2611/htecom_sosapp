// ignore_for_file: file_names

enum AuthUserRole { student, staff }

class AuthUserSettingsEntity {
  const AuthUserSettingsEntity({
    this.pushEnabled = true,
    this.sosSoundEnabled = true,
    this.language,
    this.darkMode = false,
    this.workTime = false,
    this.supportArea = false,
  });

  final bool pushEnabled;
  final bool sosSoundEnabled;
  final String? language;
  final bool darkMode;
  final bool workTime;
  final bool supportArea;
}

class AuthUserCardEntity {
  const AuthUserCardEntity({
    this.frontFileId,
    this.frontUrl,
    this.backFileId,
    this.backUrl,
  });

  final int? frontFileId;
  final String? frontUrl;
  final int? backFileId;
  final String? backUrl;
}

class AuthUserStaffWorkEntity {
  const AuthUserStaffWorkEntity({
    this.employeeCode,
    this.departmentName,
    this.ktxDepartmentName,
    this.department,
    this.jobTitle,
    this.employeeTypeLabel,
    this.statusLabel,
    this.zone,
    this.rating,
    this.roleLabel,
    this.staffActive,
  });

  final String? employeeCode;
  final String? departmentName;
  final String? ktxDepartmentName;
  final String? department;
  final String? jobTitle;
  final String? employeeTypeLabel;
  final String? statusLabel;
  final String? zone;
  final double? rating;
  final String? roleLabel;
  final bool? staffActive;
}

class AuthUserStaffStatisticsEntity {
  const AuthUserStaffStatisticsEntity({
    this.completed = 0,
    this.totalAssigned = 0,
    this.completionRate = 0,
    this.performanceRate = 0,
    this.avgProcessingTimeMinutes = 0,
    this.ratingAvg,
  });

  final int completed;
  final int totalAssigned;
  final double completionRate;
  final double performanceRate;
  final double avgProcessingTimeMinutes;
  final double? ratingAvg;
}

class AuthUserEntity {
  const AuthUserEntity({
    required this.id,
    required this.displayName,
    required this.role,
    this.availableRoles = const [],
    this.phone,
    this.studentCode,
    this.staffCode,
    this.email,
    this.avatarUrl,
    this.schoolId,
    this.schoolName,
    this.displayCode,
    this.cccd,
    this.studentCardNumber,
    this.major,
    this.roomBuilding,
    this.ktxArea,
    this.department,
    this.departmentName,
    this.ktxDepartmentName,
    this.staffActive,
    this.studentCard,
    this.nationalCard,
    this.staffWork,
    this.staffStatistics,
    this.settings = const AuthUserSettingsEntity(),
    this.isVerified = false,
    this.isBlocked = false,
  });

  final String id;
  final String displayName;
  final AuthUserRole role;
  final List<AuthUserRole> availableRoles;
  final String? phone;
  final String? studentCode;
  final String? staffCode;
  final String? email;
  final String? avatarUrl;
  final String? schoolId;
  final String? schoolName;
  final String? displayCode;
  final String? cccd;
  final String? studentCardNumber;
  final String? major;
  final String? roomBuilding;
  final String? ktxArea;
  final String? department;
  final String? departmentName;
  final String? ktxDepartmentName;
  final bool? staffActive;
  final AuthUserCardEntity? studentCard;
  final AuthUserCardEntity? nationalCard;
  final AuthUserStaffWorkEntity? staffWork;
  final AuthUserStaffStatisticsEntity? staffStatistics;
  final AuthUserSettingsEntity settings;
  final bool isVerified;
  final bool isBlocked;

  AuthUserEntity copyWith({
    String? id,
    String? displayName,
    AuthUserRole? role,
    List<AuthUserRole>? availableRoles,
    String? phone,
    String? studentCode,
    String? staffCode,
    String? email,
    String? avatarUrl,
    String? schoolId,
    String? schoolName,
    String? displayCode,
    String? cccd,
    String? studentCardNumber,
    String? major,
    String? roomBuilding,
    String? ktxArea,
    String? department,
    String? departmentName,
    String? ktxDepartmentName,
    bool? staffActive,
    AuthUserCardEntity? studentCard,
    AuthUserCardEntity? nationalCard,
    AuthUserStaffWorkEntity? staffWork,
    AuthUserStaffStatisticsEntity? staffStatistics,
    AuthUserSettingsEntity? settings,
    bool? isVerified,
    bool? isBlocked,
  }) {
    return AuthUserEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      availableRoles: availableRoles ?? this.availableRoles,
      phone: phone ?? this.phone,
      studentCode: studentCode ?? this.studentCode,
      staffCode: staffCode ?? this.staffCode,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      displayCode: displayCode ?? this.displayCode,
      cccd: cccd ?? this.cccd,
      studentCardNumber: studentCardNumber ?? this.studentCardNumber,
      major: major ?? this.major,
      roomBuilding: roomBuilding ?? this.roomBuilding,
      ktxArea: ktxArea ?? this.ktxArea,
      department: department ?? this.department,
      departmentName: departmentName ?? this.departmentName,
      ktxDepartmentName: ktxDepartmentName ?? this.ktxDepartmentName,
      staffActive: staffActive ?? this.staffActive,
      studentCard: studentCard ?? this.studentCard,
      nationalCard: nationalCard ?? this.nationalCard,
      staffWork: staffWork ?? this.staffWork,
      staffStatistics: staffStatistics ?? this.staffStatistics,
      settings: settings ?? this.settings,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
