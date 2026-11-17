/// Multi-Company/Organization Model
/// Supports multiple companies using the same app
class Company {
  final String id;
  final String name;
  final String? description;
  final String? industry;
  final CompanySize size;
  final CompanyStatus status;
  final String? website;
  final String? logoUrl;
  final String? address;
  final String? city;
  final String? country;
  final String timezone;
  final int employeeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    this.description,
    this.industry,
    required this.size,
    required this.status,
    this.website,
    this.logoUrl,
    this.address,
    this.city,
    this.country,
    required this.timezone,
    this.employeeCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse size
    CompanySize parseSize(dynamic value) {
      if (value == null) return CompanySize.small;
      final sizeStr = value.toString().toLowerCase();
      return CompanySize.values.firstWhere(
        (e) => e.name.toLowerCase() == sizeStr,
        orElse: () => CompanySize.small,
      );
    }

    // Helper to safely parse status
    CompanyStatus parseStatus(dynamic value) {
      if (value == null) return CompanyStatus.active;
      final statusStr = value.toString().toLowerCase();
      return CompanyStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statusStr,
        orElse: () => CompanyStatus.active,
      );
    }

    return Company(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      industry: json['industry']?.toString(),
      size: parseSize(json['size']),
      status: parseStatus(json['status']),
      website: json['website']?.toString(),
      logoUrl: json['logo_url']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      timezone: json['timezone']?.toString() ?? 'UTC',
      employeeCount: (json['employee_count'] is int) 
          ? json['employee_count'] as int
          : int.tryParse(json['employee_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'industry': industry,
      'size': size.name,
      'status': status.name,
      'website': website,
      'logo_url': logoUrl,
      'address': address,
      'city': city,
      'country': country,
      'timezone': timezone,
      'employee_count': employeeCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Company copyWith({
    String? id,
    String? name,
    String? description,
    String? industry,
    CompanySize? size,
    CompanyStatus? status,
    String? website,
    String? logoUrl,
    String? address,
    String? city,
    String? country,
    String? timezone,
    int? employeeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      industry: industry ?? this.industry,
      size: size ?? this.size,
      status: status ?? this.status,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
      employeeCount: employeeCount ?? this.employeeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Company size categories
enum CompanySize {
  small, // 1-50 employees
  medium, // 51-500 employees
  large, // 501-5000 employees
  enterprise, // 5000+ employees
}

/// Company status
enum CompanyStatus {
  active,
  suspended,
  trial,
  inactive,
}

extension CompanySizeExtension on CompanySize {
  String get displayName {
    switch (this) {
      case CompanySize.small:
        return 'Small (1-50)';
      case CompanySize.medium:
        return 'Medium (51-500)';
      case CompanySize.large:
        return 'Large (501-5000)';
      case CompanySize.enterprise:
        return 'Enterprise (5000+)';
    }
  }

  String get icon {
    switch (this) {
      case CompanySize.small:
        return '🏢';
      case CompanySize.medium:
        return '🏭';
      case CompanySize.large:
        return '🏙️';
      case CompanySize.enterprise:
        return '🌆';
    }
  }
}

extension CompanyStatusExtension on CompanyStatus {
  String get displayName {
    switch (this) {
      case CompanyStatus.active:
        return 'Active';
      case CompanyStatus.suspended:
        return 'Suspended';
      case CompanyStatus.trial:
        return 'Trial';
      case CompanyStatus.inactive:
        return 'Inactive';
    }
  }

  String get color {
    switch (this) {
      case CompanyStatus.active:
        return '#10B981';
      case CompanyStatus.suspended:
        return '#EF4444';
      case CompanyStatus.trial:
        return '#F59E0B';
      case CompanyStatus.inactive:
        return '#6B7280';
    }
  }
}
