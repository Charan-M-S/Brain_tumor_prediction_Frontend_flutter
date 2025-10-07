import 'package:flutter/material.dart';

// --- Color Palette (Consistent with other screens) ---
const Color primaryColor = Color(0xFF1D5D9B);
const Color accentColor = Color(0xFFF4D160);
const Color backgroundColor = Color(0xFFF7F9FC);

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _navigateToLogin(BuildContext context) {
    Navigator.pushNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: LayoutBuilder(
        // Use LayoutBuilder for dynamic adaptation
        builder: (context, constraints) {
          final double screenWidth = constraints.maxWidth;
          // Define breakpoints for layout switching
          final bool isTabletOrDesktop = screenWidth > 800;
          final bool isDesktop = screenWidth > 1200;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isTabletOrDesktop
                    ? _buildTwoColumnLayout(context, isDesktop)
                    : _buildSingleColumnLayout(context),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Layout Builders ---

  // Layout for wide screens (Desktop/Large Tablet)
  Widget _buildTwoColumnLayout(BuildContext context, bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Section: Hero Text
        Expanded(
          flex: isDesktop
              ? 3
              : 2, // Give more space to text on ultra-wide screens
          child: Padding(
            padding: const EdgeInsets.only(right: 60.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Digital Diagnostics',
                  style: TextStyle(
                    fontSize: 24, // Slightly larger on desktop
                    fontWeight: FontWeight.w600,
                    color: primaryColor.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'MRI Analysis Platform',
                  style: TextStyle(
                    fontSize: isDesktop ? 60 : 48, // Adaptive font size
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Access advanced AI-powered tools for quick and accurate tumor prediction and validation.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),

        // Right Section: Role Selection Buttons
        Expanded(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoleButton(
                context,
                title: 'Doctor Login',
                subtitle: 'Medical professionals with validation access.',
                icon: Icons.local_hospital_outlined,
                color: primaryColor,
                onTap: () => _navigateToLogin(context),
                isWideScreen: true,
              ),
              const SizedBox(height: 30),
              _buildRoleButton(
                context,
                title: 'Patient Login',
                subtitle: 'View your prediction history and reports.',
                icon: Icons.person_outline,
                color: accentColor,
                onTap: () => _navigateToLogin(context),
                isWideScreen: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Layout for narrow screens (Mobile/Small Tablet)
  Widget _buildSingleColumnLayout(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Branding/Logo
        Icon(Icons.medical_services_outlined, size: 70, color: primaryColor),
        const SizedBox(height: 20),
        Text(
          'MRI Analysis Platform',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: primaryColor,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Select your role to continue.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 50),

        // Buttons
        _buildRoleButton(
          context,
          title: 'Doctor Login',
          subtitle: 'Medical professionals with validation access.',
          icon: Icons.local_hospital_outlined,
          color: primaryColor,
          onTap: () => _navigateToLogin(context),
          isWideScreen: false,
        ),
        const SizedBox(height: 20),
        _buildRoleButton(
          context,
          title: 'Patient Login',
          subtitle: 'View your prediction history and reports.',
          icon: Icons.person_outline,
          color: accentColor,
          onTap: () => _navigateToLogin(context),
          isWideScreen: false,
        ),
      ],
    );
  }

  // --- Custom Button Widget ---

  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isWideScreen, // New parameter for dynamic sizing
  }) {
    // Dynamic sizing adjustment for padding/font size
    final double verticalPadding = isWideScreen ? 30 : 20;
    final double iconSize = isWideScreen ? 45 : 35;
    final double titleSize = isWideScreen ? 24 : 20;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.1),
          hoverColor: color.withOpacity(0.05),

          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: verticalPadding,
              horizontal: 20,
            ),
            child: Row(
              children: [
                Icon(icon, size: iconSize, color: color),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
