// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Component/ExitAppConfirmScope.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/View/Common/MenuView.dart';
import 'package:hcmu_sos/View/Staff/StaffHomeView.dart';
import 'package:hcmu_sos/View/Staff/StaffTaskView.dart';

class StaffDashboardView extends StatefulWidget {
  const StaffDashboardView({super.key});

  @override
  State<StaffDashboardView> createState() => _StaffDashboardViewState();
}

class _StaffDashboardViewState extends State<StaffDashboardView> {
  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _activeColor = Color(0xFFF82D37);

  int _currentIndex = 0;

  static const List<_DashboardNavItem> _items = [
    _DashboardNavItem(
      assetPath: 'assets/icon/icon_db_home.svg',
      labelKey: 'nav.home',
    ),
    _DashboardNavItem(
      assetPath: 'assets/icon/icon_db_task.svg',
      labelKey: 'nav.task',
    ),
    _DashboardNavItem(
      assetPath: 'assets/icon/icon_db_menu.svg',
      labelKey: 'nav.account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      StaffHomeView(onSeeMoreTasks: () => setState(() => _currentIndex = 1)),
      const StaffTaskView(),
      const MenuView(),
    ];

    return ExitAppConfirmScope(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: _StaffBottomNav(
            items: _items,
            currentIndex: _currentIndex,
            activeColor: _activeColor,
            inactiveColor: _primaryColor,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ),
      ),
    );
  }
}

class _StaffBottomNav extends StatelessWidget {
  const _StaffBottomNav({
    required this.items,
    required this.currentIndex,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final List<_DashboardNavItem> items;
  final int currentIndex;
  final Color activeColor;
  final Color inactiveColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 70 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final selected = index == currentIndex;
          final itemColor = selected ? activeColor : inactiveColor;

          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavSvgIcon(
                    assetPath: item.assetPath,
                    color: itemColor,
                    size: 23,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    item.labelKey.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: itemColor,
                      fontSize: AppFontSizes.base,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavSvgIcon extends StatelessWidget {
  const _NavSvgIcon({
    required this.assetPath,
    required this.color,
    required this.size,
  });

  final String assetPath;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      colorMapper: _NavIconColorMapper(color),
    );
  }
}

class _NavIconColorMapper extends ColorMapper {
  const _NavIconColorMapper(this.color);

  final Color color;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color svgColor,
  ) {
    if (svgColor == Colors.white) {
      return Colors.white;
    }

    return color.withValues(alpha: svgColor.a);
  }
}

class _DashboardNavItem {
  const _DashboardNavItem({required this.assetPath, required this.labelKey});

  final String assetPath;
  final String labelKey;
}
