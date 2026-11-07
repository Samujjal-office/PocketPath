import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _keyTransactions = 'pocketpath_transactions_v1';
  static const String _keyBudgets = 'pocketpath_budgets_v1';
  static const String _keyGoals = 'pocketpath_goals_v1';
  static const String _keyUserInit = 'pocketpath_initialized_v1';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Initialize local phone storage.
  /// No fake data is forced. It starts cleanly.
  Future<void> init() async {
    final p = await prefs;
    final isInitialized = p.getBool(_keyUserInit) ?? false;
    if (!isInitialized) {
      await p.setBool(_keyUserInit, true);
      // Initialize with empty transaction list and default category budgets
      if (!p.containsKey(_keyTransactions)) {
        await p.setStringList(_keyTransactions, []);
      }
      if (!p.containsKey(_keyBudgets)) {
        // Pre-create standard category budgets for the current month with initial 0 spent
        final now = DateTime.now();
        final defaultBudgets = [
          Budget(
            id: 'b_food',
            category: TransactionCategory.food,
            limitPaise: 1500000, // ₹15,000
            spentPaise: 0,
            month: now.month,
            year: now.year,
          ),
          Budget(
            id: 'b_transport',
            category: TransactionCategory.transport,
            limitPaise: 500000, // ₹5,000
            spentPaise: 0,
            month: now.month,
            year: now.year,
          ),
          Budget(
            id: 'b_shopping',
            category: TransactionCategory.shopping,
            limitPaise: 800000, // ₹8,000
            spentPaise: 0,
            month: now.month,
            year: now.year,
          ),
          Budget(
            id: 'b_utilities',
            category: TransactionCategory.utilities,
            limitPaise: 400000, // ₹4,000
            spentPaise: 0,
            month: now.month,
            year: now.year,
          ),
          Budget(
            id: 'b_entertainment',
            category: TransactionCategory.entertainment,
            limitPaise: 300000, // ₹3,000
            spentPaise: 0,
            month: now.month,
            year: now.year,
          ),
        ];
        await saveBudgets(defaultBudgets);
      }
      if (!p.containsKey(_keyGoals)) {
        await p.setStringList(_keyGoals, []);
      }
    }
  }

  // ==========================================
  // TRANSACTIONS
  // ==========================================

  Future<List<Transaction>> getTransactions() async {
    final p = await prefs;
    final rawList = p.getStringList(_keyTransactions) ?? [];
    final list = <Transaction>[];
    for (final item in rawList) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        list.add(Transaction.fromJson(decoded));
      } catch (e) {
        debugPrint('Error decoding transaction: $e');
      }
    }
    // Sort descending by date
    list.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    return list;
  }

  Future<void> addTransaction(Transaction tx) async {
    final p = await prefs;
    final current = await getTransactions();
    // Add to list
    current.insert(0, tx);
    final stringList = current.map((t) => jsonEncode(t.toJson())).toList();
    await p.setStringList(_keyTransactions, stringList);

    // Also update budget spent for this category if expense
    if (tx.direction == TransactionDirection.expense) {
      await _updateBudgetSpendForTransaction(tx);
    }
  }

  Future<void> updateTransaction(Transaction tx) async {
    final p = await prefs;
    final current = await getTransactions();
    final index = current.indexWhere((t) => t.id == tx.id);
    if (index != -1) {
      current[index] = tx;
      final stringList = current.map((t) => jsonEncode(t.toJson())).toList();
      await p.setStringList(_keyTransactions, stringList);
      await recalculateBudgets();
    }
  }

  Future<void> deleteTransaction(String id) async {
    final p = await prefs;
    final current = await getTransactions();
    current.removeWhere((t) => t.id == id);
    final stringList = current.map((t) => jsonEncode(t.toJson())).toList();
    await p.setStringList(_keyTransactions, stringList);
    await recalculateBudgets();
  }

  // ==========================================
  // BUDGETS
  // ==========================================

  Future<List<Budget>> getBudgets({int? month, int? year}) async {
    final p = await prefs;
    final rawList = p.getStringList(_keyBudgets) ?? [];
    final list = <Budget>[];
    final targetMonth = month ?? DateTime.now().month;
    final targetYear = year ?? DateTime.now().year;

    for (final item in rawList) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final b = Budget.fromJson(decoded);
        if (b.month == targetMonth && b.year == targetYear) {
          list.add(b);
        }
      } catch (e) {
        debugPrint('Error decoding budget: $e');
      }
    }

    // If no budgets exist for this month/year yet, copy existing categories with 0 spent
    if (list.isEmpty) {
      final allRaw = p.getStringList(_keyBudgets) ?? [];
      final existingCategories = <TransactionCategory>{};
      for (final item in allRaw) {
        try {
          final decoded = jsonDecode(item) as Map<String, dynamic>;
          final b = Budget.fromJson(decoded);
          existingCategories.add(b.category);
        } catch (_) {}
      }
      if (existingCategories.isNotEmpty) {
        for (final cat in existingCategories) {
          list.add(Budget(
            id: 'b_${cat.name}_${targetMonth}_$targetYear',
            category: cat,
            limitPaise: 500000,
            spentPaise: 0,
            month: targetMonth,
            year: targetYear,
          ));
        }
        await saveBudgets(list);
      }
    }

    return list;
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final p = await prefs;
    final rawList = p.getStringList(_keyBudgets) ?? [];
    final allBudgets = <Budget>[];

    for (final item in rawList) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        allBudgets.add(Budget.fromJson(decoded));
      } catch (_) {}
    }

    for (final newB in budgets) {
      final idx = allBudgets.indexWhere((b) =>
          b.category == newB.category &&
          b.month == newB.month &&
          b.year == newB.year);
      if (idx != -1) {
        allBudgets[idx] = newB;
      } else {
        allBudgets.add(newB);
      }
    }

    final stringList = allBudgets.map((b) => jsonEncode(b.toJson())).toList();
    await p.setStringList(_keyBudgets, stringList);
  }

  Future<void> updateBudgetLimit(String id, int limitPaise) async {
    final p = await prefs;
    final rawList = p.getStringList(_keyBudgets) ?? [];
    final allBudgets = <Budget>[];

    for (final item in rawList) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        var b = Budget.fromJson(decoded);
        if (b.id == id) {
          b = b.copyWith(limitPaise: limitPaise);
        }
        allBudgets.add(b);
      } catch (_) {}
    }

    final stringList = allBudgets.map((b) => jsonEncode(b.toJson())).toList();
    await p.setStringList(_keyBudgets, stringList);
  }

  Future<void> _updateBudgetSpendForTransaction(Transaction tx) async {
    final budgets = await getBudgets(
      month: tx.dateTime.month,
      year: tx.dateTime.year,
    );
    final idx = budgets.indexWhere((b) => b.category == tx.category);
    if (idx != -1) {
      final updated = budgets[idx].copyWith(
        spentPaise: budgets[idx].spentPaise + tx.amountPaise,
      );
      budgets[idx] = updated;
      await saveBudgets(budgets);
    }
  }

  Future<void> recalculateBudgets() async {
    final txs = await getTransactions();
    final p = await prefs;
    final rawList = p.getStringList(_keyBudgets) ?? [];
    final allBudgets = <Budget>[];

    for (final item in rawList) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final b = Budget.fromJson(decoded);
        // Calculate total spend for this category and month/year
        final spent = txs
            .where((t) =>
                t.direction == TransactionDirection.expense &&
                t.category == b.category &&
                t.dateTime.month == b.month &&
                t.dateTime.year == b.year)
            .fold<int>(0, (sum, t) => sum + t.amountPaise);
        allBudgets.add(b.copyWith(spentPaise: spent));
      } catch (_) {}
    }

    final stringList = allBudgets.map((b) => jsonEncode(b.toJson())).toList();
    await p.setStringList(_keyBudgets, stringList);
  }

  // ==========================================
  // SAVINGS GOALS
  // ==========================================

  Future<List<SavingsGoal>> getSavingsGoals() async {
    final p = await prefs;
    final rawList = p.getStringList(_keyGoals) ?? [];
    final list = <SavingsGoal>[];
    for (final item in rawList) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        list.add(SavingsGoal.fromJson(decoded));
      } catch (e) {
        debugPrint('Error decoding goal: $e');
      }
    }
    return list;
  }

  Future<void> saveSavingsGoal(SavingsGoal goal) async {
    final p = await prefs;
    final current = await getSavingsGoals();
    final idx = current.indexWhere((g) => g.id == goal.id);
    if (idx != -1) {
      current[idx] = goal;
    } else {
      current.add(goal);
    }
    final stringList = current.map((g) => jsonEncode(g.toJson())).toList();
    await p.setStringList(_keyGoals, stringList);
  }

  Future<void> contributeToGoal(String id, int amountPaise) async {
    final p = await prefs;
    final current = await getSavingsGoals();
    final idx = current.indexWhere((g) => g.id == id);
    if (idx != -1) {
      final goal = current[idx];
      current[idx] = goal.copyWith(
        savedPaise: goal.savedPaise + amountPaise,
      );
      final stringList = current.map((g) => jsonEncode(g.toJson())).toList();
      await p.setStringList(_keyGoals, stringList);
    }
  }

  Future<void> deleteGoal(String id) async {
    final p = await prefs;
    final current = await getSavingsGoals();
    current.removeWhere((g) => g.id == id);
    final stringList = current.map((g) => jsonEncode(g.toJson())).toList();
    await p.setStringList(_keyGoals, stringList);
  }

  // ==========================================
  // STATEMENTS & DOWNLOADS
  // ==========================================

  /// Formats transactions into standard CSV statement
  String generateCsvStatement(List<Transaction> transactions, {String? accountHolder}) {
    final sb = StringBuffer();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(now);

    // Metadata header
    sb.writeln('PocketPath Account Statement');
    sb.writeln('Generated On: "$formattedDate"');
    if (accountHolder != null && accountHolder.isNotEmpty) {
      sb.writeln('Account Holder: "$accountHolder"');
    }
    sb.writeln('Total Transactions: ${transactions.length}');
    sb.writeln('');

    // Table Columns
    sb.writeln('Transaction ID,Date,Time,Merchant / Description,Category,Type,Amount (INR),Status,Notes');

    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm:ss');

    for (final tx in transactions) {
      final date = dateFormat.format(tx.dateTime);
      final time = timeFormat.format(tx.dateTime);
      final merchant = '"${tx.merchant.replaceAll('"', '""')}"';
      final category = tx.category.displayName;
      final type = tx.direction == TransactionDirection.income ? 'INCOME' : 'EXPENSE';
      final amount = (tx.amountPaise / 100.0).toStringAsFixed(2);
      final status = tx.status.name.toUpperCase();
      final notes = '"${(tx.note ?? '').replaceAll('"', '""')}"';

      sb.writeln('${tx.id},$date,$time,$merchant,$category,$type,$amount,$status,$notes');
    }

    return sb.toString();
  }

  /// Saves the statement to local device phone storage (Downloads or App Documents directory)
  Future<File> downloadStatement({
    List<Transaction>? transactions,
    String? accountHolder,
    String? customFileName,
  }) async {
    final txList = transactions ?? await getTransactions();
    final csvContent = generateCsvStatement(txList, accountHolder: accountHolder);

    Directory storageDir;
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && await downloadsDir.exists()) {
        storageDir = downloadsDir;
      } else {
        storageDir = await getApplicationDocumentsDirectory();
      }
    } catch (_) {
      storageDir = await getApplicationDocumentsDirectory();
    }

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = customFileName ?? 'PocketPath_Statement_$timestamp.csv';
    final filePath = '${storageDir.path}${Platform.pathSeparator}$fileName';

    final file = File(filePath);
    await file.writeAsString(csvContent, flush: true);
    return file;
  }

  /// Downloads and triggers native Share/Save dialog so user can directly save, email or open statement
  Future<File> downloadAndShareStatement({
    List<Transaction>? transactions,
    String? accountHolder,
  }) async {
    final file = await downloadStatement(
      transactions: transactions,
      accountHolder: accountHolder,
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        text: 'PocketPath Account Statement (${DateFormat('MMM yyyy').format(DateTime.now())})',
        subject: 'PocketPath Account Statement',
      ),
    );
    return file;
  }

  // ==========================================
  // DEMO DATA SEEDING & RESET
  // ==========================================

  Future<void> seedDemoData() async {
    final p = await prefs;
    final txStrings = sampleTransactions.map((t) => jsonEncode(t.toJson())).toList();
    await p.setStringList(_keyTransactions, txStrings);

    final budgetStrings = sampleBudgets.map((b) => jsonEncode(b.toJson())).toList();
    await p.setStringList(_keyBudgets, budgetStrings);

    final goalStrings = sampleGoals.map((g) => jsonEncode(g.toJson())).toList();
    await p.setStringList(_keyGoals, goalStrings);

    await recalculateBudgets();
  }

  Future<void> clearAllData() async {
    final p = await prefs;
    await p.remove(_keyTransactions);
    await p.remove(_keyBudgets);
    await p.remove(_keyGoals);
    await init();
  }
}

