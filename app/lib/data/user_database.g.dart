// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_database.dart';

// ignore_for_file: type=lint
class $LearnedWordsTable extends LearnedWords
    with TableInfo<$LearnedWordsTable, LearnedWord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LearnedWordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordMeta = const VerificationMeta('word');
  @override
  late final GeneratedColumn<String> word = GeneratedColumn<String>(
    'word',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _familiarityMeta = const VerificationMeta(
    'familiarity',
  );
  @override
  late final GeneratedColumn<int> familiarity = GeneratedColumn<int>(
    'familiarity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctCountInLevelMeta =
      const VerificationMeta('correctCountInLevel');
  @override
  late final GeneratedColumn<int> correctCountInLevel = GeneratedColumn<int>(
    'correct_count_in_level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _learnedOnMeta = const VerificationMeta(
    'learnedOn',
  );
  @override
  late final GeneratedColumn<DateTime> learnedOn = GeneratedColumn<DateTime>(
    'learned_on',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastReviewedAtMeta = const VerificationMeta(
    'lastReviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>(
        'last_reviewed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextDueAtMeta = const VerificationMeta(
    'nextDueAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextDueAt = GeneratedColumn<DateTime>(
    'next_due_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _missedOnMeta = const VerificationMeta(
    'missedOn',
  );
  @override
  late final GeneratedColumn<DateTime> missedOn = GeneratedColumn<DateTime>(
    'missed_on',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _graduatedMeta = const VerificationMeta(
    'graduated',
  );
  @override
  late final GeneratedColumn<bool> graduated = GeneratedColumn<bool>(
    'graduated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("graduated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    word,
    familiarity,
    correctCountInLevel,
    learnedOn,
    lastReviewedAt,
    nextDueAt,
    missedOn,
    graduated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'learned_words';
  @override
  VerificationContext validateIntegrity(
    Insertable<LearnedWord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word')) {
      context.handle(
        _wordMeta,
        word.isAcceptableOrUnknown(data['word']!, _wordMeta),
      );
    } else if (isInserting) {
      context.missing(_wordMeta);
    }
    if (data.containsKey('familiarity')) {
      context.handle(
        _familiarityMeta,
        familiarity.isAcceptableOrUnknown(
          data['familiarity']!,
          _familiarityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_familiarityMeta);
    }
    if (data.containsKey('correct_count_in_level')) {
      context.handle(
        _correctCountInLevelMeta,
        correctCountInLevel.isAcceptableOrUnknown(
          data['correct_count_in_level']!,
          _correctCountInLevelMeta,
        ),
      );
    }
    if (data.containsKey('learned_on')) {
      context.handle(
        _learnedOnMeta,
        learnedOn.isAcceptableOrUnknown(data['learned_on']!, _learnedOnMeta),
      );
    } else if (isInserting) {
      context.missing(_learnedOnMeta);
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
        _lastReviewedAtMeta,
        lastReviewedAt.isAcceptableOrUnknown(
          data['last_reviewed_at']!,
          _lastReviewedAtMeta,
        ),
      );
    }
    if (data.containsKey('next_due_at')) {
      context.handle(
        _nextDueAtMeta,
        nextDueAt.isAcceptableOrUnknown(data['next_due_at']!, _nextDueAtMeta),
      );
    }
    if (data.containsKey('missed_on')) {
      context.handle(
        _missedOnMeta,
        missedOn.isAcceptableOrUnknown(data['missed_on']!, _missedOnMeta),
      );
    }
    if (data.containsKey('graduated')) {
      context.handle(
        _graduatedMeta,
        graduated.isAcceptableOrUnknown(data['graduated']!, _graduatedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {word};
  @override
  LearnedWord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LearnedWord(
      word: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}word'],
      )!,
      familiarity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}familiarity'],
      )!,
      correctCountInLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_count_in_level'],
      )!,
      learnedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}learned_on'],
      )!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_reviewed_at'],
      ),
      nextDueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_due_at'],
      ),
      missedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}missed_on'],
      ),
      graduated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}graduated'],
      )!,
    );
  }

  @override
  $LearnedWordsTable createAlias(String alias) {
    return $LearnedWordsTable(attachedDatabase, alias);
  }
}

class LearnedWord extends DataClass implements Insertable<LearnedWord> {
  final String word;
  final int familiarity;
  final int correctCountInLevel;
  final DateTime learnedOn;
  final DateTime? lastReviewedAt;
  final DateTime? nextDueAt;
  final DateTime? missedOn;
  final bool graduated;
  const LearnedWord({
    required this.word,
    required this.familiarity,
    required this.correctCountInLevel,
    required this.learnedOn,
    this.lastReviewedAt,
    this.nextDueAt,
    this.missedOn,
    required this.graduated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word'] = Variable<String>(word);
    map['familiarity'] = Variable<int>(familiarity);
    map['correct_count_in_level'] = Variable<int>(correctCountInLevel);
    map['learned_on'] = Variable<DateTime>(learnedOn);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    if (!nullToAbsent || nextDueAt != null) {
      map['next_due_at'] = Variable<DateTime>(nextDueAt);
    }
    if (!nullToAbsent || missedOn != null) {
      map['missed_on'] = Variable<DateTime>(missedOn);
    }
    map['graduated'] = Variable<bool>(graduated);
    return map;
  }

  LearnedWordsCompanion toCompanion(bool nullToAbsent) {
    return LearnedWordsCompanion(
      word: Value(word),
      familiarity: Value(familiarity),
      correctCountInLevel: Value(correctCountInLevel),
      learnedOn: Value(learnedOn),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      nextDueAt: nextDueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDueAt),
      missedOn: missedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(missedOn),
      graduated: Value(graduated),
    );
  }

  factory LearnedWord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LearnedWord(
      word: serializer.fromJson<String>(json['word']),
      familiarity: serializer.fromJson<int>(json['familiarity']),
      correctCountInLevel: serializer.fromJson<int>(
        json['correctCountInLevel'],
      ),
      learnedOn: serializer.fromJson<DateTime>(json['learnedOn']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      nextDueAt: serializer.fromJson<DateTime?>(json['nextDueAt']),
      missedOn: serializer.fromJson<DateTime?>(json['missedOn']),
      graduated: serializer.fromJson<bool>(json['graduated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'word': serializer.toJson<String>(word),
      'familiarity': serializer.toJson<int>(familiarity),
      'correctCountInLevel': serializer.toJson<int>(correctCountInLevel),
      'learnedOn': serializer.toJson<DateTime>(learnedOn),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'nextDueAt': serializer.toJson<DateTime?>(nextDueAt),
      'missedOn': serializer.toJson<DateTime?>(missedOn),
      'graduated': serializer.toJson<bool>(graduated),
    };
  }

  LearnedWord copyWith({
    String? word,
    int? familiarity,
    int? correctCountInLevel,
    DateTime? learnedOn,
    Value<DateTime?> lastReviewedAt = const Value.absent(),
    Value<DateTime?> nextDueAt = const Value.absent(),
    Value<DateTime?> missedOn = const Value.absent(),
    bool? graduated,
  }) => LearnedWord(
    word: word ?? this.word,
    familiarity: familiarity ?? this.familiarity,
    correctCountInLevel: correctCountInLevel ?? this.correctCountInLevel,
    learnedOn: learnedOn ?? this.learnedOn,
    lastReviewedAt: lastReviewedAt.present
        ? lastReviewedAt.value
        : this.lastReviewedAt,
    nextDueAt: nextDueAt.present ? nextDueAt.value : this.nextDueAt,
    missedOn: missedOn.present ? missedOn.value : this.missedOn,
    graduated: graduated ?? this.graduated,
  );
  LearnedWord copyWithCompanion(LearnedWordsCompanion data) {
    return LearnedWord(
      word: data.word.present ? data.word.value : this.word,
      familiarity: data.familiarity.present
          ? data.familiarity.value
          : this.familiarity,
      correctCountInLevel: data.correctCountInLevel.present
          ? data.correctCountInLevel.value
          : this.correctCountInLevel,
      learnedOn: data.learnedOn.present ? data.learnedOn.value : this.learnedOn,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      nextDueAt: data.nextDueAt.present ? data.nextDueAt.value : this.nextDueAt,
      missedOn: data.missedOn.present ? data.missedOn.value : this.missedOn,
      graduated: data.graduated.present ? data.graduated.value : this.graduated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LearnedWord(')
          ..write('word: $word, ')
          ..write('familiarity: $familiarity, ')
          ..write('correctCountInLevel: $correctCountInLevel, ')
          ..write('learnedOn: $learnedOn, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('nextDueAt: $nextDueAt, ')
          ..write('missedOn: $missedOn, ')
          ..write('graduated: $graduated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    word,
    familiarity,
    correctCountInLevel,
    learnedOn,
    lastReviewedAt,
    nextDueAt,
    missedOn,
    graduated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LearnedWord &&
          other.word == this.word &&
          other.familiarity == this.familiarity &&
          other.correctCountInLevel == this.correctCountInLevel &&
          other.learnedOn == this.learnedOn &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.nextDueAt == this.nextDueAt &&
          other.missedOn == this.missedOn &&
          other.graduated == this.graduated);
}

class LearnedWordsCompanion extends UpdateCompanion<LearnedWord> {
  final Value<String> word;
  final Value<int> familiarity;
  final Value<int> correctCountInLevel;
  final Value<DateTime> learnedOn;
  final Value<DateTime?> lastReviewedAt;
  final Value<DateTime?> nextDueAt;
  final Value<DateTime?> missedOn;
  final Value<bool> graduated;
  final Value<int> rowid;
  const LearnedWordsCompanion({
    this.word = const Value.absent(),
    this.familiarity = const Value.absent(),
    this.correctCountInLevel = const Value.absent(),
    this.learnedOn = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.missedOn = const Value.absent(),
    this.graduated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LearnedWordsCompanion.insert({
    required String word,
    required int familiarity,
    this.correctCountInLevel = const Value.absent(),
    required DateTime learnedOn,
    this.lastReviewedAt = const Value.absent(),
    this.nextDueAt = const Value.absent(),
    this.missedOn = const Value.absent(),
    this.graduated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : word = Value(word),
       familiarity = Value(familiarity),
       learnedOn = Value(learnedOn);
  static Insertable<LearnedWord> custom({
    Expression<String>? word,
    Expression<int>? familiarity,
    Expression<int>? correctCountInLevel,
    Expression<DateTime>? learnedOn,
    Expression<DateTime>? lastReviewedAt,
    Expression<DateTime>? nextDueAt,
    Expression<DateTime>? missedOn,
    Expression<bool>? graduated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (word != null) 'word': word,
      if (familiarity != null) 'familiarity': familiarity,
      if (correctCountInLevel != null)
        'correct_count_in_level': correctCountInLevel,
      if (learnedOn != null) 'learned_on': learnedOn,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (nextDueAt != null) 'next_due_at': nextDueAt,
      if (missedOn != null) 'missed_on': missedOn,
      if (graduated != null) 'graduated': graduated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LearnedWordsCompanion copyWith({
    Value<String>? word,
    Value<int>? familiarity,
    Value<int>? correctCountInLevel,
    Value<DateTime>? learnedOn,
    Value<DateTime?>? lastReviewedAt,
    Value<DateTime?>? nextDueAt,
    Value<DateTime?>? missedOn,
    Value<bool>? graduated,
    Value<int>? rowid,
  }) {
    return LearnedWordsCompanion(
      word: word ?? this.word,
      familiarity: familiarity ?? this.familiarity,
      correctCountInLevel: correctCountInLevel ?? this.correctCountInLevel,
      learnedOn: learnedOn ?? this.learnedOn,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      nextDueAt: nextDueAt ?? this.nextDueAt,
      missedOn: missedOn ?? this.missedOn,
      graduated: graduated ?? this.graduated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (word.present) {
      map['word'] = Variable<String>(word.value);
    }
    if (familiarity.present) {
      map['familiarity'] = Variable<int>(familiarity.value);
    }
    if (correctCountInLevel.present) {
      map['correct_count_in_level'] = Variable<int>(correctCountInLevel.value);
    }
    if (learnedOn.present) {
      map['learned_on'] = Variable<DateTime>(learnedOn.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (nextDueAt.present) {
      map['next_due_at'] = Variable<DateTime>(nextDueAt.value);
    }
    if (missedOn.present) {
      map['missed_on'] = Variable<DateTime>(missedOn.value);
    }
    if (graduated.present) {
      map['graduated'] = Variable<bool>(graduated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LearnedWordsCompanion(')
          ..write('word: $word, ')
          ..write('familiarity: $familiarity, ')
          ..write('correctCountInLevel: $correctCountInLevel, ')
          ..write('learnedOn: $learnedOn, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('nextDueAt: $nextDueAt, ')
          ..write('missedOn: $missedOn, ')
          ..write('graduated: $graduated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckInsTable extends CheckIns with TableInfo<$CheckInsTable, CheckIn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<DateTime> day = GeneratedColumn<DateTime>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [day];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckIn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {day};
  @override
  CheckIn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckIn(
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}day'],
      )!,
    );
  }

  @override
  $CheckInsTable createAlias(String alias) {
    return $CheckInsTable(attachedDatabase, alias);
  }
}

class CheckIn extends DataClass implements Insertable<CheckIn> {
  final DateTime day;
  const CheckIn({required this.day});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day'] = Variable<DateTime>(day);
    return map;
  }

  CheckInsCompanion toCompanion(bool nullToAbsent) {
    return CheckInsCompanion(day: Value(day));
  }

  factory CheckIn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckIn(day: serializer.fromJson<DateTime>(json['day']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'day': serializer.toJson<DateTime>(day)};
  }

  CheckIn copyWith({DateTime? day}) => CheckIn(day: day ?? this.day);
  CheckIn copyWithCompanion(CheckInsCompanion data) {
    return CheckIn(day: data.day.present ? data.day.value : this.day);
  }

  @override
  String toString() {
    return (StringBuffer('CheckIn(')
          ..write('day: $day')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => day.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is CheckIn && other.day == this.day);
}

class CheckInsCompanion extends UpdateCompanion<CheckIn> {
  final Value<DateTime> day;
  final Value<int> rowid;
  const CheckInsCompanion({
    this.day = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckInsCompanion.insert({
    required DateTime day,
    this.rowid = const Value.absent(),
  }) : day = Value(day);
  static Insertable<CheckIn> custom({
    Expression<DateTime>? day,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (day != null) 'day': day,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckInsCompanion copyWith({Value<DateTime>? day, Value<int>? rowid}) {
    return CheckInsCompanion(day: day ?? this.day, rowid: rowid ?? this.rowid);
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (day.present) {
      map['day'] = Variable<DateTime>(day.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckInsCompanion(')
          ..write('day: $day, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$UserDatabase extends GeneratedDatabase {
  _$UserDatabase(QueryExecutor e) : super(e);
  $UserDatabaseManager get managers => $UserDatabaseManager(this);
  late final $LearnedWordsTable learnedWords = $LearnedWordsTable(this);
  late final $CheckInsTable checkIns = $CheckInsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    learnedWords,
    checkIns,
    appSettings,
  ];
}

typedef $$LearnedWordsTableCreateCompanionBuilder =
    LearnedWordsCompanion Function({
      required String word,
      required int familiarity,
      Value<int> correctCountInLevel,
      required DateTime learnedOn,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime?> nextDueAt,
      Value<DateTime?> missedOn,
      Value<bool> graduated,
      Value<int> rowid,
    });
typedef $$LearnedWordsTableUpdateCompanionBuilder =
    LearnedWordsCompanion Function({
      Value<String> word,
      Value<int> familiarity,
      Value<int> correctCountInLevel,
      Value<DateTime> learnedOn,
      Value<DateTime?> lastReviewedAt,
      Value<DateTime?> nextDueAt,
      Value<DateTime?> missedOn,
      Value<bool> graduated,
      Value<int> rowid,
    });

class $$LearnedWordsTableFilterComposer
    extends Composer<_$UserDatabase, $LearnedWordsTable> {
  $$LearnedWordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get familiarity => $composableBuilder(
    column: $table.familiarity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctCountInLevel => $composableBuilder(
    column: $table.correctCountInLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get learnedOn => $composableBuilder(
    column: $table.learnedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextDueAt => $composableBuilder(
    column: $table.nextDueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get missedOn => $composableBuilder(
    column: $table.missedOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get graduated => $composableBuilder(
    column: $table.graduated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LearnedWordsTableOrderingComposer
    extends Composer<_$UserDatabase, $LearnedWordsTable> {
  $$LearnedWordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get word => $composableBuilder(
    column: $table.word,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get familiarity => $composableBuilder(
    column: $table.familiarity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctCountInLevel => $composableBuilder(
    column: $table.correctCountInLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get learnedOn => $composableBuilder(
    column: $table.learnedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextDueAt => $composableBuilder(
    column: $table.nextDueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get missedOn => $composableBuilder(
    column: $table.missedOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get graduated => $composableBuilder(
    column: $table.graduated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LearnedWordsTableAnnotationComposer
    extends Composer<_$UserDatabase, $LearnedWordsTable> {
  $$LearnedWordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get word =>
      $composableBuilder(column: $table.word, builder: (column) => column);

  GeneratedColumn<int> get familiarity => $composableBuilder(
    column: $table.familiarity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctCountInLevel => $composableBuilder(
    column: $table.correctCountInLevel,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get learnedOn =>
      $composableBuilder(column: $table.learnedOn, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
    column: $table.lastReviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextDueAt =>
      $composableBuilder(column: $table.nextDueAt, builder: (column) => column);

  GeneratedColumn<DateTime> get missedOn =>
      $composableBuilder(column: $table.missedOn, builder: (column) => column);

  GeneratedColumn<bool> get graduated =>
      $composableBuilder(column: $table.graduated, builder: (column) => column);
}

class $$LearnedWordsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $LearnedWordsTable,
          LearnedWord,
          $$LearnedWordsTableFilterComposer,
          $$LearnedWordsTableOrderingComposer,
          $$LearnedWordsTableAnnotationComposer,
          $$LearnedWordsTableCreateCompanionBuilder,
          $$LearnedWordsTableUpdateCompanionBuilder,
          (
            LearnedWord,
            BaseReferences<_$UserDatabase, $LearnedWordsTable, LearnedWord>,
          ),
          LearnedWord,
          PrefetchHooks Function()
        > {
  $$LearnedWordsTableTableManager(_$UserDatabase db, $LearnedWordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LearnedWordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LearnedWordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LearnedWordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> word = const Value.absent(),
                Value<int> familiarity = const Value.absent(),
                Value<int> correctCountInLevel = const Value.absent(),
                Value<DateTime> learnedOn = const Value.absent(),
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime?> nextDueAt = const Value.absent(),
                Value<DateTime?> missedOn = const Value.absent(),
                Value<bool> graduated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearnedWordsCompanion(
                word: word,
                familiarity: familiarity,
                correctCountInLevel: correctCountInLevel,
                learnedOn: learnedOn,
                lastReviewedAt: lastReviewedAt,
                nextDueAt: nextDueAt,
                missedOn: missedOn,
                graduated: graduated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String word,
                required int familiarity,
                Value<int> correctCountInLevel = const Value.absent(),
                required DateTime learnedOn,
                Value<DateTime?> lastReviewedAt = const Value.absent(),
                Value<DateTime?> nextDueAt = const Value.absent(),
                Value<DateTime?> missedOn = const Value.absent(),
                Value<bool> graduated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LearnedWordsCompanion.insert(
                word: word,
                familiarity: familiarity,
                correctCountInLevel: correctCountInLevel,
                learnedOn: learnedOn,
                lastReviewedAt: lastReviewedAt,
                nextDueAt: nextDueAt,
                missedOn: missedOn,
                graduated: graduated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LearnedWordsTable, LearnedWord>(table),
                  BaseReferences<
                    _$UserDatabase,
                    $LearnedWordsTable,
                    LearnedWord
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LearnedWordsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $LearnedWordsTable,
      LearnedWord,
      $$LearnedWordsTableFilterComposer,
      $$LearnedWordsTableOrderingComposer,
      $$LearnedWordsTableAnnotationComposer,
      $$LearnedWordsTableCreateCompanionBuilder,
      $$LearnedWordsTableUpdateCompanionBuilder,
      (
        LearnedWord,
        BaseReferences<_$UserDatabase, $LearnedWordsTable, LearnedWord>,
      ),
      LearnedWord,
      PrefetchHooks Function()
    >;
typedef $$CheckInsTableCreateCompanionBuilder = CheckInsCompanion Function({
  required DateTime day,
  Value<int> rowid,
});
typedef $$CheckInsTableUpdateCompanionBuilder = CheckInsCompanion Function({
  Value<DateTime> day,
  Value<int> rowid,
});

class $$CheckInsTableFilterComposer
    extends Composer<_$UserDatabase, $CheckInsTable> {
  $$CheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CheckInsTableOrderingComposer
    extends Composer<_$UserDatabase, $CheckInsTable> {
  $$CheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CheckInsTableAnnotationComposer
    extends Composer<_$UserDatabase, $CheckInsTable> {
  $$CheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);
}

class $$CheckInsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $CheckInsTable,
          CheckIn,
          $$CheckInsTableFilterComposer,
          $$CheckInsTableOrderingComposer,
          $$CheckInsTableAnnotationComposer,
          $$CheckInsTableCreateCompanionBuilder,
          $$CheckInsTableUpdateCompanionBuilder,
          (CheckIn, BaseReferences<_$UserDatabase, $CheckInsTable, CheckIn>),
          CheckIn,
          PrefetchHooks Function()
        > {
  $$CheckInsTableTableManager(_$UserDatabase db, $CheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<DateTime> day = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => CheckInsCompanion(day: day, rowid: rowid),
          createCompanionCallback: ({
            required DateTime day,
            Value<int> rowid = const Value.absent(),
          }) => CheckInsCompanion.insert(day: day, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CheckInsTable, CheckIn>(table),
                  BaseReferences<_$UserDatabase, $CheckInsTable, CheckIn>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $CheckInsTable,
      CheckIn,
      $$CheckInsTableFilterComposer,
      $$CheckInsTableOrderingComposer,
      $$CheckInsTableAnnotationComposer,
      $$CheckInsTableCreateCompanionBuilder,
      $$CheckInsTableUpdateCompanionBuilder,
      (CheckIn, BaseReferences<_$UserDatabase, $CheckInsTable, CheckIn>),
      CheckIn,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$UserDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$UserDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$UserDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$UserDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$UserDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$UserDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSetting>(table),
                  BaseReferences<_$UserDatabase, $AppSettingsTable, AppSetting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$UserDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$UserDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;

class $UserDatabaseManager {
  final _$UserDatabase _db;
  $UserDatabaseManager(this._db);
  $$LearnedWordsTableTableManager get learnedWords =>
      $$LearnedWordsTableTableManager(_db, _db.learnedWords);
  $$CheckInsTableTableManager get checkIns =>
      $$CheckInsTableTableManager(_db, _db.checkIns);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
