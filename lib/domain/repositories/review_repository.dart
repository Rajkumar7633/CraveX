import 'package:dartz/dartz.dart';
import 'package:zomato_clone/core/error/failures.dart';
import 'package:zomato_clone/domain/entities/review_entity.dart';

abstract class ReviewRepository {
  Future<Either<Failure, ReviewEntity>> addReview({
    required String restaurantId,
    required String orderId,
    required double rating,
    required String review,
    List<String>? images,
  });

  Future<Either<Failure, List<ReviewEntity>>> getRestaurantReviews({
    required String restaurantId,
    int? page,
    int? limit,
  });

  Future<Either<Failure, ReviewEntity>> getReviewById({
    required String reviewId,
  });

  Future<Either<Failure, bool>> updateReview({
    required String reviewId,
    required String review,
    required double rating,
  });

  Future<Either<Failure, bool>> deleteReview({
    required String reviewId,
  });

  Future<Either<Failure, bool>> likeReview({
    required String reviewId,
  });

  Future<Either<Failure, bool>> unlikeReview({
    required String reviewId,
  });

  Future<Either<Failure, ReviewReplyEntity>> addReply({
    required String reviewId,
    required String reply,
  });

  Future<Either<Failure, List<ReviewReplyEntity>>> getReplies({
    required String reviewId,
  });

  Future<Either<Failure, bool>> deleteReply({
    required String replyId,
  });
}
