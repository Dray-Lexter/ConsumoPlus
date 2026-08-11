import 'package:consumo_plus/features/electricity/domain/models/electricity_account.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_account_status.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_consumption_record.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_payment_record.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_snapshot.dart';
import 'package:consumo_plus/features/electricity/domain/models/electricity_synchronization_metadata.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'electricity_database_schema.dart';

abstract interface class ElectricityLocalStore {
  Future<ElectricitySnapshot?> loadLatest(String providerId);

  Future<ElectricityLocalUpsertResult> persistSynchronization({
    required ElectricityAccount account,
    required ElectricityAccountStatus accountStatus,
    required List<ElectricityConsumptionRecord> consumptionRecords,
    required List<ElectricityPaymentRecord> paymentRecords,
    required DateTime attemptedAt,
  });

  Future<void> recordFailure({
    required String providerId,
    required String contractNumber,
    required DateTime attemptedAt,
    required String sanitizedErrorCode,
  });

  Future<void> deleteProvider(String providerId);
}

class ElectricityLocalDataSource implements ElectricityLocalStore {
  const ElectricityLocalDataSource(this._database);

  final Database _database;

  @override
  Future<ElectricitySnapshot?> loadLatest(String providerId) async {
    final accountRows = await _database.query(
      ElectricityDatabaseSchema.accounts,
      where: 'provider_id = ?',
      whereArgs: [providerId],
      orderBy: 'synchronized_at DESC',
      limit: 1,
    );
    if (accountRows.isEmpty) return null;
    final account = _accountFromMap(accountRows.single);
    final keys = [account.providerId, account.contractNumber];
    final statuses = await _database.query(
      ElectricityDatabaseSchema.accountStatus,
      where: 'provider_id = ? AND contract_number = ?',
      whereArgs: keys,
      orderBy: 'billing_year DESC, billing_month DESC',
    );
    final consumptions = await _database.query(
      ElectricityDatabaseSchema.consumptions,
      where: 'provider_id = ? AND contract_number = ?',
      whereArgs: keys,
      orderBy: 'billing_year DESC, billing_month DESC',
    );
    final payments = await _database.query(
      ElectricityDatabaseSchema.payments,
      where: 'provider_id = ? AND contract_number = ?',
      whereArgs: keys,
      orderBy: 'payment_date DESC',
    );
    final metadataRows = await _database.query(
      ElectricityDatabaseSchema.synchronization,
      where: 'provider_id = ? AND contract_number = ?',
      whereArgs: keys,
      limit: 1,
    );
    final metadata = metadataRows.isEmpty
        ? ElectricitySynchronizationMetadata(
            providerId: account.providerId,
            contractNumber: account.contractNumber,
            lastAttemptAt: account.synchronizedAt,
            lastSuccessfulSyncAt: account.synchronizedAt,
            status: ElectricitySynchronizationStatus.success,
            insertedConsumptionRecords: 0,
            updatedConsumptionRecords: 0,
            insertedPaymentRecords: 0,
            updatedPaymentRecords: 0,
            accountStatusUpdated: false,
            supplyDetailsUpdated: false,
          )
        : _metadataFromMap(metadataRows.single);
    return ElectricitySnapshot(
      account: account,
      accountStatuses: statuses.map(_statusFromMap).toList(growable: false),
      consumptionRecords: consumptions
          .map(_consumptionFromMap)
          .toList(growable: false),
      paymentRecords: payments.map(_paymentFromMap).toList(growable: false),
      synchronization: metadata,
    );
  }

  @override
  Future<ElectricityLocalUpsertResult> persistSynchronization({
    required ElectricityAccount account,
    required ElectricityAccountStatus accountStatus,
    required List<ElectricityConsumptionRecord> consumptionRecords,
    required List<ElectricityPaymentRecord> paymentRecords,
    required DateTime attemptedAt,
  }) {
    return _database.transaction((transaction) async {
      final oldAccount = await transaction.query(
        ElectricityDatabaseSchema.accounts,
        where: 'provider_id = ? AND contract_number = ?',
        whereArgs: [account.providerId, account.contractNumber],
        limit: 1,
      );
      final supplyUpdated =
          oldAccount.isEmpty ||
          !_mapMatches(
            oldAccount.single,
            _accountToMap(account),
            _accountFields,
          );
      await transaction.insert(
        ElectricityDatabaseSchema.accounts,
        _accountToMap(account),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final oldStatus = await transaction.query(
        ElectricityDatabaseSchema.accountStatus,
        where:
            'provider_id = ? AND contract_number = ? AND source_period_code = ?',
        whereArgs: [
          accountStatus.providerId,
          accountStatus.contractNumber,
          accountStatus.sourcePeriodCode,
        ],
        limit: 1,
      );
      final statusUpdated =
          oldStatus.isEmpty ||
          !_mapMatches(
            oldStatus.single,
            _statusToMap(accountStatus),
            _statusFields,
          );
      await transaction.insert(
        ElectricityDatabaseSchema.accountStatus,
        _statusToMap(accountStatus),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      var insertedConsumptions = 0;
      var updatedConsumptions = 0;
      for (final record in consumptionRecords) {
        final old = await transaction.query(
          ElectricityDatabaseSchema.consumptions,
          where:
              'provider_id = ? AND contract_number = ? AND source_period_code = ?',
          whereArgs: [
            record.providerId,
            record.contractNumber,
            record.sourcePeriodCode,
          ],
          limit: 1,
        );
        if (old.isEmpty) {
          insertedConsumptions += 1;
        } else if (!_mapMatches(
          old.single,
          _consumptionToMap(record),
          _consumptionFields,
        )) {
          updatedConsumptions += 1;
        }
        await transaction.insert(
          ElectricityDatabaseSchema.consumptions,
          _consumptionToMap(record),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      var insertedPayments = 0;
      var updatedPayments = 0;
      for (final record in paymentRecords) {
        final map = _paymentToMap(record);
        final old = await transaction.query(
          ElectricityDatabaseSchema.payments,
          where:
              'provider_id = ? AND contract_number = ? AND source_period_code = ? '
              'AND payment_date = ? AND amount_cents = ? AND payment_center = ?',
          whereArgs: [
            record.providerId,
            record.contractNumber,
            record.sourcePeriodCode,
            map['payment_date'],
            record.amountCents,
            record.paymentCenter,
          ],
          limit: 1,
        );
        if (old.isEmpty) {
          insertedPayments += 1;
        } else if (!_mapMatches(old.single, map, _paymentFields)) {
          updatedPayments += 1;
        }
        await transaction.insert(
          ElectricityDatabaseSchema.payments,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final result = ElectricityLocalUpsertResult(
        insertedConsumptionRecords: insertedConsumptions,
        updatedConsumptionRecords: updatedConsumptions,
        insertedPaymentRecords: insertedPayments,
        updatedPaymentRecords: updatedPayments,
        accountStatusUpdated: statusUpdated,
        supplyDetailsUpdated: supplyUpdated,
      );
      await transaction.insert(
        ElectricityDatabaseSchema.synchronization,
        _metadataToMap(
          ElectricitySynchronizationMetadata(
            providerId: account.providerId,
            contractNumber: account.contractNumber,
            lastAttemptAt: attemptedAt,
            lastSuccessfulSyncAt: attemptedAt,
            status: ElectricitySynchronizationStatus.success,
            insertedConsumptionRecords: result.insertedConsumptionRecords,
            updatedConsumptionRecords: result.updatedConsumptionRecords,
            insertedPaymentRecords: result.insertedPaymentRecords,
            updatedPaymentRecords: result.updatedPaymentRecords,
            accountStatusUpdated: result.accountStatusUpdated,
            supplyDetailsUpdated: result.supplyDetailsUpdated,
          ),
        ),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return result;
    });
  }

  @override
  Future<void> recordFailure({
    required String providerId,
    required String contractNumber,
    required DateTime attemptedAt,
    required String sanitizedErrorCode,
  }) async {
    final account = await _database.query(
      ElectricityDatabaseSchema.accounts,
      where: 'provider_id = ? AND contract_number = ?',
      whereArgs: [providerId, contractNumber],
      limit: 1,
    );
    if (account.isEmpty) return;
    final old = await _database.query(
      ElectricityDatabaseSchema.synchronization,
      where: 'provider_id = ? AND contract_number = ?',
      whereArgs: [providerId, contractNumber],
      limit: 1,
    );
    final previous = old.isEmpty ? null : old.single;
    await _database.insert(
      ElectricityDatabaseSchema.synchronization,
      {
        'provider_id': providerId,
        'contract_number': contractNumber,
        'last_attempt_at': _epoch(attemptedAt),
        'last_successful_sync_at': previous?['last_successful_sync_at'],
        'status': ElectricitySynchronizationStatus.failed.name,
        'sanitized_error_code': sanitizedErrorCode,
        'inserted_consumption_records':
            previous?['inserted_consumption_records'] ?? 0,
        'updated_consumption_records':
            previous?['updated_consumption_records'] ?? 0,
        'inserted_payment_records': previous?['inserted_payment_records'] ?? 0,
        'updated_payment_records': previous?['updated_payment_records'] ?? 0,
        'account_status_updated': previous?['account_status_updated'] ?? 0,
        'supply_details_updated': previous?['supply_details_updated'] ?? 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteProvider(String providerId) {
    return _database.transaction((transaction) async {
      for (final table in ElectricityDatabaseSchema.tables.reversed) {
        await transaction.delete(
          table,
          where: 'provider_id = ?',
          whereArgs: [providerId],
        );
      }
    });
  }

  static const _accountFields = [
    'owner_name',
    'service_address',
    'tariff_code',
    'connection_type',
    'feeder_type',
    'contracted_power',
    'voltage_level',
    'meter_number',
  ];
  static const _statusFields = [
    'billing_year',
    'billing_month',
    'current_billing_cents',
    'previous_debt_cents',
    'total_debt_cents',
    'amount_paid_cents',
    'total_balance_cents',
    'due_date',
    'issue_date',
    'reading_date',
    'previous_reading_date',
  ];
  static const _consumptionFields = [
    'billing_year',
    'billing_month',
    'tariff_code',
    'consumption_wh',
    'monthly_charge_cents',
  ];
  static const _paymentFields = ['billing_year', 'billing_month'];

  static bool _mapMatches(
    Map<String, Object?> old,
    Map<String, Object?> next,
    List<String> fields,
  ) => fields.every((field) => old[field] == next[field]);

  static Map<String, Object?> _accountToMap(ElectricityAccount value) => {
    'provider_id': value.providerId,
    'contract_number': value.contractNumber,
    'owner_name': value.ownerName,
    'service_address': value.serviceAddress,
    'tariff_code': value.tariffCode,
    'connection_type': value.connectionType,
    'feeder_type': value.feederType,
    'contracted_power': value.contractedPower,
    'voltage_level': value.voltageLevel,
    'meter_number': value.meterNumber,
    'synchronized_at': _epoch(value.synchronizedAt),
  };

  static Map<String, Object?> _statusToMap(ElectricityAccountStatus value) => {
    'provider_id': value.providerId,
    'contract_number': value.contractNumber,
    'billing_year': value.billingYear,
    'billing_month': value.billingMonth,
    'source_period_code': value.sourcePeriodCode,
    'current_billing_cents': value.currentBillingCents,
    'previous_debt_cents': value.previousDebtCents,
    'total_debt_cents': value.totalDebtCents,
    'amount_paid_cents': value.amountPaidCents,
    'total_balance_cents': value.totalBalanceCents,
    'due_date': _date(value.dueDate),
    'issue_date': _date(value.issueDate),
    'reading_date': _date(value.readingDate),
    'previous_reading_date': _date(value.previousReadingDate),
    'synchronized_at': _epoch(value.synchronizedAt),
  };

  static Map<String, Object?> _consumptionToMap(
    ElectricityConsumptionRecord value,
  ) => {
    'provider_id': value.providerId,
    'contract_number': value.contractNumber,
    'billing_year': value.billingYear,
    'billing_month': value.billingMonth,
    'source_period_code': value.sourcePeriodCode,
    'tariff_code': value.tariffCode,
    'consumption_wh': value.consumptionWh,
    'monthly_charge_cents': value.monthlyChargeCents,
    'synchronized_at': _epoch(value.synchronizedAt),
  };

  static Map<String, Object?> _paymentToMap(ElectricityPaymentRecord value) => {
    'provider_id': value.providerId,
    'contract_number': value.contractNumber,
    'billing_year': value.billingYear,
    'billing_month': value.billingMonth,
    'source_period_code': value.sourcePeriodCode,
    'payment_date': _date(value.paymentDate),
    'amount_cents': value.amountCents,
    'payment_center': value.paymentCenter,
    'synchronized_at': _epoch(value.synchronizedAt),
  };

  static Map<String, Object?> _metadataToMap(
    ElectricitySynchronizationMetadata value,
  ) => {
    'provider_id': value.providerId,
    'contract_number': value.contractNumber,
    'last_attempt_at': _epoch(value.lastAttemptAt),
    'last_successful_sync_at': value.lastSuccessfulSyncAt == null
        ? null
        : _epoch(value.lastSuccessfulSyncAt!),
    'status': value.status.name,
    'sanitized_error_code': value.sanitizedErrorCode,
    'inserted_consumption_records': value.insertedConsumptionRecords,
    'updated_consumption_records': value.updatedConsumptionRecords,
    'inserted_payment_records': value.insertedPaymentRecords,
    'updated_payment_records': value.updatedPaymentRecords,
    'account_status_updated': value.accountStatusUpdated ? 1 : 0,
    'supply_details_updated': value.supplyDetailsUpdated ? 1 : 0,
  };

  static ElectricityAccount _accountFromMap(Map<String, Object?> map) =>
      ElectricityAccount(
        providerId: map['provider_id']! as String,
        contractNumber: map['contract_number']! as String,
        ownerName: map['owner_name']! as String,
        serviceAddress: map['service_address']! as String,
        tariffCode: map['tariff_code']! as String,
        connectionType: map['connection_type'] as String?,
        feederType: map['feeder_type'] as String?,
        contractedPower: map['contracted_power'] as String?,
        voltageLevel: map['voltage_level'] as String?,
        meterNumber: map['meter_number'] as String?,
        synchronizedAt: _dateTime(map['synchronized_at']!),
      );

  static ElectricityAccountStatus _statusFromMap(Map<String, Object?> map) =>
      ElectricityAccountStatus(
        providerId: map['provider_id']! as String,
        contractNumber: map['contract_number']! as String,
        billingYear: map['billing_year']! as int,
        billingMonth: map['billing_month']! as int,
        sourcePeriodCode: map['source_period_code']! as String,
        currentBillingCents: map['current_billing_cents']! as int,
        previousDebtCents: map['previous_debt_cents']! as int,
        totalDebtCents: map['total_debt_cents']! as int,
        amountPaidCents: map['amount_paid_cents']! as int,
        totalBalanceCents: map['total_balance_cents']! as int,
        dueDate: _nullableDate(map['due_date']),
        issueDate: _nullableDate(map['issue_date']),
        readingDate: _nullableDate(map['reading_date']),
        previousReadingDate: _nullableDate(map['previous_reading_date']),
        synchronizedAt: _dateTime(map['synchronized_at']!),
      );

  static ElectricityConsumptionRecord _consumptionFromMap(
    Map<String, Object?> map,
  ) => ElectricityConsumptionRecord(
    providerId: map['provider_id']! as String,
    contractNumber: map['contract_number']! as String,
    billingYear: map['billing_year']! as int,
    billingMonth: map['billing_month']! as int,
    sourcePeriodCode: map['source_period_code']! as String,
    tariffCode: map['tariff_code']! as String,
    consumptionWh: map['consumption_wh']! as int,
    monthlyChargeCents: map['monthly_charge_cents']! as int,
    synchronizedAt: _dateTime(map['synchronized_at']!),
  );

  static ElectricityPaymentRecord _paymentFromMap(Map<String, Object?> map) =>
      ElectricityPaymentRecord(
        providerId: map['provider_id']! as String,
        contractNumber: map['contract_number']! as String,
        billingYear: map['billing_year']! as int,
        billingMonth: map['billing_month']! as int,
        sourcePeriodCode: map['source_period_code']! as String,
        paymentDate: DateTime.parse(map['payment_date']! as String),
        amountCents: map['amount_cents']! as int,
        paymentCenter: map['payment_center']! as String,
        synchronizedAt: _dateTime(map['synchronized_at']!),
      );

  static ElectricitySynchronizationMetadata _metadataFromMap(
    Map<String, Object?> map,
  ) => ElectricitySynchronizationMetadata(
    providerId: map['provider_id']! as String,
    contractNumber: map['contract_number']! as String,
    lastAttemptAt: _dateTime(map['last_attempt_at']!),
    lastSuccessfulSyncAt: map['last_successful_sync_at'] == null
        ? null
        : _dateTime(map['last_successful_sync_at']!),
    status: ElectricitySynchronizationStatus.values.byName(
      map['status']! as String,
    ),
    sanitizedErrorCode: map['sanitized_error_code'] as String?,
    insertedConsumptionRecords: map['inserted_consumption_records']! as int,
    updatedConsumptionRecords: map['updated_consumption_records']! as int,
    insertedPaymentRecords: map['inserted_payment_records']! as int,
    updatedPaymentRecords: map['updated_payment_records']! as int,
    accountStatusUpdated: map['account_status_updated'] == 1,
    supplyDetailsUpdated: map['supply_details_updated'] == 1,
  );

  static int _epoch(DateTime value) => value.toUtc().millisecondsSinceEpoch;
  static DateTime _dateTime(Object value) =>
      DateTime.fromMillisecondsSinceEpoch(value as int, isUtc: true);
  static DateTime? _nullableDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
  static String? _date(DateTime? value) => value == null
      ? null
      : '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class ElectricityLocalUpsertResult {
  const ElectricityLocalUpsertResult({
    required this.insertedConsumptionRecords,
    required this.updatedConsumptionRecords,
    required this.insertedPaymentRecords,
    required this.updatedPaymentRecords,
    required this.accountStatusUpdated,
    required this.supplyDetailsUpdated,
  });

  final int insertedConsumptionRecords;
  final int updatedConsumptionRecords;
  final int insertedPaymentRecords;
  final int updatedPaymentRecords;
  final bool accountStatusUpdated;
  final bool supplyDetailsUpdated;
}
