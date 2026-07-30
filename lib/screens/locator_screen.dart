import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/db/app_database.dart';
import '../data/locator_models.dart';
import '../data/locator_service.dart';
import '../providers/providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../widgets/common.dart';
import '../widgets/first_run_empty_card.dart';
import '../widgets/locator_map.dart';
import '../widgets/motion.dart';
import '../widgets/sheet_form.dart';

enum _LocatorFilter { all, fresh, stale }

class LocatorScreen extends ConsumerStatefulWidget {
  const LocatorScreen({super.key});

  @override
  ConsumerState<LocatorScreen> createState() => _LocatorScreenState();
}

class _LocatorScreenState extends ConsumerState<LocatorScreen> {
  bool _busy = false;
  bool _showMyLocation = false;
  String? _error;
  String? _focusMemberId;
  _LocatorFilter _filter = _LocatorFilter.all;
  ({double lat, double lng})? _me;
  bool _didAutoFocus = false;
  double _sheetSize = 0.36;
  final _sheetController = DraggableScrollableController();

  static const _sheetMin = 0.24;
  static const _sheetInitial = 0.36;
  static const _sheetMax = 0.9;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refreshMyLocationFlag();
      await _refreshMe();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _refreshMyLocationFlag() async {
    final ok = await ref.read(locatorServiceProvider).hasWhenInUsePermission();
    if (mounted) setState(() => _showMyLocation = ok);
  }

  Future<void> _refreshMe() async {
    final me = await ref.read(locatorServiceProvider).peekDevicePosition();
    if (mounted) setState(() => _me = me);
  }

  Future<void> _shareNow() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final loc = await ref.read(locatorServiceProvider).shareNow();
      ref.invalidate(locatorSharingProvider);
      await _refreshMyLocationFlag();
      await _refreshMe();
      if (mounted) {
        setState(() => _focusMemberId = loc.memberId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              (loc.label ?? '').trim().isEmpty
                  ? 'Shared your location with the nest'
                  : 'Shared · ${loc.label!.trim()}',
            ),
          ),
        );
      }
    } on LocatorException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not get your location. Try again.');
      debugPrint('Locator shareNow: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setSharing(bool enabled) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (enabled) {
        final loc = await ref.read(locatorServiceProvider).shareNow();
        await _refreshMyLocationFlag();
        await _refreshMe();
        if (mounted) setState(() => _focusMemberId = loc.memberId);
      } else {
        await ref.read(locatorServiceProvider).setSharingEnabled(false);
      }
      ref.invalidate(locatorSharingProvider);
    } on LocatorException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not update sharing.');
      debugPrint('Locator setSharing: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openMaps(NestLocation loc) async {
    final uri = Uri.parse(locatorMapsUrl(loc.lat, loc.lng));
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      final g = Uri.parse(locatorGoogleMapsUrl(loc.lat, loc.lng));
      await launchUrl(g, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openDirections(NestLocation loc) async {
    final uri = Uri.parse(locatorDirectionsUrl(loc.lat, loc.lng));
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      final g = Uri.parse(locatorGoogleDirectionsUrl(loc.lat, loc.lng));
      await launchUrl(g, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyPin(NestLocation loc) async {
    final text =
        '${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)}';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordinates copied')),
    );
  }

  List<NestLocation> _filtered(List<NestLocation> locs) {
    switch (_filter) {
      case _LocatorFilter.all:
        return locs;
      case _LocatorFilter.fresh:
        return locs.where((l) => !l.isStale()).toList();
      case _LocatorFilter.stale:
        return locs.where((l) => l.isStale()).toList();
    }
  }

  String? _distanceFor(NestLocation loc) {
    final me = _me;
    if (me == null || !loc.hasCoordinates) return null;
    final meters = haversineMeters(
      lat1: me.lat,
      lng1: me.lng,
      lat2: loc.lat,
      lng2: loc.lng,
    );
    final formatted = formatLocatorDistance(meters);
    return formatted.isEmpty ? null : formatted;
  }

  @override
  Widget build(BuildContext context) {
    final sharingAsync = ref.watch(locatorSharingProvider);
    final locationsAsync = ref.watch(nestLocationsProvider);
    final members = ref.watch(membersProvider).valueOrNull ?? const [];
    final sharing = sharingAsync.valueOrNull ?? false;
    final locations = locationsAsync.valueOrNull ?? const <NestLocation>[];
    final freshCount = locations.where((l) => !l.isStale()).length;
    final staleCount = locations.length - freshCount;

    // Auto-focus newest pin once.
    if (!_didAutoFocus && _focusMemberId == null && locations.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didAutoFocus) return;
        setState(() {
          _didAutoFocus = true;
          _focusMemberId = locations.first.memberId;
        });
      });
    }

    NestMember? memberFor(String id) {
      for (final m in members) {
        if (m.id == id) return m;
      }
      return null;
    }

    final statusText = locations.isEmpty
        ? null
        : freshCount == locations.length
            ? '$freshCount live'
            : '$freshCount live · $staleCount stale';

    final mapBottomInset =
        MediaQuery.sizeOf(context).height * _sheetSize + 12;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Locator'),
        actions: [
          if (sharing)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: SoftPill(
                  label: 'Sharing on',
                  selected: true,
                  background: AppColors.mint,
                  foreground: AppColors.ink,
                ),
              ),
            ),
        ],
      ),
      body: NotificationListener<DraggableScrollableNotification>(
        onNotification: (n) {
          if ((n.extent - _sheetSize).abs() > 0.01) {
            setState(() => _sheetSize = n.extent);
          }
          return false;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: LocatorMap(
                locations: locations,
                members: members,
                focusMemberId: _focusMemberId,
                onMarkerTap: (id) => setState(() => _focusMemberId = id),
                showMyLocation: _showMyLocation,
                statusText: statusText,
                edgeToEdge: true,
                bottomControlsInset: mapBottomInset.clamp(80.0, 420.0),
              ),
            ),
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: _sheetInitial,
              minChildSize: _sheetMin,
              maxChildSize: _sheetMax,
              snap: true,
              snapSizes: const [_sheetMin, _sheetInitial, 0.62, _sheetMax],
              builder: (context, scrollController) {
                return Material(
                  color: AppColors.surface,
                  elevation: 10,
                  shadowColor: Colors.black.withValues(alpha: 0.18),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
                    children: [
                      sheetHandle(),
                      const SizedBox(height: 10),
                      Appear(
                        child: NestCard(
                          color: AppColors.primaryWash,
                          bordered: false,
                          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Your nest pulse',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          sharing
                                              ? 'Last-known pin is visible to the nest'
                                              : 'Opt-in only — nothing shares until you do',
                                          style: const TextStyle(
                                            color: AppColors.inkSecondary,
                                            height: 1.35,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch.adaptive(
                                    value: sharing,
                                    onChanged: _busy
                                        ? null
                                        : (v) {
                                            _setSharing(v);
                                          },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _busy ? null : _shareNow,
                                  icon: _busy
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.my_location_rounded),
                                  label: Text(
                                    _busy ? 'Pinning…' : 'Share now',
                                  ),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (locations.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              SoftPill(
                                label: 'Everyone',
                                selected: _focusMemberId == null,
                                onTap: () =>
                                    setState(() => _focusMemberId = null),
                              ),
                              const SizedBox(width: 8),
                              for (final loc in locations) ...[
                                _MemberFocusChip(
                                  member: memberFor(loc.memberId),
                                  stale: loc.isStale(),
                                  selected:
                                      _focusMemberId == loc.memberId,
                                  onTap: () => setState(
                                    () => _focusMemberId = loc.memberId,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(
                            child: SectionLabel('Nest locations'),
                          ),
                          SoftPill(
                            label: 'All',
                            selected: _filter == _LocatorFilter.all,
                            onTap: () => setState(
                              () => _filter = _LocatorFilter.all,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SoftPill(
                            label: 'Live',
                            selected: _filter == _LocatorFilter.fresh,
                            onTap: () => setState(
                              () => _filter = _LocatorFilter.fresh,
                            ),
                          ),
                          const SizedBox(width: 6),
                          SoftPill(
                            label: 'Stale',
                            selected: _filter == _LocatorFilter.stale,
                            onTap: () => setState(
                              () => _filter = _LocatorFilter.stale,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      locationsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Could not load nest locations.',
                            style: TextStyle(color: AppColors.inkSecondary),
                          ),
                        ),
                        data: (locs) {
                          if (locs.isEmpty) {
                            return FirstRunEmptyCard(
                              icon: Icons.location_on_outlined,
                              color: AppColors.tileTeal,
                              title: 'No one is sharing yet',
                              body:
                                  'When a nest member opts in and taps Share now, their '
                                  'last-known pin shows up on the map.',
                              actionLabel:
                                  sharing ? 'Share now' : 'Turn on sharing',
                              onAction: () {
                                if (_busy) return;
                                if (sharing) {
                                  _shareNow();
                                } else {
                                  _setSharing(true);
                                }
                              },
                            );
                          }

                          final shown = _filtered(locs);
                          if (shown.isEmpty) {
                            return NestCard(
                              color: AppColors.surfaceMuted,
                              bordered: false,
                              child: Text(
                                _filter == _LocatorFilter.fresh
                                    ? 'No live pins right now — try All or Share now.'
                                    : 'No stale pins — everyone’s fresh.',
                                style: const TextStyle(
                                  color: AppColors.inkSecondary,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: [
                              for (var i = 0; i < shown.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Appear(
                                    delay:
                                        AppMotion.stagger * i.clamp(0, 8),
                                    replayKey: shown[i].memberId,
                                    child: _LocationCard(
                                      location: shown[i],
                                      member:
                                          memberFor(shown[i].memberId),
                                      selected: _focusMemberId ==
                                          shown[i].memberId,
                                      color: AppColors.softCardColors[i %
                                          AppColors.softCardColors.length],
                                      distanceLabel:
                                          _distanceFor(shown[i]),
                                      onSelect: () => setState(
                                        () => _focusMemberId =
                                            shown[i].memberId,
                                      ),
                                      onOpenMaps: () =>
                                          _openMaps(shown[i]),
                                      onDirections: () =>
                                          _openDirections(shown[i]),
                                      onCopy: () => _copyPin(shown[i]),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      NestCard(
                        bordered: true,
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                              color: AppColors.inkMuted,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Locator never tracks in the background. Pins expire '
                                'visually after 24 hours so the nest doesn’t rely on '
                                'outdated places.',
                                style: TextStyle(
                                  color: AppColors.inkSecondary,
                                  fontSize: 12.5,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberFocusChip extends StatelessWidget {
  const _MemberFocusChip({
    required this.member,
    required this.stale,
    required this.selected,
    required this.onTap,
  });

  final NestMember? member;
  final bool stale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = member?.name.split(' ').first ?? 'Member';
    final initials = member?.initials ?? '?';
    final color = member == null
        ? AppColors.accent
        : Color(member!.colorValue);

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: selected ? null : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: stale ? 0.55 : 1,
              child: MemberAvatar(
                initials: initials,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: selected ? AppColors.onDark : AppColors.ink,
              ),
            ),
            if (stale) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: selected ? AppColors.onDark : AppColors.inkMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.location,
    required this.member,
    required this.color,
    required this.selected,
    required this.onSelect,
    required this.onOpenMaps,
    required this.onDirections,
    required this.onCopy,
    this.distanceLabel,
  });

  final NestLocation location;
  final NestMember? member;
  final Color color;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpenMaps;
  final VoidCallback onDirections;
  final VoidCallback onCopy;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final stale = location.isStale();
    final name = member?.name ?? 'Family member';
    final age = formatLocatorAge(location.updatedAt);
    final label = (location.label ?? '').trim();
    final accuracy = formatLocatorAccuracy(location.accuracyM);
    final meta = <String>[
      if (label.isNotEmpty) label,
      stale ? 'Last seen $age' : 'Updated $age',
      if (accuracy.isNotEmpty) accuracy,
      if ((distanceLabel ?? '').isNotEmpty) '$distanceLabel away',
    ].join(' · ');

    return NestCard(
      onTap: onSelect,
      color: stale ? AppColors.surfaceMuted : color,
      bordered: stale || selected,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (member != null)
                MemberAvatar(
                  initials: member!.initials,
                  color: Color(member!.colorValue),
                  size: 44,
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: AppColors.inkMuted,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color:
                                  stale ? AppColors.inkMuted : AppColors.ink,
                            ),
                          ),
                        ),
                        _StatusBadge(stale: stale),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      style: const TextStyle(
                        color: AppColors.inkSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionChip(
                icon: Icons.directions_rounded,
                label: 'Directions',
                onTap: onDirections,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.map_outlined,
                label: 'Open map',
                onTap: onOpenMaps,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.copy_rounded,
                label: 'Copy',
                onTap: onCopy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.stale});

  final bool stale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: stale ? AppColors.primarySoft : AppColors.mint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        stale ? 'Stale' : 'Live',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: stale ? AppColors.inkMuted : AppColors.ink,
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.ink),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
