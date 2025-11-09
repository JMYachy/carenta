import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> payment;
  final Map<String, dynamic>? rental; // optional rental details if available
  const BookingReceiptScreen({
    super.key,
    required this.payment,
    this.rental,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat('#,##0.00', 'en_PH');

    final receiptNo = payment['receipt_no'] ?? 'N/A';
    final referenceNo = payment['reference_no'] ?? 'N/A';
    final paymentPhase = payment['payment_phase']?.toString().toUpperCase() ?? 'FULL';
    final amount = (payment['amount'] != null)
        ? double.tryParse(payment['amount'].toString()) ?? 0.0
        : 0.0;
    final method = payment['method']?.toString().toUpperCase() ?? 'N/A';
    final status = payment['status']?.toString().toUpperCase() ?? 'PENDING';
    final remarks = payment['remarks'] ?? '';
    final createdAt = payment['paid_at'] ?? payment['created_at'] ?? '';
    final rentalId = payment['rentalid'] ?? payment['rental_id'] ?? 'N/A';
    final carName = rental?['car_name'] ?? 'Car Rental #$rentalId';
    final totalDays = rental?['days'] ?? rental?['total_days'] ?? 0;
    final pickup = rental?['pickup_location'] ?? 'N/A';
    final dropoff = rental?['dropoff_location'] ?? 'N/A';
    final rentalStatus = rental?['status']?.toString().toUpperCase() ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text('Payment Receipt'),
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🧾 Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Carenta Official Receipt",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "#$receiptNo",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🧍 User & Booking Info
                Text(
                  "Booking ID: $rentalId",
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                Text("Rental Status: $rentalStatus",
                    style: const TextStyle(color: Colors.grey)),
                const Divider(height: 24),

                // 🚗 Rental Details
                Text(
                  "Vehicle: $carName",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Text("Pickup: $pickup"),
                Text("Drop-off: $dropoff"),
                Text("Duration: $totalDays day(s)"),
                const Divider(height: 24),

                // 💳 Payment Details
                const Text(
                  "Payment Details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildInfoRow("Reference No", referenceNo),
                _buildInfoRow("Payment Phase", paymentPhase),
                _buildInfoRow("Payment Method", method),
                _buildInfoRow("Status", status),
                _buildInfoRow(
                    "Date", createdAt.toString().replaceAll("T", " ").split(".").first),
                const SizedBox(height: 10),

                // 💰 Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Amount Paid",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(
                      "₱${currencyFmt.format(amount)}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (remarks.isNotEmpty)
                  Text("Remarks: $remarks",
                      style: const TextStyle(color: Colors.grey)),
                const Divider(height: 30),

                // ✅ Footer Notice
                Text(
                  status == "REFUNDED"
                      ? "⚠️ This payment has been refunded."
                      : "✅ Thank you for your payment.",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: status == "REFUNDED"
                        ? Colors.redAccent
                        : Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 15),
                Center(
                  child: Text(
                    "Generated by Carenta",
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
