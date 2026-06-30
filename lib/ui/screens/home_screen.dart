import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'profile_screen.dart';
import 'home_content.dart';
import 'goals_screen.dart';
import 'statistics_screen.dart';
import '../widgets/action_selector_sheet.dart';
import '../widgets/register_saving_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const GoalsScreen(),
    const StatisticsScreen(),
    const ProfileScreen(),
  ];

  void _showActionSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ActionSelectorSheet(
        onOptionSelected: (type) {
          Navigator.pop(context);
          _showRegisterForm(context, type);
        },
      ),
    );
  }

  void _showRegisterForm(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RegisterSavingSheet(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // Usamos extendBody para que el contenido pase por detrás si es necesario,
      // pero con HomeContent ajustado con padding inferior.
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(theme),
    );
  }

  Widget _buildBottomNavBar(ThemeData theme) {
    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.4 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, "Inicio", 0),
            _buildNavItem(Icons.shield_outlined, "Metas", 1),
            _buildMiddleButton(theme),
            _buildNavItem(Icons.bar_chart_rounded, "Estadísticas", 2),
            _buildNavItem(Icons.person_rounded, "Perfil", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? Colors.blueAccent : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blueAccent : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddleButton(ThemeData theme) {
    return GestureDetector(
      onTap: () => _showActionSelector(context),
      child: CustomPaint(
        painter: GradientPainter(),
        child: Container(
          width: 52,
          height: 52,
          margin: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surface,
          ),
          child: Icon(Icons.add,
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              size: 30),
        ),
      ),
    );
  }
}

class GradientPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.indigoAccent, Colors.cyanAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
