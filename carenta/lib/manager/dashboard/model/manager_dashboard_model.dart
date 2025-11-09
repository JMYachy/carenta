// lib/feature/manager/dashboard/model/manager_dashboard_model.dart
class DashboardOverview {
  final int availableVehicles;
  final int activeBookings;
  final int pendingVerifications;
  final int maintenanceVehicles;
  final int overdueRentals;
  final int rentalsToday;
  final int returnsNext3;
  final double earningsToday;

  DashboardOverview({
    required this.availableVehicles,
    required this.activeBookings,
    required this.pendingVerifications,
    required this.maintenanceVehicles,
    required this.overdueRentals,
    required this.rentalsToday,
    required this.returnsNext3,
    required this.earningsToday,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    return DashboardOverview(
      availableVehicles: int.tryParse(json['available_vehicles'].toString()) ?? 0,
      activeBookings: int.tryParse(json['active_bookings'].toString()) ?? 0,
      pendingVerifications:
          int.tryParse(json['pending_verifications'].toString()) ?? 0,
      maintenanceVehicles:
          int.tryParse(json['maintenance_vehicles'].toString()) ?? 0,
      overdueRentals: int.tryParse(json['overdue_rentals'].toString()) ?? 0,
      rentalsToday: int.tryParse(json['rentals_today'].toString()) ?? 0,
      returnsNext3: int.tryParse(json['returns_next3'].toString()) ?? 0,
      earningsToday:
          double.tryParse(json['earnings_today'].toString()) ?? 0.0,
    );
  }
}

class TopModelData {
  final String model;
  final int count;

  TopModelData({required this.model, required this.count});

  factory TopModelData.fromJson(Map<String, dynamic> j) => TopModelData(
        model: j['model'] ?? '',
        count: int.tryParse(j['count'].toString()) ?? 0,
      );
}

class DashboardMessage {
  final String username;
  final String snippet;

  DashboardMessage({required this.username, required this.snippet});

  factory DashboardMessage.fromJson(Map<String, dynamic> j) => DashboardMessage(
        username: j['username'] ?? '',
        snippet: j['snippet'] ?? '',
      );
}

class DashboardFeedback {
  final String username;
  final int rating;
  final String comment;

  DashboardFeedback({
    required this.username,
    required this.rating,
    required this.comment,
  });

  factory DashboardFeedback.fromJson(Map<String, dynamic> j) => DashboardFeedback(
        username: j['username'] ?? '',
        rating: int.tryParse(j['rating'].toString()) ?? 0,
        comment: j['comment'] ?? '',
      );
}
