$shopsDir = "e:\Hasnet Projects\NavCore\navcore_mobile\assets\images\shops"
if (!(Test-Path $shopsDir)) {
    New-Item -ItemType Directory -Force -Path $shopsDir | Out-Null
}

$images = @(
    @{ file = "b1_executive_valet_concierge.jpg"; url = "https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=800&auto=format&fit=crop&q=80" },
    @{ file = "keells_express_supermarket_b1.jpg"; url = "https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=800&auto=format&fit=crop&q=80" },
    @{ file = "b1_eco_ev_charging_hub.jpg"; url = "https://images.unsplash.com/photo-1563720223185-11003d516935?w=800&auto=format&fit=crop&q=80" },
    @{ file = "b1_auto_car_wash.jpg"; url = "https://images.unsplash.com/photo-1520340356584-f9917d1eea6f?w=800&auto=format&fit=crop&q=80" },
    @{ file = "b1_luggage_lockers.jpg"; url = "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=800&auto=format&fit=crop&q=80" },
    @{ file = "odel_flagship_store.jpg"; url = "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&auto=format&fit=crop&q=80" },
    @{ file = "concierge_information_desk.jpg"; url = "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&auto=format&fit=crop&q=80" },
    @{ file = "spa_ceylon_luxury_ayurveda.jpg"; url = "https://images.unsplash.com/photo-1540555700478-4be289fbecef?w=800&auto=format&fit=crop&q=80" },
    @{ file = "dilmah_tea_lounge.jpg"; url = "https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=800&auto=format&fit=crop&q=80" },
    @{ file = "keells_super_hypermarket.jpg"; url = "https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&auto=format&fit=crop&q=80" },
    @{ file = "cotton_collection.jpg"; url = "https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?w=800&auto=format&fit=crop&q=80" },
    @{ file = "kelly_felder_designer_lounge.jpg"; url = "https://images.unsplash.com/photo-1539109136881-3be0616acf4b?w=800&auto=format&fit=crop&q=80" },
    @{ file = "house_of_fashion_outlet.jpg"; url = "https://images.unsplash.com/photo-1445205170230-053b83016050?w=800&auto=format&fit=crop&q=80" },
    @{ file = "barefoot_ceylon_handwoven.jpg"; url = "https://images.unsplash.com/photo-1606744824163-985d376605aa?w=800&auto=format&fit=crop&q=80" },
    @{ file = "hugo_boss_luxury_apparel.jpg"; url = "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=800&auto=format&fit=crop&q=80" },
    @{ file = "singer_mega_experience_center.jpg"; url = "https://images.unsplash.com/photo-1550009158-9ebf69173e03?w=800&auto=format&fit=crop&q=80" },
    @{ file = "abans_elite_apple_lg_store.jpg"; url = "https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=800&auto=format&fit=crop&q=80" },
    @{ file = "dialog_axiata_experience_centre.jpg"; url = "https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800&auto=format&fit=crop&q=80" },
    @{ file = "mobitel_slt_broadband_lounge.jpg"; url = "https://images.unsplash.com/photo-1562976540-1502c2145186?w=800&auto=format&fit=crop&q=80" },
    @{ file = "samsung_smart_experience_zone.jpg"; url = "https://images.unsplash.com/photo-1610945265064-0e34e5519bbf?w=800&auto=format&fit=crop&q=80" },
    @{ file = "food_studio_ceylon_court.jpg"; url = "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&auto=format&fit=crop&q=80" },
    @{ file = "ministry_of_crab_express.jpg"; url = "https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=800&auto=format&fit=crop&q=80" },
    @{ file = "barista_ceylon_espresso_bar.jpg"; url = "https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&auto=format&fit=crop&q=80" },
    @{ file = "taco_bell_sri_lanka.jpg"; url = "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&auto=format&fit=crop&q=80" },
    @{ file = "pvr_scope_cinemas_imax.jpg"; url = "https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=800&auto=format&fit=crop&q=80" }
)

$client = New-Object System.Net.WebClient
foreach ($item in $images) {
    $outPath = Join-Path $shopsDir $item.file
    Write-Host "Downloading $($item.file)..."
    $client.DownloadFile($item.url, $outPath)
}
Write-Host "Done!"
