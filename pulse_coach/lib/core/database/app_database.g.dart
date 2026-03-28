// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intensityMeta = const VerificationMeta(
    'intensity',
  );
  @override
  late final GeneratedColumn<int> intensity = GeneratedColumn<int>(
    'intensity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _abandonedMeta = const VerificationMeta(
    'abandoned',
  );
  @override
  late final GeneratedColumn<bool> abandoned = GeneratedColumn<bool>(
    'abandoned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("abandoned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionType,
    intensity,
    durationSeconds,
    abandoned,
    completedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionTypeMeta);
    }
    if (data.containsKey('intensity')) {
      context.handle(
        _intensityMeta,
        intensity.isAcceptableOrUnknown(data['intensity']!, _intensityMeta),
      );
    } else if (isInserting) {
      context.missing(_intensityMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('abandoned')) {
      context.handle(
        _abandonedMeta,
        abandoned.isAcceptableOrUnknown(data['abandoned']!, _abandonedMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_type'],
      )!,
      intensity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intensity'],
      )!,
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      )!,
      abandoned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}abandoned'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final int id;
  final String sessionType;
  final int intensity;
  final int durationSeconds;
  final bool abandoned;
  final DateTime? completedAt;
  final DateTime createdAt;
  const Session({
    required this.id,
    required this.sessionType,
    required this.intensity,
    required this.durationSeconds,
    required this.abandoned,
    this.completedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_type'] = Variable<String>(sessionType);
    map['intensity'] = Variable<int>(intensity);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['abandoned'] = Variable<bool>(abandoned);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      sessionType: Value(sessionType),
      intensity: Value(intensity),
      durationSeconds: Value(durationSeconds),
      abandoned: Value(abandoned),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<int>(json['id']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      intensity: serializer.fromJson<int>(json['intensity']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      abandoned: serializer.fromJson<bool>(json['abandoned']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionType': serializer.toJson<String>(sessionType),
      'intensity': serializer.toJson<int>(intensity),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'abandoned': serializer.toJson<bool>(abandoned),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Session copyWith({
    int? id,
    String? sessionType,
    int? intensity,
    int? durationSeconds,
    bool? abandoned,
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
  }) => Session(
    id: id ?? this.id,
    sessionType: sessionType ?? this.sessionType,
    intensity: intensity ?? this.intensity,
    durationSeconds: durationSeconds ?? this.durationSeconds,
    abandoned: abandoned ?? this.abandoned,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
      intensity: data.intensity.present ? data.intensity.value : this.intensity,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      abandoned: data.abandoned.present ? data.abandoned.value : this.abandoned,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('sessionType: $sessionType, ')
          ..write('intensity: $intensity, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('abandoned: $abandoned, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionType,
    intensity,
    durationSeconds,
    abandoned,
    completedAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.sessionType == this.sessionType &&
          other.intensity == this.intensity &&
          other.durationSeconds == this.durationSeconds &&
          other.abandoned == this.abandoned &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<int> id;
  final Value<String> sessionType;
  final Value<int> intensity;
  final Value<int> durationSeconds;
  final Value<bool> abandoned;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.intensity = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.abandoned = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SessionsCompanion.insert({
    this.id = const Value.absent(),
    required String sessionType,
    required int intensity,
    required int durationSeconds,
    this.abandoned = const Value.absent(),
    this.completedAt = const Value.absent(),
    required DateTime createdAt,
  }) : sessionType = Value(sessionType),
       intensity = Value(intensity),
       durationSeconds = Value(durationSeconds),
       createdAt = Value(createdAt);
  static Insertable<Session> custom({
    Expression<int>? id,
    Expression<String>? sessionType,
    Expression<int>? intensity,
    Expression<int>? durationSeconds,
    Expression<bool>? abandoned,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionType != null) 'session_type': sessionType,
      if (intensity != null) 'intensity': intensity,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (abandoned != null) 'abandoned': abandoned,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? sessionType,
    Value<int>? intensity,
    Value<int>? durationSeconds,
    Value<bool>? abandoned,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      sessionType: sessionType ?? this.sessionType,
      intensity: intensity ?? this.intensity,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      abandoned: abandoned ?? this.abandoned,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (intensity.present) {
      map['intensity'] = Variable<int>(intensity.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (abandoned.present) {
      map['abandoned'] = Variable<bool>(abandoned.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('sessionType: $sessionType, ')
          ..write('intensity: $intensity, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('abandoned: $abandoned, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DailyPlansTable extends DailyPlans
    with TableInfo<$DailyPlansTable, DailyPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _planDateMeta = const VerificationMeta(
    'planDate',
  );
  @override
  late final GeneratedColumn<String> planDate = GeneratedColumn<String>(
    'plan_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _planJsonMeta = const VerificationMeta(
    'planJson',
  );
  @override
  late final GeneratedColumn<String> planJson = GeneratedColumn<String>(
    'plan_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _generatedAtMeta = const VerificationMeta(
    'generatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
    'generated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planDate,
    planJson,
    generatedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPlan> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('plan_date')) {
      context.handle(
        _planDateMeta,
        planDate.isAcceptableOrUnknown(data['plan_date']!, _planDateMeta),
      );
    } else if (isInserting) {
      context.missing(_planDateMeta);
    }
    if (data.containsKey('plan_json')) {
      context.handle(
        _planJsonMeta,
        planJson.isAcceptableOrUnknown(data['plan_json']!, _planJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_planJsonMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
        _generatedAtMeta,
        generatedAt.isAcceptableOrUnknown(
          data['generated_at']!,
          _generatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPlan(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      planDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_date'],
      )!,
      planJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_json'],
      )!,
      generatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}generated_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $DailyPlansTable createAlias(String alias) {
    return $DailyPlansTable(attachedDatabase, alias);
  }
}

class DailyPlan extends DataClass implements Insertable<DailyPlan> {
  final int id;
  final String planDate;
  final String planJson;
  final DateTime generatedAt;
  final DateTime createdAt;
  const DailyPlan({
    required this.id,
    required this.planDate,
    required this.planJson,
    required this.generatedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['plan_date'] = Variable<String>(planDate);
    map['plan_json'] = Variable<String>(planJson);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  DailyPlansCompanion toCompanion(bool nullToAbsent) {
    return DailyPlansCompanion(
      id: Value(id),
      planDate: Value(planDate),
      planJson: Value(planJson),
      generatedAt: Value(generatedAt),
      createdAt: Value(createdAt),
    );
  }

  factory DailyPlan.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPlan(
      id: serializer.fromJson<int>(json['id']),
      planDate: serializer.fromJson<String>(json['planDate']),
      planJson: serializer.fromJson<String>(json['planJson']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'planDate': serializer.toJson<String>(planDate),
      'planJson': serializer.toJson<String>(planJson),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  DailyPlan copyWith({
    int? id,
    String? planDate,
    String? planJson,
    DateTime? generatedAt,
    DateTime? createdAt,
  }) => DailyPlan(
    id: id ?? this.id,
    planDate: planDate ?? this.planDate,
    planJson: planJson ?? this.planJson,
    generatedAt: generatedAt ?? this.generatedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  DailyPlan copyWithCompanion(DailyPlansCompanion data) {
    return DailyPlan(
      id: data.id.present ? data.id.value : this.id,
      planDate: data.planDate.present ? data.planDate.value : this.planDate,
      planJson: data.planJson.present ? data.planJson.value : this.planJson,
      generatedAt: data.generatedAt.present
          ? data.generatedAt.value
          : this.generatedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlan(')
          ..write('id: $id, ')
          ..write('planDate: $planDate, ')
          ..write('planJson: $planJson, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, planDate, planJson, generatedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPlan &&
          other.id == this.id &&
          other.planDate == this.planDate &&
          other.planJson == this.planJson &&
          other.generatedAt == this.generatedAt &&
          other.createdAt == this.createdAt);
}

class DailyPlansCompanion extends UpdateCompanion<DailyPlan> {
  final Value<int> id;
  final Value<String> planDate;
  final Value<String> planJson;
  final Value<DateTime> generatedAt;
  final Value<DateTime> createdAt;
  const DailyPlansCompanion({
    this.id = const Value.absent(),
    this.planDate = const Value.absent(),
    this.planJson = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  DailyPlansCompanion.insert({
    this.id = const Value.absent(),
    required String planDate,
    required String planJson,
    required DateTime generatedAt,
    required DateTime createdAt,
  }) : planDate = Value(planDate),
       planJson = Value(planJson),
       generatedAt = Value(generatedAt),
       createdAt = Value(createdAt);
  static Insertable<DailyPlan> custom({
    Expression<int>? id,
    Expression<String>? planDate,
    Expression<String>? planJson,
    Expression<DateTime>? generatedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planDate != null) 'plan_date': planDate,
      if (planJson != null) 'plan_json': planJson,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  DailyPlansCompanion copyWith({
    Value<int>? id,
    Value<String>? planDate,
    Value<String>? planJson,
    Value<DateTime>? generatedAt,
    Value<DateTime>? createdAt,
  }) {
    return DailyPlansCompanion(
      id: id ?? this.id,
      planDate: planDate ?? this.planDate,
      planJson: planJson ?? this.planJson,
      generatedAt: generatedAt ?? this.generatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (planDate.present) {
      map['plan_date'] = Variable<String>(planDate.value);
    }
    if (planJson.present) {
      map['plan_json'] = Variable<String>(planJson.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlansCompanion(')
          ..write('id: $id, ')
          ..write('planDate: $planDate, ')
          ..write('planJson: $planJson, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $UserProfileTable extends UserProfile
    with TableInfo<$UserProfileTable, UserProfileData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fitnessGoalMeta = const VerificationMeta(
    'fitnessGoal',
  );
  @override
  late final GeneratedColumn<String> fitnessGoal = GeneratedColumn<String>(
    'fitness_goal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weeklySessionTargetMeta =
      const VerificationMeta('weeklySessionTarget');
  @override
  late final GeneratedColumn<int> weeklySessionTarget = GeneratedColumn<int>(
    'weekly_session_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _intensityPreferenceMeta =
      const VerificationMeta('intensityPreference');
  @override
  late final GeneratedColumn<String> intensityPreference =
      GeneratedColumn<String>(
        'intensity_preference',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _environmentPreferenceMeta =
      const VerificationMeta('environmentPreference');
  @override
  late final GeneratedColumn<String> environmentPreference =
      GeneratedColumn<String>(
        'environment_preference',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _onboardingCompletedMeta =
      const VerificationMeta('onboardingCompleted');
  @override
  late final GeneratedColumn<bool> onboardingCompleted = GeneratedColumn<bool>(
    'onboarding_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fitnessGoal,
    weeklySessionTarget,
    intensityPreference,
    environmentPreference,
    onboardingCompleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfileData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('fitness_goal')) {
      context.handle(
        _fitnessGoalMeta,
        fitnessGoal.isAcceptableOrUnknown(
          data['fitness_goal']!,
          _fitnessGoalMeta,
        ),
      );
    }
    if (data.containsKey('weekly_session_target')) {
      context.handle(
        _weeklySessionTargetMeta,
        weeklySessionTarget.isAcceptableOrUnknown(
          data['weekly_session_target']!,
          _weeklySessionTargetMeta,
        ),
      );
    }
    if (data.containsKey('intensity_preference')) {
      context.handle(
        _intensityPreferenceMeta,
        intensityPreference.isAcceptableOrUnknown(
          data['intensity_preference']!,
          _intensityPreferenceMeta,
        ),
      );
    }
    if (data.containsKey('environment_preference')) {
      context.handle(
        _environmentPreferenceMeta,
        environmentPreference.isAcceptableOrUnknown(
          data['environment_preference']!,
          _environmentPreferenceMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_completed')) {
      context.handle(
        _onboardingCompletedMeta,
        onboardingCompleted.isAcceptableOrUnknown(
          data['onboarding_completed']!,
          _onboardingCompletedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfileData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfileData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fitnessGoal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fitness_goal'],
      ),
      weeklySessionTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekly_session_target'],
      )!,
      intensityPreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}intensity_preference'],
      ),
      environmentPreference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment_preference'],
      ),
      onboardingCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserProfileTable createAlias(String alias) {
    return $UserProfileTable(attachedDatabase, alias);
  }
}

class UserProfileData extends DataClass implements Insertable<UserProfileData> {
  final int id;
  final String? fitnessGoal;
  final int weeklySessionTarget;
  final String? intensityPreference;
  final String? environmentPreference;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserProfileData({
    required this.id,
    this.fitnessGoal,
    required this.weeklySessionTarget,
    this.intensityPreference,
    this.environmentPreference,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || fitnessGoal != null) {
      map['fitness_goal'] = Variable<String>(fitnessGoal);
    }
    map['weekly_session_target'] = Variable<int>(weeklySessionTarget);
    if (!nullToAbsent || intensityPreference != null) {
      map['intensity_preference'] = Variable<String>(intensityPreference);
    }
    if (!nullToAbsent || environmentPreference != null) {
      map['environment_preference'] = Variable<String>(environmentPreference);
    }
    map['onboarding_completed'] = Variable<bool>(onboardingCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfileCompanion toCompanion(bool nullToAbsent) {
    return UserProfileCompanion(
      id: Value(id),
      fitnessGoal: fitnessGoal == null && nullToAbsent
          ? const Value.absent()
          : Value(fitnessGoal),
      weeklySessionTarget: Value(weeklySessionTarget),
      intensityPreference: intensityPreference == null && nullToAbsent
          ? const Value.absent()
          : Value(intensityPreference),
      environmentPreference: environmentPreference == null && nullToAbsent
          ? const Value.absent()
          : Value(environmentPreference),
      onboardingCompleted: Value(onboardingCompleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfileData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfileData(
      id: serializer.fromJson<int>(json['id']),
      fitnessGoal: serializer.fromJson<String?>(json['fitnessGoal']),
      weeklySessionTarget: serializer.fromJson<int>(
        json['weeklySessionTarget'],
      ),
      intensityPreference: serializer.fromJson<String?>(
        json['intensityPreference'],
      ),
      environmentPreference: serializer.fromJson<String?>(
        json['environmentPreference'],
      ),
      onboardingCompleted: serializer.fromJson<bool>(
        json['onboardingCompleted'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fitnessGoal': serializer.toJson<String?>(fitnessGoal),
      'weeklySessionTarget': serializer.toJson<int>(weeklySessionTarget),
      'intensityPreference': serializer.toJson<String?>(intensityPreference),
      'environmentPreference': serializer.toJson<String?>(
        environmentPreference,
      ),
      'onboardingCompleted': serializer.toJson<bool>(onboardingCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfileData copyWith({
    int? id,
    Value<String?> fitnessGoal = const Value.absent(),
    int? weeklySessionTarget,
    Value<String?> intensityPreference = const Value.absent(),
    Value<String?> environmentPreference = const Value.absent(),
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfileData(
    id: id ?? this.id,
    fitnessGoal: fitnessGoal.present ? fitnessGoal.value : this.fitnessGoal,
    weeklySessionTarget: weeklySessionTarget ?? this.weeklySessionTarget,
    intensityPreference: intensityPreference.present
        ? intensityPreference.value
        : this.intensityPreference,
    environmentPreference: environmentPreference.present
        ? environmentPreference.value
        : this.environmentPreference,
    onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserProfileData copyWithCompanion(UserProfileCompanion data) {
    return UserProfileData(
      id: data.id.present ? data.id.value : this.id,
      fitnessGoal: data.fitnessGoal.present
          ? data.fitnessGoal.value
          : this.fitnessGoal,
      weeklySessionTarget: data.weeklySessionTarget.present
          ? data.weeklySessionTarget.value
          : this.weeklySessionTarget,
      intensityPreference: data.intensityPreference.present
          ? data.intensityPreference.value
          : this.intensityPreference,
      environmentPreference: data.environmentPreference.present
          ? data.environmentPreference.value
          : this.environmentPreference,
      onboardingCompleted: data.onboardingCompleted.present
          ? data.onboardingCompleted.value
          : this.onboardingCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileData(')
          ..write('id: $id, ')
          ..write('fitnessGoal: $fitnessGoal, ')
          ..write('weeklySessionTarget: $weeklySessionTarget, ')
          ..write('intensityPreference: $intensityPreference, ')
          ..write('environmentPreference: $environmentPreference, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    fitnessGoal,
    weeklySessionTarget,
    intensityPreference,
    environmentPreference,
    onboardingCompleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfileData &&
          other.id == this.id &&
          other.fitnessGoal == this.fitnessGoal &&
          other.weeklySessionTarget == this.weeklySessionTarget &&
          other.intensityPreference == this.intensityPreference &&
          other.environmentPreference == this.environmentPreference &&
          other.onboardingCompleted == this.onboardingCompleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfileCompanion extends UpdateCompanion<UserProfileData> {
  final Value<int> id;
  final Value<String?> fitnessGoal;
  final Value<int> weeklySessionTarget;
  final Value<String?> intensityPreference;
  final Value<String?> environmentPreference;
  final Value<bool> onboardingCompleted;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const UserProfileCompanion({
    this.id = const Value.absent(),
    this.fitnessGoal = const Value.absent(),
    this.weeklySessionTarget = const Value.absent(),
    this.intensityPreference = const Value.absent(),
    this.environmentPreference = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserProfileCompanion.insert({
    this.id = const Value.absent(),
    this.fitnessGoal = const Value.absent(),
    this.weeklySessionTarget = const Value.absent(),
    this.intensityPreference = const Value.absent(),
    this.environmentPreference = const Value.absent(),
    this.onboardingCompleted = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserProfileData> custom({
    Expression<int>? id,
    Expression<String>? fitnessGoal,
    Expression<int>? weeklySessionTarget,
    Expression<String>? intensityPreference,
    Expression<String>? environmentPreference,
    Expression<bool>? onboardingCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fitnessGoal != null) 'fitness_goal': fitnessGoal,
      if (weeklySessionTarget != null)
        'weekly_session_target': weeklySessionTarget,
      if (intensityPreference != null)
        'intensity_preference': intensityPreference,
      if (environmentPreference != null)
        'environment_preference': environmentPreference,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserProfileCompanion copyWith({
    Value<int>? id,
    Value<String?>? fitnessGoal,
    Value<int>? weeklySessionTarget,
    Value<String?>? intensityPreference,
    Value<String?>? environmentPreference,
    Value<bool>? onboardingCompleted,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return UserProfileCompanion(
      id: id ?? this.id,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      weeklySessionTarget: weeklySessionTarget ?? this.weeklySessionTarget,
      intensityPreference: intensityPreference ?? this.intensityPreference,
      environmentPreference:
          environmentPreference ?? this.environmentPreference,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fitnessGoal.present) {
      map['fitness_goal'] = Variable<String>(fitnessGoal.value);
    }
    if (weeklySessionTarget.present) {
      map['weekly_session_target'] = Variable<int>(weeklySessionTarget.value);
    }
    if (intensityPreference.present) {
      map['intensity_preference'] = Variable<String>(intensityPreference.value);
    }
    if (environmentPreference.present) {
      map['environment_preference'] = Variable<String>(
        environmentPreference.value,
      );
    }
    if (onboardingCompleted.present) {
      map['onboarding_completed'] = Variable<bool>(onboardingCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfileCompanion(')
          ..write('id: $id, ')
          ..write('fitnessGoal: $fitnessGoal, ')
          ..write('weeklySessionTarget: $weeklySessionTarget, ')
          ..write('intensityPreference: $intensityPreference, ')
          ..write('environmentPreference: $environmentPreference, ')
          ..write('onboardingCompleted: $onboardingCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RpeFeedbackTable extends RpeFeedback
    with TableInfo<$RpeFeedbackTable, RpeFeedbackData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RpeFeedbackTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rpeValueMeta = const VerificationMeta(
    'rpeValue',
  );
  @override
  late final GeneratedColumn<int> rpeValue = GeneratedColumn<int>(
    'rpe_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, sessionId, rpeValue, recordedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rpe_feedback';
  @override
  VerificationContext validateIntegrity(
    Insertable<RpeFeedbackData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('rpe_value')) {
      context.handle(
        _rpeValueMeta,
        rpeValue.isAcceptableOrUnknown(data['rpe_value']!, _rpeValueMeta),
      );
    } else if (isInserting) {
      context.missing(_rpeValueMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RpeFeedbackData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RpeFeedbackData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      rpeValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rpe_value'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $RpeFeedbackTable createAlias(String alias) {
    return $RpeFeedbackTable(attachedDatabase, alias);
  }
}

class RpeFeedbackData extends DataClass implements Insertable<RpeFeedbackData> {
  final int id;
  final int sessionId;
  final int rpeValue;
  final DateTime recordedAt;
  const RpeFeedbackData({
    required this.id,
    required this.sessionId,
    required this.rpeValue,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    map['rpe_value'] = Variable<int>(rpeValue);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    return map;
  }

  RpeFeedbackCompanion toCompanion(bool nullToAbsent) {
    return RpeFeedbackCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      rpeValue: Value(rpeValue),
      recordedAt: Value(recordedAt),
    );
  }

  factory RpeFeedbackData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RpeFeedbackData(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      rpeValue: serializer.fromJson<int>(json['rpeValue']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'rpeValue': serializer.toJson<int>(rpeValue),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
    };
  }

  RpeFeedbackData copyWith({
    int? id,
    int? sessionId,
    int? rpeValue,
    DateTime? recordedAt,
  }) => RpeFeedbackData(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    rpeValue: rpeValue ?? this.rpeValue,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  RpeFeedbackData copyWithCompanion(RpeFeedbackCompanion data) {
    return RpeFeedbackData(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      rpeValue: data.rpeValue.present ? data.rpeValue.value : this.rpeValue,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RpeFeedbackData(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('rpeValue: $rpeValue, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sessionId, rpeValue, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RpeFeedbackData &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.rpeValue == this.rpeValue &&
          other.recordedAt == this.recordedAt);
}

class RpeFeedbackCompanion extends UpdateCompanion<RpeFeedbackData> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<int> rpeValue;
  final Value<DateTime> recordedAt;
  const RpeFeedbackCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.rpeValue = const Value.absent(),
    this.recordedAt = const Value.absent(),
  });
  RpeFeedbackCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    required int rpeValue,
    required DateTime recordedAt,
  }) : sessionId = Value(sessionId),
       rpeValue = Value(rpeValue),
       recordedAt = Value(recordedAt);
  static Insertable<RpeFeedbackData> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<int>? rpeValue,
    Expression<DateTime>? recordedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (rpeValue != null) 'rpe_value': rpeValue,
      if (recordedAt != null) 'recorded_at': recordedAt,
    });
  }

  RpeFeedbackCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<int>? rpeValue,
    Value<DateTime>? recordedAt,
  }) {
    return RpeFeedbackCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      rpeValue: rpeValue ?? this.rpeValue,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (rpeValue.present) {
      map['rpe_value'] = Variable<int>(rpeValue.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RpeFeedbackCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('rpeValue: $rpeValue, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }
}

class $BanditStateTable extends BanditState
    with TableInfo<$BanditStateTable, BanditStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BanditStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _armWeightsJsonMeta = const VerificationMeta(
    'armWeightsJson',
  );
  @override
  late final GeneratedColumn<String> armWeightsJson = GeneratedColumn<String>(
    'arm_weights_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, armWeightsJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bandit_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<BanditStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('arm_weights_json')) {
      context.handle(
        _armWeightsJsonMeta,
        armWeightsJson.isAcceptableOrUnknown(
          data['arm_weights_json']!,
          _armWeightsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_armWeightsJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BanditStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BanditStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      armWeightsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arm_weights_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BanditStateTable createAlias(String alias) {
    return $BanditStateTable(attachedDatabase, alias);
  }
}

class BanditStateData extends DataClass implements Insertable<BanditStateData> {
  final int id;
  final String armWeightsJson;
  final DateTime updatedAt;
  const BanditStateData({
    required this.id,
    required this.armWeightsJson,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['arm_weights_json'] = Variable<String>(armWeightsJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BanditStateCompanion toCompanion(bool nullToAbsent) {
    return BanditStateCompanion(
      id: Value(id),
      armWeightsJson: Value(armWeightsJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory BanditStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BanditStateData(
      id: serializer.fromJson<int>(json['id']),
      armWeightsJson: serializer.fromJson<String>(json['armWeightsJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'armWeightsJson': serializer.toJson<String>(armWeightsJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BanditStateData copyWith({
    int? id,
    String? armWeightsJson,
    DateTime? updatedAt,
  }) => BanditStateData(
    id: id ?? this.id,
    armWeightsJson: armWeightsJson ?? this.armWeightsJson,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BanditStateData copyWithCompanion(BanditStateCompanion data) {
    return BanditStateData(
      id: data.id.present ? data.id.value : this.id,
      armWeightsJson: data.armWeightsJson.present
          ? data.armWeightsJson.value
          : this.armWeightsJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BanditStateData(')
          ..write('id: $id, ')
          ..write('armWeightsJson: $armWeightsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, armWeightsJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BanditStateData &&
          other.id == this.id &&
          other.armWeightsJson == this.armWeightsJson &&
          other.updatedAt == this.updatedAt);
}

class BanditStateCompanion extends UpdateCompanion<BanditStateData> {
  final Value<int> id;
  final Value<String> armWeightsJson;
  final Value<DateTime> updatedAt;
  const BanditStateCompanion({
    this.id = const Value.absent(),
    this.armWeightsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BanditStateCompanion.insert({
    this.id = const Value.absent(),
    required String armWeightsJson,
    required DateTime updatedAt,
  }) : armWeightsJson = Value(armWeightsJson),
       updatedAt = Value(updatedAt);
  static Insertable<BanditStateData> custom({
    Expression<int>? id,
    Expression<String>? armWeightsJson,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (armWeightsJson != null) 'arm_weights_json': armWeightsJson,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BanditStateCompanion copyWith({
    Value<int>? id,
    Value<String>? armWeightsJson,
    Value<DateTime>? updatedAt,
  }) {
    return BanditStateCompanion(
      id: id ?? this.id,
      armWeightsJson: armWeightsJson ?? this.armWeightsJson,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (armWeightsJson.present) {
      map['arm_weights_json'] = Variable<String>(armWeightsJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BanditStateCompanion(')
          ..write('id: $id, ')
          ..write('armWeightsJson: $armWeightsJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $BehavioralStateTable extends BehavioralState
    with TableInfo<$BehavioralStateTable, BehavioralStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BehavioralStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _currentStateMeta = const VerificationMeta(
    'currentState',
  );
  @override
  late final GeneratedColumn<String> currentState = GeneratedColumn<String>(
    'current_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _restingHrMeta = const VerificationMeta(
    'restingHr',
  );
  @override
  late final GeneratedColumn<int> restingHr = GeneratedColumn<int>(
    'resting_hr',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stepCountMeta = const VerificationMeta(
    'stepCount',
  );
  @override
  late final GeneratedColumn<int> stepCount = GeneratedColumn<int>(
    'step_count',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _streakCountMeta = const VerificationMeta(
    'streakCount',
  );
  @override
  late final GeneratedColumn<int> streakCount = GeneratedColumn<int>(
    'streak_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    currentState,
    restingHr,
    stepCount,
    streakCount,
    recordedAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'behavioral_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<BehavioralStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('current_state')) {
      context.handle(
        _currentStateMeta,
        currentState.isAcceptableOrUnknown(
          data['current_state']!,
          _currentStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentStateMeta);
    }
    if (data.containsKey('resting_hr')) {
      context.handle(
        _restingHrMeta,
        restingHr.isAcceptableOrUnknown(data['resting_hr']!, _restingHrMeta),
      );
    }
    if (data.containsKey('step_count')) {
      context.handle(
        _stepCountMeta,
        stepCount.isAcceptableOrUnknown(data['step_count']!, _stepCountMeta),
      );
    }
    if (data.containsKey('streak_count')) {
      context.handle(
        _streakCountMeta,
        streakCount.isAcceptableOrUnknown(
          data['streak_count']!,
          _streakCountMeta,
        ),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BehavioralStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BehavioralStateData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      currentState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_state'],
      )!,
      restingHr: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resting_hr'],
      ),
      stepCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_count'],
      ),
      streakCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_count'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $BehavioralStateTable createAlias(String alias) {
    return $BehavioralStateTable(attachedDatabase, alias);
  }
}

class BehavioralStateData extends DataClass
    implements Insertable<BehavioralStateData> {
  final int id;
  final String currentState;
  final int? restingHr;
  final int? stepCount;
  final int streakCount;
  final DateTime recordedAt;
  final DateTime updatedAt;
  const BehavioralStateData({
    required this.id,
    required this.currentState,
    this.restingHr,
    this.stepCount,
    required this.streakCount,
    required this.recordedAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['current_state'] = Variable<String>(currentState);
    if (!nullToAbsent || restingHr != null) {
      map['resting_hr'] = Variable<int>(restingHr);
    }
    if (!nullToAbsent || stepCount != null) {
      map['step_count'] = Variable<int>(stepCount);
    }
    map['streak_count'] = Variable<int>(streakCount);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BehavioralStateCompanion toCompanion(bool nullToAbsent) {
    return BehavioralStateCompanion(
      id: Value(id),
      currentState: Value(currentState),
      restingHr: restingHr == null && nullToAbsent
          ? const Value.absent()
          : Value(restingHr),
      stepCount: stepCount == null && nullToAbsent
          ? const Value.absent()
          : Value(stepCount),
      streakCount: Value(streakCount),
      recordedAt: Value(recordedAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BehavioralStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BehavioralStateData(
      id: serializer.fromJson<int>(json['id']),
      currentState: serializer.fromJson<String>(json['currentState']),
      restingHr: serializer.fromJson<int?>(json['restingHr']),
      stepCount: serializer.fromJson<int?>(json['stepCount']),
      streakCount: serializer.fromJson<int>(json['streakCount']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'currentState': serializer.toJson<String>(currentState),
      'restingHr': serializer.toJson<int?>(restingHr),
      'stepCount': serializer.toJson<int?>(stepCount),
      'streakCount': serializer.toJson<int>(streakCount),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BehavioralStateData copyWith({
    int? id,
    String? currentState,
    Value<int?> restingHr = const Value.absent(),
    Value<int?> stepCount = const Value.absent(),
    int? streakCount,
    DateTime? recordedAt,
    DateTime? updatedAt,
  }) => BehavioralStateData(
    id: id ?? this.id,
    currentState: currentState ?? this.currentState,
    restingHr: restingHr.present ? restingHr.value : this.restingHr,
    stepCount: stepCount.present ? stepCount.value : this.stepCount,
    streakCount: streakCount ?? this.streakCount,
    recordedAt: recordedAt ?? this.recordedAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BehavioralStateData copyWithCompanion(BehavioralStateCompanion data) {
    return BehavioralStateData(
      id: data.id.present ? data.id.value : this.id,
      currentState: data.currentState.present
          ? data.currentState.value
          : this.currentState,
      restingHr: data.restingHr.present ? data.restingHr.value : this.restingHr,
      stepCount: data.stepCount.present ? data.stepCount.value : this.stepCount,
      streakCount: data.streakCount.present
          ? data.streakCount.value
          : this.streakCount,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BehavioralStateData(')
          ..write('id: $id, ')
          ..write('currentState: $currentState, ')
          ..write('restingHr: $restingHr, ')
          ..write('stepCount: $stepCount, ')
          ..write('streakCount: $streakCount, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    currentState,
    restingHr,
    stepCount,
    streakCount,
    recordedAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BehavioralStateData &&
          other.id == this.id &&
          other.currentState == this.currentState &&
          other.restingHr == this.restingHr &&
          other.stepCount == this.stepCount &&
          other.streakCount == this.streakCount &&
          other.recordedAt == this.recordedAt &&
          other.updatedAt == this.updatedAt);
}

class BehavioralStateCompanion extends UpdateCompanion<BehavioralStateData> {
  final Value<int> id;
  final Value<String> currentState;
  final Value<int?> restingHr;
  final Value<int?> stepCount;
  final Value<int> streakCount;
  final Value<DateTime> recordedAt;
  final Value<DateTime> updatedAt;
  const BehavioralStateCompanion({
    this.id = const Value.absent(),
    this.currentState = const Value.absent(),
    this.restingHr = const Value.absent(),
    this.stepCount = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  BehavioralStateCompanion.insert({
    this.id = const Value.absent(),
    required String currentState,
    this.restingHr = const Value.absent(),
    this.stepCount = const Value.absent(),
    this.streakCount = const Value.absent(),
    required DateTime recordedAt,
    required DateTime updatedAt,
  }) : currentState = Value(currentState),
       recordedAt = Value(recordedAt),
       updatedAt = Value(updatedAt);
  static Insertable<BehavioralStateData> custom({
    Expression<int>? id,
    Expression<String>? currentState,
    Expression<int>? restingHr,
    Expression<int>? stepCount,
    Expression<int>? streakCount,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (currentState != null) 'current_state': currentState,
      if (restingHr != null) 'resting_hr': restingHr,
      if (stepCount != null) 'step_count': stepCount,
      if (streakCount != null) 'streak_count': streakCount,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  BehavioralStateCompanion copyWith({
    Value<int>? id,
    Value<String>? currentState,
    Value<int?>? restingHr,
    Value<int?>? stepCount,
    Value<int>? streakCount,
    Value<DateTime>? recordedAt,
    Value<DateTime>? updatedAt,
  }) {
    return BehavioralStateCompanion(
      id: id ?? this.id,
      currentState: currentState ?? this.currentState,
      restingHr: restingHr ?? this.restingHr,
      stepCount: stepCount ?? this.stepCount,
      streakCount: streakCount ?? this.streakCount,
      recordedAt: recordedAt ?? this.recordedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (currentState.present) {
      map['current_state'] = Variable<String>(currentState.value);
    }
    if (restingHr.present) {
      map['resting_hr'] = Variable<int>(restingHr.value);
    }
    if (stepCount.present) {
      map['step_count'] = Variable<int>(stepCount.value);
    }
    if (streakCount.present) {
      map['streak_count'] = Variable<int>(streakCount.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BehavioralStateCompanion(')
          ..write('id: $id, ')
          ..write('currentState: $currentState, ')
          ..write('restingHr: $restingHr, ')
          ..write('stepCount: $stepCount, ')
          ..write('streakCount: $streakCount, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $WeatherCacheTable extends WeatherCache
    with TableInfo<$WeatherCacheTable, WeatherCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeatherCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _temperatureMeta = const VerificationMeta(
    'temperature',
  );
  @override
  late final GeneratedColumn<double> temperature = GeneratedColumn<double>(
    'temperature',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precipitationProbabilityMeta =
      const VerificationMeta('precipitationProbability');
  @override
  late final GeneratedColumn<double> precipitationProbability =
      GeneratedColumn<double>(
        'precipitation_probability',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _aqiValueMeta = const VerificationMeta(
    'aqiValue',
  );
  @override
  late final GeneratedColumn<int> aqiValue = GeneratedColumn<int>(
    'aqi_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    latitude,
    longitude,
    temperature,
    precipitationProbability,
    aqiValue,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weather_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeatherCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('temperature')) {
      context.handle(
        _temperatureMeta,
        temperature.isAcceptableOrUnknown(
          data['temperature']!,
          _temperatureMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_temperatureMeta);
    }
    if (data.containsKey('precipitation_probability')) {
      context.handle(
        _precipitationProbabilityMeta,
        precipitationProbability.isAcceptableOrUnknown(
          data['precipitation_probability']!,
          _precipitationProbabilityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_precipitationProbabilityMeta);
    }
    if (data.containsKey('aqi_value')) {
      context.handle(
        _aqiValueMeta,
        aqiValue.isAcceptableOrUnknown(data['aqi_value']!, _aqiValueMeta),
      );
    } else if (isInserting) {
      context.missing(_aqiValueMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeatherCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeatherCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      temperature: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature'],
      )!,
      precipitationProbability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}precipitation_probability'],
      )!,
      aqiValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}aqi_value'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $WeatherCacheTable createAlias(String alias) {
    return $WeatherCacheTable(attachedDatabase, alias);
  }
}

class WeatherCacheData extends DataClass
    implements Insertable<WeatherCacheData> {
  final int id;
  final double latitude;
  final double longitude;
  final double temperature;
  final double precipitationProbability;
  final int aqiValue;
  final DateTime cachedAt;
  const WeatherCacheData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.temperature,
    required this.precipitationProbability,
    required this.aqiValue,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['temperature'] = Variable<double>(temperature);
    map['precipitation_probability'] = Variable<double>(
      precipitationProbability,
    );
    map['aqi_value'] = Variable<int>(aqiValue);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  WeatherCacheCompanion toCompanion(bool nullToAbsent) {
    return WeatherCacheCompanion(
      id: Value(id),
      latitude: Value(latitude),
      longitude: Value(longitude),
      temperature: Value(temperature),
      precipitationProbability: Value(precipitationProbability),
      aqiValue: Value(aqiValue),
      cachedAt: Value(cachedAt),
    );
  }

  factory WeatherCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeatherCacheData(
      id: serializer.fromJson<int>(json['id']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      temperature: serializer.fromJson<double>(json['temperature']),
      precipitationProbability: serializer.fromJson<double>(
        json['precipitationProbability'],
      ),
      aqiValue: serializer.fromJson<int>(json['aqiValue']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'temperature': serializer.toJson<double>(temperature),
      'precipitationProbability': serializer.toJson<double>(
        precipitationProbability,
      ),
      'aqiValue': serializer.toJson<int>(aqiValue),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  WeatherCacheData copyWith({
    int? id,
    double? latitude,
    double? longitude,
    double? temperature,
    double? precipitationProbability,
    int? aqiValue,
    DateTime? cachedAt,
  }) => WeatherCacheData(
    id: id ?? this.id,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    temperature: temperature ?? this.temperature,
    precipitationProbability:
        precipitationProbability ?? this.precipitationProbability,
    aqiValue: aqiValue ?? this.aqiValue,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  WeatherCacheData copyWithCompanion(WeatherCacheCompanion data) {
    return WeatherCacheData(
      id: data.id.present ? data.id.value : this.id,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      temperature: data.temperature.present
          ? data.temperature.value
          : this.temperature,
      precipitationProbability: data.precipitationProbability.present
          ? data.precipitationProbability.value
          : this.precipitationProbability,
      aqiValue: data.aqiValue.present ? data.aqiValue.value : this.aqiValue,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCacheData(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('temperature: $temperature, ')
          ..write('precipitationProbability: $precipitationProbability, ')
          ..write('aqiValue: $aqiValue, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    latitude,
    longitude,
    temperature,
    precipitationProbability,
    aqiValue,
    cachedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeatherCacheData &&
          other.id == this.id &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.temperature == this.temperature &&
          other.precipitationProbability == this.precipitationProbability &&
          other.aqiValue == this.aqiValue &&
          other.cachedAt == this.cachedAt);
}

class WeatherCacheCompanion extends UpdateCompanion<WeatherCacheData> {
  final Value<int> id;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> temperature;
  final Value<double> precipitationProbability;
  final Value<int> aqiValue;
  final Value<DateTime> cachedAt;
  const WeatherCacheCompanion({
    this.id = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.temperature = const Value.absent(),
    this.precipitationProbability = const Value.absent(),
    this.aqiValue = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  WeatherCacheCompanion.insert({
    this.id = const Value.absent(),
    required double latitude,
    required double longitude,
    required double temperature,
    required double precipitationProbability,
    required int aqiValue,
    required DateTime cachedAt,
  }) : latitude = Value(latitude),
       longitude = Value(longitude),
       temperature = Value(temperature),
       precipitationProbability = Value(precipitationProbability),
       aqiValue = Value(aqiValue),
       cachedAt = Value(cachedAt);
  static Insertable<WeatherCacheData> custom({
    Expression<int>? id,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? temperature,
    Expression<double>? precipitationProbability,
    Expression<int>? aqiValue,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (temperature != null) 'temperature': temperature,
      if (precipitationProbability != null)
        'precipitation_probability': precipitationProbability,
      if (aqiValue != null) 'aqi_value': aqiValue,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  WeatherCacheCompanion copyWith({
    Value<int>? id,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? temperature,
    Value<double>? precipitationProbability,
    Value<int>? aqiValue,
    Value<DateTime>? cachedAt,
  }) {
    return WeatherCacheCompanion(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      temperature: temperature ?? this.temperature,
      precipitationProbability:
          precipitationProbability ?? this.precipitationProbability,
      aqiValue: aqiValue ?? this.aqiValue,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (temperature.present) {
      map['temperature'] = Variable<double>(temperature.value);
    }
    if (precipitationProbability.present) {
      map['precipitation_probability'] = Variable<double>(
        precipitationProbability.value,
      );
    }
    if (aqiValue.present) {
      map['aqi_value'] = Variable<int>(aqiValue.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeatherCacheCompanion(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('temperature: $temperature, ')
          ..write('precipitationProbability: $precipitationProbability, ')
          ..write('aqiValue: $aqiValue, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $ExerciseCacheTable extends ExerciseCache
    with TableInfo<$ExerciseCacheTable, ExerciseCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExerciseCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _exerciseJsonMeta = const VerificationMeta(
    'exerciseJson',
  );
  @override
  late final GeneratedColumn<String> exerciseJson = GeneratedColumn<String>(
    'exercise_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cachedAtMeta = const VerificationMeta(
    'cachedAt',
  );
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
    'cached_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    exerciseId,
    exerciseJson,
    cachedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercise_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExerciseCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('exercise_json')) {
      context.handle(
        _exerciseJsonMeta,
        exerciseJson.isAcceptableOrUnknown(
          data['exercise_json']!,
          _exerciseJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_exerciseJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(
        _cachedAtMeta,
        cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExerciseCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExerciseCacheData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      exerciseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_json'],
      )!,
      cachedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cached_at'],
      )!,
    );
  }

  @override
  $ExerciseCacheTable createAlias(String alias) {
    return $ExerciseCacheTable(attachedDatabase, alias);
  }
}

class ExerciseCacheData extends DataClass
    implements Insertable<ExerciseCacheData> {
  final int id;
  final String exerciseId;
  final String exerciseJson;
  final DateTime cachedAt;
  const ExerciseCacheData({
    required this.id,
    required this.exerciseId,
    required this.exerciseJson,
    required this.cachedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['exercise_json'] = Variable<String>(exerciseJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  ExerciseCacheCompanion toCompanion(bool nullToAbsent) {
    return ExerciseCacheCompanion(
      id: Value(id),
      exerciseId: Value(exerciseId),
      exerciseJson: Value(exerciseJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory ExerciseCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExerciseCacheData(
      id: serializer.fromJson<int>(json['id']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      exerciseJson: serializer.fromJson<String>(json['exerciseJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'exerciseJson': serializer.toJson<String>(exerciseJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  ExerciseCacheData copyWith({
    int? id,
    String? exerciseId,
    String? exerciseJson,
    DateTime? cachedAt,
  }) => ExerciseCacheData(
    id: id ?? this.id,
    exerciseId: exerciseId ?? this.exerciseId,
    exerciseJson: exerciseJson ?? this.exerciseJson,
    cachedAt: cachedAt ?? this.cachedAt,
  );
  ExerciseCacheData copyWithCompanion(ExerciseCacheCompanion data) {
    return ExerciseCacheData(
      id: data.id.present ? data.id.value : this.id,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      exerciseJson: data.exerciseJson.present
          ? data.exerciseJson.value
          : this.exerciseJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseCacheData(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseJson: $exerciseJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, exerciseId, exerciseJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExerciseCacheData &&
          other.id == this.id &&
          other.exerciseId == this.exerciseId &&
          other.exerciseJson == this.exerciseJson &&
          other.cachedAt == this.cachedAt);
}

class ExerciseCacheCompanion extends UpdateCompanion<ExerciseCacheData> {
  final Value<int> id;
  final Value<String> exerciseId;
  final Value<String> exerciseJson;
  final Value<DateTime> cachedAt;
  const ExerciseCacheCompanion({
    this.id = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.exerciseJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
  });
  ExerciseCacheCompanion.insert({
    this.id = const Value.absent(),
    required String exerciseId,
    required String exerciseJson,
    required DateTime cachedAt,
  }) : exerciseId = Value(exerciseId),
       exerciseJson = Value(exerciseJson),
       cachedAt = Value(cachedAt);
  static Insertable<ExerciseCacheData> custom({
    Expression<int>? id,
    Expression<String>? exerciseId,
    Expression<String>? exerciseJson,
    Expression<DateTime>? cachedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (exerciseJson != null) 'exercise_json': exerciseJson,
      if (cachedAt != null) 'cached_at': cachedAt,
    });
  }

  ExerciseCacheCompanion copyWith({
    Value<int>? id,
    Value<String>? exerciseId,
    Value<String>? exerciseJson,
    Value<DateTime>? cachedAt,
  }) {
    return ExerciseCacheCompanion(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseJson: exerciseJson ?? this.exerciseJson,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (exerciseJson.present) {
      map['exercise_json'] = Variable<String>(exerciseJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExerciseCacheCompanion(')
          ..write('id: $id, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('exerciseJson: $exerciseJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    eventType,
    payload,
    retryCount,
    nextRetryAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncQueueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueEntry extends DataClass implements Insertable<SyncQueueEntry> {
  final int id;
  final String eventType;
  final String payload;
  final int retryCount;
  final DateTime? nextRetryAt;
  final DateTime createdAt;
  const SyncQueueEntry({
    required this.id,
    required this.eventType,
    required this.payload,
    required this.retryCount,
    this.nextRetryAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['event_type'] = Variable<String>(eventType);
    map['payload'] = Variable<String>(payload);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      eventType: Value(eventType),
      payload: Value(payload),
      retryCount: Value(retryCount),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      createdAt: Value(createdAt),
    );
  }

  factory SyncQueueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueEntry(
      id: serializer.fromJson<int>(json['id']),
      eventType: serializer.fromJson<String>(json['eventType']),
      payload: serializer.fromJson<String>(json['payload']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'eventType': serializer.toJson<String>(eventType),
      'payload': serializer.toJson<String>(payload),
      'retryCount': serializer.toJson<int>(retryCount),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncQueueEntry copyWith({
    int? id,
    String? eventType,
    String? payload,
    int? retryCount,
    Value<DateTime?> nextRetryAt = const Value.absent(),
    DateTime? createdAt,
  }) => SyncQueueEntry(
    id: id ?? this.id,
    eventType: eventType ?? this.eventType,
    payload: payload ?? this.payload,
    retryCount: retryCount ?? this.retryCount,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncQueueEntry copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueEntry(
      id: data.id.present ? data.id.value : this.id,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      payload: data.payload.present ? data.payload.value : this.payload,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueEntry(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, eventType, payload, retryCount, nextRetryAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueEntry &&
          other.id == this.id &&
          other.eventType == this.eventType &&
          other.payload == this.payload &&
          other.retryCount == this.retryCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.createdAt == this.createdAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueEntry> {
  final Value<int> id;
  final Value<String> eventType;
  final Value<String> payload;
  final Value<int> retryCount;
  final Value<DateTime?> nextRetryAt;
  final Value<DateTime> createdAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.eventType = const Value.absent(),
    this.payload = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String eventType,
    required String payload,
    this.retryCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    required DateTime createdAt,
  }) : eventType = Value(eventType),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<SyncQueueEntry> custom({
    Expression<int>? id,
    Expression<String>? eventType,
    Expression<String>? payload,
    Expression<int>? retryCount,
    Expression<DateTime>? nextRetryAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (eventType != null) 'event_type': eventType,
      if (payload != null) 'payload': payload,
      if (retryCount != null) 'retry_count': retryCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SyncQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? eventType,
    Value<String>? payload,
    Value<int>? retryCount,
    Value<DateTime?>? nextRetryAt,
    Value<DateTime>? createdAt,
  }) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      eventType: eventType ?? this.eventType,
      payload: payload ?? this.payload,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('eventType: $eventType, ')
          ..write('payload: $payload, ')
          ..write('retryCount: $retryCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $DailyPlansTable dailyPlans = $DailyPlansTable(this);
  late final $UserProfileTable userProfile = $UserProfileTable(this);
  late final $RpeFeedbackTable rpeFeedback = $RpeFeedbackTable(this);
  late final $BanditStateTable banditState = $BanditStateTable(this);
  late final $BehavioralStateTable behavioralState = $BehavioralStateTable(
    this,
  );
  late final $WeatherCacheTable weatherCache = $WeatherCacheTable(this);
  late final $ExerciseCacheTable exerciseCache = $ExerciseCacheTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final SessionsDao sessionsDao = SessionsDao(this as AppDatabase);
  late final DailyPlansDao dailyPlansDao = DailyPlansDao(this as AppDatabase);
  late final UserProfileDao userProfileDao = UserProfileDao(
    this as AppDatabase,
  );
  late final RpeFeedbackDao rpeFeedbackDao = RpeFeedbackDao(
    this as AppDatabase,
  );
  late final BanditStateDao banditStateDao = BanditStateDao(
    this as AppDatabase,
  );
  late final BehavioralStateDao behavioralStateDao = BehavioralStateDao(
    this as AppDatabase,
  );
  late final WeatherCacheDao weatherCacheDao = WeatherCacheDao(
    this as AppDatabase,
  );
  late final ExerciseCacheDao exerciseCacheDao = ExerciseCacheDao(
    this as AppDatabase,
  );
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    dailyPlans,
    userProfile,
    rpeFeedback,
    banditState,
    behavioralState,
    weatherCache,
    exerciseCache,
    syncQueue,
  ];
}

typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      required String sessionType,
      required int intensity,
      required int durationSeconds,
      Value<bool> abandoned,
      Value<DateTime?> completedAt,
      required DateTime createdAt,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<int> id,
      Value<String> sessionType,
      Value<int> intensity,
      Value<int> durationSeconds,
      Value<bool> abandoned,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get abandoned => $composableBuilder(
    column: $table.abandoned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intensity => $composableBuilder(
    column: $table.intensity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get abandoned => $composableBuilder(
    column: $table.abandoned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intensity =>
      $composableBuilder(column: $table.intensity, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get abandoned =>
      $composableBuilder(column: $table.abandoned, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<int> intensity = const Value.absent(),
                Value<int> durationSeconds = const Value.absent(),
                Value<bool> abandoned = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                sessionType: sessionType,
                intensity: intensity,
                durationSeconds: durationSeconds,
                abandoned: abandoned,
                completedAt: completedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String sessionType,
                required int intensity,
                required int durationSeconds,
                Value<bool> abandoned = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                required DateTime createdAt,
              }) => SessionsCompanion.insert(
                id: id,
                sessionType: sessionType,
                intensity: intensity,
                durationSeconds: durationSeconds,
                abandoned: abandoned,
                completedAt: completedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$DailyPlansTableCreateCompanionBuilder =
    DailyPlansCompanion Function({
      Value<int> id,
      required String planDate,
      required String planJson,
      required DateTime generatedAt,
      required DateTime createdAt,
    });
typedef $$DailyPlansTableUpdateCompanionBuilder =
    DailyPlansCompanion Function({
      Value<int> id,
      Value<String> planDate,
      Value<String> planJson,
      Value<DateTime> generatedAt,
      Value<DateTime> createdAt,
    });

class $$DailyPlansTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPlansTable> {
  $$DailyPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planDate => $composableBuilder(
    column: $table.planDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get planJson => $composableBuilder(
    column: $table.planJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPlansTable> {
  $$DailyPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planDate => $composableBuilder(
    column: $table.planDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get planJson => $composableBuilder(
    column: $table.planJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPlansTable> {
  $$DailyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get planDate =>
      $composableBuilder(column: $table.planDate, builder: (column) => column);

  GeneratedColumn<String> get planJson =>
      $composableBuilder(column: $table.planJson, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
    column: $table.generatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$DailyPlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyPlansTable,
          DailyPlan,
          $$DailyPlansTableFilterComposer,
          $$DailyPlansTableOrderingComposer,
          $$DailyPlansTableAnnotationComposer,
          $$DailyPlansTableCreateCompanionBuilder,
          $$DailyPlansTableUpdateCompanionBuilder,
          (
            DailyPlan,
            BaseReferences<_$AppDatabase, $DailyPlansTable, DailyPlan>,
          ),
          DailyPlan,
          PrefetchHooks Function()
        > {
  $$DailyPlansTableTableManager(_$AppDatabase db, $DailyPlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> planDate = const Value.absent(),
                Value<String> planJson = const Value.absent(),
                Value<DateTime> generatedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => DailyPlansCompanion(
                id: id,
                planDate: planDate,
                planJson: planJson,
                generatedAt: generatedAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String planDate,
                required String planJson,
                required DateTime generatedAt,
                required DateTime createdAt,
              }) => DailyPlansCompanion.insert(
                id: id,
                planDate: planDate,
                planJson: planJson,
                generatedAt: generatedAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyPlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyPlansTable,
      DailyPlan,
      $$DailyPlansTableFilterComposer,
      $$DailyPlansTableOrderingComposer,
      $$DailyPlansTableAnnotationComposer,
      $$DailyPlansTableCreateCompanionBuilder,
      $$DailyPlansTableUpdateCompanionBuilder,
      (DailyPlan, BaseReferences<_$AppDatabase, $DailyPlansTable, DailyPlan>),
      DailyPlan,
      PrefetchHooks Function()
    >;
typedef $$UserProfileTableCreateCompanionBuilder =
    UserProfileCompanion Function({
      Value<int> id,
      Value<String?> fitnessGoal,
      Value<int> weeklySessionTarget,
      Value<String?> intensityPreference,
      Value<String?> environmentPreference,
      Value<bool> onboardingCompleted,
      required DateTime createdAt,
      required DateTime updatedAt,
    });
typedef $$UserProfileTableUpdateCompanionBuilder =
    UserProfileCompanion Function({
      Value<int> id,
      Value<String?> fitnessGoal,
      Value<int> weeklySessionTarget,
      Value<String?> intensityPreference,
      Value<String?> environmentPreference,
      Value<bool> onboardingCompleted,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$UserProfileTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fitnessGoal => $composableBuilder(
    column: $table.fitnessGoal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weeklySessionTarget => $composableBuilder(
    column: $table.weeklySessionTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get intensityPreference => $composableBuilder(
    column: $table.intensityPreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environmentPreference => $composableBuilder(
    column: $table.environmentPreference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fitnessGoal => $composableBuilder(
    column: $table.fitnessGoal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weeklySessionTarget => $composableBuilder(
    column: $table.weeklySessionTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get intensityPreference => $composableBuilder(
    column: $table.intensityPreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environmentPreference => $composableBuilder(
    column: $table.environmentPreference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfileTable> {
  $$UserProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get fitnessGoal => $composableBuilder(
    column: $table.fitnessGoal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weeklySessionTarget => $composableBuilder(
    column: $table.weeklySessionTarget,
    builder: (column) => column,
  );

  GeneratedColumn<String> get intensityPreference => $composableBuilder(
    column: $table.intensityPreference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get environmentPreference => $composableBuilder(
    column: $table.environmentPreference,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingCompleted => $composableBuilder(
    column: $table.onboardingCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfileTable,
          UserProfileData,
          $$UserProfileTableFilterComposer,
          $$UserProfileTableOrderingComposer,
          $$UserProfileTableAnnotationComposer,
          $$UserProfileTableCreateCompanionBuilder,
          $$UserProfileTableUpdateCompanionBuilder,
          (
            UserProfileData,
            BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>,
          ),
          UserProfileData,
          PrefetchHooks Function()
        > {
  $$UserProfileTableTableManager(_$AppDatabase db, $UserProfileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> fitnessGoal = const Value.absent(),
                Value<int> weeklySessionTarget = const Value.absent(),
                Value<String?> intensityPreference = const Value.absent(),
                Value<String?> environmentPreference = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UserProfileCompanion(
                id: id,
                fitnessGoal: fitnessGoal,
                weeklySessionTarget: weeklySessionTarget,
                intensityPreference: intensityPreference,
                environmentPreference: environmentPreference,
                onboardingCompleted: onboardingCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> fitnessGoal = const Value.absent(),
                Value<int> weeklySessionTarget = const Value.absent(),
                Value<String?> intensityPreference = const Value.absent(),
                Value<String?> environmentPreference = const Value.absent(),
                Value<bool> onboardingCompleted = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
              }) => UserProfileCompanion.insert(
                id: id,
                fitnessGoal: fitnessGoal,
                weeklySessionTarget: weeklySessionTarget,
                intensityPreference: intensityPreference,
                environmentPreference: environmentPreference,
                onboardingCompleted: onboardingCompleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfileTable,
      UserProfileData,
      $$UserProfileTableFilterComposer,
      $$UserProfileTableOrderingComposer,
      $$UserProfileTableAnnotationComposer,
      $$UserProfileTableCreateCompanionBuilder,
      $$UserProfileTableUpdateCompanionBuilder,
      (
        UserProfileData,
        BaseReferences<_$AppDatabase, $UserProfileTable, UserProfileData>,
      ),
      UserProfileData,
      PrefetchHooks Function()
    >;
typedef $$RpeFeedbackTableCreateCompanionBuilder =
    RpeFeedbackCompanion Function({
      Value<int> id,
      required int sessionId,
      required int rpeValue,
      required DateTime recordedAt,
    });
typedef $$RpeFeedbackTableUpdateCompanionBuilder =
    RpeFeedbackCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<int> rpeValue,
      Value<DateTime> recordedAt,
    });

class $$RpeFeedbackTableFilterComposer
    extends Composer<_$AppDatabase, $RpeFeedbackTable> {
  $$RpeFeedbackTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rpeValue => $composableBuilder(
    column: $table.rpeValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RpeFeedbackTableOrderingComposer
    extends Composer<_$AppDatabase, $RpeFeedbackTable> {
  $$RpeFeedbackTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rpeValue => $composableBuilder(
    column: $table.rpeValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RpeFeedbackTableAnnotationComposer
    extends Composer<_$AppDatabase, $RpeFeedbackTable> {
  $$RpeFeedbackTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get rpeValue =>
      $composableBuilder(column: $table.rpeValue, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );
}

class $$RpeFeedbackTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RpeFeedbackTable,
          RpeFeedbackData,
          $$RpeFeedbackTableFilterComposer,
          $$RpeFeedbackTableOrderingComposer,
          $$RpeFeedbackTableAnnotationComposer,
          $$RpeFeedbackTableCreateCompanionBuilder,
          $$RpeFeedbackTableUpdateCompanionBuilder,
          (
            RpeFeedbackData,
            BaseReferences<_$AppDatabase, $RpeFeedbackTable, RpeFeedbackData>,
          ),
          RpeFeedbackData,
          PrefetchHooks Function()
        > {
  $$RpeFeedbackTableTableManager(_$AppDatabase db, $RpeFeedbackTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RpeFeedbackTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RpeFeedbackTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RpeFeedbackTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<int> rpeValue = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
              }) => RpeFeedbackCompanion(
                id: id,
                sessionId: sessionId,
                rpeValue: rpeValue,
                recordedAt: recordedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                required int rpeValue,
                required DateTime recordedAt,
              }) => RpeFeedbackCompanion.insert(
                id: id,
                sessionId: sessionId,
                rpeValue: rpeValue,
                recordedAt: recordedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RpeFeedbackTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RpeFeedbackTable,
      RpeFeedbackData,
      $$RpeFeedbackTableFilterComposer,
      $$RpeFeedbackTableOrderingComposer,
      $$RpeFeedbackTableAnnotationComposer,
      $$RpeFeedbackTableCreateCompanionBuilder,
      $$RpeFeedbackTableUpdateCompanionBuilder,
      (
        RpeFeedbackData,
        BaseReferences<_$AppDatabase, $RpeFeedbackTable, RpeFeedbackData>,
      ),
      RpeFeedbackData,
      PrefetchHooks Function()
    >;
typedef $$BanditStateTableCreateCompanionBuilder =
    BanditStateCompanion Function({
      Value<int> id,
      required String armWeightsJson,
      required DateTime updatedAt,
    });
typedef $$BanditStateTableUpdateCompanionBuilder =
    BanditStateCompanion Function({
      Value<int> id,
      Value<String> armWeightsJson,
      Value<DateTime> updatedAt,
    });

class $$BanditStateTableFilterComposer
    extends Composer<_$AppDatabase, $BanditStateTable> {
  $$BanditStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get armWeightsJson => $composableBuilder(
    column: $table.armWeightsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BanditStateTableOrderingComposer
    extends Composer<_$AppDatabase, $BanditStateTable> {
  $$BanditStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get armWeightsJson => $composableBuilder(
    column: $table.armWeightsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BanditStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $BanditStateTable> {
  $$BanditStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get armWeightsJson => $composableBuilder(
    column: $table.armWeightsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BanditStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BanditStateTable,
          BanditStateData,
          $$BanditStateTableFilterComposer,
          $$BanditStateTableOrderingComposer,
          $$BanditStateTableAnnotationComposer,
          $$BanditStateTableCreateCompanionBuilder,
          $$BanditStateTableUpdateCompanionBuilder,
          (
            BanditStateData,
            BaseReferences<_$AppDatabase, $BanditStateTable, BanditStateData>,
          ),
          BanditStateData,
          PrefetchHooks Function()
        > {
  $$BanditStateTableTableManager(_$AppDatabase db, $BanditStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BanditStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BanditStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BanditStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> armWeightsJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BanditStateCompanion(
                id: id,
                armWeightsJson: armWeightsJson,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String armWeightsJson,
                required DateTime updatedAt,
              }) => BanditStateCompanion.insert(
                id: id,
                armWeightsJson: armWeightsJson,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BanditStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BanditStateTable,
      BanditStateData,
      $$BanditStateTableFilterComposer,
      $$BanditStateTableOrderingComposer,
      $$BanditStateTableAnnotationComposer,
      $$BanditStateTableCreateCompanionBuilder,
      $$BanditStateTableUpdateCompanionBuilder,
      (
        BanditStateData,
        BaseReferences<_$AppDatabase, $BanditStateTable, BanditStateData>,
      ),
      BanditStateData,
      PrefetchHooks Function()
    >;
typedef $$BehavioralStateTableCreateCompanionBuilder =
    BehavioralStateCompanion Function({
      Value<int> id,
      required String currentState,
      Value<int?> restingHr,
      Value<int?> stepCount,
      Value<int> streakCount,
      required DateTime recordedAt,
      required DateTime updatedAt,
    });
typedef $$BehavioralStateTableUpdateCompanionBuilder =
    BehavioralStateCompanion Function({
      Value<int> id,
      Value<String> currentState,
      Value<int?> restingHr,
      Value<int?> stepCount,
      Value<int> streakCount,
      Value<DateTime> recordedAt,
      Value<DateTime> updatedAt,
    });

class $$BehavioralStateTableFilterComposer
    extends Composer<_$AppDatabase, $BehavioralStateTable> {
  $$BehavioralStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currentState => $composableBuilder(
    column: $table.currentState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restingHr => $composableBuilder(
    column: $table.restingHr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepCount => $composableBuilder(
    column: $table.stepCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BehavioralStateTableOrderingComposer
    extends Composer<_$AppDatabase, $BehavioralStateTable> {
  $$BehavioralStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currentState => $composableBuilder(
    column: $table.currentState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restingHr => $composableBuilder(
    column: $table.restingHr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepCount => $composableBuilder(
    column: $table.stepCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BehavioralStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $BehavioralStateTable> {
  $$BehavioralStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get currentState => $composableBuilder(
    column: $table.currentState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restingHr =>
      $composableBuilder(column: $table.restingHr, builder: (column) => column);

  GeneratedColumn<int> get stepCount =>
      $composableBuilder(column: $table.stepCount, builder: (column) => column);

  GeneratedColumn<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BehavioralStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BehavioralStateTable,
          BehavioralStateData,
          $$BehavioralStateTableFilterComposer,
          $$BehavioralStateTableOrderingComposer,
          $$BehavioralStateTableAnnotationComposer,
          $$BehavioralStateTableCreateCompanionBuilder,
          $$BehavioralStateTableUpdateCompanionBuilder,
          (
            BehavioralStateData,
            BaseReferences<
              _$AppDatabase,
              $BehavioralStateTable,
              BehavioralStateData
            >,
          ),
          BehavioralStateData,
          PrefetchHooks Function()
        > {
  $$BehavioralStateTableTableManager(
    _$AppDatabase db,
    $BehavioralStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BehavioralStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BehavioralStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BehavioralStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> currentState = const Value.absent(),
                Value<int?> restingHr = const Value.absent(),
                Value<int?> stepCount = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => BehavioralStateCompanion(
                id: id,
                currentState: currentState,
                restingHr: restingHr,
                stepCount: stepCount,
                streakCount: streakCount,
                recordedAt: recordedAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String currentState,
                Value<int?> restingHr = const Value.absent(),
                Value<int?> stepCount = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                required DateTime recordedAt,
                required DateTime updatedAt,
              }) => BehavioralStateCompanion.insert(
                id: id,
                currentState: currentState,
                restingHr: restingHr,
                stepCount: stepCount,
                streakCount: streakCount,
                recordedAt: recordedAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BehavioralStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BehavioralStateTable,
      BehavioralStateData,
      $$BehavioralStateTableFilterComposer,
      $$BehavioralStateTableOrderingComposer,
      $$BehavioralStateTableAnnotationComposer,
      $$BehavioralStateTableCreateCompanionBuilder,
      $$BehavioralStateTableUpdateCompanionBuilder,
      (
        BehavioralStateData,
        BaseReferences<
          _$AppDatabase,
          $BehavioralStateTable,
          BehavioralStateData
        >,
      ),
      BehavioralStateData,
      PrefetchHooks Function()
    >;
typedef $$WeatherCacheTableCreateCompanionBuilder =
    WeatherCacheCompanion Function({
      Value<int> id,
      required double latitude,
      required double longitude,
      required double temperature,
      required double precipitationProbability,
      required int aqiValue,
      required DateTime cachedAt,
    });
typedef $$WeatherCacheTableUpdateCompanionBuilder =
    WeatherCacheCompanion Function({
      Value<int> id,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> temperature,
      Value<double> precipitationProbability,
      Value<int> aqiValue,
      Value<DateTime> cachedAt,
    });

class $$WeatherCacheTableFilterComposer
    extends Composer<_$AppDatabase, $WeatherCacheTable> {
  $$WeatherCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precipitationProbability => $composableBuilder(
    column: $table.precipitationProbability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get aqiValue => $composableBuilder(
    column: $table.aqiValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeatherCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $WeatherCacheTable> {
  $$WeatherCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precipitationProbability => $composableBuilder(
    column: $table.precipitationProbability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get aqiValue => $composableBuilder(
    column: $table.aqiValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeatherCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeatherCacheTable> {
  $$WeatherCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get temperature => $composableBuilder(
    column: $table.temperature,
    builder: (column) => column,
  );

  GeneratedColumn<double> get precipitationProbability => $composableBuilder(
    column: $table.precipitationProbability,
    builder: (column) => column,
  );

  GeneratedColumn<int> get aqiValue =>
      $composableBuilder(column: $table.aqiValue, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$WeatherCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeatherCacheTable,
          WeatherCacheData,
          $$WeatherCacheTableFilterComposer,
          $$WeatherCacheTableOrderingComposer,
          $$WeatherCacheTableAnnotationComposer,
          $$WeatherCacheTableCreateCompanionBuilder,
          $$WeatherCacheTableUpdateCompanionBuilder,
          (
            WeatherCacheData,
            BaseReferences<_$AppDatabase, $WeatherCacheTable, WeatherCacheData>,
          ),
          WeatherCacheData,
          PrefetchHooks Function()
        > {
  $$WeatherCacheTableTableManager(_$AppDatabase db, $WeatherCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeatherCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeatherCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeatherCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> temperature = const Value.absent(),
                Value<double> precipitationProbability = const Value.absent(),
                Value<int> aqiValue = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => WeatherCacheCompanion(
                id: id,
                latitude: latitude,
                longitude: longitude,
                temperature: temperature,
                precipitationProbability: precipitationProbability,
                aqiValue: aqiValue,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required double latitude,
                required double longitude,
                required double temperature,
                required double precipitationProbability,
                required int aqiValue,
                required DateTime cachedAt,
              }) => WeatherCacheCompanion.insert(
                id: id,
                latitude: latitude,
                longitude: longitude,
                temperature: temperature,
                precipitationProbability: precipitationProbability,
                aqiValue: aqiValue,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeatherCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeatherCacheTable,
      WeatherCacheData,
      $$WeatherCacheTableFilterComposer,
      $$WeatherCacheTableOrderingComposer,
      $$WeatherCacheTableAnnotationComposer,
      $$WeatherCacheTableCreateCompanionBuilder,
      $$WeatherCacheTableUpdateCompanionBuilder,
      (
        WeatherCacheData,
        BaseReferences<_$AppDatabase, $WeatherCacheTable, WeatherCacheData>,
      ),
      WeatherCacheData,
      PrefetchHooks Function()
    >;
typedef $$ExerciseCacheTableCreateCompanionBuilder =
    ExerciseCacheCompanion Function({
      Value<int> id,
      required String exerciseId,
      required String exerciseJson,
      required DateTime cachedAt,
    });
typedef $$ExerciseCacheTableUpdateCompanionBuilder =
    ExerciseCacheCompanion Function({
      Value<int> id,
      Value<String> exerciseId,
      Value<String> exerciseJson,
      Value<DateTime> cachedAt,
    });

class $$ExerciseCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ExerciseCacheTable> {
  $$ExerciseCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseJson => $composableBuilder(
    column: $table.exerciseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExerciseCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ExerciseCacheTable> {
  $$ExerciseCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseJson => $composableBuilder(
    column: $table.exerciseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
    column: $table.cachedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExerciseCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExerciseCacheTable> {
  $$ExerciseCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseJson => $composableBuilder(
    column: $table.exerciseJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$ExerciseCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExerciseCacheTable,
          ExerciseCacheData,
          $$ExerciseCacheTableFilterComposer,
          $$ExerciseCacheTableOrderingComposer,
          $$ExerciseCacheTableAnnotationComposer,
          $$ExerciseCacheTableCreateCompanionBuilder,
          $$ExerciseCacheTableUpdateCompanionBuilder,
          (
            ExerciseCacheData,
            BaseReferences<
              _$AppDatabase,
              $ExerciseCacheTable,
              ExerciseCacheData
            >,
          ),
          ExerciseCacheData,
          PrefetchHooks Function()
        > {
  $$ExerciseCacheTableTableManager(_$AppDatabase db, $ExerciseCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExerciseCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExerciseCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExerciseCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<String> exerciseJson = const Value.absent(),
                Value<DateTime> cachedAt = const Value.absent(),
              }) => ExerciseCacheCompanion(
                id: id,
                exerciseId: exerciseId,
                exerciseJson: exerciseJson,
                cachedAt: cachedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String exerciseId,
                required String exerciseJson,
                required DateTime cachedAt,
              }) => ExerciseCacheCompanion.insert(
                id: id,
                exerciseId: exerciseId,
                exerciseJson: exerciseJson,
                cachedAt: cachedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExerciseCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExerciseCacheTable,
      ExerciseCacheData,
      $$ExerciseCacheTableFilterComposer,
      $$ExerciseCacheTableOrderingComposer,
      $$ExerciseCacheTableAnnotationComposer,
      $$ExerciseCacheTableCreateCompanionBuilder,
      $$ExerciseCacheTableUpdateCompanionBuilder,
      (
        ExerciseCacheData,
        BaseReferences<_$AppDatabase, $ExerciseCacheTable, ExerciseCacheData>,
      ),
      ExerciseCacheData,
      PrefetchHooks Function()
    >;
typedef $$SyncQueueTableCreateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      required String eventType,
      required String payload,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      required DateTime createdAt,
    });
typedef $$SyncQueueTableUpdateCompanionBuilder =
    SyncQueueCompanion Function({
      Value<int> id,
      Value<String> eventType,
      Value<String> payload,
      Value<int> retryCount,
      Value<DateTime?> nextRetryAt,
      Value<DateTime> createdAt,
    });

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncQueueTable,
          SyncQueueEntry,
          $$SyncQueueTableFilterComposer,
          $$SyncQueueTableOrderingComposer,
          $$SyncQueueTableAnnotationComposer,
          $$SyncQueueTableCreateCompanionBuilder,
          $$SyncQueueTableUpdateCompanionBuilder,
          (
            SyncQueueEntry,
            BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
          ),
          SyncQueueEntry,
          PrefetchHooks Function()
        > {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => SyncQueueCompanion(
                id: id,
                eventType: eventType,
                payload: payload,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String eventType,
                required String payload,
                Value<int> retryCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                required DateTime createdAt,
              }) => SyncQueueCompanion.insert(
                id: id,
                eventType: eventType,
                payload: payload,
                retryCount: retryCount,
                nextRetryAt: nextRetryAt,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncQueueTable,
      SyncQueueEntry,
      $$SyncQueueTableFilterComposer,
      $$SyncQueueTableOrderingComposer,
      $$SyncQueueTableAnnotationComposer,
      $$SyncQueueTableCreateCompanionBuilder,
      $$SyncQueueTableUpdateCompanionBuilder,
      (
        SyncQueueEntry,
        BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueEntry>,
      ),
      SyncQueueEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$DailyPlansTableTableManager get dailyPlans =>
      $$DailyPlansTableTableManager(_db, _db.dailyPlans);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db, _db.userProfile);
  $$RpeFeedbackTableTableManager get rpeFeedback =>
      $$RpeFeedbackTableTableManager(_db, _db.rpeFeedback);
  $$BanditStateTableTableManager get banditState =>
      $$BanditStateTableTableManager(_db, _db.banditState);
  $$BehavioralStateTableTableManager get behavioralState =>
      $$BehavioralStateTableTableManager(_db, _db.behavioralState);
  $$WeatherCacheTableTableManager get weatherCache =>
      $$WeatherCacheTableTableManager(_db, _db.weatherCache);
  $$ExerciseCacheTableTableManager get exerciseCache =>
      $$ExerciseCacheTableTableManager(_db, _db.exerciseCache);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
