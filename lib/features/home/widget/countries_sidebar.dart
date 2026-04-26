import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/region.dart';
import 'package:hiddify/core/theme/noda_theme.dart';
import 'package:hiddify/core/widget/noda_chrome.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hiddify/features/settings/data/config_option_repository.dart';
import 'package:hiddify/features/proxy/active/ip_widget.dart';

class CountriesSidebar extends HookConsumerWidget {
  const CountriesSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final selectedCountry = ref.watch(ConfigOptions.region);

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(color: context.nodaBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search country...",
                hintStyle: TextStyle(fontSize: 13, color: context.nodaMuted),
                prefixIcon: Icon(Icons.search, size: 16, color: context.nodaMuted),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).colorScheme.surfaceBright,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.nodaBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.nodaBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.nodaText, width: 2),
                ),
              ),
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _SidebarMenuRow(icon: Icons.access_time_filled_rounded, title: "Recents", shortcut: "⌘ 1"),
                const Gap(4),
                _SidebarMenuRow(icon: Icons.public_rounded, title: "Countries", shortcut: "⌘ 2", isActive: true),
              ],
            ),
          ),

          Divider(height: 16, indent: 24, endIndent: 24, color: context.nodaBorder),

          // Sub tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: context.nodaText, width: 2)),
                  ),
                  child: Text(
                    "All",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.nodaText),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              "COUNTRIES (${Region.availableCountries.length})",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: context.nodaMuted,
              ),
            ),
          ),

          // Fastest country quick select
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Material(
              color: Theme.of(context).brightness == Brightness.light ? const Color(0xFFE5EEFF) : context.nodaNeon.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: context.nodaNeon,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.power_settings_new, size: 12, color: Colors.white),
                      ),
                      const Gap(12),
                      Text(
                        "Fastest country",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.nodaNeon,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Countries List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: Region.availableCountries.length,
              itemBuilder: (context, index) {
                final region = Region.availableCountries[index];
                final isSelected = region == selectedCountry;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: isSelected ? (Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).colorScheme.surfaceBright) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        await ref.read(ConfigOptions.region.notifier).update(region);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? context.nodaBorder : Colors.transparent,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected && Theme.of(context).brightness == Brightness.light ? [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
                          ] : [],
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 2, offset: const Offset(0, 1))],
                              ),
                              child: IPCountryFlag(countryCode: region.name.toUpperCase(), size: 20),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Text(
                                region.present(t),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? context.nodaText : context.nodaText.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: context.nodaMuted)
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarMenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? shortcut;
  final bool isActive;

  const _SidebarMenuRow({
    required this.icon,
    required this.title,
    this.shortcut,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? context.nodaText.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isActive ? context.nodaText : context.nodaMuted),
              const Gap(12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive ? context.nodaText : context.nodaText.withValues(alpha: 0.8),
                  ),
                ),
              ),
              if (shortcut != null)
                Text(
                  shortcut!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: context.nodaMuted.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
