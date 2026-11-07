import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/transaction.dart';
import '../../../core/services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storageService = StorageService();

  bool _isOnline = true;
  bool _isSyncing = false;
  int _txCount = 0;
  int _pendingCount = 0;
  String _lastSynced = 'Just now';
  double _textScale = 1.0;
  List<Transaction> _pendingTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadStorageData();
  }

  Future<void> _loadStorageData() async {
    final allTxs = await _storageService.getTransactions();
    final pending = allTxs.where((t) => t.status != TransactionStatus.synced).toList();

    if (!mounted) return;
    setState(() {
      _txCount = allTxs.length;
      _pendingTransactions = pending;
      _pendingCount = pending.length;
      _lastSynced = DateFormat('d MMM yyyy, h:mm a').format(DateTime.now());
    });
  }

  Future<void> _handleSyncNow() async {
    if (!_isOnline || _isSyncing) return;
    setState(() => _isSyncing = true);

    // Sync all pending transactions
    for (final tx in _pendingTransactions) {
      await _storageService.updateTransaction(
        tx.copyWith(status: TransactionStatus.synced),
      );
    }

    await Future.delayed(const Duration(milliseconds: 600));
    await _loadStorageData();

    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _lastSynced = DateFormat('d MMM yyyy, h:mm a').format(DateTime.now());
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All local transactions synced successfully'),
        backgroundColor: AppColors.incomeGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleDownloadStatement() async {
    try {
      final file = await _storageService.downloadStatement();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statement saved to phone storage:\n${file.path}'),
          backgroundColor: AppColors.incomeGreen,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'SHARE',
            textColor: Colors.white,
            onPressed: () => _storageService.downloadAndShareStatement(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download statement: $e'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
    }
  }

  Future<void> _handleShareStatement() async {
    try {
      await _storageService.downloadAndShareStatement();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share statement: $e'),
          backgroundColor: AppColors.expenseRed,
        ),
      );
    }
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Local Data'),
        content: const Text(
          'This will permanently delete all transactions, custom budgets, and goals stored on this device. Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _storageService.clearAllData();
              await _loadStorageData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All local storage cleared.'),
                    backgroundColor: AppColors.expenseRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expenseRed,
            ),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
  }

  void _handleLoadDemoData() async {
    await _storageService.seedDemoData();
    await _loadStorageData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Demo sample data loaded into phone storage.'),
        backgroundColor: AppColors.primary,
      ),
    );
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
          _buildLocalStorageCard(),
          const SizedBox(height: 20),
          _buildSyncCard(),
          const SizedBox(height: 20),
          _buildPreferencesCard(),
          const SizedBox(height: 20),
          _buildDataManagementCard(),
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
                'PP',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My PocketPath',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Personal Finance Account',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalStorageCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.phone_android_rounded,
                    size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Phone Storage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Spacer(),
                Text(
                  'Active',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.incomeGreen,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.receipt_long_rounded,
                  label: 'Stored Transactions',
                  value: '$_txCount items',
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  icon: Icons.security_rounded,
                  label: 'Storage Location',
                  value: 'Device Local Storage',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _handleShareStatement,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text('Share CSV'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _handleDownloadStatement,
                        icon: const Icon(Icons.file_download_rounded, size: 16),
                        label: const Text('Download CSV'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  icon: Icons.pending_actions_rounded,
                  label: 'Pending entries',
                  value: _pendingCount == 0
                      ? 'All stored & synced'
                      : '$_pendingCount item${_pendingCount > 1 ? 's' : ''}',
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: (!_isOnline || _isSyncing || _pendingCount == 0)
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 12,
              color: _isOnline ? AppColors.incomeGreen : AppColors.neutralGrey,
            ),
            const SizedBox(width: 4),
            Text(
              _isOnline ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isOnline ? AppColors.incomeGreen : AppColors.neutralGrey,
              ),
            ),
          ],
        ),
      ),
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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
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
                              fontSize: 12, color: AppColors.textMedium),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.storage_rounded, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Data Management',
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
          ListTile(
            leading: const Icon(Icons.download_rounded, color: AppColors.primary),
            title: const Text('Export All Statements'),
            subtitle: const Text('Download complete account history CSV'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _handleDownloadStatement,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.dataset_rounded, color: AppColors.primaryDark),
            title: const Text('Load Demo Sample Data'),
            subtitle: const Text('Populate demo transactions to test features'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _handleLoadDemoData,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ListTile(
            leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.expenseRed),
            title: const Text('Clear All Local Data', style: TextStyle(color: AppColors.expenseRed)),
            subtitle: const Text('Reset local storage to a blank slate'),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.expenseRed),
            onTap: _confirmClearData,
          ),
        ],
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
        'PocketPath v1.0.0 · Phone Local Storage Enabled',
        style: TextStyle(fontSize: 12, color: AppColors.textLight),
      ),
    );
  }
}
