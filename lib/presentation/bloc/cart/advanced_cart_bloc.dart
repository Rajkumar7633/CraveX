import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zomato_clone/domain/entities/cart_item.dart';
import 'package:zomato_clone/domain/repositories/cart_repository.dart';

// Advanced Cart BLoC with exact pricing formula integration
part 'advanced_cart_bloc_event.dart';
part 'advanced_cart_bloc_state.dart';

class AdvancedCartBloc extends Bloc<AdvancedCartEvent, AdvancedCartState> {
  final CartRepository cartRepository;

  AdvancedCartBloc(this.cartRepository) : super(const AdvancedCartInitial()) {
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItem>(_onUpdateCartItem);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<CalculateCartPricing>(_onCalculateCartPricing);
    on<ApplyCoupon>(_onApplyCoupon);
    on<ValidateCartAtCheckout>(_onValidateCartAtCheckout);
  }

  Future<void> _onAddToCart(
    AddToCart event,
    Emitter<AdvancedCartState> emit,
  ) async {
    try {
      await cartRepository.addToCart(event.cartItem);
      emit(const AdvancedCartItemAdded());
    } catch (e) {
      emit(AdvancedCartError(e.toString()));
    }
  }

  Future<void> _onUpdateCartItem(
    UpdateCartItem event,
    Emitter<AdvancedCartState> emit,
  ) async {
    try {
      await cartRepository.updateCartItem(event.cartItemId, event.quantity);
      emit(const AdvancedCartItemUpdated());
    } catch (e) {
      emit(AdvancedCartError(e.toString()));
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<AdvancedCartState> emit,
  ) async {
    try {
      await cartRepository.removeFromCart(event.cartItemId);
      emit(const AdvancedCartItemRemoved());
    } catch (e) {
      emit(AdvancedCartError(e.toString()));
    }
  }

  Future<void> _onCalculateCartPricing(
    CalculateCartPricing event,
    Emitter<AdvancedCartState> emit,
  ) async {
    emit(const AdvancedCartLoading());
    try {
      final pricing = await cartRepository.calculateCartPricing(
        event.userId,
        event.restaurantId,
        event.items,
        event.deliveryAddress,
        event.couponCode,
        event.tipAmount,
      );
      emit(AdvancedCartPricingCalculated(pricing));
    } catch (e) {
      emit(AdvancedCartError(e.toString()));
    }
  }

  Future<void> _onApplyCoupon(
    ApplyCoupon event,
    Emitter<AdvancedCartState> emit,
  ) async {
    try {
      final pricing = await cartRepository.applyCoupon(
        event.userId,
        event.restaurantId,
        event.couponCode,
      );
      emit(AdvancedCouponApplied(pricing));
    } catch (e) {
      emit(AdvancedCartError(e.toString()));
    }
  }

  Future<void> _onValidateCartAtCheckout(
    ValidateCartAtCheckout event,
    Emitter<AdvancedCartState> emit,
  ) async {
    emit(const AdvancedCartLoading());
    try {
      final validation = await cartRepository.validateCartAtCheckout(
        event.userId,
        event.restaurantId,
        event.items,
        event.cachedPricing,
      );
      emit(AdvancedCartValidated(validation));
    } catch (e) {
      emit(AdvancedCartError(e.toString()));
    }
  }
}
