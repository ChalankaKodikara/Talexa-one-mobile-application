class EmployeeClaim {
  final int id;
  final String claimType;
  final double claimAmount;
  final String requestedDate;
  final String finalStatus;

  EmployeeClaim({
    required this.id,
    required this.claimType,
    required this.claimAmount,
    required this.requestedDate,
    required this.finalStatus,
  });

  factory EmployeeClaim.fromJson(Map<String, dynamic> json) {
    return EmployeeClaim(
      id: json['id'],
      claimType: json['ClaimConfiguration']['claim_type'],
      claimAmount: double.parse(json['claim_amount']),
      requestedDate: json['claim_requested_date'],
      finalStatus: json['final_status'],
    );
  }
}
