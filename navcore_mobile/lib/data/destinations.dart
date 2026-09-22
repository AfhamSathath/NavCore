import '../engine/ecef_engine.dart';

class DestinationPOI {
  final String id;
  final String name;
  final String category;
  final int floorNumber;
  final double rating;
  final GeodeticCoords location;
  final String description;
  final String openStatus;
  final String? imageUrl;

  const DestinationPOI({
    required this.id,
    required this.name,
    required this.category,
    required this.floorNumber,
    required this.rating,
    required this.location,
    required this.description,
    required this.openStatus,
    this.imageUrl,
  });

  /// Helper to return a guaranteed high-quality suitable image URL for the shop
  String get effectiveImageUrl {
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      return imageUrl!;
    }
    return getFallbackShopImage(name, category);
  }
}

/// Dynamic fallback resolver based on shop category and keywords
String getFallbackShopImage(String name, String category) {
  final n = name.toLowerCase();
  final c = category.toLowerCase();

  if (n.contains('coffee') || n.contains('barista') || n.contains('tea') || n.contains('espresso')) {
    return 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&q=80';
  }
  if (n.contains('crab') || n.contains('seafood')) {
    return 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=800&auto=format&fit=crop&q=80';
  }
  if (n.contains('taco') || n.contains('burrito') || n.contains('mexican')) {
    return 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&auto=format&fit=crop&q=80';
  }
  if (c.contains('food') || n.contains('food') || n.contains('dining') || n.contains('court')) {
    return 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&auto=format&fit=crop&q=80';
  }
  if (n.contains('cinema') || n.contains('imax') || n.contains('pvr') || c.contains('entertainment')) {
    return 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&auto=format&fit=crop&q=80';
  }
  if (n.contains('apple') || n.contains('samsung') || n.contains('singer') || n.contains('dialog') || n.contains('mobitel') || c.contains('tech')) {
    return 'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=800&auto=format&fit=crop&q=80';
  }
  if (n.contains('odel') || n.contains('hugo') || n.contains('fashion') || n.contains('cotton') || n.contains('kelly') || n.contains('barefoot') || c.contains('retail')) {
    return 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&auto=format&fit=crop&q=80';
  }
  if (n.contains('supermarket') || n.contains('hypermarket') || n.contains('keells')) {
    return 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=800&auto=format&fit=crop&q=80';
  }
  if (n.contains('spa') || n.contains('ayurveda')) {
    return 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800&auto=format&fit=crop&q=80';
  }
  if (n.contains('ev') || n.contains('charging')) {
    return 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=800&auto=format&fit=crop&q=80';
  }
  if (n.contains('wash') || n.contains('car')) {
    return 'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?w=800&auto=format&fit=crop&q=80';
  }
  if (n.contains('valet') || n.contains('concierge') || n.contains('lockers') || c.contains('services')) {
    return 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=800&auto=format&fit=crop&q=80';
  }

  return 'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=800&auto=format&fit=crop&q=80';
}

/// Entrance Anchor for One Galle Face Mall, Colombo, Sri Lanka
const entranceAnchor = GeodeticCoords(
  latitude: 6.927079,
  longitude: 79.845612,
  height: 45.0,
);

final mockDestinations = [
  // FLOOR -1 - Basement 1 Parking & Express Services (5 Items)
  const DestinationPOI(
    id: 'poi-b1-01',
    name: 'B1 Executive Valet & Concierge',
    category: 'SERVICES',
    floorNumber: -1,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.926600,
      longitude: 79.845100,
      height: 40.0,
    ),
    description: 'VIP valet drop-off, luggage storage, and premium parking concierge desk.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-b1-02',
    name: 'Keells Express Supermarket B1',
    category: 'SERVICES',
    floorNumber: -1,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.927600,
      longitude: 79.846100,
      height: 40.0,
    ),
    description: 'Express groceries, fresh takeaway snacks, cold beverages, and essentials.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-b1-03',
    name: 'B1 Eco EV Fast-Charging Hub',
    category: 'TECH & ELECTRONICS',
    floorNumber: -1,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.926300,
      longitude: 79.844900,
      height: 40.0,
    ),
    description: 'High-speed 120kW DC EV chargers for Tesla, Hyundai, Nissan & BYD vehicles.',
    openStatus: '24/7',
    imageUrl: 'https://images.unsplash.com/photo-1563720223185-11003d516935?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-b1-04',
    name: 'B1 Auto Car Wash & Detailing',
    category: 'SERVICES',
    floorNumber: -1,
    rating: 4.7,
    location: GeodeticCoords(
      latitude: 6.927900,
      longitude: 79.846300,
      height: 40.0,
    ),
    description: 'Eco-friendly waterless car wash, interior vacuuming & ceramic coating.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-b1-05',
    name: 'B1 Luggage Lockers & Express Counter',
    category: 'SERVICES',
    floorNumber: -1,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.926800,
      longitude: 79.845500,
      height: 40.0,
    ),
    description: 'Automated smart luggage lockers, parcel pickup, and courier services.',
    openStatus: '24/7',
    imageUrl: 'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800&auto=format&fit=crop&q=80',
  ),

  // FLOOR 1 - Ground Floor & Ceylon Atrium (5 Items)
  const DestinationPOI(
    id: 'poi-101',
    name: 'Odel Flagship Department Store',
    category: 'RETAIL & FASHION',
    floorNumber: 1,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.927550,
      longitude: 79.846250,
      height: 45.0,
    ),
    description: 'Premier Sri Lankan lifestyle, fashion & department store.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-102',
    name: 'Concierge & Information Desk',
    category: 'SERVICES',
    floorNumber: 1,
    rating: 5.0,
    location: GeodeticCoords(
      latitude: 6.927220,
      longitude: 79.845800,
      height: 45.0,
    ),
    description: 'Sri Lanka tourist assistance, mall guide & lost property services.',
    openStatus: '24/7',
    imageUrl: 'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-103',
    name: 'Spa Ceylon Luxury Ayurveda',
    category: 'SERVICES',
    floorNumber: 1,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.926680,
      longitude: 79.845250,
      height: 45.0,
    ),
    description: 'Royal Sri Lankan Ayurveda wellness, essential oils & skincare.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-104',
    name: 'Dilmah Tea Lounge & t-Bar',
    category: 'FOOD & DRINK',
    floorNumber: 1,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.927700,
      longitude: 79.845180,
      height: 45.0,
    ),
    description: 'Handpicked single-origin Ceylon tea tasting, mocktails & high tea.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-105',
    name: 'Keells Super Hypermarket',
    category: 'SERVICES',
    floorNumber: 1,
    rating: 4.7,
    location: GeodeticCoords(
      latitude: 6.926450,
      longitude: 79.846100,
      height: 45.0,
    ),
    description: 'Gourmet groceries, fresh Sri Lankan produce, bakery & spices.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&auto=format&fit=crop&q=80',
  ),

  // FLOOR 2 - Fashion & Apparel (5 Items)
  const DestinationPOI(
    id: 'poi-201',
    name: 'Cotton Collection',
    category: 'RETAIL & FASHION',
    floorNumber: 2,
    rating: 4.6,
    location: GeodeticCoords(
      latitude: 6.927850,
      longitude: 79.845150,
      height: 50.0,
    ),
    description: 'Casual island wear, linen garments, tropical resort fashion & accessories.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-202',
    name: 'Kelly Felder Designer Lounge',
    category: 'RETAIL & FASHION',
    floorNumber: 2,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.926350,
      longitude: 79.846400,
      height: 50.0,
    ),
    description: 'Chic Sri Lankan womenswear, evening attire, and designer handbags.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-203',
    name: 'House of Fashion Outlet',
    category: 'RETAIL & FASHION',
    floorNumber: 2,
    rating: 4.7,
    location: GeodeticCoords(
      latitude: 6.928100,
      longitude: 79.846600,
      height: 50.0,
    ),
    description: 'Extensive selection of international trends and local Sri Lankan apparel.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-204',
    name: 'Barefoot Ceylon Handwoven Gallery',
    category: 'RETAIL & FASHION',
    floorNumber: 2,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.926150,
      longitude: 79.844850,
      height: 50.0,
    ),
    description: 'Vibrant handwoven Sri Lankan textiles, books, toys, and artisanal crafts.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1606744824163-985d376605aa?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-205',
    name: 'Hugo Boss & Luxury Apparel',
    category: 'RETAIL & FASHION',
    floorNumber: 2,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.927200,
      longitude: 79.845900,
      height: 50.0,
    ),
    description: 'Premium luxury suits, formal wear, leather shoes & accessories.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&auto=format&fit=crop&q=80',
  ),

  // FLOOR 3 - Tech & Electronics Hub (5 Items)
  const DestinationPOI(
    id: 'poi-301',
    name: 'Singer Mega Experience Center',
    category: 'TECH & ELECTRONICS',
    floorNumber: 3,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.927950,
      longitude: 79.846750,
      height: 55.0,
    ),
    description: 'Smart TVs, home electronics, laptops, and consumer technology.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-302',
    name: 'Abans Elite Apple & LG Store',
    category: 'TECH & ELECTRONICS',
    floorNumber: 3,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.928300,
      longitude: 79.845300,
      height: 55.0,
    ),
    description: 'Authorized Apple products, iPhones, MacBooks, and LG smart devices.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-303',
    name: 'Dialog Axiata Experience Centre',
    category: 'TECH & ELECTRONICS',
    floorNumber: 3,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.925950,
      longitude: 79.846500,
      height: 55.0,
    ),
    description: '5G SIM connections, eSIM activation, fiber broadband & IoT gadgets.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-304',
    name: 'Mobitel & SLT Broadband Lounge',
    category: 'TECH & ELECTRONICS',
    floorNumber: 3,
    rating: 4.7,
    location: GeodeticCoords(
      latitude: 6.927650,
      longitude: 79.844500,
      height: 55.0,
    ),
    description: 'National telecom service desk, fiber routers, and mobile accessories.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1562976540-1502c2145186?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-305',
    name: 'Samsung Smart Experience Zone',
    category: 'TECH & ELECTRONICS',
    floorNumber: 3,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.926800,
      longitude: 79.845600,
      height: 55.0,
    ),
    description: 'Galaxy smartphones, tablets, smartwatches & home appliance displays.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=800&auto=format&fit=crop&q=80',
  ),

  // FLOOR 4 - Food Court & Dining Layer (5 Items)
  const DestinationPOI(
    id: 'poi-401',
    name: 'Food Studio Ceylon Court',
    category: 'FOOD & DRINK',
    floorNumber: 4,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.928450,
      longitude: 79.847150,
      height: 60.0,
    ),
    description: 'Fresh Kottu Roti, Jaffna Crab Curry, Egg Hoppers & Ceylon street food.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-402',
    name: 'Ministry of Crab Express',
    category: 'FOOD & DRINK',
    floorNumber: 4,
    rating: 5.0,
    location: GeodeticCoords(
      latitude: 6.928800,
      longitude: 79.844600,
      height: 60.0,
    ),
    description: 'World-renowned Sri Lankan giant lagoon crab & Garlic Chili Prawns.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-403',
    name: 'Barista Ceylon Espresso Bar',
    category: 'FOOD & DRINK',
    floorNumber: 4,
    rating: 4.7,
    location: GeodeticCoords(
      latitude: 6.925500,
      longitude: 79.847350,
      height: 60.0,
    ),
    description: 'Artisanal local coffees, iced lattes, fresh pastries, and savories.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-404',
    name: 'Taco Bell Sri Lanka',
    category: 'FOOD & DRINK',
    floorNumber: 4,
    rating: 4.6,
    location: GeodeticCoords(
      latitude: 6.927500,
      longitude: 79.844100,
      height: 60.0,
    ),
    description: 'Mexican inspired burritos, crunchy tacos, and spicy Sri Lankan sauces.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&auto=format&fit=crop&q=80',
  ),
  const DestinationPOI(
    id: 'poi-405',
    name: 'PVR / Scope Cinemas IMAX OGF',
    category: 'ENTERTAINMENT',
    floorNumber: 4,
    rating: 5.0,
    location: GeodeticCoords(
      latitude: 6.928750,
      longitude: 79.847400,
      height: 60.0,
    ),
    description: 'Premium 3D IMAX screen, Dolby Atmos surround sound & luxury recliners.',
    openStatus: 'OPEN NOW',
    imageUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&auto=format&fit=crop&q=80',
  ),
];
