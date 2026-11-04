import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isOnline = true;
  bool _isSyncing = false;
  int _pendingCount = 3;
  String _lastSynced = '3 Nov 2026, 12:45 PM';
  double _textScale = 1.0;

  final List<_OutboxItem> _outboxItems = [
    _OutboxItem(
      label: 'Expense: Swiggy ₹349.00',
      status: SyncItemStatus.pending,
      time: '2:30 PM',
    ),
    _OutboxItem(
      label: 'Expense: Amazon ₹1,899.00',
      status: SyncItemStatus.pending,
      time: '1:15 PM',
    ),
    _OutboxItem(
      label: 'Expense: Netflix ₹649.00',
      status: SyncItemStatus.failed,
      time: '11:00 AM',
    ),
  ];

  Future<void> _handleSyncNow() async {
    if (!_isOnline || _isSyncing) return;
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _pendingCount = 0;
      _lastSynced = '3 Nov 2026, 1:02 PM';
      for (final item in _outboxItems) {
        item.status = SyncItemStatus.synced;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All items synced successfully'),
          backgroundColor: AppColors.incomeGreen,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of PocketPath?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pushNamedAndRemoveUntil(
                  '/auth', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 20),
          _buildSyncCard(),
          const SizedBox(height: 20),
          _buildPreferencesCard(),
          const SizedBox(height: 20),
          _buildLogoutButton(),
          const SizedBox(height: 32),
          _buildVersionFooter(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text(
                'AS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Arjun Sharma',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'user@pocketpath.in',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: AppColors.textMedium),
            tooltip: 'Edit Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildSyncCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.sync_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Sync Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                _buildConnectionBadge(),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Status details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  icon: Icons.pending_actions_rounded,
                  label: 'Pending items',
                  value: _pendingCount == 0
                      ? 'All synced'
                      : '$_pendingCount item${_pendingCount > 1 ? 's' : ''} waiting',
                  valueColor: _pendingCount > 0
                      ? AppColors.warningOchre
                      : AppColors.incomeGreen,
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.access_time_rounded,
                  label: 'Last synced',
                  value: _lastSynced,
                ),
                if (_outboxItems.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Outbox',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._outboxItems.map((item) => _OutboxRow(item: item)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (!_isOnline || _isSyncing ||
                            _pendingCount == 0)
                        ? null
                        : _handleSyncNow,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(
                      _isSyncing
                          ? 'Syncing…'
                          : _pendingCount == 0
                              ? 'Everything Synced'
                              : 'Sync Now',
                    ),
                  ),
                ),
                if (!_isOnline) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Connect to the internet to sync your data.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMedium,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge() {
    return GestureDetector(
      onTap: () => setState(() => _isOnline = !_isOnline),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _isOnline
              ? AppColors.incomeGreenLight
              : AppColors.neutralGreyLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isOnline
                  ? Icons.wifi_rounded
                  : Icons.wifi_off_rounded,
              size: 12,
              color: _isOnline
                  ? AppColors.incomeGreen
                  : AppColors.neutralGrey,
            ),
            const SizedBox(width: 4),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isOnline
                    ? AppColors.incomeGreen
                    : AppColors.neutralGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMedium),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMedium,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.tune_rounded,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Preferences',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Text Size',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'Accessibility / Readability',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMedium),
                        ),
                      ],
                    ),
                    Text(
                      '${(_textScale * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _textScale,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.neutralGreyLight,
                  onChanged: (v) => setState(() => _textScale = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Small',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMedium)),
                    const Text('Large',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMedium)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(Icons.logout_rounded, size: 18),
        label: const Text('Log Out'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.expenseRed,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVersionFooter() {
    return const Center(
      child: Text(
        'PocketPath v1.0.0 · Built with Flutter',
        style: TextStyle(fontSize: 12, color: AppColors.textLight),
      ),
    );
  }
}

class _OutboxRow extends StatelessWidget {
  final _OutboxItem item;
  const _OutboxRow({required this.item});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (item.status) {
      case SyncItemStatus.pending:
        statusColor = AppColors.warningOchre;
        statusIcon = Icons.schedule_rounded;
        statusLabel = 'Pending';
        break;
      case SyncItemStatus.failed:
        statusColor = AppColors.expenseRed;
        statusIcon = Icons.error_outline_rounded;
        statusLabel = 'Failed';
        break;
      case SyncItemStatus.synced:
        statusColor = AppColors.incomeGreen;
        statusIcon = Icons.check_circle_outline_rounded;
        statusLabel = 'Synced';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textDark),
            ),
          ),
          Text(
            item.time,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textMedium),
          ),
        ],
      ),
    );
  }
}

class _OutboxItem {
  final String label;
  SyncItemStatus status;
  final String time;

  _OutboxItem({
    required this.label,
    required this.status,
    required this.time,
  });
}

enum SyncItemStatus { pending, failed, synced }
