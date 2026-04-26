import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hiddify/core/theme/noda_theme.dart';

class SettingsMenuCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onClick;

  const SettingsMenuCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverableContainer(
      onClick: onClick,
      builder: (context, isHovered, isPressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.nodaSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isHovered ? context.nodaBorder.withValues(alpha: 0.8) : context.nodaBorder,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isHovered ? context.nodaSurfaceSoft.withValues(alpha: 0.8) : context.nodaSurfaceSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.nodaBorder.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 24,
                    color: isHovered ? context.nodaText : context.nodaMuted,
                  ),
                ),
              ),
              const Gap(20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: context.nodaText,
                        height: 1.2,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: context.nodaMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: isHovered ? context.nodaText : context.nodaMuted,
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onClick;

  const SettingsListItem({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverableContainer(
      onClick: onClick,
      builder: (context, isHovered, isPressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isPressed
                ? context.nodaSurfaceSoft
                : (isHovered ? context.nodaSurfaceSoft.withValues(alpha: 0.5) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: isHovered ? context.nodaText : context.nodaMuted),
              const Gap(20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.nodaText,
                      ),
                    ),
                    if (value != null) ...[
                      const Gap(2),
                      Text(
                        value!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.nodaMuted,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class SettingsToggleItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final bool enabled;
  final VoidCallback onChange;

  const SettingsToggleItem({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    required this.enabled,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverableContainer(
      onClick: onChange,
      builder: (context, isHovered, isPressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isHovered ? context.nodaSurfaceSoft.withValues(alpha: 0.5) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: context.nodaMuted),
              const Gap(20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.nodaText,
                      ),
                    ),
                    if (description != null) ...[
                      const Gap(4),
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: context.nodaMuted,
                          height: 1.4,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              const Gap(16),
              _PremiumToggle(enabled: enabled),
            ],
          ),
        );
      },
    );
  }
}

class _PremiumToggle extends StatelessWidget {
  final bool enabled;

  const _PremiumToggle({required this.enabled});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      width: 48,
      height: 28,
      decoration: BoxDecoration(
        color: enabled ? ((Theme.of(context).brightness == Brightness.dark) ? context.nodaNeon : Colors.black) : context.nodaSurfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(3),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            left: enabled ? 20 : 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: enabled ? ((Theme.of(context).brightness == Brightness.dark) ? Colors.black : Colors.white) : context.nodaMuted,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsPremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SettingsPremiumCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.nodaSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.nodaBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class SettingsHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;

  const SettingsHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        children: [
          _HoverableContainer(
            onClick: onBack,
            builder: (context, isHovered, isPressed) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.nodaSurface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isHovered ? context.nodaBorder.withValues(alpha: 0.8) : context.nodaBorder,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: isHovered ? context.nodaText : context.nodaMuted,
                  ),
                ),
              );
            },
          ),
          const Gap(16),
          Text(
            title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: context.nodaText,
            ),
          ),
        ],
      ),
    );
  }
}

typedef HoverBuilder = Widget Function(BuildContext context, bool isHovered, bool isPressed);

class _HoverableContainer extends StatefulWidget {
  final HoverBuilder builder;
  final VoidCallback onClick;

  const _HoverableContainer({required this.builder, required this.onClick});

  @override
  State<_HoverableContainer> createState() => _HoverableContainerState();
}

class _HoverableContainerState extends State<_HoverableContainer> {
  bool isHovered = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) {
          setState(() => isPressed = false);
          widget.onClick();
        },
        onTapCancel: () => setState(() => isPressed = false),
        child: widget.builder(context, isHovered, isPressed),
      ),
    );
  }
}

class NodaDesktopDropdown<T> extends StatefulWidget {
  final T value;
  final List<T> items;
  final Widget Function(T item, bool isSelected, bool isHovered) itemBuilder;
  final Widget Function(BuildContext context, bool isOpen) childBuilder;
  final ValueChanged<T> onSelected;
  final double width;
  final double yOffset;

  const NodaDesktopDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.itemBuilder,
    required this.childBuilder,
    required this.onSelected,
    this.width = 240,
    this.yOffset = 48,
  });

  @override
  State<NodaDesktopDropdown<T>> createState() => _NodaDesktopDropdownState<T>();
}

class _NodaDesktopDropdownState<T> extends State<NodaDesktopDropdown<T>> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    _animationController.forward();
  }

  void _closeDropdown() {
    _animationController.reverse().then((_) {
      _removeOverlay();
      if (mounted) {
        setState(() => _isOpen = false);
      }
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _closeDropdown,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, widget.yOffset),
              child: Material(
                color: Colors.transparent,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  alignment: Alignment.topLeft,
                  child: FadeTransition(
                    opacity: _animationController,
                    child: Container(
                      width: widget.width,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light ? Colors.white : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.light 
                              ? Colors.grey.withValues(alpha: 0.1) 
                              : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.items.map((item) {
                          final isSelected = item == widget.value;
                          return _DropdownItem<T>(
                            item: item,
                            isSelected: isSelected,
                            builder: widget.itemBuilder,
                            onTap: () {
                              widget.onSelected(item);
                              _closeDropdown();
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _toggleDropdown,
        behavior: HitTestBehavior.opaque,
        child: widget.childBuilder(context, _isOpen),
      ),
    );
  }
}

class _DropdownItem<T> extends StatefulWidget {
  final T item;
  final bool isSelected;
  final Widget Function(T item, bool isSelected, bool isHovered) builder;
  final VoidCallback onTap;

  const _DropdownItem({
    required this.item,
    required this.isSelected,
    required this.builder,
    required this.onTap,
  });

  @override
  State<_DropdownItem<T>> createState() => _DropdownItemState<T>();
}

class _DropdownItemState<T> extends State<_DropdownItem<T>> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? (Theme.of(context).brightness == Brightness.light 
                    ? const Color(0xFFFDF2F8) // pink-50 approx
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1))
                : (_isHovered 
                    ? (Theme.of(context).brightness == Brightness.light 
                        ? Colors.grey.withValues(alpha: 0.05) // hover:bg-gray-50
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04))
                    : Colors.transparent),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.isSelected 
                        ? (Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white) 
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: widget.builder(widget.item, widget.isSelected, _isHovered),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
