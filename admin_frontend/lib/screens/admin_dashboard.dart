import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/constants.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> teams = [];
  bool isLoading = true;
  IO.Socket? socket;

  @override
  void initState() {
    super.initState();
    _fetchTeams();
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io(Constants.baseUrl.replaceAll('/api', ''), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket!.onConnect((_) {
      print('Admin websocket connected');
    });

    socket!.on('team_created', (_) {
      // Reload teams when a new team is created
      if (mounted) _fetchTeams();
    });

    socket!.on('team_updated', (data) {
      // Reload teams when a team is updated to see latest attendance/judging
      if (mounted) _fetchTeams();
    });
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  Future<void> _fetchTeams() async {
    setState(() => isLoading = true);
    try {
      final fetchedTeams = await ApiService.getAllTeams();
      setState(() {
        teams = fetchedTeams;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showCreateTeamResultDialog(String teamName, String teamId, String qrCodeBase64) {
    // The backend returns a data URL like "data:image/png;base64,iVBORw..."
    final String base64String = qrCodeBase64.contains(',') 
        ? qrCodeBase64.split(',').last 
        : qrCodeBase64;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 12),
              const Text('Team Created!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Team \'\$teamName\' was successfully registered.', style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                ),
                child: Text('Team ID: $teamId', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
              ),
              const SizedBox(height: 24),
              const Text('Share this QR code with the team to login via their Authenticator App:', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.memory(
                      base64Decode(base64String),
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                    // Logo overlay in the middle of QR code
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => Icon(Icons.hub, color: Theme.of(context).colorScheme.primary, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateTeamDialog() {
    final nameController = TextEditingController();
    final memberNameControllers = [TextEditingController()];
    final memberEmailControllers = [TextEditingController()];
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Create New Team'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Team Name', prefixIcon: Icon(Icons.group_add)),
                    ),
                    const SizedBox(height: 24),
                    const Text('Members:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    ...List.generate(memberNameControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: memberNameControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Name ${index + 1}',
                                  labelStyle: const TextStyle(fontSize: 14),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: memberEmailControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Email ${index + 1}',
                                  labelStyle: const TextStyle(fontSize: 14),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                              ),
                            ),
                            if (memberNameControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                onPressed: () {
                                  setStateDialog(() {
                                    memberNameControllers.removeAt(index);
                                    memberEmailControllers.removeAt(index);
                                  });
                                },
                              )
                            else 
                              const SizedBox(width: 48), // Match width of icon for alignment
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another Member'),
                      onPressed: () {
                        setStateDialog(() {
                          memberNameControllers.add(TextEditingController());
                          memberEmailControllers.add(TextEditingController());
                        });
                      },
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context), 
                child: const Text('Cancel')
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team name is required')));
                    return;
                  }
                  
                  setStateDialog(() => isSubmitting = true);
                  final members = List.generate(memberNameControllers.length, (i) => {
                    'name': memberNameControllers[i].text,
                    'email': memberEmailControllers[i].text,
                  });
                  try {
                    final response = await ApiService.createTeam(nameController.text, members);
                    if (mounted) {
                      Navigator.pop(context); // Close create form
                      _fetchTeams(); // refresh list
                      
                      // Show success with QR
                      if (response['teamId'] != null && response['qrCode'] != null) {
                        _showCreateTeamResultDialog(nameController.text, response['teamId'], response['qrCode']);
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      setStateDialog(() => isSubmitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
                      );
                    }
                  }
                },
                child: isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Team'),
              )
            ],
          );
        }
      ),
    );
  }

  void _showTeamDetails(Map<String, dynamic> team) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final members = List<dynamic>.from(team['members']);
          final judgingStatus = Map<String, dynamic>.from(team['judgingStatus']);

          return AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: SizedBox(
              width: 800,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("${team['teamName']} (${team['teamId']})", 
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.rule, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Judging Results', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: ['round1', 'round2', 'round3'].map((r) {
                                return Column(
                                  children: [
                                    Text(r.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    DropdownButtonHideUnderline(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Theme.of(context).dividerColor),
                                        ),
                                        child: DropdownButton<String>(
                                          value: judgingStatus[r],
                                          items: ['Pending', 'Selected', 'Rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: TextStyle(
                                            color: s == 'Selected' ? Colors.green : (s == 'Rejected' ? Colors.red : Colors.orange),
                                            fontWeight: FontWeight.bold,
                                          )))).toList(),
                                          onChanged: (v) async {
                                            if (v != null) {
                                              try {
                                                await ApiService.updateJudging(team['teamId'], r, v);
                                                setStateDialog(() => judgingStatus[r] = v);
                                                // Optional: show small success toast here
                                              } catch (e) {
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Icon(Icons.fact_check, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text('Members & Attendance', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Theme.of(context).dividerColor),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(Theme.of(context).primaryColor.withOpacity(0.05)),
                                columns: const [
                                  DataColumn(label: Text('Member Info', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('R1', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('R2', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('R3', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: members.map((m) {
                                  final att = m['attendance'];
                                  return DataRow(cells: [
                                    DataCell(Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(m['email'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    )),
                                    DataCell(Checkbox(
                                      value: att['round1'],
                                      activeColor: Colors.green,
                                      onChanged: (v) async {
                                        try {
                                          await ApiService.updateAttendance(team['teamId'], 'round1', [{'memberId': m['_id'], 'signature': ''}]);
                                          setStateDialog(() => m['attendance']['round1'] = v);
                                        } catch(e) {}
                                      },
                                    )),
                                    DataCell(Checkbox(
                                      value: att['round2'],
                                      activeColor: Colors.green,
                                      onChanged: (v) async {
                                        try {
                                          await ApiService.updateAttendance(team['teamId'], 'round2', [{'memberId': m['_id'], 'signature': ''}]);
                                          setStateDialog(() => m['attendance']['round2'] = v);
                                        } catch(e) {}
                                      },
                                    )),
                                    DataCell(Checkbox(
                                      value: att['round3'],
                                      activeColor: Colors.green,
                                      onChanged: (v) async {
                                        try {
                                          await ApiService.updateAttendance(team['teamId'], 'round3', [{'memberId': m['_id'], 'signature': ''}]);
                                          setStateDialog(() => m['attendance']['round3'] = v);
                                        } catch(e) {}
                                      },
                                    )),
                                  ]);
                                }).toList(),
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
          );
        }
      ),
    );
  }

  void _logout() async {
    await Provider.of<AuthProvider>(context, listen: false).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.admin_panel_settings, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Admin Hub',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchTeams();
            },
            tooltip: 'Reload Teams',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTeamDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Team'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (teams.isEmpty 
            ? _buildEmptyState()
            : _buildTeamsList()
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 100, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text('No teams found', style: TextStyle(fontSize: 20, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Click "New Team" to register participants.', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTeamsList() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Registered Teams (${teams.length})', 
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _showTeamDetails(team),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                child: Icon(Icons.group, color: Theme.of(context).colorScheme.primary, size: 28),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      team['teamName'], 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3))
                                      ),
                                      child: Text(
                                        'ID: ${team['teamId']}',
                                        style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('View Details', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                                  SizedBox(height: 4),
                                  Icon(Icons.arrow_forward, color: Colors.grey),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
