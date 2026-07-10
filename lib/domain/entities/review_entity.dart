import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userImage;
  final String restaurantId;
  final String? orderId;
  final double rating;
  final String review;
  final List<String> images;
  final List<String> likes;
  final int replyCount;
  final List<ReviewReplyEntity>? replies;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReviewEntity({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.restaurantId,
    this.orderId,
    required this.rating,
    required this.review,
    required this.images,
    required this.likes,
    required this.replyCount,
    this.replies,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userImage,
        restaurantId,
        orderId,
        rating,
        review,
        images,
        likes,
        replyCount,
        replies,
        createdAt,
        updatedAt,
      ];
}

class ReviewReplyEntity extends Equatable {
  final String id;
  final String reviewId;
  final String userId;
  final String userName;
  final String? userImage;
  final String reply;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReviewReplyEntity({
    required this.id,
    required this.reviewId,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.reply,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        reviewId,
        userId,
        userName,
        userImage,
        reply,
        createdAt,
        updatedAt,
      ];
}
