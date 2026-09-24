$filePath = 'e:\Hasnet Projects\NavCore\navcore_mobile\lib\ui\home_screen.dart'
$c = [System.IO.File]::ReadAllText($filePath)

$target = "children: [`r`n                                          Expanded("
if (-not $c.Contains($target)) {
    $target = "children: [`n                                          Expanded("
}

$replacement = "children: [`n                                          ClipRRect(`n                                            borderRadius: BorderRadius.circular(8),`n                                            child: ShopImage(`n                                              imagePathOrUrl: shop.effectiveImageUrl,`n                                              width: 34,`n                                              height: 34,`n                                              fit: BoxFit.cover,`n                                            ),`n                                          ),`n                                          const SizedBox(width: 9),`n                                          Expanded("

if ($c.Contains($target)) {
    $c = $c.Replace($target, $replacement)
    [System.IO.File]::WriteAllText($filePath, $c)
    Write-Host "EDITED_DYNAMICALLY_OK"
} else {
    Write-Host "TARGET_NOT_MATCHED"
}
