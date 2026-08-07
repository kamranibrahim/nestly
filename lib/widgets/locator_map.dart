import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../data/db/app_database.dart';
import '../data/locator_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../l10n/l10n_ext.dart';
import 'common.dart';
import 'locator_marker_bitmap.dart';
import 'locator_map_style.dart';

/// Embedded nest map — avatar pins, accuracy ring, HUD controls.
class LocatorMap extends StatefulWidget {
  const LocatorMap({
    super.key,
    required this.locations,
    required this.members,
    this.focusMemberId,
    this.onMarkerTap,
    this.height = 220,
    this.expanded = false,
    this.onToggleExpand,
    this.showMyLocation = false,
    this.statusText,
    this.edgeToEdge = false,
    this.bottomControlsInset = 10,
  });

  final List<NestLocation> locations;
  final List<NestMember> members;
  final String? focusMemberId;
  final ValueChanged<String>? onMarkerTap;
  final double height;
  final bool expanded;
  final VoidCallback? onToggleExpand;
  final bool showMyLocation;
  final String? statusText;
  final bool edgeToEdge;
  final double bottomControlsInset;

  @override
  State<LocatorMap> createState() => _LocatorMapState();
}

class _LocatorMapState extends State<LocatorMap> {
  GoogleMapController? _controller;
  String? _lastFocused;
  Map<String, BitmapDescriptor> _icons = {};
  bool _buildingIcons = false;
  MapType _mapType = MapType.normal;

  NestMember? _member(String id) {
    for (final m in widget.members) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<void> _rebuildIcons() async {
    if (_buildingIcons) return;
    _buildingIcons = true;
    final next = <String, BitmapDescriptor>{};
    try {
      for (final loc in widget.locations) {
        if (!loc.hasCoordinates) continue;
        final member = _member(loc.memberId);
        final selected = widget.focusMemberId == loc.memberId;
        final icon = await LocatorMarkerBitmaps.avatar(
          initials: member?.initials ?? '?',
          color: member == null
              ? AppColors.accent
              : Color(member.colorValue),
          selected: selected,
          stale: loc.isStale(),
          logicalSize: selected ? 54 : 46,
        );
        next[loc.memberId] = icon;
      }
      if (!mounted) return;
      setState(() => _icons = next);
    } finally {
      _buildingIcons = false;
    }
  }

  Set<Marker> _markers(AppLocalizations l10n) {
    final out = <Marker>{};
    for (final loc in widget.locations) {
      if (!loc.hasCoordinates) continue;
      final member = _member(loc.memberId);
      final selected = widget.focusMemberId == loc.memberId;
      final icon = _icons[loc.memberId] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
      final age = formatLocatorAge(loc.updatedAt, l10n: l10n);
      out.add(
        Marker(
          markerId: MarkerId(loc.memberId),
          position: LatLng(loc.lat, loc.lng),
          infoWindow: InfoWindow(
            title: member?.name ?? l10n.familyMember,
            snippet: [
              if (displayLocatorLabel(loc.label, l10n).isNotEmpty)
                displayLocatorLabel(loc.label, l10n),
              loc.isStale()
                  ? l10n.locatorLastSeen(age)
                  : l10n.locatorUpdatedAge(age),
            ].join(' · '),
          ),
          icon: icon,
          alpha: loc.isStale() ? 0.75 : 1,
          zIndexInt: selected ? 2 : 1,
          onTap: () => widget.onMarkerTap?.call(loc.memberId),
        ),
      );
    }
    return out;
  }

  Set<Circle> _circles() {
    final focusId = widget.focusMemberId;
    if (focusId == null) return {};
    NestLocation? focused;
    for (final loc in widget.locations) {
      if (loc.memberId == focusId && loc.hasCoordinates) {
        focused = loc;
        break;
      }
    }
    final accuracy = focused?.accuracyM;
    if (focused == null || accuracy == null || accuracy <= 0) return {};
    final radius = accuracy.clamp(25, 400).toDouble();
    return {
      Circle(
        circleId: CircleId('accuracy-$focusId'),
        center: LatLng(focused.lat, focused.lng),
        radius: radius,
        fillColor: const Color(0xFFB2B2E6).withValues(alpha: 0.16),
        strokeColor: const Color(0xFF8E8ED4).withValues(alpha: 0.45),
        strokeWidth: 1,
        zIndex: 0,
      ),
    };
  }

  Future<void> _fitOrFocus({bool forceFit = false}) async {
    final controller = _controller;
    if (controller == null || !mounted) return;

    final focusId = widget.focusMemberId;
    if (!forceFit && focusId != null && focusId != _lastFocused) {
      NestLocation? target;
      for (final loc in widget.locations) {
        if (loc.memberId == focusId && loc.hasCoordinates) {
          target = loc;
          break;
        }
      }
      if (target != null) {
        _lastFocused = focusId;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(target.lat, target.lng), 15),
        );
        return;
      }
    }

    final bounds = boundsForLocations(widget.locations);
    if (bounds == null) return;
    _lastFocused = null;
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(bounds.south, bounds.west),
          northeast: LatLng(bounds.north, bounds.east),
        ),
        56,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildIcons());
  }

  @override
  void didUpdateWidget(covariant LocatorMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final focusChanged = widget.focusMemberId != oldWidget.focusMemberId;
    final locsChanged = widget.locations.length != oldWidget.locations.length ||
        !_sameIds(widget.locations, oldWidget.locations);
    if (focusChanged || locsChanged) {
      _rebuildIcons();
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitOrFocus());
    }
  }

  bool _sameIds(List<NestLocation> a, List<NestLocation> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].memberId != b[i].memberId) return false;
      if (a[i].lat != b[i].lat || a[i].lng != b[i].lng) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pins = widget.locations.where((l) => l.hasCoordinates).toList();
    final bounds = boundsForLocations(pins);
    final initial = bounds == null
        ? const CameraPosition(target: LatLng(20, 0), zoom: 1.5)
        : CameraPosition(
            target: LatLng(bounds.centerLat, bounds.centerLng),
            zoom: pins.length == 1 ? 13.5 : 10,
          );
    final status = (widget.statusText ?? '').trim();
    final useModernStyle = _mapType == MapType.normal;
    final mapStack = Stack(
      fit: StackFit.expand,
      children: [
        GoogleMap(
          initialCameraPosition: initial,
          mapType: _mapType,
          style: useModernStyle ? locatorMapStyleJson : null,
          markers: _markers(l10n),
          circles: _circles(),
          myLocationEnabled: widget.showMyLocation,
          myLocationButtonEnabled: false,
          compassEnabled: false,
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          buildingsEnabled: false,
          indoorViewEnabled: false,
          trafficEnabled: false,
          padding: EdgeInsets.only(
            top: 8,
            left: 8,
            right: 8,
            bottom: widget.bottomControlsInset * 0.15,
          ),
          onMapCreated: (c) {
            _controller = c;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitOrFocus();
            });
          },
        ),
        // Soft top vignette so HUD reads cleanly on satellite too.
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.12, 1],
                colors: [
                  Colors.black.withValues(alpha: 0.06),
                  Colors.transparent,
                  Colors.transparent,
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        if (pins.isEmpty)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.tileTeal.withValues(alpha: 0.72),
                    AppColors.accent.withValues(alpha: 0.35),
                    AppColors.surfaceMuted.withValues(alpha: 0.97),
                  ],
                ),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 40,
                        color: AppColors.inkMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.locatorMapWake,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkSecondary,
                          height: 1.35,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (status.isNotEmpty)
          Positioned(
            left: 12,
            top: 12,
            child: _MapChip(
              icon: Icons.sensors_rounded,
              label: status,
              onTap: null,
            ),
          ),
        Positioned(
          right: 12,
          top: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.onToggleExpand != null) ...[
                _MapIconButton(
                  icon: widget.expanded
                      ? Icons.fullscreen_exit_rounded
                      : Icons.fullscreen_rounded,
                  tooltip: widget.expanded
                      ? l10n.locatorShrinkMap
                      : l10n.locatorExpandMap,
                  onTap: widget.onToggleExpand,
                ),
                const SizedBox(height: 8),
              ],
              _MapIconButton(
                icon: useModernStyle
                    ? Icons.layers_outlined
                    : Icons.map_outlined,
                tooltip: useModernStyle
                    ? l10n.locatorSatellite
                    : l10n.locatorModernMap,
                onTap: () {
                  setState(() {
                    _mapType = useModernStyle
                        ? MapType.hybrid
                        : MapType.normal;
                  });
                },
              ),
            ],
          ),
        ),
        Positioned(
          right: 12,
          bottom: widget.bottomControlsInset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.focusMemberId != null) ...[
                _MapChip(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Focus',
                  onTap: () {
                    _lastFocused = null;
                    _fitOrFocus();
                  },
                ),
                const SizedBox(height: 8),
              ],
              _MapChip(
                icon: Icons.zoom_out_map_rounded,
                label: l10n.locatorFitAll,
                onTap: () {
                  _lastFocused = null;
                  _fitOrFocus(forceFit: true);
                },
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.edgeToEdge) {
      return SizedBox.expand(child: mapStack);
    }

    return NestCard(
      bordered: true,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.standard,
          height: widget.height,
          width: double.infinity,
          child: mapStack,
        ),
      ),
    );
  }
}

class _MapChip extends StatelessWidget {
  const _MapChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.ink),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.ink,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? child
            : InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onTap,
                child: child,
              ),
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, size: 20, color: AppColors.ink),
            ),
          ),
        ),
      ),
    );
  }
}
