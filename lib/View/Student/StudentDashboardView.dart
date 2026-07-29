// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:hcmu_sos/Component/ExitAppConfirmScope.dart';
import 'package:hcmu_sos/Theme/AppTypography.dart';
import 'package:hcmu_sos/View/Common/MenuView.dart';
import 'package:hcmu_sos/View/Student/CreateSOSView.dart';
import 'package:hcmu_sos/View/Student/CreateTicketView.dart';
import 'package:hcmu_sos/View/Student/HistoryView.dart';
import 'package:hcmu_sos/View/Student/StudentHomeView.dart';
import 'package:hcmu_sos/ViewModel/Student/CreateSOSViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/CreateTicketViewModel.dart';
import 'package:hcmu_sos/ViewModel/Student/HistoryViewModel.dart';

class StudentDashboardView extends StatefulWidget {
  const StudentDashboardView({super.key});

  @override
  State<StudentDashboardView> createState() => _StudentDashboardViewState();
}

class _StudentDashboardViewState extends State<StudentDashboardView> {
  static const Color _primaryColor = Color(0xFF29306F);
  static const Color _activeColor = Color(0xFFF82D37);

  int _currentIndex = 0;

  static const List<_DashboardNavItem> _items = [
    _DashboardNavItem(
      assetPath: 'assets/icon/icon_db_home.svg',
      labelKey: 'nav.home',
    ),
    _DashboardNavItem(
      assetPath: 'assets/icon/icon_db_add.svg',
      labelKey: 'nav.request',
    ),
    _DashboardNavItem(assetPath: '', labelKey: 'SOS', isCenterAction: true),
    _DashboardNavItem(
      assetPath: 'assets/icon/icon_db_history.svg',
      labelKey: 'nav.history',
    ),
    _DashboardNavItem(
      assetPath: 'assets/icon/icon_db_menu.svg',
      labelKey: 'nav.account',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentHomeView(
        onSeeMoreRequests: () => _selectTab(3),
        onSosTap: () => _selectTab(2),
        onCreateRequestTap: () => _selectTab(1),
      ),
      CreateTicketView(onCreated: _openHistoryAndReload),
      const CreateSOSView(),
      const HistoryView(),
      const MenuView(),
    ];

    return ExitAppConfirmScope(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: _StudentBottomNav(
            items: _items,
            currentIndex: _currentIndex,
            activeColor: _activeColor,
            inactiveColor: _primaryColor,
            onTap: _selectTab,
          ),
        ),
      ),
    );
  }

  void _selectTab(int nextIndex) {
    if (nextIndex == 1 && _currentIndex != 1) {
      if (Get.isRegistered<CreateTicketViewModel>()) {
        Get.find<CreateTicketViewModel>().resetForm();
      }
    }

    _resetSosTabIfLeaving(nextIndex);
    setState(() => _currentIndex = nextIndex);
  }

  void _openHistoryAndReload() {
    _resetSosTabIfLeaving(3);
    setState(() => _currentIndex = 3);
    if (Get.isRegistered<HistoryViewModel>()) {
      Get.find<HistoryViewModel>().loadRequests();
    }
  }

  void _resetSosTabIfLeaving(int nextIndex) {
    if (_currentIndex != 2 || nextIndex == 2) return;
    if (!Get.isRegistered<CreateSOSViewModel>()) return;

    final createSOSViewModel = Get.find<CreateSOSViewModel>();
    if (createSOSViewModel.state.value == CreateSOSState.sent) {
      createSOSViewModel.resetToReady();
    }
  }
}

class _StudentBottomNav extends StatelessWidget {
  const _StudentBottomNav({
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
      height: 76 + bottomPadding,
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
                  if (item.isCenterAction) ...[
                    SizedBox(
                      height: 28,
                      child: OverflowBox(
                        minWidth: 58,
                        maxWidth: 58,
                        minHeight: 58,
                        maxHeight: 58,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: itemColor, width: 1.8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0x26000000),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: itemColor.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.sos_rounded,
                              color: itemColor,
                              size: 29,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ] else ...[
                    _NavSvgIcon(
                      assetPath: item.assetPath,
                      color: itemColor,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                  ],
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
  const _DashboardNavItem({
    required this.assetPath,
    required this.labelKey,
    this.isCenterAction = false,
  });

  final String assetPath;
  final String labelKey;
  final bool isCenterAction;
}
