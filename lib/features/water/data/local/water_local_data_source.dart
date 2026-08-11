import 'package:consumo_plus/features/water/data/local/water_database_schema.dart';
import 'package:consumo_plus/features/water/domain/models/billing_record.dart';
import 'package:consumo_plus/features/water/domain/models/payment_record.dart';
import 'package:consumo_plus/features/water/domain/models/synchronization_metadata.dart';
import 'package:consumo_plus/features/water/domain/models/water_account.dart';
import 'package:consumo_plus/features/water/domain/models/water_snapshot.dart';
import 'package:sqflite_common/sqlite_api.dart';

abstract interface class WaterLocalStore {
  Future<WaterSnapshot?> loadLatest(String providerId);

  Future<LocalUpsertResult> persistSynchronization({
    required WaterAccount account,
    required List<BillingRecord> billingRecords,
    required List<PaymentRecord> paymentRecords,
    required DateTime attemptedAt,
  });

  Future<void> recordFailure({
    required String providerId,
    required String customerCode,
    required DateTime attemptedAt,
    required String sanitizedErrorCode,
  });

  Future<void> deleteProvider(String providerId);
}

class WaterLocalDataSource implements WaterLocalStore {
  const WaterLocalDataSource(this._database);

  final Database _database;

  @override
  Future<WaterSnapshot?> loadLatest(String providerId) async {
    final accountRows = await _database.query(
      WaterDatabaseSchema.accounts,
      where: 'provider_id = ?',
      whereArgs: [providerId],
      orderBy: 'synchronized_at DESC',
      limit: 1,
    );
    if (accountRows.isEmpty) return null;

    final account = _accountFromMap(accountRows.single);
    final keys = [account.providerId, account.customerCode];
    final billingRows = await _database.query(
      WaterDatabaseSchema.billing,
      where: 'provider_id = ? AND customer_code = ?',
      whereArgs: keys,
      orderBy: 'billing_year DESC, billing_month DESC',
    );
    final paymentRows = await _database.query(
      WaterDatabaseSchema.payments,
      where: 'provider_id = ? AND customer_code = ?',
      whereArgs: keys,
      orderBy: 'payment_date DESC',
    );
    final metadataRows = await _database.query(
      WaterDatabaseSchema.synchronization,
      where: 'provider_id = ? AND customer_code = ?',
      whereArgs: keys,
      limit: 1,
    );
    final metadata = metadataRows.isEmpty
        ? SynchronizationMetadata(
            providerId: account.providerId,
            customerCode: account.customerCode,
            lastAttemptAt: account.synchronizedAt,
            lastSuccessfulSyncAt: account.synchronizedAt,
            status: SynchronizationStatus.success,
            insertedBillingRecords: 0,
            updatedBillingRecords: 0,
            insertedPaymentRecords: 0,
            updatedPaymentRecords: 0,
          )
        : _metadataFromMap(metadataRows.single);

    return WaterSnapshot(
      account: account,
      billingRecords: billingRows.map(_billingFromMap).toList(growable: false),
      paymentRecords: paymentRows.map(_paymentFromMap).toList(growable: false),
      synchronization: metadata,
    );
  }

  @override
  Future<LocalUpsertResult> persistSynchronization({
    required WaterAccount account,
    required List<BillingRecord> billingRecords,
    required List<PaymentRecord> paymentRecords,
    required DateTime attemptedAt,
  }) {
    return _database.transaction((transaction) async {
      var insertedBilling = 0;
      var updatedBilling = 0;
      var insertedPayments = 0;
      var updatedPayments = 0;

      await transaction.insert(
        WaterDatabaseSchema.accounts,
        _accountToMap(account),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final record in billingRecords) {
        final existing = await transaction.query(
          WaterDatabaseSchema.billing,
          where: 'provider_id = ? AND customer_code = ? AND receipt_number = ?',
          whereArgs: [
            record.providerId,
            record.customerCode,
            record.receiptNumber,
          ],
          limit: 1,
        );
        if (existing.isEmpty) {
          insertedBilling += 1;
        } else if (!_billingMatches(existing.single, record)) {
          updatedBilling += 1;
        }
        await transaction.insert(
          WaterDatabaseSchema.billing,
          _billingToMap(record),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (final record in paymentRecords) {
        final existing = await transaction.query(
          WaterDatabaseSchema.payments,
          where:
              'provider_id = ? AND customer_code = ? AND receipt_number = ? '
              'AND payment_date = ? AND amount_cents = ?',
          whereArgs: [
            record.providerId,
            record.customerCode,
            record.receiptNumber,
            _dateOnly(record.paymentDate),
            record.amountCents,
          ],
          limit: 1,
        );
        if (existing.isEmpty) {
          insertedPayments += 1;
        } else if (!_paymentMatches(existing.single, record)) {
          updatedPayments += 1;
        }
        await transaction.insert(
          WaterDatabaseSchema.payments,
          _paymentToMap(record),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final result = LocalUpsertResult(
        insertedBillingRecords: insertedBilling,
        updatedBillingRecords: updatedBilling,
        insertedPaymentRecords: insertedPayments,
        updatedPaymentRecords: updatedPayments,
      );
      await transaction.insert(
        WaterDatabaseSchema.synchronization,
        {
          'provider_id': account.providerId,
          'customer_code': account.customerCode,
          'last_attempt_at': attemptedAt.toUtc().millisecondsSinceEpoch,
          'last_successful_sync_at': attemptedAt.toUtc().millisecondsSinceEpoch,
          'status': SynchronizationStatus.success.name,
          'sanitized_error_code': null,
          ...result.toMap(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return result;
    });
  }

  @override
  Future<void> recordFailure({
    required String providerId,
    required String customerCode,
    required DateTime attemptedAt,
    required String sanitizedErrorCode,
  }) async {
    final accountRows = await _database.query(
      WaterDatabaseSchema.accounts,
      columns: ['provider_id'],
      where: 'provider_id = ? AND customer_code = ?',
      whereArgs: [providerId, customerCode],
      limit: 1,
    );
    if (accountRows.isEmpty) return;

    final existing = await _database.query(
      WaterDatabaseSchema.synchronization,
      where: 'provider_id = ? AND customer_code = ?',
      whereArgs: [providerId, customerCode],
      limit: 1,
    );
    final previous = existing.isEmpty ? null : existing.single;
    await _database.insert(
      WaterDatabaseSchema.synchronization,
      {
        'provider_id': providerId,
        'customer_code': customerCode,
        'last_attempt_at': attemptedAt.toUtc().millisecondsSinceEpoch,
        'last_successful_sync_at': previous?['last_successful_sync_at'],
        'status': SynchronizationStatus.failed.name,
        'sanitized_error_code': sanitizedErrorCode,
        'inserted_billing_records': previous?['inserted_billing_records'] ?? 0,
        'updated_billing_records': previous?['updated_billing_records'] ?? 0,
        'inserted_payment_records': previous?['inserted_payment_records'] ?? 0,
        'updated_payment_records': previous?['updated_payment_records'] ?? 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteProvider(String providerId) {
    return _database.transaction((transaction) async {
      for (final table in WaterDatabaseSchema.tables.reversed) {
        await transaction.delete(
          table,
          where: 'provider_id = ?',
          whereArgs: [providerId],
        );
      }
    });
  }

  static Map<String, Object?> _accountToMap(WaterAccount account) => {
    'provider_id': account.providerId,
    'customer_code': account.customerCode,
    'owner_name': account.ownerName,
    'service_address': account.serviceAddress,
    'service_status': account.serviceStatus,
    'tariff_name': account.tariffName,
    'meter_number': account.meterNumber,
    'connection_type': account.connectionType,
    'synchronized_at': account.synchronizedAt.toUtc().millisecondsSinceEpoch,
  };

  static Map<String, Object?> _billingToMap(BillingRecord record) => {
    'provider_id': record.providerId,
    'customer_code': record.customerCode,
    'billing_year': record.billingYear,
    'billing_month': record.billingMonth,
    'source_period_label': record.sourcePeriodLabel,
    'receipt_number': record.receiptNumber,
    'consumption_cubic_meters': record.consumptionCubicMeters,
    'average_reading': record.averageReading,
    'monthly_charge_cents': record.monthlyChargeCents,
    'overdue_months': record.overdueMonths,
    'outstanding_debt_cents': record.outstandingDebtCents,
    'total_amount_cents': record.totalAmountCents,
    'synchronized_at': record.synchronizedAt.toUtc().millisecondsSinceEpoch,
  };

  static Map<String, Object?> _paymentToMap(PaymentRecord record) => {
    'provider_id': record.providerId,
    'customer_code': record.customerCode,
    'payment_date': _dateOnly(record.paymentDate),
    'payment_center': record.paymentCenter,
    'payment_year': record.paymentYear,
    'payment_month': record.paymentMonth,
    'document_type': record.documentType,
    'receipt_number': record.receiptNumber,
    'amount_cents': record.amountCents,
    'detail': record.detail,
    'synchronized_at': record.synchronizedAt.toUtc().millisecondsSinceEpoch,
  };

  static bool _billingMatches(Map<String, Object?> row, BillingRecord record) {
    return row['billing_year'] == record.billingYear &&
        row['billing_month'] == record.billingMonth &&
        row['source_period_label'] == record.sourcePeriodLabel &&
        (row['consumption_cubic_meters'] as num).toDouble() ==
            record.consumptionCubicMeters &&
        (row['average_reading'] as num).toDouble() == record.averageReading &&
        row['monthly_charge_cents'] == record.monthlyChargeCents &&
        row['overdue_months'] == record.overdueMonths &&
        row['outstanding_debt_cents'] == record.outstandingDebtCents &&
        row['total_amount_cents'] == record.totalAmountCents;
  }

  static bool _paymentMatches(Map<String, Object?> row, PaymentRecord record) {
    return row['payment_center'] == record.paymentCenter &&
        row['payment_year'] == record.paymentYear &&
        row['payment_month'] == record.paymentMonth &&
        row['document_type'] == record.documentType &&
        row['detail'] == record.detail;
  }

  static WaterAccount _accountFromMap(Map<String, Object?> map) => WaterAccount(
    providerId: map['provider_id']! as String,
    customerCode: map['customer_code']! as String,
    ownerName: map['owner_name']! as String,
    serviceAddress: map['service_address'] as String?,
    serviceStatus: map['service_status'] as String?,
    tariffName: map['tariff_name'] as String?,
    meterNumber: map['meter_number'] as String?,
    connectionType: map['connection_type'] as String?,
    synchronizedAt: _dateTime(map['synchronized_at']!),
  );

  static BillingRecord _billingFromMap(Map<String, Object?> map) =>
      BillingRecord(
        providerId: map['provider_id']! as String,
        customerCode: map['customer_code']! as String,
        billingYear: map['billing_year']! as int,
        billingMonth: map['billing_month']! as int,
        sourcePeriodLabel: map['source_period_label']! as String,
        receiptNumber: map['receipt_number']! as String,
        consumptionCubicMeters: (map['consumption_cubic_meters']! as num)
            .toDouble(),
        averageReading: (map['average_reading']! as num).toDouble(),
        monthlyChargeCents: map['monthly_charge_cents']! as int,
        overdueMonths: map['overdue_months']! as int,
        outstandingDebtCents: map['outstanding_debt_cents']! as int,
        totalAmountCents: map['total_amount_cents']! as int,
        synchronizedAt: _dateTime(map['synchronized_at']!),
      );

  static PaymentRecord _paymentFromMap(Map<String, Object?> map) =>
      PaymentRecord(
        providerId: map['provider_id']! as String,
        customerCode: map['customer_code']! as String,
        paymentDate: DateTime.parse(map['payment_date']! as String),
        paymentCenter: map['payment_center']! as String,
        paymentYear: map['payment_year']! as int,
        paymentMonth: map['payment_month']! as int,
        documentType: map['document_type']! as String,
        receiptNumber: map['receipt_number']! as String,
        amountCents: map['amount_cents']! as int,
        detail: map['detail']! as String,
        synchronizedAt: _dateTime(map['synchronized_at']!),
      );

  static SynchronizationMetadata _metadataFromMap(Map<String, Object?> map) {
    return SynchronizationMetadata(
      providerId: map['provider_id']! as String,
      customerCode: map['customer_code']! as String,
      lastAttemptAt: _dateTime(map['last_attempt_at']!),
      lastSuccessfulSyncAt: map['last_successful_sync_at'] == null
          ? null
          : _dateTime(map['last_successful_sync_at']!),
      status: SynchronizationStatus.values.byName(map['status']! as String),
      sanitizedErrorCode: map['sanitized_error_code'] as String?,
      insertedBillingRecords: map['inserted_billing_records']! as int,
      updatedBillingRecords: map['updated_billing_records']! as int,
      insertedPaymentRecords: map['inserted_payment_records']! as int,
      updatedPaymentRecords: map['updated_payment_records']! as int,
    );
  }

  static DateTime _dateTime(Object value) {
    return DateTime.fromMillisecondsSinceEpoch(value as int, isUtc: true);
  }

  static String _dateOnly(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class LocalUpsertResult {
  const LocalUpsertResult({
    required this.insertedBillingRecords,
    required this.updatedBillingRecords,
    required this.insertedPaymentRecords,
    required this.updatedPaymentRecords,
  });

  final int insertedBillingRecords;
  final int updatedBillingRecords;
  final int insertedPaymentRecords;
  final int updatedPaymentRecords;

  Map<String, int> toMap() => {
    'inserted_billing_records': insertedBillingRecords,
    'updated_billing_records': updatedBillingRecords,
    'inserted_payment_records': insertedPaymentRecords,
    'updated_payment_records': updatedPaymentRecords,
  };
}
