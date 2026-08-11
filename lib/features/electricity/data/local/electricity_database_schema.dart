import 'package:sqflite_common/sqlite_api.dart';

abstract final class ElectricityDatabaseSchema {
  static const accounts = 'electricity_accounts';
  static const accountStatus = 'electricity_account_status';
  static const consumptions = 'electricity_consumption_records';
  static const payments = 'electricity_payment_records';
  static const synchronization = 'electricity_synchronization_metadata';
  static const tables = [
    accounts,
    accountStatus,
    consumptions,
    payments,
    synchronization,
  ];

  static Future<void> create(Database database) async {
    await database.execute('''
      CREATE TABLE $accounts (
        provider_id TEXT NOT NULL,
        contract_number TEXT NOT NULL CHECK(length(contract_number) > 0),
        owner_name TEXT NOT NULL CHECK(length(owner_name) > 0),
        service_address TEXT NOT NULL CHECK(length(service_address) > 0),
        tariff_code TEXT NOT NULL CHECK(length(tariff_code) > 0),
        connection_type TEXT,
        feeder_type TEXT,
        contracted_power TEXT,
        voltage_level TEXT,
        meter_number TEXT,
        synchronized_at INTEGER NOT NULL,
        PRIMARY KEY (provider_id, contract_number)
      )
    ''');
    await database.execute('''
      CREATE TABLE $accountStatus (
        provider_id TEXT NOT NULL,
        contract_number TEXT NOT NULL,
        billing_year INTEGER NOT NULL,
        billing_month INTEGER NOT NULL CHECK(billing_month BETWEEN 1 AND 12),
        source_period_code TEXT NOT NULL CHECK(length(source_period_code) = 6),
        current_billing_cents INTEGER NOT NULL,
        previous_debt_cents INTEGER NOT NULL,
        total_debt_cents INTEGER NOT NULL,
        amount_paid_cents INTEGER NOT NULL,
        total_balance_cents INTEGER NOT NULL,
        due_date TEXT,
        issue_date TEXT,
        reading_date TEXT,
        previous_reading_date TEXT,
        synchronized_at INTEGER NOT NULL,
        PRIMARY KEY (provider_id, contract_number, source_period_code)
      )
    ''');
    await database.execute('''
      CREATE TABLE $consumptions (
        provider_id TEXT NOT NULL,
        contract_number TEXT NOT NULL,
        billing_year INTEGER NOT NULL,
        billing_month INTEGER NOT NULL CHECK(billing_month BETWEEN 1 AND 12),
        source_period_code TEXT NOT NULL CHECK(length(source_period_code) = 6),
        tariff_code TEXT NOT NULL,
        consumption_wh INTEGER NOT NULL,
        monthly_charge_cents INTEGER NOT NULL,
        synchronized_at INTEGER NOT NULL,
        PRIMARY KEY (provider_id, contract_number, source_period_code)
      )
    ''');
    await database.execute('''
      CREATE TABLE $payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        provider_id TEXT NOT NULL,
        contract_number TEXT NOT NULL,
        billing_year INTEGER NOT NULL,
        billing_month INTEGER NOT NULL CHECK(billing_month BETWEEN 1 AND 12),
        source_period_code TEXT NOT NULL CHECK(length(source_period_code) = 6),
        payment_date TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        payment_center TEXT NOT NULL,
        synchronized_at INTEGER NOT NULL,
        UNIQUE (
          provider_id,
          contract_number,
          source_period_code,
          payment_date,
          amount_cents,
          payment_center
        )
      )
    ''');
    await database.execute('''
      CREATE TABLE $synchronization (
        provider_id TEXT NOT NULL,
        contract_number TEXT NOT NULL,
        last_attempt_at INTEGER NOT NULL,
        last_successful_sync_at INTEGER,
        status TEXT NOT NULL,
        sanitized_error_code TEXT,
        inserted_consumption_records INTEGER NOT NULL,
        updated_consumption_records INTEGER NOT NULL,
        inserted_payment_records INTEGER NOT NULL,
        updated_payment_records INTEGER NOT NULL,
        account_status_updated INTEGER NOT NULL,
        supply_details_updated INTEGER NOT NULL,
        PRIMARY KEY (provider_id, contract_number)
      )
    ''');
  }
}
