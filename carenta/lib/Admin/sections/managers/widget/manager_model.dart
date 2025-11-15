class ManagerModel {
  final int adminid;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String status;
  final String? phoneNumber;
  final String? profilePicture;
  final String? lastLogin;
  final String createdAt;

  ManagerModel({
    required this.adminid,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.phoneNumber,
    this.profilePicture,
    this.lastLogin,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory ManagerModel.fromJson(Map<String, dynamic> j) => ManagerModel(
    adminid: j['adminid'],
    username: j['username'] ?? '',
    email: j['email'] ?? '',
    firstName: j['first_name'] ?? '',
    lastName: j['last_name'] ?? '',
    status: j['status'] ?? 'inactive',
    phoneNumber: j['phone_number'],
    profilePicture: j['profile_picture'],
    lastLogin: j['last_login'],
    createdAt: j['created_at'] ?? '',
  );
}
