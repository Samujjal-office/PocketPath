import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketapp/main.dart';
import 'package:pocketapp/core/models/transaction.dart';
import 'package:pocketapp/core/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await StorageService().init();
  });

  testWidgets('PocketPath app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PocketPathApp());
    expect(find.text('Sign in to your PocketPath account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  test('StorageService persists transactions in local phone storage', () async {
    final storage = StorageService();

    // Verify initial clean state has 0 transactions
    var txs = await storage.getTransactions();
    expect(txs.isEmpty, isTrue);

    // Save a new expense
    final newTx = Transaction(
      id: 'tx_test_1',
      merchant: 'Fresh Mart',
      category: TransactionCategory.food,
      direction: TransactionDirection.expense,
      amountPaise: 45000, // ₹450.00
      dateTime: DateTime(2026, 10, 15, 14, 30),
      status: TransactionStatus.synced,
      note: 'Groceries',
    );
    await storage.addTransaction(newTx);

    // Verify retrieved from storage
    txs = await storage.getTransactions();
    expect(txs.length, equals(1));
    expect(txs.first.merchant, equals('Fresh Mart'));
    expect(txs.first.amountPaise, equals(45000));
    expect(txs.first.category, equals(TransactionCategory.food));

    // Save an income
    final incomeTx = Transaction(
      id: 'tx_test_2',
      merchant: 'Freelance Pay',
      category: TransactionCategory.salary,
      direction: TransactionDirection.income,
      amountPaise: 2500000, // ₹25,000.00
      dateTime: DateTime(2026, 10, 20, 10, 0),
      status: TransactionStatus.synced,
    );
    await storage.addTransaction(incomeTx);

    txs = await storage.getTransactions();
    expect(txs.length, equals(2));

    // Verify CSV statement generation
    final csv = storage.generateCsvStatement(txs, accountHolder: 'Test User');
    expect(csv.contains('PocketPath Account Statement'), isTrue);
    expect(csv.contains('Fresh Mart'), isTrue);
    expect(csv.contains('Freelance Pay'), isTrue);
    expect(csv.contains('450.00'), isTrue);
    expect(csv.contains('25000.00'), isTrue);
    expect(csv.contains('EXPENSE'), isTrue);
    expect(csv.contains('INCOME'), isTrue);

    // Delete transaction
    await storage.deleteTransaction('tx_test_1');
    txs = await storage.getTransactions();
    expect(txs.length, equals(1));
    expect(txs.first.id, equals('tx_test_2'));
  });
}
