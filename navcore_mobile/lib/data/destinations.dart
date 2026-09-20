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

  const DestinationPOI({
    required this.id,
    required this.name,
    required this.category,
    required this.floorNumber,
    required this.rating,
    required this.location,
    required this.description,
    required this.openStatus,
  });
}

/// Entrance Anchor for One Galle Face Mall, Colombo, Sri Lanka
const entranceAnchor = GeodeticCoords(
  latitude: 6.927079,
  longitude: 79.845612,
  height: 45.0,
);

final mockDestinations = [
  // FLOOR B2 - Basement 2 Parking & Facilities (80m - 140m 3D Dist)
  const DestinationPOI(
    id: 'poi-b2-01',
    name: 'B2 Premium Long-Stay Parking Zone',
    category: 'SERVICES',
    floorNumber: -2,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.926200,
      longitude: 79.844700,
      height: 35.0,
    ),
    description: 'Reserved long-stay bays, 24/7 CCTV surveillance & automated ticket kiosk.',
    openStatus: '24/7',
  ),
  const DestinationPOI(
    id: 'poi-b2-02',
    name: 'B2 Security & Lost Property Desk',
    category: 'SERVICES',
    floorNumber: -2,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.927800,
      longitude: 79.845100,
      height: 35.0,
    ),
    description: 'Mall security headquarters, lost & found items, and emergency assistance.',
    openStatus: '24/7',
  ),
  const DestinationPOI(
    id: 'poi-b2-03',
    name: 'B2 Tyre & Battery Care Station',
    category: 'SERVICES',
    floorNumber: -2,
    rating: 4.7,
    location: GeodeticCoords(
      latitude: 6.926400,
      longitude: 79.846200,
      height: 35.0,
    ),
    description: 'Automated air pressure, battery jumpstart, tyre pressure check & emergency care.',
    openStatus: 'OPEN NOW',
  ),

  // FLOOR B1 - Basement 1 Parking & Express Services (60m - 120m 3D Dist)
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
  ),

  // FLOOR 1 - Ground Floor & Ceylon Tea / Retail (35m - 90m 3D Dist)
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
  ),
  const DestinationPOI(
    id: 'poi-103',
    name: 'Spa Ceylon Luxury Ayurveda',
    category: 'BEAUTY & HEALTH',
    floorNumber: 1,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.926680,
      longitude: 79.845250,
      height: 45.0,
    ),
    description: 'Royal Sri Lankan Ayurveda wellness, essential oils & skincare.',
    openStatus: 'OPEN NOW',
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
  ),

  // FLOOR 2 - Fashion & Apparel (75m - 140m 3D Dist)
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
  ),

  // FLOOR 3 - Tech & Electronics Hub (100m - 180m 3D Dist)
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
  ),

  // FLOOR 4 - Gems, Jewelry & Sri Lankan Gold (140m - 220m 3D Dist)
  const DestinationPOI(
    id: 'poi-401',
    name: 'Colombo Jewellery Stores (CJS)',
    category: 'LUXURY',
    floorNumber: 4,
    rating: 5.0,
    location: GeodeticCoords(
      latitude: 6.928150,
      longitude: 79.846950,
      height: 60.0,
    ),
    description: 'Iconic Ceylon Blue Sapphires, natural gemstones, and luxury Swiss watches.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-402',
    name: 'Vogue Jewellers Lanka',
    category: 'LUXURY',
    floorNumber: 4,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.925750,
      longitude: 79.846900,
      height: 60.0,
    ),
    description: 'Mastercrafted 22K Sri Lankan gold jewelry, bridal collections, and gems.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-403',
    name: 'Raja Jewellers Gem Gallery',
    category: 'LUXURY',
    floorNumber: 4,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.928500,
      longitude: 79.844800,
      height: 60.0,
    ),
    description: 'Fine Sri Lankan rubies, star sapphires, and custom handcrafted jewelry.',
    openStatus: 'OPEN NOW',
  ),

  // FLOOR 5 - Food Studio & Sri Lankan Cuisine (160m - 250m 3D Dist)
  const DestinationPOI(
    id: 'poi-501',
    name: 'Food Studio Ceylon Court',
    category: 'FOOD & DRINK',
    floorNumber: 5,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.928450,
      longitude: 79.847150,
      height: 65.0,
    ),
    description: 'Fresh Kottu Roti, Jaffna Crab Curry, Egg Hoppers & Ceylon street food.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-502',
    name: 'Ministry of Crab Express',
    category: 'FOOD & DRINK',
    floorNumber: 5,
    rating: 5.0,
    location: GeodeticCoords(
      latitude: 6.928800,
      longitude: 79.844600,
      height: 65.0,
    ),
    description: 'World-renowned Sri Lankan giant lagoon crab & Garlic Chili Prawns.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-503',
    name: 'Barista Ceylon Espresso Bar',
    category: 'FOOD & DRINK',
    floorNumber: 5,
    rating: 4.7,
    location: GeodeticCoords(
      latitude: 6.925500,
      longitude: 79.847350,
      height: 65.0,
    ),
    description: 'Artisanal local coffees, iced lattes, fresh pastries, and savories.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-504',
    name: 'Taco Bell Sri Lanka',
    category: 'FOOD & DRINK',
    floorNumber: 5,
    rating: 4.6,
    location: GeodeticCoords(
      latitude: 6.927500,
      longitude: 79.844100,
      height: 65.0,
    ),
    description: 'Mexican inspired burritos, crunchy tacos, and spicy Sri Lankan sauces.',
    openStatus: 'OPEN NOW',
  ),

  // FLOOR 6 - Entertainment & Cinema (200m - 290m 3D Dist)
  const DestinationPOI(
    id: 'poi-601',
    name: 'PVR / Scope Cinemas IMAX OGF',
    category: 'ENTERTAINMENT',
    floorNumber: 6,
    rating: 5.0,
    location: GeodeticCoords(
      latitude: 6.928750,
      longitude: 79.847400,
      height: 70.0,
    ),
    description: 'Premium 3D IMAX screen, Dolby Atmos surround sound & luxury recliners.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-602',
    name: 'Playzone Arcade & VR World',
    category: 'ENTERTAINMENT',
    floorNumber: 6,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.925250,
      longitude: 79.847650,
      height: 70.0,
    ),
    description: 'Multiplayer arcade games, VR motion simulators, and kids play park.',
    openStatus: 'OPEN NOW',
  ),

  // FLOOR 7 - Corporate & Tech Innovation (230m - 320m 3D Dist)
  const DestinationPOI(
    id: 'poi-701',
    name: 'Virtusa Tech Innovation Hub',
    category: 'SERVICES',
    floorNumber: 7,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.928950,
      longitude: 79.847650,
      height: 75.0,
    ),
    description: 'Global IT solution engineering, AI research, and agile co-working space.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-702',
    name: 'WSO2 Open-Source Cloud Center',
    category: 'TECH & ELECTRONICS',
    floorNumber: 7,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.925050,
      longitude: 79.847950,
      height: 75.0,
    ),
    description: 'API management, digital identity solutions, and tech community meetups.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-703',
    name: 'SLT Mobitel 5G Smart Lab',
    category: 'TECH & ELECTRONICS',
    floorNumber: 7,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.929250,
      longitude: 79.844100,
      height: 75.0,
    ),
    description: 'IoT innovation lab, smart city tech demonstrations, and 5G testbed.',
    openStatus: 'OPEN NOW',
  ),

  // FLOOR 8 - Enterprise & Banking Suites (260m - 340m 3D Dist)
  const DestinationPOI(
    id: 'poi-801',
    name: 'Commercial Bank Premier Lounge',
    category: 'SERVICES',
    floorNumber: 8,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.924850,
      longitude: 79.848100,
      height: 80.0,
    ),
    description: 'Exclusive priority banking, forex exchange, and private wealth advisory.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-802',
    name: 'Hatton National Bank (HNB) VIP Suite',
    category: 'SERVICES',
    floorNumber: 8,
    rating: 4.7,
    location: GeodeticCoords(
      latitude: 6.929350,
      longitude: 79.844300,
      height: 80.0,
    ),
    description: 'Digital self-service banking center, corporate loans & trade desk.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-803',
    name: 'Sampath Bank Smart Banking Kiosk',
    category: 'SERVICES',
    floorNumber: 8,
    rating: 4.8,
    location: GeodeticCoords(
      latitude: 6.929550,
      longitude: 79.847900,
      height: 80.0,
    ),
    description: '24/7 automated cash deposit, ATM machines, and card services.',
    openStatus: '24/7',
  ),

  // FLOOR 9 - VIP Gemology & Executive Suites (290m - 360m 3D Dist)
  const DestinationPOI(
    id: 'poi-901',
    name: 'Ceylon Gem & Sapphire Guild Salon',
    category: 'LUXURY',
    floorNumber: 9,
    rating: 5.0,
    location: GeodeticCoords(
      latitude: 6.929450,
      longitude: 79.847750,
      height: 85.0,
    ),
    description: 'Certified rare Ratnapura gemstones, padparadscha sapphires & custom cuts.',
    openStatus: 'BY APPOINTMENT',
  ),
  const DestinationPOI(
    id: 'poi-902',
    name: 'Ocean View Executive Club',
    category: 'SERVICES',
    floorNumber: 9,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.924650,
      longitude: 79.848350,
      height: 85.0,
    ),
    description: 'Private executive conference lounge overlooking the Indian Ocean coastline.',
    openStatus: 'OPEN NOW',
  ),

  // FLOOR 10 - Sky Lounge & Ocean View Terrace (320m - 390m 3D Dist)
  const DestinationPOI(
    id: 'poi-1001',
    name: 'Galle Face Sunset Sky Lounge',
    category: 'ENTERTAINMENT',
    floorNumber: 10,
    rating: 5.0,
    location: GeodeticCoords(
      latitude: 6.929750,
      longitude: 79.848250,
      height: 90.0,
    ),
    description: '360-degree ocean view rooftop lounge with live acoustic music & mocktails.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-1002',
    name: 'Indian Ocean Terrace Fine Dining',
    category: 'FOOD & DRINK',
    floorNumber: 10,
    rating: 4.9,
    location: GeodeticCoords(
      latitude: 6.924450,
      longitude: 79.843950,
      height: 90.0,
    ),
    description: 'Fresh seafood grill, international fusion dishes & open-air terrace dining.',
    openStatus: 'OPEN NOW',
  ),
  const DestinationPOI(
    id: 'poi-1003',
    name: 'Helipad & Executive Sky Gate',
    category: 'SERVICES',
    floorNumber: 10,
    rating: 5.0,
    location: GeodeticCoords(
      latitude: 6.927300,
      longitude: 79.845680,
      height: 90.0,
    ),
    description: 'Rooftop helipad reception, VIP sky elevator & express check-in.',
    openStatus: '24/7',
  ),
];
