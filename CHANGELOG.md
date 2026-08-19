## 1.2.1

* **FIX:** Menu state desync and leaked dismiss barrier:
	* `_openMenu`/`_closeMenu` early-return guards now re-sync `FloaticaMenuController.isOpen` instead of leaving it stale, which previously made subsequent `close()` calls no-ops (menu stayed open forever).
	* Opening the menu now removes any stale barrier left over from an interrupted close animation, so orphaned full-screen barriers can no longer swallow taps (e.g. dead back button on a pushed route while edge-swipe still worked).

## 1.2.0

* **FEAT:**
	* Liquid Glass effect overhaul — significantly closer to iOS 26 Liquid Glass:
		* Multi-layer specular highlights (radial glow, top-edge bar, left-edge highlight, diagonal streak, bottom-right warm glow).
		* Shape-aware edge glow following border radius (outer glow, inner highlight, corner accent) with `edgeGlowIntensity` parameter.
		* Improved frosted noise texture — grid-based with jitter for organic look (bright + dark dots mix).
		* Four-edge inner shadows (top, bottom, left, right) for realistic glass depth.
		* Multi-layer luminosity-aware border (main gradient + inner accent).
	* Nav bar now sizes to its content width instead of expanding to full screen width.
	* Menu expands to match nav bar width (content reflows via `Wrap`).

* **FIX:**
	* Fix barrier overlay not covering full screen when nav bar uses intrinsic sizing.
	* Fix nav bar shifting left when menu opens with barrier.
	* Fix menu items not receiving tap events due to `hitTestChildren` returning `false`.

## 1.1.0

* **FIX:**
	* Rename `flloatica_menu_item.dart` → `floatica_menu_item.dart` (typo fix).
	* Fix overlay leak — guard against unmounted widget in `addPostFrameCallback`.
	* Fix `_removeBarrierOverlay` potential crash with `try-catch`.
	* Fix selected tab color being ignored with dot/underline indicator styles.
	* Fix `_buildContent` being built twice when glass effect is enabled.
	* Fix `Expanded` layout issue on icon when `labelPosition` is bottom.
	* Export `FloaticaMenuItemWidget` in public API.
	* Fix incorrect install command in README (`flexible_sheet` → `floatica`).

* **FEAT:**
	* Auto-shrink tabs on small screens — `FittedBox` replaces disabled `SingleChildScrollView`, preventing overflow with many tabs.

* **IMPROVE:**
	* Optimize `shouldRepaint` in `_LiquidGlassPainter` — compare fields instead of references.
	* Remove unnecessary `ImageFilter.blur(0,0)` fallback when saturation boost is 1.0.
	* Make `ContextEx` getters public (`theme`, `colorScheme`).
	* Update minimum Flutter constraint to `>=3.10.0`.
	* Add 14 unit and widget tests (models, controller, overflow).

## 1.0.0+3

* **FIX:**
	* Fix README.
	
## 1.0.0+2

* **FIX:**
	* Fix LICENSE.

## 1.0.0+1

* **FIX:**
	* Fix README.

## 1.0.0

* **Initial release**