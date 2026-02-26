class OtpRequestDto {
  final String phone;

  const OtpRequestDto({
    required this.phone,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
    };
  }
}
