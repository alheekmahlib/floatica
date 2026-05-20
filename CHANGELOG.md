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