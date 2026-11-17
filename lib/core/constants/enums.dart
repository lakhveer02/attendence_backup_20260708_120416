/// User Roles in the System per Architecture Blueprint
/// IMPORTANT: These role values must match the backend API expectations
/// 
/// Definitive Role Hierarchy:
/// 1. Super Admin - Platform owner, system-wide monitoring
/// 2. Company Admin - Tenant owner, full workspace ownership
/// 3. HR Manager - Personnel operations, department oversight
/// 4. Manager - Team lead, bounded to direct reports only
/// 5. Employee - End-user, personal data access only
/// 
/// Role Creation Permissions:
/// - Company Admin → can create HR Manager, Manager
/// - HR Manager → can create Employee, Manager
/// - Manager → can create Employee only
/// - Employee → cannot create anyone
enum UserRole {
  superAdmin('super_admin', 'Super Admin', 'Platform owner - system-wide access'),
  companyAdmin('company_admin', 'Company Admin', 'Tenant owner - full workspace control'),
  hrManager('hr_manager', 'HR Manager', 'Personnel operations and department oversight'),
  teamManager('team_manager', 'Team Manager', 'Team lead - direct reports visibility only'),
  employee('employee', 'Employee', 'End-user - personal data access only');

  final String value;
  final String displayName;
  final String description;

  const UserRole(this.value, this.displayName, this.description);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.employee,
    );
  }

  bool get isSuperAdmin => this == UserRole.superAdmin;
  bool get isCompanyAdmin => this == UserRole.companyAdmin;
  bool get isHRManager => this == UserRole.hrManager;
  bool get isTeamManager => this == UserRole.teamManager;
  bool get isEmployee => this == UserRole.employee;

  bool get canManageCompanies => isSuperAdmin;
  bool get canManageEmployees => isSuperAdmin || isCompanyAdmin || isHRManager;
  bool get canManageTeam => isSuperAdmin || isCompanyAdmin || isHRManager || isTeamManager;
  bool get canViewReports => this != UserRole.employee;
  
  /// Returns roles this user can create based on hierarchy
  List<UserRole> get canCreateRoles {
    switch (this) {
      case UserRole.superAdmin:
        return [UserRole.superAdmin, UserRole.companyAdmin, UserRole.hrManager, UserRole.teamManager, UserRole.employee];
      case UserRole.companyAdmin:
        return [UserRole.hrManager, UserRole.teamManager];
      case UserRole.hrManager:
        return [UserRole.employee, UserRole.teamManager];
      case UserRole.teamManager:
        return [UserRole.employee];
      case UserRole.employee:
        return [];
    }
  }
}

/// Attendance Status
enum AttendanceStatus {
  checkedIn('checked_in', 'Checked In', 'Currently at work'),
  checkedOut('checked_out', 'Checked Out', 'Left work for the day'),
  onBreak('on_break', 'On Break', 'Taking a break'),
  absent('absent', 'Absent', 'Not present'),
  late('late', 'Late', 'Arrived late'),
  halfDay('half_day', 'Half Day', 'Half day present');

  final String value;
  final String displayName;
  final String description;

  const AttendanceStatus(this.value, this.displayName, this.description);

  static AttendanceStatus fromString(String value) {
    return AttendanceStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AttendanceStatus.absent,
    );
  }
}

/// Attendance Verification Method
enum AttendanceMethod {
  gps('gps', 'GPS Location', 'Location-based check-in'),
  faceRecognition('face', 'Face Recognition', 'Face verification'),
  fingerprint('fingerprint', 'Fingerprint', 'Biometric authentication'),
  qrCode('qr', 'QR Code', 'Scan QR code'),
  wifi('wifi', 'WiFi', 'WiFi-based verification'),
  bluetooth('bluetooth', 'Bluetooth', 'Beacon proximity'),
  manual('manual', 'Manual', 'Manual entry by admin');

  final String value;
  final String displayName;
  final String description;

  const AttendanceMethod(this.value, this.displayName, this.description);

  static AttendanceMethod fromString(String value) {
    return AttendanceMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => AttendanceMethod.manual,
    );
  }
}

/// Leave Type
enum LeaveType {
  casual('casual', 'Casual Leave', 'General purpose leave'),
  sick('sick', 'Sick Leave', 'Medical leave'),
  earned('earned', 'Earned Leave', 'Annual leave'),
  halfDay('half_day', 'Half Day', 'Half day leave'),
  emergency('emergency', 'Emergency Leave', 'Urgent leave'),
  unpaid('unpaid', 'Unpaid Leave', 'Leave without pay'),
  maternity('maternity', 'Maternity Leave', 'Maternity leave'),
  paternity('paternity', 'Paternity Leave', 'Paternity leave'),
  compensatory('compensatory', 'Compensatory Leave', 'Comp-off leave');

  final String value;
  final String displayName;
  final String description;

  const LeaveType(this.value, this.displayName, this.description);

  static LeaveType fromString(String value) {
    return LeaveType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => LeaveType.casual,
    );
  }
}

/// Leave Status
enum LeaveStatus {
  pending('pending', 'Pending', 'Awaiting approval'),
  approved('approved', 'Approved', 'Request approved'),
  rejected('rejected', 'Rejected', 'Request rejected'),
  cancelled('cancelled', 'Cancelled', 'Request cancelled');

  final String value;
  final String displayName;
  final String description;

  const LeaveStatus(this.value, this.displayName, this.description);

  static LeaveStatus fromString(String value) {
    return LeaveStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => LeaveStatus.pending,
    );
  }
}

/// Task Priority
enum TaskPriority {
  low('low', 'Low', 'Low priority'),
  medium('medium', 'Medium', 'Medium priority'),
  high('high', 'High', 'High priority'),
  urgent('urgent', 'Urgent', 'Urgent priority');

  final String value;
  final String displayName;
  final String description;

  const TaskPriority(this.value, this.displayName, this.description);

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

/// Task Status
enum TaskStatus {
  todo('todo', 'To Do', 'Not started'),
  inProgress('in_progress', 'In Progress', 'Currently working'),
  review('review', 'In Review', 'Under review'),
  completed('completed', 'Completed', 'Task completed'),
  cancelled('cancelled', 'Cancelled', 'Task cancelled');

  final String value;
  final String displayName;
  final String description;

  const TaskStatus(this.value, this.displayName, this.description);

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

/// Work Mode
enum WorkMode {
  office('office', 'Office', 'Working from office'),
  remote('remote', 'Remote', 'Working remotely'),
  hybrid('hybrid', 'Hybrid', 'Hybrid work mode'),
  fieldWork('field_work', 'Field Work', 'Working in field');

  final String value;
  final String displayName;
  final String description;

  const WorkMode(this.value, this.displayName, this.description);

  static WorkMode fromString(String value) {
    return WorkMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => WorkMode.office,
    );
  }
}

/// Shift Type
enum ShiftType {
  morning('morning', 'Morning Shift', '6 AM - 2 PM'),
  day('day', 'Day Shift', '9 AM - 5 PM'),
  evening('evening', 'Evening Shift', '2 PM - 10 PM'),
  night('night', 'Night Shift', '10 PM - 6 AM'),
  flexible('flexible', 'Flexible', 'Flexible hours');

  final String value;
  final String displayName;
  final String description;

  const ShiftType(this.value, this.displayName, this.description);

  static ShiftType fromString(String value) {
    return ShiftType.values.firstWhere(
      (shift) => shift.value == value,
      orElse: () => ShiftType.day,
    );
  }
}

/// Notification Type
enum NotificationType {
  attendance('attendance', 'Attendance'),
  leave('leave', 'Leave'),
  task('task', 'Task'),
  announcement('announcement', 'Announcement'),
  reminder('reminder', 'Reminder'),
  birthday('birthday', 'Birthday'),
  holiday('holiday', 'Holiday'),
  system('system', 'System');

  final String value;
  final String displayName;

  const NotificationType(this.value, this.displayName);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => NotificationType.system,
    );
  }
}

/// Report Type
enum ReportType {
  attendance('attendance', 'Attendance Report'),
  leave('leave', 'Leave Report'),
  productivity('productivity', 'Productivity Report'),
  overtime('overtime', 'Overtime Report'),
  department('department', 'Department Report'),
  payroll('payroll', 'Payroll Report'),
  monthly('monthly', 'Monthly Summary');

  final String value;
  final String displayName;

  const ReportType(this.value, this.displayName);

  static ReportType fromString(String value) {
    return ReportType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ReportType.attendance,
    );
  }
}

/// Export Format
enum ExportFormat {
  pdf('pdf', 'PDF', 'Portable Document Format'),
  excel('excel', 'Excel', 'Microsoft Excel'),
  csv('csv', 'CSV', 'Comma-separated values');

  final String value;
  final String displayName;
  final String description;

  const ExportFormat(this.value, this.displayName, this.description);
}

/// Subscription Plan
enum SubscriptionPlan {
  free('free', 'Free', 'Basic features', 0),
  starter('starter', 'Starter', 'Small teams', 9.99),
  professional('professional', 'Professional', 'Growing businesses', 29.99),
  enterprise('enterprise', 'Enterprise', 'Large organizations', 99.99);

  final String value;
  final String displayName;
  final String description;
  final double price;

  const SubscriptionPlan(this.value, this.displayName, this.description, this.price);

  static SubscriptionPlan fromString(String value) {
    return SubscriptionPlan.values.firstWhere(
      (plan) => plan.value == value,
      orElse: () => SubscriptionPlan.free,
    );
  }
}


/// Authentication Method
enum AuthMethod {
  email('email', 'Email/Password'),
  mobileOTP('mobile_otp', 'Mobile OTP'),
  google('google', 'Google'),
  apple('apple', 'Apple'),
  microsoft('microsoft', 'Microsoft'),
  biometric('biometric', 'Biometric'),
  faceID('face_id', 'Face ID'),
  fingerprint('fingerprint_auth', 'Fingerprint');

  final String value;
  final String displayName;

  const AuthMethod(this.value, this.displayName);

  static AuthMethod fromString(String value) {
    return AuthMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => AuthMethod.email,
    );
  }
}

/// Expense Type
enum ExpenseType {
  travel('travel', 'Travel'),
  food('food', 'Food/Meals'),
  accommodation('accommodation', 'Accommodation'),
  fuel('fuel', 'Fuel'),
  officeSupplies('office_supplies', 'Office Supplies'),
  clientEntertainment('client_entertainment', 'Client Entertainment'),
  training('training', 'Training'),
  medical('medical', 'Medical'),
  communication('communication', 'Mobile/Internet'),
  miscellaneous('miscellaneous', 'Miscellaneous');

  final String value;
  final String displayName;

  const ExpenseType(this.value, this.displayName);

  static ExpenseType fromString(String value) {
    return ExpenseType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ExpenseType.miscellaneous,
    );
  }
}

/// Expense Status
enum ExpenseStatus {
  draft('draft', 'Draft'),
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  reimbursed('reimbursed', 'Reimbursed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String displayName;

  const ExpenseStatus(this.value, this.displayName);

  static ExpenseStatus fromString(String value) {
    return ExpenseStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ExpenseStatus.pending,
    );
  }
}

/// Recruitment Status
enum RecruitmentStatus {
  sourcing('sourcing', 'Sourcing'),
  screening('screening', 'Screening'),
  interview('interview', 'Interview'),
  evaluation('evaluation', 'Evaluation'),
  offer('offer', 'Offer'),
  hired('hired', 'Hired'),
  rejected('rejected', 'Rejected'),
  withdrawn('withdrawn', 'Withdrawn');

  final String value;
  final String displayName;

  const RecruitmentStatus(this.value, this.displayName);

  static RecruitmentStatus fromString(String value) {
    return RecruitmentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RecruitmentStatus.sourcing,
    );
  }
}

/// Employee Status
enum EmployeeStatus {
  active('active', 'Active'),
  inactive('inactive', 'Inactive'),
  onLeave('on_leave', 'On Leave'),
  probation('probation', 'Probation'),
  notice('notice', 'Notice Period'),
  terminated('terminated', 'Terminated'),
  resigned('resigned', 'Resigned');

  final String value;
  final String displayName;

  const EmployeeStatus(this.value, this.displayName);

  static EmployeeStatus fromString(String value) {
    return EmployeeStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => EmployeeStatus.active,
    );
  }
}

/// Document Type
enum DocumentType {
  identityProof('identity_proof', 'Identity Proof'),
  addressProof('address_proof', 'Address Proof'),
  education('education', 'Educational Certificate'),
  experience('experience', 'Experience Letter'),
  offerLetter('offer_letter', 'Offer Letter'),
  appointment('appointment', 'Appointment Letter'),
  bankDocument('bank_document', 'Bank Document'),
  medical('medical', 'Medical Certificate'),
  vaccination('vaccination', 'Vaccination Record'),
  other('other', 'Other');

  final String value;
  final String displayName;

  const DocumentType(this.value, this.displayName);

  static DocumentType fromString(String value) {
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentType.other,
    );
  }
}

/// Meeting Type
enum MeetingType {
  audio('audio', 'Audio Call'),
  video('video', 'Video Call'),
  conference('conference', 'Conference'),
  oneOnOne('one_on_one', 'One-on-One');

  final String value;
  final String displayName;

  const MeetingType(this.value, this.displayName);

  static MeetingType fromString(String value) {
    return MeetingType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MeetingType.audio,
    );
  }
}

/// Asset Type
enum AssetType {
  laptop('laptop', 'Laptop'),
  desktop('desktop', 'Desktop'),
  mobile('mobile', 'Mobile Phone'),
  tablet('tablet', 'Tablet'),
  accessory('accessory', 'Accessory'),
  furniture('furniture', 'Furniture'),
  vehicle('vehicle', 'Vehicle'),
  equipment('equipment', 'Equipment'),
  other('other', 'Other');

  final String value;
  final String displayName;

  const AssetType(this.value, this.displayName);

  static AssetType fromString(String value) {
    return AssetType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AssetType.other,
    );
  }
}

/// Training Status
enum TrainingStatus {
  scheduled('scheduled', 'Scheduled'),
  ongoing('ongoing', 'Ongoing'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled'),
  pending('pending', 'Pending');

  final String value;
  final String displayName;

  const TrainingStatus(this.value, this.displayName);

  static TrainingStatus fromString(String value) {
    return TrainingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TrainingStatus.pending,
    );
  }
}

/// Performance Rating
enum PerformanceRating {
  outstanding('outstanding', 'Outstanding', 5),
  exceeds('exceeds', 'Exceeds Expectations', 4),
  meets('meets', 'Meets Expectations', 3),
  needs('needs', 'Needs Improvement', 2),
  unsatisfactory('unsatisfactory', 'Unsatisfactory', 1);

  final String value;
  final String displayName;
  final int score;

  const PerformanceRating(this.value, this.displayName, this.score);

  static PerformanceRating fromString(String value) {
    return PerformanceRating.values.firstWhere(
      (rating) => rating.value == value,
      orElse: () => PerformanceRating.meets,
    );
  }
}

/// Travel Request Status
enum TravelRequestStatus {
  pending('pending', 'Pending'),
  approved('approved', 'Approved'),
  rejected('rejected', 'Rejected'),
  inProgress('in_progress', 'In Progress'),
  completed('completed', 'Completed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String displayName;

  const TravelRequestStatus(this.value, this.displayName);

  static TravelRequestStatus fromString(String value) {
    return TravelRequestStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TravelRequestStatus.pending,
    );
  }
}

/// Payroll Status
enum PayrollStatus {
  draft('draft', 'Draft'),
  processed('processed', 'Processed'),
  approved('approved', 'Approved'),
  paid('paid', 'Paid'),
  failed('failed', 'Failed'),
  cancelled('cancelled', 'Cancelled');

  final String value;
  final String displayName;

  const PayrollStatus(this.value, this.displayName);

  static PayrollStatus fromString(String value) {
    return PayrollStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PayrollStatus.draft,
    );
  }
}

/// Chart Type
enum ChartType {
  line('line', 'Line Chart'),
  bar('bar', 'Bar Chart'),
  pie('pie', 'Pie Chart'),
  doughnut('doughnut', 'Doughnut Chart'),
  area('area', 'Area Chart'),
  scatter('scatter', 'Scatter Plot'),
  radar('radar', 'Radar Chart'),
  heatmap('heatmap', 'Heat Map');

  final String value;
  final String displayName;

  const ChartType(this.value, this.displayName);
}

/// Time Period
enum TimePeriod {
  today('today', 'Today'),
  yesterday('yesterday', 'Yesterday'),
  thisWeek('this_week', 'This Week'),
  lastWeek('last_week', 'Last Week'),
  thisMonth('this_month', 'This Month'),
  lastMonth('last_month', 'Last Month'),
  thisQuarter('this_quarter', 'This Quarter'),
  lastQuarter('last_quarter', 'Last Quarter'),
  thisYear('this_year', 'This Year'),
  lastYear('last_year', 'Last Year'),
  custom('custom', 'Custom Range');

  final String value;
  final String displayName;

  const TimePeriod(this.value, this.displayName);

  static TimePeriod fromString(String value) {
    return TimePeriod.values.firstWhere(
      (period) => period.value == value,
      orElse: () => TimePeriod.today,
    );
  }
}

/// Gender
enum Gender {
  male('male', 'Male'),
  female('female', 'Female'),
  other('other', 'Other'),
  preferNotToSay('prefer_not_to_say', 'Prefer not to say');

  final String value;
  final String displayName;

  const Gender(this.value, this.displayName);

  static Gender fromString(String value) {
    return Gender.values.firstWhere(
      (gender) => gender.value == value,
      orElse: () => Gender.preferNotToSay,
    );
  }
}

/// Employment Type
enum EmploymentType {
  fullTime('full_time', 'Full Time'),
  partTime('part_time', 'Part Time'),
  contract('contract', 'Contract'),
  freelance('freelance', 'Freelance'),
  intern('intern', 'Intern'),
  temporary('temporary', 'Temporary');

  final String value;
  final String displayName;

  const EmploymentType(this.value, this.displayName);

  static EmploymentType fromString(String value) {
    return EmploymentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => EmploymentType.fullTime,
    );
  }
}

/// Message Type
enum MessageType {
  text('text', 'Text'),
  image('image', 'Image'),
  file('file', 'File'),
  audio('audio', 'Audio'),
  video('video', 'Video'),
  location('location', 'Location'),
  contact('contact', 'Contact');

  final String value;
  final String displayName;

  const MessageType(this.value, this.displayName);

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.text,
    );
  }
}
