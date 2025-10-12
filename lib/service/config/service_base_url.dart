// lib/service/config/service_base_url.dart

class ServiceBaseUrl {
  // Change this one line when moving between local and production
  static const String baseUrl = "https://carentaph.com/carenta/api/";

  // Helper to build full API URLs
  static String endpoint(String path) => "$baseUrl$path";
}
