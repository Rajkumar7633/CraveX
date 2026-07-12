import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:theme/app_theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'veg_indicator.dart';

class RestaurantCard extends StatelessWidget {
	final Restaurant restaurant;
	final VoidCallback onTap;
	final VoidCallback? onFavorite;
	final bool isFavorite;

	const RestaurantCard({
		super.key,
		required this.restaurant,
		required this.onTap,
		this.onFavorite,
		this.isFavorite = false,
	});

	@override
	Widget build(BuildContext context) {
		return Card(
			margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
			clipBehavior: Clip.antiAlias,
			child: InkWell(
				onTap: onTap,
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Stack(
							children: [
								if (restaurant.coverImage != null && restaurant.coverImage!.isNotEmpty)
									CachedNetworkImage(
										imageUrl: restaurant.coverImage!,
										height: 160,
										width: double.infinity,
										fit: BoxFit.cover,
										placeholder: (context, url) => Container(
											height: 160,
											width: double.infinity,
											color: Colors.grey[200],
											child: const Center(
												child: SizedBox(
													width: 24,
													height: 24,
													child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryRed),
												),
											),
										),
										errorWidget: (context, url, error) => Container(
											height: 160,
											width: double.infinity,
											color: Colors.grey[300],
											child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
										),
									)
								else
									Container(
										height: 160,
										width: double.infinity,
										color: Colors.grey[300],
										child: const Icon(Icons.restaurant, size: 48, color: Colors.grey),
									),
                if (restaurant.hasOffer)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        restaurant.offerText ?? 'OFFER',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (onFavorite != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppTheme.primaryRed : Colors.white),
                      onPressed: onFavorite,
                      style: IconButton.styleFrom(backgroundColor: Colors.black38),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(restaurant.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      _ratingBadge(restaurant.rating),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(restaurant.cuisines.join(' • '),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (restaurant.isPureVeg) ...[
                        const VegIndicator(isVeg: true, size: 14),
                        const SizedBox(width: 8),
                      ],
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      Text(' ${restaurant.deliveryTime} mins', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const SizedBox(width: 12),
                      Icon(Icons.delivery_dining, size: 14, color: Colors.grey[600]),
                      Text(
                        restaurant.deliveryFee == 0 ? ' Free' : ' ₹${restaurant.deliveryFee.toInt()}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Text('₹${restaurant.costForTwo} for two', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ratingBadge(double rating) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: rating >= 4 ? Colors.green : Colors.orange,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(rating.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            const Icon(Icons.star, color: Colors.white, size: 12),
          ],
        ),
      );
}
