import 'package:dartz/dartz.dart';
import 'package:zomato_clone/core/error/failures.dart';
import 'package:zomato_clone/domain/entities/rider_entity.dart';
import 'package:zomato_clone/domain/entities/order_entity.dart';

abstract class RiderRepository {
  Future<Either<Failure, RiderEntity>> getRiderProfile({
    required String riderId,
  });

  Future<Either<Failure, bool>> updateRiderProfile({
    required String riderId,
    required Map<String, dynamic> data,
  });

  Future<Either<Failure, bool>> updateRiderLocation({
    required String riderId,
    required double latitude,
    required double longitude,
  });

  Future<Either<Failure, bool>> setOnlineStatus({
    required String riderId,
    required bool isOnline,
  });

  Future<Either<Failure, bool>> setAvailableStatus({
    required String riderId,
    required bool isAvailable,
  });

  Future<Either<Failure, List<OrderEntity>>> getAvailableOrders({
    required double latitude,
    required double longitude,
    required double radius,
  });

  Future<Either<Failure, bool>> acceptOrder({
    required String orderId,
    required String riderId,
  });

  Future<Either<Failure, bool>> rejectOrder({
    required String orderId,
    required String riderId,
  });

  Future<Either<Failure, bool>> updateOrderStatus({
    required String orderId,
    required String status,
  });

  Future<Either<Failure, List<EarningEntity>>> getEarnings({
    required String riderId,
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, bool>> requestWithdrawal({
    required String riderId,
    required double amount,
  });

  Future<Either<Failure, List<OrderEntity>>> getRiderOrderHistory({
    required String riderId,
    String? status,
    int? page,
    int? limit,
  });

  Stream<RiderEntity> riderStream({
    required String riderId,
  });
}
