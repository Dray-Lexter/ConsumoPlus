import 'package:sqflite_common/sqlite_api.dart';

abstract final class WaterDatabaseSchema {
  static const version = 1;
  static const accounts = 'water_accounts';
  static const billing = 'billing_records';
  static const payments = 'payment_records';
  static const synchronization = 'synchronization_metadata';
  static const tables = [accounts, billing, payments, synchronization];

  static Future<void> create(Database database, int version) async {
    await database.execute('''
      CREATE TABLE $accounts (
        provider_id TEXT NOT NULL,
        customer_code TEXT NOT NULL CHECK(length(customer_code) > 0),
        owner_name TEXT NOT NULL CHECK(length(owner_name) > 0),
        service_address TEXT,
        service_status TEXT,
        tariff_name TEXT,
        meter_number TEXT,
        connection_type TEXT,
        synchronized_at INTEGER NOT NULL,
        PRIMARY KEY (provider_id, customer_code)
      )
    ''');
    await database.execute('''
      CREATE TABLE $billing (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider_id TEXT NOT NULL,
        customer_code TEXT NOT NULL,
        billing_year INTEGER NOT NULL,
        billing_month INTEGER NOT NULL CHECK(billing_month BETWEEN 1 AND 12),
        source_period_label TEXT NOT NULL,
        receipt_number TEXT NOT NULL CHECK(length(receipt_number) > 0),
        consumption_cubic_meters REAL NOT NULL,
        average_reading REAL NOT NULL,
        monthly_charge_cents INTEGER NOT NULL,
        overdue_months INTEGER NOT NULL,
        outstanding_debt_cents INTEGER NOT NULL,
        total_amount_cents INTEGER NOT NULL,
        synchronized_at INTEGER NOT NULL,
        UNIQUE (provider_id, customer_code, receipt_number)
      )
    ''');
    await database.execute('''
      CREATE TABLE $payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider_id TEXT NOT NULL,
        customer_code TEXT NOT NULL,
        payment_date TEXT NOT NULL,
        payment_center TEXT NOT NULL,
        payment_year INTEGER NOT NULL,
        payment_month INTEGER NOT NULL CHECK(payment_month BETWEEN 1 AND 12),
        document_type TEXT NOT NULL,
        receipt_number TEXT NOT NULL CHECK(length(receipt_number) > 0),
        amount_cents INTEGER NOT NULL,
        detail TEXT NOT NULL,
        synchronized_at INTEGER NOT NULL,
        UNIQUE (
          provider_id,
          customer_code,
          receipt_number,
          payment_date,
          amount_cents
        )
      )
    ''');
    await database.execute('''
      CREATE TABLE $synchronization (
        provider_id TEXT NOT NULL,
        customer_code TEXT NOT NULL,
        last_attempt_at INTEGER NOT NULL,
        last_successful_sync_at INTEGER,
        status TEXT NOT NULL,
        sanitized_error_code TEXT,
        inserted_billing_records INTEGER NOT NULL,
        updated_billing_records INTEGER NOT NULL,
        inserted_payment_records INTEGER NOT NULL,
        updated_payment_records INTEGER NOT NULL,
        PRIMARY KEY (provider_id, customer_code)
      )
    ''');
  }
}
