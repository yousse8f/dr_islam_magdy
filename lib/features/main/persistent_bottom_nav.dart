import 'package:flutter/material.dart';

class PersistentBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isArabic;

  const PersistentBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33124634), // rgba(18,70,52,0.2)
            blurRadius: 25,
            offset: Offset(0, -5),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                0,
                isArabic ? 'الرئيسية' : 'Home',
                Icons.home_rounded,
              ),
              _buildNavItem(
                context,
                1,
                isArabic ? 'اعرفنا أكتر' : 'About',
                Icons.info_outline_rounded,
              ),
              _buildNavItem(
                context,
                2,
                isArabic ? 'احجز خدماتك' : 'Book',
                Icons.calendar_month_rounded,
              ),
              _buildNavItem(
                context,
                3,
                isArabic ? 'خدماتنا' : 'Services',
                Icons.medical_services_rounded,
              ),
              _buildNavItem(
                context,
                4,
                isArabic ? 'الأسئلة الشائعة' : 'FAQ',
                Icons.help_outline_rounded,
              ),
              _buildNavItem(
                context,
                5,
                isArabic ? 'تواصل معنا' : 'Contact',
                Icons.phone_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    String label,
    IconData icon,
  ) {
    final isActive = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 40,
              height: 40,
              transform: Matrix4.translationValues(0, isActive ? -8 : 0, 0),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF124634), Color(0xFF207B5D)],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      )
                    : null,
                color: isActive ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isActive
                    ? const [
                        BoxShadow(
                          color: Color(0x59124634), // rgba(18,70,52,0.35)
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                size: 20,
                color: isActive ? Colors.white : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 2),
            Transform.translate(
              offset: Offset(0, isActive ? -4 : 0),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8.5,
                  height: 1.1,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF124634)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
