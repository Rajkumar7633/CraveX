import 'package:dartz/dartz.dart';
import 'package:zomato_clone/core/error/failures.dart';
import 'package:zomato_clone/domain/entities/cart_entity.dart';

abstract class CartRepository {
  Future<Either<Failure, CartEntity>> getCart();

  Future<Either<Failure, CartEntity>> addToCart({
    required String menuItemId,
    required String name,
    required double price,
    required int quantity,
    String? image,
    List<AddonEntity>? selectedAddons,
    VariantEntity? selectedVariant,
  });

  Future<Either<Failure, CartEntity>> updateCartItem({
    required String cartItemId,
    required int quantity,
  });

  Future<Either<Failure, CartEntity>> removeFromCart({
    required String cartItemId,
  });

  Future<Either<Failure, CartEntity>> clearCart();

  Future<Either<Failure, CartEntity>> applyCoupon({
    required String couponCode,
  });

  Future<Either<Failure, CartEntity>> removeCoupon();

  Future<Either<Failure, CartEntity>> setDeliveryAddress({
    required AddressEntity address,
  });

  Stream<CartEntity> cartStream();
}
