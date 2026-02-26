class OtpVerifyDto {
  final String phone;
  final String code;

  const OtpVerifyDto({
    required this.phone,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'code': code,
    };
  }
}
