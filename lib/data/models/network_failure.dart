import 'package:dio/dio.dart';
import 'package:walleta/data/models/api_failure.dart';

class NetworkFailure extends DioException {
  final RequestOptions request;

  final ApiFailure apiFailure;

  NetworkFailure({
    required this.request,
    required this.apiFailure,
    super.error,
    super.message,
    super.response,
    super.stackTrace,
    super.type,
  }) : super(requestOptions: request);
}
