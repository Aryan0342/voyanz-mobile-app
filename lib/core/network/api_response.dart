/// Standard envelope used by the Visioco REST API.
///
/// Success: `{ "data": ..., "err": null, "meta": {} }`
/// Error:   `{ "data": null, "err": { "code": ..., "status": ..., "message": ... } }`
class ApiResponse<T> {
  final T? data;
  final ApiError? err;
  final Map<String, dynamic>? meta;

  const ApiResponse({this.data, this.err, this.meta});

  bool get isSuccess => err == null;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json) fromJsonT,
  ) {
    return ApiResponse(
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      err: json['err'] != null
          ? ApiError.fromJson(json['err'] as Map<String, dynamic>)
          : null,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}

class ApiError {
  final String? code;
  final int? status;
  final String? message;

  const ApiError({this.code, this.status, this.message});

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String?,
      status: json['status'] as int?,
      message: json['message'] as String?,
    );
  }

  @override
  String toString() => 'ApiError($code, $status, $message)';
}
