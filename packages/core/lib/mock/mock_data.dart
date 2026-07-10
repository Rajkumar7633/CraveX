import '../models/address.dart';
import '../models/admin_models.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/restaurant.dart';
import '../models/rider.dart';
import '../models/user.dart';

class MockData {
  static const demoUser = User(
    id: 'user-1',
    name: 'Rahul Sharma',
    email: 'rahul@example.com',
    phone: '+919876543210',
    userType: 'customer',
    referralCode: 'RAHUL50',
    walletBalance: 250,
    isGoldMember: true,
  );

  static final addresses = [
    const Address(
      id: 'addr-1',
      label: 'Home',
      addressLine1: '42, MG Road',
      addressLine2: 'Koramangala 5th Block',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560095',
      latitude: 12.9352,
      longitude: 77.6245,
      landmark: 'Near Forum Mall',
    ),
    const Address(
      id: 'addr-2',
      label: 'Work',
      addressLine1: 'Tech Park, Outer Ring Road',
      city: 'Bangalore',
      state: 'Karnataka',
      pincode: '560103',
      latitude: 12.9279,
      longitude: 77.6271,
    ),
  ];

  static final categories = [
    {'name': 'Pizza', 'icon': '🍕'},
    {'name': 'Biryani', 'icon': '🍛'},
    {'name': 'Chinese', 'icon': '🥡'},
    {'name': 'Burger', 'icon': '🍔'},
    {'name': 'Desserts', 'icon': '🍰'},
    {'name': 'North Indian', 'icon': '🍲'},
    {'name': 'South Indian', 'icon': '🥘'},
    {'name': 'Healthy', 'icon': '🥗'},
  ];

  static final banners = [
    {'title': '50% OFF on first order', 'subtitle': 'Use code: FIRST50', 'color': 0xFFE23744},
    {'title': 'Free Delivery', 'subtitle': 'On orders above ₹199', 'color': 0xFF1C1C1C},
    {'title': 'Gold Member', 'subtitle': 'Extra 10% off everywhere', 'color': 0xFFB8860B},
  ];

  static final restaurants = [
    Restaurant(
      id: 'rest-1',
      name: 'Meghana Foods',
      description: 'Authentic Andhra & Biryani since 1986',
      cuisines: ['Biryani', 'Andhra', 'North Indian'],
      address: 'Koramangala, Bangalore',
      latitude: 12.9352,
      longitude: 77.6245,
      rating: 4.4,
      reviewCount: 12500,
      deliveryTime: 25,
      deliveryFee: 0,
      costForTwo: 600,
      isPureVeg: false,
      isOpen: true,
      distanceKm: 1.2,
      hasOffer: true,
      offerText: '50% OFF up to ₹100',
      fssaiLicense: '10018042001234',
    ),
    Restaurant(
      id: 'rest-2',
      name: 'Truffles',
      description: 'Burgers, Steaks & Continental',
      cuisines: ['American', 'Continental', 'Burger'],
      address: 'St Marks Road, Bangalore',
      latitude: 12.9716,
      longitude: 77.5946,
      rating: 4.5,
      reviewCount: 8900,
      deliveryTime: 35,
      deliveryFee: 40,
      costForTwo: 800,
      isPureVeg: false,
      isOpen: true,
      distanceKm: 2.8,
      hasOffer: true,
      offerText: 'Flat ₹100 OFF',
    ),
    Restaurant(
      id: 'rest-3',
      name: 'Vaango',
      description: 'Pure South Indian vegetarian',
      cuisines: ['South Indian', 'Dosa', 'Idli'],
      address: 'Indiranagar, Bangalore',
      latitude: 12.9784,
      longitude: 77.6408,
      rating: 4.2,
      reviewCount: 5600,
      deliveryTime: 20,
      deliveryFee: 30,
      costForTwo: 400,
      isPureVeg: true,
      isOpen: true,
      distanceKm: 0.8,
    ),
    Restaurant(
      id: 'rest-4',
      name: 'Behrouz Biryani',
      description: 'Royal Biryani experience',
      cuisines: ['Biryani', 'Mughlai'],
      address: 'HSR Layout, Bangalore',
      latitude: 12.9116,
      longitude: 77.6388,
      rating: 4.3,
      reviewCount: 15200,
      deliveryTime: 40,
      deliveryFee: 0,
      costForTwo: 700,
      isPureVeg: false,
      isOpen: true,
      distanceKm: 3.5,
      hasOffer: true,
      offerText: 'Buy 1 Get 1 Free',
    ),
    Restaurant(
      id: 'rest-5',
      name: 'Domino\'s Pizza',
      description: 'Pizza delivery in 30 mins',
      cuisines: ['Pizza', 'Fast Food'],
      address: 'BTM Layout, Bangalore',
      latitude: 12.9166,
      longitude: 77.6101,
      rating: 4.0,
      reviewCount: 22000,
      deliveryTime: 30,
      deliveryFee: 0,
      costForTwo: 500,
      isPureVeg: false,
      isOpen: true,
      distanceKm: 2.1,
    ),
  ];

  static List<MenuCategory> menuCategories(String restaurantId) => [
        MenuCategory(id: 'cat-1', name: 'Recommended', restaurantId: restaurantId),
        MenuCategory(id: 'cat-2', name: 'Starters', restaurantId: restaurantId),
        MenuCategory(id: 'cat-3', name: 'Main Course', restaurantId: restaurantId),
        MenuCategory(id: 'cat-4', name: 'Biryani', restaurantId: restaurantId),
        MenuCategory(id: 'cat-5', name: 'Desserts', restaurantId: restaurantId),
        MenuCategory(id: 'cat-6', name: 'Beverages', restaurantId: restaurantId),
      ];

  static List<MenuItem> menuItems(String restaurantId) => [
        MenuItem(
          id: 'item-1',
          categoryId: 'cat-1',
          name: 'Chicken Biryani',
          description: 'Aromatic basmati rice with tender chicken pieces',
          price: 299,
          isVeg: false,
          isRecommended: true,
          spiceLevel: 2,
          addOns: ['Extra Raita ₹40', 'Boiled Egg ₹30', 'Extra Gravy ₹50'],
        ),
        MenuItem(
          id: 'item-2',
          categoryId: 'cat-1',
          name: 'Paneer Butter Masala',
          description: 'Creamy tomato gravy with soft paneer cubes',
          price: 249,
          isVeg: true,
          isRecommended: true,
          spiceLevel: 1,
        ),
        MenuItem(
          id: 'item-3',
          categoryId: 'cat-2',
          name: 'Chicken 65',
          description: 'Spicy deep-fried chicken starter',
          price: 199,
          isVeg: false,
          spiceLevel: 3,
        ),
        MenuItem(
          id: 'item-4',
          categoryId: 'cat-2',
          name: 'Veg Spring Rolls',
          description: 'Crispy rolls with mixed vegetable filling',
          price: 149,
          isVeg: true,
        ),
        MenuItem(
          id: 'item-5',
          categoryId: 'cat-3',
          name: 'Butter Naan',
          description: 'Soft leavened bread with butter',
          price: 49,
          isVeg: true,
        ),
        MenuItem(
          id: 'item-6',
          categoryId: 'cat-4',
          name: 'Mutton Biryani',
          description: 'Slow-cooked mutton with fragrant rice',
          price: 399,
          isVeg: false,
          spiceLevel: 2,
        ),
        MenuItem(
          id: 'item-7',
          categoryId: 'cat-5',
          name: 'Gulab Jamun',
          description: 'Soft milk dumplings in sugar syrup (2 pcs)',
          price: 89,
          isVeg: true,
        ),
        MenuItem(
          id: 'item-8',
          categoryId: 'cat-6',
          name: 'Masala Chai',
          description: 'Traditional spiced tea',
          price: 49,
          isVeg: true,
        ),
      ];

  static final coupons = [
    {'code': 'FIRST50', 'discount': 50, 'type': 'percent', 'maxDiscount': 100},
    {'code': 'FLAT100', 'discount': 100, 'type': 'flat', 'maxDiscount': 100},
    {'code': 'FREEDEL', 'discount': 0, 'type': 'free_delivery', 'maxDiscount': 40},
  ];

  static final demoRider = Rider(
    id: 'rider-1',
    name: 'Amit Kumar',
    phone: '+919123456789',
    vehicleType: 'bike',
    isOnline: true,
    isVerified: true,
    rating: 4.8,
    totalDeliveries: 2450,
    todayEarnings: 850,
    latitude: 12.9352,
    longitude: 77.6245,
  );

  static Order sampleOrder(String status) => Order(
        id: 'order-${DateTime.now().millisecondsSinceEpoch}',
        userId: demoUser.id,
        restaurantId: restaurants.first.id,
        restaurantName: restaurants.first.name,
        items: const [
          OrderLineItem(
            menuItemId: 'item-1',
            name: 'Chicken Biryani',
            price: 299,
            quantity: 2,
            isVeg: false,
          ),
          OrderLineItem(
            menuItemId: 'item-7',
            name: 'Gulab Jamun',
            price: 89,
            quantity: 1,
            isVeg: true,
          ),
        ],
        subtotal: 687,
        deliveryFee: 0,
        tax: 34.35,
        platformFee: 5,
        packagingCharge: 10,
        discount: 50,
        tip: 20,
        total: 706.35,
        status: status,
        paymentMethod: 'upi',
        isPaid: true,
        deliveryAddress: addresses.first,
        riderId: demoRider.id,
        riderName: demoRider.name,
        riderPhone: demoRider.phone,
        estimatedDeliveryTime: DateTime.now().add(const Duration(minutes: 25)),
        createdAt: DateTime.now(),
        statusHistory: _statusHistoryFor(status),
      );

  static List<OrderStatusStep> _statusHistoryFor(String currentStatus) {
    final steps = [
      AppOrderStatus.placed,
      AppOrderStatus.accepted,
      AppOrderStatus.preparing,
      AppOrderStatus.ready,
      AppOrderStatus.pickedUp,
      AppOrderStatus.onTheWay,
      AppOrderStatus.delivered,
    ];
    final idx = steps.indexOf(currentStatus);
    final now = DateTime.now();
    return steps
        .take(idx + 1)
        .toList()
        .asMap()
        .entries
        .map((e) => OrderStatusStep(
              status: e.value,
              timestamp: now.subtract(Duration(minutes: (steps.length - e.key) * 5)),
            ))
        .toList();
  }

  static final restaurantOrders = [
    sampleOrder('placed'),
    sampleOrder('preparing'),
    sampleOrder('ready'),
  ];

  static final adminStats = {
    'totalOrders': 12450,
    'todayOrders': 342,
    'gmv': 45.6,
    'activeRestaurants': 1280,
    'activeRiders': 456,
    'pendingApprovals': 12,
    'openTickets': 8,
  };

  static const demoAdmin = AdminUser(
    id: 'admin-1',
    name: 'Super Admin',
    email: 'admin@zomato-clone.com',
    role: 'super_admin',
  );

  static final pendingRestaurants = [
    PendingRestaurant(
      id: 'pr-1',
      name: 'Spice Garden',
      ownerName: 'Rajesh Kumar',
      city: 'Bangalore',
      status: 'pending',
      submittedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PendingRestaurant(
      id: 'pr-2',
      name: 'Pizza Palace',
      ownerName: 'Priya Singh',
      city: 'Mumbai',
      status: 'pending',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PendingRestaurant(
      id: 'pr-3',
      name: 'Dosa Corner',
      ownerName: 'Venkat Rao',
      city: 'Hyderabad',
      status: 'rejected',
      rejectReason: 'Invalid FSSAI license',
      submittedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static final pendingRiders = [
    PendingRider(
      id: 'pr-r1',
      name: 'Suresh Reddy',
      phone: '+919876543211',
      vehicleType: 'bike',
      status: 'pending',
      submittedAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    PendingRider(
      id: 'pr-r2',
      name: 'Deepak Sharma',
      phone: '+919876543212',
      vehicleType: 'scooter',
      status: 'pending',
      submittedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final riderPerformance = [
    {'name': 'Amit Kumar', 'onTime': 0.94},
    {'name': 'Suresh Reddy', 'onTime': 0.88},
    {'name': 'Deepak Sharma', 'onTime': 0.91},
  ];

  static final customerComplaints = [
    {'subject': 'Wrong item delivered', 'customer': 'Rahul Sharma', 'date': 'Today', 'resolved': false},
    {'subject': 'Late delivery refund', 'customer': 'Priya Singh', 'date': 'Yesterday', 'resolved': true},
    {'subject': 'Missing item in order', 'customer': 'Amit Patel', 'date': '2 days ago', 'resolved': false},
  ];

  static final orderDisputes = [
    {'orderId': 'ORD-78234', 'reason': 'Customer claims missing biryani'},
    {'orderId': 'ORD-78190', 'reason': 'Quality complaint — cold food'},
  ];

  static final adminBanners = [
    BannerItem(id: 'b1', title: '50% OFF on first order', subtitle: 'Use code: FIRST50', isActive: true),
    BannerItem(id: 'b2', title: 'Free Delivery', subtitle: 'On orders above ₹199', isActive: true),
    BannerItem(id: 'b3', title: 'Gold Member', subtitle: 'Extra 10% off everywhere', isActive: false),
  ];

  static final adminCoupons = [
    const Coupon(code: 'FIRST50', type: 'percent', discount: 50, maxDiscount: 100, scope: 'global'),
    const Coupon(code: 'FLAT100', type: 'flat', discount: 100, maxDiscount: 100, scope: 'global'),
    const Coupon(code: 'MEGHANA20', type: 'percent', discount: 20, maxDiscount: 80, scope: 'restaurant'),
  ];

  static final pushCampaigns = [
    {'title': 'Weekend Biryani Sale', 'segment': 'Biryani lovers', 'sent': 12500, 'opened': 4200, 'status': 'Sent'},
    {'title': 'Gold Membership Offer', 'segment': 'Inactive users', 'sent': 8900, 'opened': 2100, 'status': 'Scheduled'},
  ];

  static final payouts = [
    PayoutRecord(id: 'pay-1', entityName: 'Meghana Foods', entityType: 'restaurant', amount: 45200, status: 'pending', date: DateTime.now()),
    PayoutRecord(id: 'pay-2', entityName: 'Truffles', entityType: 'restaurant', amount: 32100, status: 'processed', date: DateTime.now().subtract(const Duration(days: 2))),
    PayoutRecord(id: 'pay-3', entityName: 'Amit Kumar', entityType: 'rider', amount: 8500, status: 'pending', date: DateTime.now()),
    PayoutRecord(id: 'pay-4', entityName: 'Suresh Reddy', entityType: 'rider', amount: 6200, status: 'processed', date: DateTime.now().subtract(const Duration(days: 1))),
  ];

  static final financeSummary = {
    'pendingPayouts': '1.2L',
    'processedMonth': '45.6L',
    'commission': '8.2L',
  };

  static final revenueBreakdown = {
    'Delivery Fees': 12.4,
    'Platform Commission': 8.2,
    'Subscription (Gold)': 3.1,
    'Advertising': 1.8,
  };

  static final analyticsMetrics = {
    'newCustomers': 1240,
    'retention': 68,
    'aov': 385,
    'cancelRate': 3.2,
  };

  static final cityOrderVolume = {
    'Bangalore': 42,
    'Mumbai': 28,
    'Delhi': 18,
    'Hyderabad': 12,
  };

  static final supportTickets = [
    SupportTicket(id: 'TKT-001', subject: 'Order not delivered', customerName: 'Rahul Sharma', priority: 'high', status: 'open', createdAt: DateTime.now()),
    SupportTicket(id: 'TKT-002', subject: 'Refund not received', customerName: 'Priya Singh', priority: 'medium', status: 'in_progress', createdAt: DateTime.now().subtract(const Duration(hours: 3))),
    SupportTicket(id: 'TKT-003', subject: 'Wrong address issue', customerName: 'Amit Patel', priority: 'low', status: 'resolved', createdAt: DateTime.now().subtract(const Duration(days: 1))),
  ];

  static final fraudAlerts = [
    {'title': 'GPS Spoofing Detected', 'detail': 'Rider RID-4521 — 3 suspicious location jumps'},
    {'title': 'Repeated Free Delivery Abuse', 'detail': 'User USR-8892 — 5 new accounts same device'},
  ];

  static final flaggedReviews = [
    {'review': 'This restaurant is terrible!!! FAKE REVIEWS everywhere!!!'},
    {'review': 'Worst food ever, don\'t order from here scam'},
  ];

  static final adminActivityLog = [
    {'icon': 'store', 'title': 'Spice Garden onboarding submitted', 'time': '2 hours ago', 'type': 'Restaurant'},
    {'icon': 'delivery', 'title': 'Suresh Reddy rider verification pending', 'time': '5 hours ago', 'type': 'Rider'},
    {'icon': 'receipt', 'title': '342 orders processed today', 'time': 'Live', 'type': 'Orders'},
    {'icon': 'support', 'title': 'New support ticket TKT-001', 'time': '30 min ago', 'type': 'Support'},
  ];

  static final notifications = [
    {'title': 'Your order is on the way!', 'body': 'Amit is delivering your Chicken Biryani', 'time': '5 min ago', 'read': false},
    {'title': '50% OFF — Limited time', 'body': 'Use FIRST50 on your next order', 'time': '2 hours ago', 'read': false},
    {'title': 'Order delivered', 'body': 'Rate your experience with Meghana Foods', 'time': 'Yesterday', 'read': true},
    {'title': 'Gold membership renewed', 'body': 'Your Gold plan is active until Aug 2026', 'time': '3 days ago', 'read': true},
  ];

  static final reviews = [
    {'user': 'Priya S.', 'rating': 5.0, 'comment': 'Best biryani in Bangalore!', 'date': '2 days ago', 'photos': 2},
    {'user': 'Amit K.', 'rating': 4.0, 'comment': 'Good food but delivery was slightly late', 'date': '1 week ago', 'photos': 0},
    {'user': 'Neha R.', 'rating': 5.0, 'comment': 'Paneer butter masala is amazing', 'date': '2 weeks ago', 'photos': 1},
  ];

  static final goldPlans = [
    {'name': 'Gold Monthly', 'price': 149, 'duration': '1 month', 'benefits': ['Free delivery', 'Extra 10% off', 'Priority support']},
    {'name': 'Gold Yearly', 'price': 999, 'duration': '12 months', 'benefits': ['Free delivery', 'Extra 15% off', 'Priority support', 'Exclusive deals']},
  ];

  static final trendingSearches = ['Biryani', 'Pizza', 'Burger', 'Chinese', 'Desserts'];
  static final searchHistory = ['Chicken Biryani', 'Meghana Foods', 'Paneer Butter Masala'];
}

class AppOrderStatus {
  static const placed = 'placed';
  static const accepted = 'accepted';
  static const preparing = 'preparing';
  static const ready = 'ready';
  static const pickedUp = 'picked_up';
  static const onTheWay = 'on_the_way';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';

  static const labels = {
    placed: 'Order Placed',
    accepted: 'Accepted',
    preparing: 'Preparing',
    ready: 'Ready for Pickup',
    pickedUp: 'Picked Up',
    onTheWay: 'On the Way',
    delivered: 'Delivered',
    cancelled: 'Cancelled',
  };

  static const customerSteps = [
    placed,
    accepted,
    preparing,
    pickedUp,
    onTheWay,
    delivered,
  ];
}
