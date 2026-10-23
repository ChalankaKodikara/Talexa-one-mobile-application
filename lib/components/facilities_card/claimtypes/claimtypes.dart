class ClaimType {
  final int id;
  final String claimType;
  final double claimAmount;
  final int policyPeriodMonths;
  final bool isActive;

  ClaimType({
    required this.id,
    required this.claimType,
    required this.claimAmount,
    required this.policyPeriodMonths,
    required this.isActive,
  });

  factory ClaimType.fromJson(Map<String, dynamic> json) {
    return ClaimType(
      id: json['id'],
      claimType: json['claim_type'],
      claimAmount: double.parse(json['claim_amount'].toString()),
      policyPeriodMonths: json['policy_period_months'],
      isActive: json['is_active'] == true,
    );
  }
}
