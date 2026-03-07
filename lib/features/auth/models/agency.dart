/// Represents the agency branding returned at login.
class Agency {
  final String? agId;
  final String? name;
  final String? logo;
  final String? primaryColor;
  final String? secondaryColor;
  final String? termsUrl;
  final String? aboutText;

  const Agency({
    this.agId,
    this.name,
    this.logo,
    this.primaryColor,
    this.secondaryColor,
    this.termsUrl,
    this.aboutText,
  });

  factory Agency.fromJson(Map<String, dynamic> json) {
    return Agency(
      agId: json['ag_id']?.toString(),
      name: json['ag_name'] as String?,
      logo: json['ag_logo'] as String?,
      primaryColor: json['ag_primary_color'] as String?,
      secondaryColor: json['ag_secondary_color'] as String?,
      termsUrl: json['ag_terms_url'] as String?,
      aboutText: json['ag_about'] as String?,
    );
  }
}
