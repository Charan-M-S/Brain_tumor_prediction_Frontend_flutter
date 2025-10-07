import 'package:flutter/material.dart';
import 'upload_mri_screen.dart';
import 'prediction_history.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const Color primaryColor = Color(0xFF1D5D9B); // Darker Blue
const Color accentColor = Color(0xFFF4D160); // Golden Accent
const Color backgroundColor = Color(0xFFF7F9FC); // Light background

class DoctorDashboard extends StatefulWidget {
  @override
  _DoctorDashboardState createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard>
    with SingleTickerProviderStateMixin {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  late TabController _tabController;
  int _selectedIndex = 0;
  String? user = "";
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadUser();
  }
  Future<void> _loadUser() async {
    final fetchedUser = await storage.read(key: 'user');
    setState(() {
      user = fetchedUser ?? 'User';
    });
  }

  void _handleTabSelection() {
    if (_tabController.index != _selectedIndex) {
      setState(() {
        _selectedIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  // Logout function
  void _logout(BuildContext context) async {
    await storage.delete(key: "jwt_token");
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth >= 1000;
        bool isTablet =
            constraints.maxWidth >= 600 && constraints.maxWidth < 1000;
        // isMobile = constraints.maxWidth < 600;

        if (isDesktop) {
          return _buildDesktopLayout(context);
        } else if (isTablet) {
          return _buildTabletLayout(context);
        } else {
          return _buildMobileLayout(context);
        }
      },
    );
  }

  // ## Desktop Layout (Side Navigation)

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 250,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.black12, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Header/Logo Area
                Container(
                  padding: const EdgeInsets.only(
                    top: 40,
                    bottom: 20,
                    left: 24,
                    right: 24,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.medical_services_outlined,
                        size: 30,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'MedAI',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                // Navigation Items
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Colors.black12),
                        const Padding(
                          padding: EdgeInsets.only(
                            left: 8.0,
                            top: 10,
                            bottom: 8,
                          ),
                          child: Text(
                            'TOOLS',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildNavItem(
                          icon: Icons.cloud_upload_outlined,
                          title: 'Upload MRI Scan',
                          isSelected: _selectedIndex == 0,
                          onTap: () => _selectTab(0),
                        ),
                        _buildNavItem(
                          icon: Icons.data_usage_outlined,
                          title: 'Prediction History',
                          isSelected: _selectedIndex == 1,
                          onTap: () => _selectTab(1),
                        ),

                        const Spacer(),

                        // Logout Button
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: ElevatedButton.icon(
                            onPressed: () => _logout(context),
                            icon: const Icon(Icons.logout, size: 18),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[50],
                              foregroundColor: Colors.red[700],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: Colors.red[200]!),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Bar (Header)
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.black12, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedIndex == 0
                            ? 'Upload MRI Scan'
                            : 'Prediction History',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 20),
                      _buildUserProfile(showName: true), // Show user name/title
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ## Tablet Layout (App Bar Tabs)\

  Widget _buildTabletLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Doctor Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          _buildUserProfile(showName: false),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: _selectTab,
          indicatorColor: accentColor,
          indicatorWeight: 4,
          labelColor: accentColor,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.cloud_upload_outlined), text: "Upload MRI"),
            Tab(icon: Icon(Icons.data_usage_outlined), text: "History"),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TabBarView(
          controller: _tabController,
          children: [UploadMRIScreen(), PredictionsHistoryScreen()],
        ),
      ),
    );
  }

  // ## Mobile Layout (Bottom Navigation)\

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          _selectedIndex == 0 ? 'Upload MRI' : 'History',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _logout(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    const Text('Logout'),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildUserProfile(showName: false),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(
          top: 10.0,
        ), // Less padding for mobile content
        child: _buildContent(),
      ),

      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                // Logic to trigger file selection or navigate to detailed upload
                // For now, it just ensures the Upload screen is shown
                _selectTab(0);

              },
              icon: const Icon(Icons.add),
              label: const Text('New Scan'),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 8, // Added elevation for lift effect
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload_outlined),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.data_usage_outlined),
            label: 'History',
          ),
        ],
      ),
    );
  }

  // ## Helper Widgets

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: primaryColor.withOpacity(
            0.05,
          ), 
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? primaryColor : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? primaryColor : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfile({required bool showName}) {
    String userName = user ?? 'User';
    const String userTitle = "Doctor";

    return Row(
      children: [
        if (showName)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                userTitle,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        if (showName) const SizedBox(width: 10),
        CircleAvatar(
          radius: 20,
          backgroundColor: primaryColor.withOpacity(0.1),
          child: Icon(Icons.person, size: 20, color: primaryColor),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      
      physics: const NeverScrollableScrollPhysics(),
      children: [UploadMRIScreen(), PredictionsHistoryScreen()],
    );
  }

  void _selectTab(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _tabController.animateTo(index);
    }
  }
}
