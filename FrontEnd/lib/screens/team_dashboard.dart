import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class TeamDashboard extends StatefulWidget {
  const TeamDashboard({super.key});

  @override
  State<TeamDashboard> createState() => _TeamDashboardState();
}

class _TeamDashboardState extends State<TeamDashboard> {
  Map<String, dynamic>? teamData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final data = await ApiService.getTeamDashboard();
      setState(() {
        teamData = data;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (teamData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Team Dashboard')),
        body: const Center(child: Text('Failed to load data')),
      );
    }

    final members = List<Map<String, dynamic>>.from(teamData!['members']);
    final judgingStatus = teamData!['judgingStatus'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hub, size: 24),
            const SizedBox(width: 12),
            Text("${teamData!['teamName']}"),
          ],
        ),
        actions: [
          Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "ID: ${teamData!['teamId']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.gavel, color: Theme.of(context).colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Judging Status',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildStatusCard('Round 1', judgingStatus['round1']),
                    const SizedBox(width: 24),
                    _buildStatusCard('Round 2', judgingStatus['round2']),
                    const SizedBox(width: 24),
                    _buildStatusCard('Round 3', judgingStatus['round3']),
                  ],
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Team Members',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Theme.of(context).dividerColor),
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final att = member['attendance'];
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              child: Text(
                                member['name'][0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    member['email'],
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                _AttendanceChip(round: 'Round 1', present: att['round1']),
                                _AttendanceChip(round: 'Round 2', present: att['round2']),
                                _AttendanceChip(round: 'Round 3', present: att['round3']),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String round, String status) {
    Color color;
    IconData iconData;
    switch (status.toLowerCase()) {
      case 'selected':
        color = Colors.green.shade500;
        iconData = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red.shade500;
        iconData = Icons.cancel;
        break;
      default:
        color = Colors.orange.shade500;
        iconData = Icons.pending;
    }
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Column(
            children: [
              Text(
                round,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Icon(iconData, color: color, size: 40),
              const SizedBox(height: 12),
              Text(
                status.toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttendanceChip extends StatelessWidget {
  final String round;
  final bool present;
  const _AttendanceChip({required this.round, required this.present});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: present 
            ? (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50) 
            : (isDark ? Colors.grey.withOpacity(0.1) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: present ? Colors.green.shade500 : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            present ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: present ? Colors.green.shade500 : Colors.grey.shade500,
          ),
          const SizedBox(width: 6),
          Text(
            round,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: present ? Colors.green.shade500 : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
