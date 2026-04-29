import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/theme/app_theme_mode.dart';
import 'package:hiddify/core/theme/noda_theme.dart';
import 'package:hiddify/core/theme/theme_preferences.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CountriesSidebar extends ConsumerWidget {
  const CountriesSidebar({
    super.key,
    required this.selectedCountry,
    this.onOpenAIAudit,
    this.onOpenSettings,
    this.onOpenAbout,
  });

  final Region selectedCountry;
  final VoidCallback? onOpenAIAudit;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenAbout;

  static const _width = 360.0;
  static const _railWidth = 84.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: _width,
      child: ClipRect(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.nodaSurface,
            border: Border(right: BorderSide(color: context.nodaBorder)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? .58 : .08),
                blurRadius: 46,
                offset: const Offset(18, 0),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 50,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: context.nodaNeon.withValues(alpha: .05), blurRadius: 100, spreadRadius: 50),
                    ],
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const _BrandHeader(),
                    Expanded(
                      child: Row(
                        children: [
                          const _NavigationRail(width: _railWidth),
                          Expanded(
                            child: _CountriesPanel(selectedCountry: selectedCountry, onOpenAIAudit: onOpenAIAudit),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        'noda.',
        style: GoogleFonts.cookie(
          fontSize: 42,
          height: 1,
          color: context.nodaText,
          shadows: [
            Shadow(color: (context.isDark ? Colors.white : Colors.black).withValues(alpha: .18), blurRadius: 10),
          ],
        ),
      ),
    );
  }
}

class _NavigationRail extends ConsumerWidget {
  const _NavigationRail({required this.width});

  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: context.nodaBorder)),
      ),
      child: Column(
        children: [
          const Gap(16),
          _RailButton(icon: Icons.power_settings_new_rounded, active: true, onTap: () {}),
          const Gap(24),
          _RailButton(icon: Icons.settings_rounded, onTap: _findSidebar(context)?.onOpenSettings),
          const Gap(24),
          _RailButton(icon: Icons.info_outline_rounded, onTap: _findSidebar(context)?.onOpenAbout),
          const Spacer(),
          _RailButton(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            onTap: () {
              final currentTheme = ref.read(themePreferencesProvider);
              ref
                  .read(themePreferencesProvider.notifier)
                  .changeThemeMode(currentTheme == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark);
            },
          ),
          const Gap(32),
        ],
      ),
    );
  }

  CountriesSidebar? _findSidebar(BuildContext context) {
    return context.findAncestorWidgetOfExactType<CountriesSidebar>();
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({required this.icon, this.active = false, this.onTap});

  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: active ? context.nodaSurfaceSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? context.nodaNeon.withValues(alpha: .80) : Colors.transparent),
            boxShadow: active ? [BoxShadow(color: context.nodaNeon.withValues(alpha: .26), blurRadius: 15)] : null,
          ),
          child: Icon(icon, color: active ? context.nodaNeon : context.nodaMuted, size: 22),
        ),
      ),
    );
  }
}

class _CountriesPanel extends ConsumerWidget {
  const _CountriesPanel({required this.selectedCountry, this.onOpenAIAudit});

  final Region selectedCountry;
  final VoidCallback? onOpenAIAudit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(24, 8, 24, 16), child: _SearchBox()),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _MenuRow(icon: Icons.access_time_rounded, title: 'Recents', badge: '1'),
              Gap(8),
              _MenuRow(icon: Icons.public_rounded, title: 'Countries', badge: '1', isActive: true),
            ],
          ),
        ),
        const Gap(24),
        const _SectionLabel('SPECIAL'),
        const Gap(12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _SpecialButton(
            icon: Icons.bolt_rounded,
            title: 'Fastest country',
            onTap: () => ref.read(ConfigOptions.region.notifier).update(Region.fi),
          ),
        ),
        const Gap(12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _SpecialButton(
            icon: Icons.security_rounded,
            title: 'AI Security Audit',
            subdued: true,
            onTap: onOpenAIAudit,
          ),
        ),
        const Gap(24),
        const _SectionLabel('ALL COUNTRIES'),
        const Gap(8),
        Expanded(
          child: ListView.builder(
            itemCount: _servers.length,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemBuilder: (context, index) {
              final server = _servers[index];
              return _CountryTile(
                server: server,
                isActive: selectedCountry == server.region,
                onTap: () => ref.read(ConfigOptions.region.notifier).update(server.region),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(color: context.nodaSurfaceSoft, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          const Gap(16),
          Icon(Icons.search_rounded, size: 16, color: context.nodaMuted),
          const Gap(12),
          Text('Search country...', style: TextStyle(color: context.nodaMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.title, required this.badge, this.isActive = false});

  final IconData icon;
  final String title;
  final String badge;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActive ? context.nodaSurfaceSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isActive ? Border.all(color: context.nodaNeon.withValues(alpha: .22)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isActive ? context.nodaNeon : context.nodaMuted),
          const Gap(12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? context.nodaText : context.nodaMuted,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: context.nodaSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: context.nodaBorder),
            ),
            child: Text(
              badge,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: context.nodaMuted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: context.nodaMuted, letterSpacing: 1.5),
      ),
    );
  }
}

class _SpecialButton extends StatelessWidget {
  const _SpecialButton({required this.icon, required this.title, this.subdued = false, this.onTap});

  final IconData icon;
  final String title;
  final bool subdued;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: subdued ? context.nodaSurfaceSoft : context.nodaNeon.withValues(alpha: context.isDark ? .13 : .08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.nodaNeon.withValues(alpha: subdued ? .22 : .40)),
            boxShadow: subdued ? null : [BoxShadow(color: context.nodaNeon.withValues(alpha: .10), blurRadius: 15)],
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: context.nodaNeon),
              const Gap(12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: context.nodaNeon),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({required this.server, required this.isActive, required this.onTap});

  final _ServerMeta server;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? context.nodaSurfaceSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isActive ? Border.all(color: context.nodaNeon.withValues(alpha: .16)) : null,
          ),
          child: Row(
            children: [
              if (isActive) ...[
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: context.nodaNeon,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [BoxShadow(color: context.nodaNeon, blurRadius: 6)],
                  ),
                ),
                const Gap(12),
              ],
              _CountryFlag(region: server.region, size: 22),
              const Gap(12),
              Expanded(
                child: Text(
                  server.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? context.nodaText : context.nodaMuted,
                  ),
                ),
              ),
              Text(server.ping, style: TextStyle(fontSize: 12, color: context.nodaMuted)),
              const Gap(8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: server.good ? context.nodaNeon : Colors.orange,
                  boxShadow: [BoxShadow(color: server.good ? context.nodaNeon : Colors.orange, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryFlag extends StatelessWidget {
  const _CountryFlag({required this.region, required this.size});

  final Region region;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(shape: BoxShape.circle, color: context.nodaSurfaceSoft),
      child: Transform.scale(
        scale: 1.35,
        child: IPCountryFlag(countryCode: _flagCode(region), size: size * 1.5),
      ),
    );
  }
}

class _ServerMeta {
  const _ServerMeta(this.region, this.name, this.ping, this.good);

  final Region region;
  final String name;
  final String ping;
  final bool good;
}

const _servers = [
  _ServerMeta(Region.fi, 'Finland, Helsinki', '18 ms', true),
];

String _flagCode(Region region) {
  return switch (region) {
    Region.uk => 'GB',
    Region.other => 'FI',
    _ => region.name.toUpperCase(),
  };
}
