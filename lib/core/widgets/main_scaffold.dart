import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  static const _tabs = [
    _Tab('/home',        Icons.home_rounded,           Icons.home_outlined,           'الرئيسية'),
    _Tab('/venues',      Icons.sports_soccer_rounded,  Icons.sports_soccer_outlined,  'الملاعب'),
    _Tab('/matchmaking', Icons.people_alt_rounded,     Icons.people_alt_outlined,     'ماتش'),
    _Tab('/teams',       Icons.shield_rounded,         Icons.shield_outlined,         'الفرق'),
    _Tab('/tournaments', Icons.emoji_events_rounded,   Icons.emoji_events_outlined,   'بطولات'),
    _Tab('/profile',     Icons.person_rounded,         Icons.person_outline_rounded,  'حسابي'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(
            top: BorderSide(color: cs.outline.withValues(alpha: 0.4), width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final selected = i == current;
                return Expanded(
                  child: _NavItem(
                    tab: tab,
                    selected: selected,
                    onTap: () { if (!selected) context.go(tab.path); },
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.tab, required this.selected, required this.onTap});

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.selected ? widget.tab.activeIcon : widget.tab.icon,
                key: ValueKey(widget.selected),
                color: widget.selected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: widget.selected ? AppColors.primary : AppColors.textSecondary,
                fontFamily: 'Cairo',
              ),
              child: Text(widget.tab.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tab {
  final String path, label;
  final IconData activeIcon, icon;
  const _Tab(this.path, this.activeIcon, this.icon, this.label);
}
