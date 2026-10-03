// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $BusinessesTable extends Businesses
    with TableInfo<$BusinessesTable, Business> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BusinessesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _businessTypeMeta = const VerificationMeta(
    'businessType',
  );
  @override
  late final GeneratedColumn<String> businessType = GeneratedColumn<String>(
    'business_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    businessId,
    name,
    address,
    phone,
    businessType,
    description,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'businesses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Business> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('business_type')) {
      context.handle(
        _businessTypeMeta,
        businessType.isAcceptableOrUnknown(
          data['business_type']!,
          _businessTypeMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {businessId};
  @override
  Business map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Business(
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      businessType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_type'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BusinessesTable createAlias(String alias) {
    return $BusinessesTable(attachedDatabase, alias);
  }
}

class Business extends DataClass implements Insertable<Business> {
  final String businessId;
  final String name;
  final String? address;
  final String? phone;
  final String? businessType;
  final String? description;
  final DateTime createdAt;
  const Business({
    required this.businessId,
    required this.name,
    this.address,
    this.phone,
    this.businessType,
    this.description,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['business_id'] = Variable<String>(businessId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || businessType != null) {
      map['business_type'] = Variable<String>(businessType);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BusinessesCompanion toCompanion(bool nullToAbsent) {
    return BusinessesCompanion(
      businessId: Value(businessId),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      businessType: businessType == null && nullToAbsent
          ? const Value.absent()
          : Value(businessType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: Value(createdAt),
    );
  }

  factory Business.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Business(
      businessId: serializer.fromJson<String>(json['businessId']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      phone: serializer.fromJson<String?>(json['phone']),
      businessType: serializer.fromJson<String?>(json['businessType']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'businessId': serializer.toJson<String>(businessId),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'phone': serializer.toJson<String?>(phone),
      'businessType': serializer.toJson<String?>(businessType),
      'description': serializer.toJson<String?>(description),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Business copyWith({
    String? businessId,
    String? name,
    Value<String?> address = const Value.absent(),
    Value<String?> phone = const Value.absent(),
    Value<String?> businessType = const Value.absent(),
    Value<String?> description = const Value.absent(),
    DateTime? createdAt,
  }) => Business(
    businessId: businessId ?? this.businessId,
    name: name ?? this.name,
    address: address.present ? address.value : this.address,
    phone: phone.present ? phone.value : this.phone,
    businessType: businessType.present ? businessType.value : this.businessType,
    description: description.present ? description.value : this.description,
    createdAt: createdAt ?? this.createdAt,
  );
  Business copyWithCompanion(BusinessesCompanion data) {
    return Business(
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      phone: data.phone.present ? data.phone.value : this.phone,
      businessType: data.businessType.present
          ? data.businessType.value
          : this.businessType,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Business(')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('businessType: $businessType, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    businessId,
    name,
    address,
    phone,
    businessType,
    description,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Business &&
          other.businessId == this.businessId &&
          other.name == this.name &&
          other.address == this.address &&
          other.phone == this.phone &&
          other.businessType == this.businessType &&
          other.description == this.description &&
          other.createdAt == this.createdAt);
}

class BusinessesCompanion extends UpdateCompanion<Business> {
  final Value<String> businessId;
  final Value<String> name;
  final Value<String?> address;
  final Value<String?> phone;
  final Value<String?> businessType;
  final Value<String?> description;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BusinessesCompanion({
    this.businessId = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.businessType = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BusinessesCompanion.insert({
    required String businessId,
    required String name,
    this.address = const Value.absent(),
    this.phone = const Value.absent(),
    this.businessType = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : businessId = Value(businessId),
       name = Value(name);
  static Insertable<Business> custom({
    Expression<String>? businessId,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? phone,
    Expression<String>? businessType,
    Expression<String>? description,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (businessId != null) 'business_id': businessId,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (phone != null) 'phone': phone,
      if (businessType != null) 'business_type': businessType,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BusinessesCompanion copyWith({
    Value<String>? businessId,
    Value<String>? name,
    Value<String?>? address,
    Value<String?>? phone,
    Value<String?>? businessType,
    Value<String?>? description,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BusinessesCompanion(
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      businessType: businessType ?? this.businessType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (businessType.present) {
      map['business_type'] = Variable<String>(businessType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BusinessesCompanion(')
          ..write('businessId: $businessId, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('phone: $phone, ')
          ..write('businessType: $businessType, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses (business_id)',
    ),
  );
  static const VerificationMeta _authUserIdMeta = const VerificationMeta(
    'authUserId',
  );
  @override
  late final GeneratedColumn<String> authUserId = GeneratedColumn<String>(
    'auth_user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (role IN (\'super_admin\',\'admin\',\'manager\',\'staff\'))',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'pending\' CHECK (status IN (\'pending\',\'active\',\'inactive\'))',
    defaultValue: const CustomExpression('\'pending\''),
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    businessId,
    authUserId,
    role,
    name,
    email,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    }
    if (data.containsKey('auth_user_id')) {
      context.handle(
        _authUserIdMeta,
        authUserId.isAcceptableOrUnknown(
          data['auth_user_id']!,
          _authUserIdMeta,
        ),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      ),
      authUserId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_user_id'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String accountId;
  final String? businessId;
  final String? authUserId;
  final String role;
  final String name;
  final String email;
  final String status;
  final DateTime createdAt;
  const Account({
    required this.accountId,
    this.businessId,
    this.authUserId,
    required this.role,
    required this.name,
    required this.email,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || businessId != null) {
      map['business_id'] = Variable<String>(businessId);
    }
    if (!nullToAbsent || authUserId != null) {
      map['auth_user_id'] = Variable<String>(authUserId);
    }
    map['role'] = Variable<String>(role);
    map['name'] = Variable<String>(name);
    map['email'] = Variable<String>(email);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      accountId: Value(accountId),
      businessId: businessId == null && nullToAbsent
          ? const Value.absent()
          : Value(businessId),
      authUserId: authUserId == null && nullToAbsent
          ? const Value.absent()
          : Value(authUserId),
      role: Value(role),
      name: Value(name),
      email: Value(email),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      accountId: serializer.fromJson<String>(json['accountId']),
      businessId: serializer.fromJson<String?>(json['businessId']),
      authUserId: serializer.fromJson<String?>(json['authUserId']),
      role: serializer.fromJson<String>(json['role']),
      name: serializer.fromJson<String>(json['name']),
      email: serializer.fromJson<String>(json['email']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'businessId': serializer.toJson<String?>(businessId),
      'authUserId': serializer.toJson<String?>(authUserId),
      'role': serializer.toJson<String>(role),
      'name': serializer.toJson<String>(name),
      'email': serializer.toJson<String>(email),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Account copyWith({
    String? accountId,
    Value<String?> businessId = const Value.absent(),
    Value<String?> authUserId = const Value.absent(),
    String? role,
    String? name,
    String? email,
    String? status,
    DateTime? createdAt,
  }) => Account(
    accountId: accountId ?? this.accountId,
    businessId: businessId.present ? businessId.value : this.businessId,
    authUserId: authUserId.present ? authUserId.value : this.authUserId,
    role: role ?? this.role,
    name: name ?? this.name,
    email: email ?? this.email,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      authUserId: data.authUserId.present
          ? data.authUserId.value
          : this.authUserId,
      role: data.role.present ? data.role.value : this.role,
      name: data.name.present ? data.name.value : this.name,
      email: data.email.present ? data.email.value : this.email,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('accountId: $accountId, ')
          ..write('businessId: $businessId, ')
          ..write('authUserId: $authUserId, ')
          ..write('role: $role, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    businessId,
    authUserId,
    role,
    name,
    email,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.accountId == this.accountId &&
          other.businessId == this.businessId &&
          other.authUserId == this.authUserId &&
          other.role == this.role &&
          other.name == this.name &&
          other.email == this.email &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> accountId;
  final Value<String?> businessId;
  final Value<String?> authUserId;
  final Value<String> role;
  final Value<String> name;
  final Value<String> email;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.accountId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.authUserId = const Value.absent(),
    this.role = const Value.absent(),
    this.name = const Value.absent(),
    this.email = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String accountId,
    this.businessId = const Value.absent(),
    this.authUserId = const Value.absent(),
    required String role,
    required String name,
    required String email,
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       role = Value(role),
       name = Value(name),
       email = Value(email);
  static Insertable<Account> custom({
    Expression<String>? accountId,
    Expression<String>? businessId,
    Expression<String>? authUserId,
    Expression<String>? role,
    Expression<String>? name,
    Expression<String>? email,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (businessId != null) 'business_id': businessId,
      if (authUserId != null) 'auth_user_id': authUserId,
      if (role != null) 'role': role,
      if (name != null) 'name': name,
      if (email != null) 'email': email,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? accountId,
    Value<String?>? businessId,
    Value<String?>? authUserId,
    Value<String>? role,
    Value<String>? name,
    Value<String>? email,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      accountId: accountId ?? this.accountId,
      businessId: businessId ?? this.businessId,
      authUserId: authUserId ?? this.authUserId,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (authUserId.present) {
      map['auth_user_id'] = Variable<String>(authUserId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('accountId: $accountId, ')
          ..write('businessId: $businessId, ')
          ..write('authUserId: $authUserId, ')
          ..write('role: $role, ')
          ..write('name: $name, ')
          ..write('email: $email, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BatchesTable extends Batches with TableInfo<$BatchesTable, Batch> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BatchesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _businessIdMeta = const VerificationMeta(
    'businessId',
  );
  @override
  late final GeneratedColumn<String> businessId = GeneratedColumn<String>(
    'business_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES businesses (business_id)',
    ),
  );
  static const VerificationMeta _assignedStaffIdMeta = const VerificationMeta(
    'assignedStaffId',
  );
  @override
  late final GeneratedColumn<String> assignedStaffId = GeneratedColumn<String>(
    'assigned_staff_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _closedByMeta = const VerificationMeta(
    'closedBy',
  );
  @override
  late final GeneratedColumn<String> closedBy = GeneratedColumn<String>(
    'closed_by',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _batchNameMeta = const VerificationMeta(
    'batchName',
  );
  @override
  late final GeneratedColumn<String> batchName = GeneratedColumn<String>(
    'batch_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _breedMeta = const VerificationMeta('breed');
  @override
  late final GeneratedColumn<String> breed = GeneratedColumn<String>(
    'breed',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startingBirdCountMeta = const VerificationMeta(
    'startingBirdCount',
  );
  @override
  late final GeneratedColumn<int> startingBirdCount = GeneratedColumn<int>(
    'starting_bird_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (starting_bird_count > 0)',
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isClosedMeta = const VerificationMeta(
    'isClosed',
  );
  @override
  late final GeneratedColumn<bool> isClosed = GeneratedColumn<bool>(
    'is_closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_closed" IN (0, 1))',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    batchId,
    businessId,
    assignedStaffId,
    closedBy,
    batchName,
    breed,
    description,
    startingBirdCount,
    startDate,
    isClosed,
    createdAt,
    closedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'batches';
  @override
  VerificationContext validateIntegrity(
    Insertable<Batch> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('business_id')) {
      context.handle(
        _businessIdMeta,
        businessId.isAcceptableOrUnknown(data['business_id']!, _businessIdMeta),
      );
    } else if (isInserting) {
      context.missing(_businessIdMeta);
    }
    if (data.containsKey('assigned_staff_id')) {
      context.handle(
        _assignedStaffIdMeta,
        assignedStaffId.isAcceptableOrUnknown(
          data['assigned_staff_id']!,
          _assignedStaffIdMeta,
        ),
      );
    }
    if (data.containsKey('closed_by')) {
      context.handle(
        _closedByMeta,
        closedBy.isAcceptableOrUnknown(data['closed_by']!, _closedByMeta),
      );
    }
    if (data.containsKey('batch_name')) {
      context.handle(
        _batchNameMeta,
        batchName.isAcceptableOrUnknown(data['batch_name']!, _batchNameMeta),
      );
    } else if (isInserting) {
      context.missing(_batchNameMeta);
    }
    if (data.containsKey('breed')) {
      context.handle(
        _breedMeta,
        breed.isAcceptableOrUnknown(data['breed']!, _breedMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('starting_bird_count')) {
      context.handle(
        _startingBirdCountMeta,
        startingBirdCount.isAcceptableOrUnknown(
          data['starting_bird_count']!,
          _startingBirdCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startingBirdCountMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('is_closed')) {
      context.handle(
        _isClosedMeta,
        isClosed.isAcceptableOrUnknown(data['is_closed']!, _isClosedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {batchId};
  @override
  Batch map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Batch(
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      businessId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}business_id'],
      )!,
      assignedStaffId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}assigned_staff_id'],
      ),
      closedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}closed_by'],
      ),
      batchName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_name'],
      )!,
      breed: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}breed'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      startingBirdCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}starting_bird_count'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      isClosed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_closed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      ),
    );
  }

  @override
  $BatchesTable createAlias(String alias) {
    return $BatchesTable(attachedDatabase, alias);
  }
}

class Batch extends DataClass implements Insertable<Batch> {
  final String batchId;
  final String businessId;
  final String? assignedStaffId;
  final String? closedBy;
  final String batchName;
  final String? breed;
  final String? description;
  final int startingBirdCount;
  final DateTime startDate;
  final bool isClosed;
  final DateTime createdAt;
  final DateTime? closedAt;
  const Batch({
    required this.batchId,
    required this.businessId,
    this.assignedStaffId,
    this.closedBy,
    required this.batchName,
    this.breed,
    this.description,
    required this.startingBirdCount,
    required this.startDate,
    required this.isClosed,
    required this.createdAt,
    this.closedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['batch_id'] = Variable<String>(batchId);
    map['business_id'] = Variable<String>(businessId);
    if (!nullToAbsent || assignedStaffId != null) {
      map['assigned_staff_id'] = Variable<String>(assignedStaffId);
    }
    if (!nullToAbsent || closedBy != null) {
      map['closed_by'] = Variable<String>(closedBy);
    }
    map['batch_name'] = Variable<String>(batchName);
    if (!nullToAbsent || breed != null) {
      map['breed'] = Variable<String>(breed);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['starting_bird_count'] = Variable<int>(startingBirdCount);
    map['start_date'] = Variable<DateTime>(startDate);
    map['is_closed'] = Variable<bool>(isClosed);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || closedAt != null) {
      map['closed_at'] = Variable<DateTime>(closedAt);
    }
    return map;
  }

  BatchesCompanion toCompanion(bool nullToAbsent) {
    return BatchesCompanion(
      batchId: Value(batchId),
      businessId: Value(businessId),
      assignedStaffId: assignedStaffId == null && nullToAbsent
          ? const Value.absent()
          : Value(assignedStaffId),
      closedBy: closedBy == null && nullToAbsent
          ? const Value.absent()
          : Value(closedBy),
      batchName: Value(batchName),
      breed: breed == null && nullToAbsent
          ? const Value.absent()
          : Value(breed),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startingBirdCount: Value(startingBirdCount),
      startDate: Value(startDate),
      isClosed: Value(isClosed),
      createdAt: Value(createdAt),
      closedAt: closedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(closedAt),
    );
  }

  factory Batch.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Batch(
      batchId: serializer.fromJson<String>(json['batchId']),
      businessId: serializer.fromJson<String>(json['businessId']),
      assignedStaffId: serializer.fromJson<String?>(json['assignedStaffId']),
      closedBy: serializer.fromJson<String?>(json['closedBy']),
      batchName: serializer.fromJson<String>(json['batchName']),
      breed: serializer.fromJson<String?>(json['breed']),
      description: serializer.fromJson<String?>(json['description']),
      startingBirdCount: serializer.fromJson<int>(json['startingBirdCount']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      isClosed: serializer.fromJson<bool>(json['isClosed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      closedAt: serializer.fromJson<DateTime?>(json['closedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'batchId': serializer.toJson<String>(batchId),
      'businessId': serializer.toJson<String>(businessId),
      'assignedStaffId': serializer.toJson<String?>(assignedStaffId),
      'closedBy': serializer.toJson<String?>(closedBy),
      'batchName': serializer.toJson<String>(batchName),
      'breed': serializer.toJson<String?>(breed),
      'description': serializer.toJson<String?>(description),
      'startingBirdCount': serializer.toJson<int>(startingBirdCount),
      'startDate': serializer.toJson<DateTime>(startDate),
      'isClosed': serializer.toJson<bool>(isClosed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'closedAt': serializer.toJson<DateTime?>(closedAt),
    };
  }

  Batch copyWith({
    String? batchId,
    String? businessId,
    Value<String?> assignedStaffId = const Value.absent(),
    Value<String?> closedBy = const Value.absent(),
    String? batchName,
    Value<String?> breed = const Value.absent(),
    Value<String?> description = const Value.absent(),
    int? startingBirdCount,
    DateTime? startDate,
    bool? isClosed,
    DateTime? createdAt,
    Value<DateTime?> closedAt = const Value.absent(),
  }) => Batch(
    batchId: batchId ?? this.batchId,
    businessId: businessId ?? this.businessId,
    assignedStaffId: assignedStaffId.present
        ? assignedStaffId.value
        : this.assignedStaffId,
    closedBy: closedBy.present ? closedBy.value : this.closedBy,
    batchName: batchName ?? this.batchName,
    breed: breed.present ? breed.value : this.breed,
    description: description.present ? description.value : this.description,
    startingBirdCount: startingBirdCount ?? this.startingBirdCount,
    startDate: startDate ?? this.startDate,
    isClosed: isClosed ?? this.isClosed,
    createdAt: createdAt ?? this.createdAt,
    closedAt: closedAt.present ? closedAt.value : this.closedAt,
  );
  Batch copyWithCompanion(BatchesCompanion data) {
    return Batch(
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      businessId: data.businessId.present
          ? data.businessId.value
          : this.businessId,
      assignedStaffId: data.assignedStaffId.present
          ? data.assignedStaffId.value
          : this.assignedStaffId,
      closedBy: data.closedBy.present ? data.closedBy.value : this.closedBy,
      batchName: data.batchName.present ? data.batchName.value : this.batchName,
      breed: data.breed.present ? data.breed.value : this.breed,
      description: data.description.present
          ? data.description.value
          : this.description,
      startingBirdCount: data.startingBirdCount.present
          ? data.startingBirdCount.value
          : this.startingBirdCount,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      isClosed: data.isClosed.present ? data.isClosed.value : this.isClosed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Batch(')
          ..write('batchId: $batchId, ')
          ..write('businessId: $businessId, ')
          ..write('assignedStaffId: $assignedStaffId, ')
          ..write('closedBy: $closedBy, ')
          ..write('batchName: $batchName, ')
          ..write('breed: $breed, ')
          ..write('description: $description, ')
          ..write('startingBirdCount: $startingBirdCount, ')
          ..write('startDate: $startDate, ')
          ..write('isClosed: $isClosed, ')
          ..write('createdAt: $createdAt, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    batchId,
    businessId,
    assignedStaffId,
    closedBy,
    batchName,
    breed,
    description,
    startingBirdCount,
    startDate,
    isClosed,
    createdAt,
    closedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Batch &&
          other.batchId == this.batchId &&
          other.businessId == this.businessId &&
          other.assignedStaffId == this.assignedStaffId &&
          other.closedBy == this.closedBy &&
          other.batchName == this.batchName &&
          other.breed == this.breed &&
          other.description == this.description &&
          other.startingBirdCount == this.startingBirdCount &&
          other.startDate == this.startDate &&
          other.isClosed == this.isClosed &&
          other.createdAt == this.createdAt &&
          other.closedAt == this.closedAt);
}

class BatchesCompanion extends UpdateCompanion<Batch> {
  final Value<String> batchId;
  final Value<String> businessId;
  final Value<String?> assignedStaffId;
  final Value<String?> closedBy;
  final Value<String> batchName;
  final Value<String?> breed;
  final Value<String?> description;
  final Value<int> startingBirdCount;
  final Value<DateTime> startDate;
  final Value<bool> isClosed;
  final Value<DateTime> createdAt;
  final Value<DateTime?> closedAt;
  final Value<int> rowid;
  const BatchesCompanion({
    this.batchId = const Value.absent(),
    this.businessId = const Value.absent(),
    this.assignedStaffId = const Value.absent(),
    this.closedBy = const Value.absent(),
    this.batchName = const Value.absent(),
    this.breed = const Value.absent(),
    this.description = const Value.absent(),
    this.startingBirdCount = const Value.absent(),
    this.startDate = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BatchesCompanion.insert({
    required String batchId,
    required String businessId,
    this.assignedStaffId = const Value.absent(),
    this.closedBy = const Value.absent(),
    required String batchName,
    this.breed = const Value.absent(),
    this.description = const Value.absent(),
    required int startingBirdCount,
    required DateTime startDate,
    this.isClosed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : batchId = Value(batchId),
       businessId = Value(businessId),
       batchName = Value(batchName),
       startingBirdCount = Value(startingBirdCount),
       startDate = Value(startDate);
  static Insertable<Batch> custom({
    Expression<String>? batchId,
    Expression<String>? businessId,
    Expression<String>? assignedStaffId,
    Expression<String>? closedBy,
    Expression<String>? batchName,
    Expression<String>? breed,
    Expression<String>? description,
    Expression<int>? startingBirdCount,
    Expression<DateTime>? startDate,
    Expression<bool>? isClosed,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? closedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (batchId != null) 'batch_id': batchId,
      if (businessId != null) 'business_id': businessId,
      if (assignedStaffId != null) 'assigned_staff_id': assignedStaffId,
      if (closedBy != null) 'closed_by': closedBy,
      if (batchName != null) 'batch_name': batchName,
      if (breed != null) 'breed': breed,
      if (description != null) 'description': description,
      if (startingBirdCount != null) 'starting_bird_count': startingBirdCount,
      if (startDate != null) 'start_date': startDate,
      if (isClosed != null) 'is_closed': isClosed,
      if (createdAt != null) 'created_at': createdAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BatchesCompanion copyWith({
    Value<String>? batchId,
    Value<String>? businessId,
    Value<String?>? assignedStaffId,
    Value<String?>? closedBy,
    Value<String>? batchName,
    Value<String?>? breed,
    Value<String?>? description,
    Value<int>? startingBirdCount,
    Value<DateTime>? startDate,
    Value<bool>? isClosed,
    Value<DateTime>? createdAt,
    Value<DateTime?>? closedAt,
    Value<int>? rowid,
  }) {
    return BatchesCompanion(
      batchId: batchId ?? this.batchId,
      businessId: businessId ?? this.businessId,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      closedBy: closedBy ?? this.closedBy,
      batchName: batchName ?? this.batchName,
      breed: breed ?? this.breed,
      description: description ?? this.description,
      startingBirdCount: startingBirdCount ?? this.startingBirdCount,
      startDate: startDate ?? this.startDate,
      isClosed: isClosed ?? this.isClosed,
      createdAt: createdAt ?? this.createdAt,
      closedAt: closedAt ?? this.closedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (businessId.present) {
      map['business_id'] = Variable<String>(businessId.value);
    }
    if (assignedStaffId.present) {
      map['assigned_staff_id'] = Variable<String>(assignedStaffId.value);
    }
    if (closedBy.present) {
      map['closed_by'] = Variable<String>(closedBy.value);
    }
    if (batchName.present) {
      map['batch_name'] = Variable<String>(batchName.value);
    }
    if (breed.present) {
      map['breed'] = Variable<String>(breed.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startingBirdCount.present) {
      map['starting_bird_count'] = Variable<int>(startingBirdCount.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (isClosed.present) {
      map['is_closed'] = Variable<bool>(isClosed.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BatchesCompanion(')
          ..write('batchId: $batchId, ')
          ..write('businessId: $businessId, ')
          ..write('assignedStaffId: $assignedStaffId, ')
          ..write('closedBy: $closedBy, ')
          ..write('batchName: $batchName, ')
          ..write('breed: $breed, ')
          ..write('description: $description, ')
          ..write('startingBirdCount: $startingBirdCount, ')
          ..write('startDate: $startDate, ')
          ..write('isClosed: $isClosed, ')
          ..write('createdAt: $createdAt, ')
          ..write('closedAt: $closedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES batches (batch_id)',
    ),
  );
  static const VerificationMeta _recordedByMeta = const VerificationMeta(
    'recordedBy',
  );
  @override
  late final GeneratedColumn<String> recordedBy = GeneratedColumn<String>(
    'recorded_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (category IN (\'chicks\',\'feed\',\'vet_medication\',\'other\'))',
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (amount > 0)',
  );
  static const VerificationMeta _feedTypeMeta = const VerificationMeta(
    'feedType',
  );
  @override
  late final GeneratedColumn<String> feedType = GeneratedColumn<String>(
    'feed_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicationNameMeta = const VerificationMeta(
    'medicationName',
  );
  @override
  late final GeneratedColumn<String> medicationName = GeneratedColumn<String>(
    'medication_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    expenseId,
    batchId,
    recordedBy,
    category,
    date,
    quantity,
    unitPrice,
    amount,
    feedType,
    medicationName,
    description,
    recordedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('recorded_by')) {
      context.handle(
        _recordedByMeta,
        recordedBy.isAcceptableOrUnknown(data['recorded_by']!, _recordedByMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedByMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('feed_type')) {
      context.handle(
        _feedTypeMeta,
        feedType.isAcceptableOrUnknown(data['feed_type']!, _feedTypeMeta),
      );
    }
    if (data.containsKey('medication_name')) {
      context.handle(
        _medicationNameMeta,
        medicationName.isAcceptableOrUnknown(
          data['medication_name']!,
          _medicationNameMeta,
        ),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {expenseId};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      recordedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      ),
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      feedType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_type'],
      ),
      medicationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_name'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String expenseId;
  final String batchId;
  final String recordedBy;
  final String category;
  final DateTime date;
  final double? quantity;
  final double? unitPrice;
  final double amount;
  final String? feedType;
  final String? medicationName;
  final String? description;
  final DateTime recordedAt;
  final DateTime syncedAt;
  const Expense({
    required this.expenseId,
    required this.batchId,
    required this.recordedBy,
    required this.category,
    required this.date,
    this.quantity,
    this.unitPrice,
    required this.amount,
    this.feedType,
    this.medicationName,
    this.description,
    required this.recordedAt,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['expense_id'] = Variable<String>(expenseId);
    map['batch_id'] = Variable<String>(batchId);
    map['recorded_by'] = Variable<String>(recordedBy);
    map['category'] = Variable<String>(category);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || quantity != null) {
      map['quantity'] = Variable<double>(quantity);
    }
    if (!nullToAbsent || unitPrice != null) {
      map['unit_price'] = Variable<double>(unitPrice);
    }
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || feedType != null) {
      map['feed_type'] = Variable<String>(feedType);
    }
    if (!nullToAbsent || medicationName != null) {
      map['medication_name'] = Variable<String>(medicationName);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      expenseId: Value(expenseId),
      batchId: Value(batchId),
      recordedBy: Value(recordedBy),
      category: Value(category),
      date: Value(date),
      quantity: quantity == null && nullToAbsent
          ? const Value.absent()
          : Value(quantity),
      unitPrice: unitPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPrice),
      amount: Value(amount),
      feedType: feedType == null && nullToAbsent
          ? const Value.absent()
          : Value(feedType),
      medicationName: medicationName == null && nullToAbsent
          ? const Value.absent()
          : Value(medicationName),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      recordedAt: Value(recordedAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      expenseId: serializer.fromJson<String>(json['expenseId']),
      batchId: serializer.fromJson<String>(json['batchId']),
      recordedBy: serializer.fromJson<String>(json['recordedBy']),
      category: serializer.fromJson<String>(json['category']),
      date: serializer.fromJson<DateTime>(json['date']),
      quantity: serializer.fromJson<double?>(json['quantity']),
      unitPrice: serializer.fromJson<double?>(json['unitPrice']),
      amount: serializer.fromJson<double>(json['amount']),
      feedType: serializer.fromJson<String?>(json['feedType']),
      medicationName: serializer.fromJson<String?>(json['medicationName']),
      description: serializer.fromJson<String?>(json['description']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'expenseId': serializer.toJson<String>(expenseId),
      'batchId': serializer.toJson<String>(batchId),
      'recordedBy': serializer.toJson<String>(recordedBy),
      'category': serializer.toJson<String>(category),
      'date': serializer.toJson<DateTime>(date),
      'quantity': serializer.toJson<double?>(quantity),
      'unitPrice': serializer.toJson<double?>(unitPrice),
      'amount': serializer.toJson<double>(amount),
      'feedType': serializer.toJson<String?>(feedType),
      'medicationName': serializer.toJson<String?>(medicationName),
      'description': serializer.toJson<String?>(description),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  Expense copyWith({
    String? expenseId,
    String? batchId,
    String? recordedBy,
    String? category,
    DateTime? date,
    Value<double?> quantity = const Value.absent(),
    Value<double?> unitPrice = const Value.absent(),
    double? amount,
    Value<String?> feedType = const Value.absent(),
    Value<String?> medicationName = const Value.absent(),
    Value<String?> description = const Value.absent(),
    DateTime? recordedAt,
    DateTime? syncedAt,
  }) => Expense(
    expenseId: expenseId ?? this.expenseId,
    batchId: batchId ?? this.batchId,
    recordedBy: recordedBy ?? this.recordedBy,
    category: category ?? this.category,
    date: date ?? this.date,
    quantity: quantity.present ? quantity.value : this.quantity,
    unitPrice: unitPrice.present ? unitPrice.value : this.unitPrice,
    amount: amount ?? this.amount,
    feedType: feedType.present ? feedType.value : this.feedType,
    medicationName: medicationName.present
        ? medicationName.value
        : this.medicationName,
    description: description.present ? description.value : this.description,
    recordedAt: recordedAt ?? this.recordedAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      recordedBy: data.recordedBy.present
          ? data.recordedBy.value
          : this.recordedBy,
      category: data.category.present ? data.category.value : this.category,
      date: data.date.present ? data.date.value : this.date,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      amount: data.amount.present ? data.amount.value : this.amount,
      feedType: data.feedType.present ? data.feedType.value : this.feedType,
      medicationName: data.medicationName.present
          ? data.medicationName.value
          : this.medicationName,
      description: data.description.present
          ? data.description.value
          : this.description,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('expenseId: $expenseId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('amount: $amount, ')
          ..write('feedType: $feedType, ')
          ..write('medicationName: $medicationName, ')
          ..write('description: $description, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    expenseId,
    batchId,
    recordedBy,
    category,
    date,
    quantity,
    unitPrice,
    amount,
    feedType,
    medicationName,
    description,
    recordedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.expenseId == this.expenseId &&
          other.batchId == this.batchId &&
          other.recordedBy == this.recordedBy &&
          other.category == this.category &&
          other.date == this.date &&
          other.quantity == this.quantity &&
          other.unitPrice == this.unitPrice &&
          other.amount == this.amount &&
          other.feedType == this.feedType &&
          other.medicationName == this.medicationName &&
          other.description == this.description &&
          other.recordedAt == this.recordedAt &&
          other.syncedAt == this.syncedAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> expenseId;
  final Value<String> batchId;
  final Value<String> recordedBy;
  final Value<String> category;
  final Value<DateTime> date;
  final Value<double?> quantity;
  final Value<double?> unitPrice;
  final Value<double> amount;
  final Value<String?> feedType;
  final Value<String?> medicationName;
  final Value<String?> description;
  final Value<DateTime> recordedAt;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.expenseId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.category = const Value.absent(),
    this.date = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.amount = const Value.absent(),
    this.feedType = const Value.absent(),
    this.medicationName = const Value.absent(),
    this.description = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String expenseId,
    required String batchId,
    required String recordedBy,
    required String category,
    required DateTime date,
    this.quantity = const Value.absent(),
    this.unitPrice = const Value.absent(),
    required double amount,
    this.feedType = const Value.absent(),
    this.medicationName = const Value.absent(),
    this.description = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : expenseId = Value(expenseId),
       batchId = Value(batchId),
       recordedBy = Value(recordedBy),
       category = Value(category),
       date = Value(date),
       amount = Value(amount);
  static Insertable<Expense> custom({
    Expression<String>? expenseId,
    Expression<String>? batchId,
    Expression<String>? recordedBy,
    Expression<String>? category,
    Expression<DateTime>? date,
    Expression<double>? quantity,
    Expression<double>? unitPrice,
    Expression<double>? amount,
    Expression<String>? feedType,
    Expression<String>? medicationName,
    Expression<String>? description,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (expenseId != null) 'expense_id': expenseId,
      if (batchId != null) 'batch_id': batchId,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (category != null) 'category': category,
      if (date != null) 'date': date,
      if (quantity != null) 'quantity': quantity,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (amount != null) 'amount': amount,
      if (feedType != null) 'feed_type': feedType,
      if (medicationName != null) 'medication_name': medicationName,
      if (description != null) 'description': description,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? expenseId,
    Value<String>? batchId,
    Value<String>? recordedBy,
    Value<String>? category,
    Value<DateTime>? date,
    Value<double?>? quantity,
    Value<double?>? unitPrice,
    Value<double>? amount,
    Value<String?>? feedType,
    Value<String?>? medicationName,
    Value<String?>? description,
    Value<DateTime>? recordedAt,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      expenseId: expenseId ?? this.expenseId,
      batchId: batchId ?? this.batchId,
      recordedBy: recordedBy ?? this.recordedBy,
      category: category ?? this.category,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      amount: amount ?? this.amount,
      feedType: feedType ?? this.feedType,
      medicationName: medicationName ?? this.medicationName,
      description: description ?? this.description,
      recordedAt: recordedAt ?? this.recordedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (recordedBy.present) {
      map['recorded_by'] = Variable<String>(recordedBy.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (feedType.present) {
      map['feed_type'] = Variable<String>(feedType.value);
    }
    if (medicationName.present) {
      map['medication_name'] = Variable<String>(medicationName.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('expenseId: $expenseId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('category: $category, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('amount: $amount, ')
          ..write('feedType: $feedType, ')
          ..write('medicationName: $medicationName, ')
          ..write('description: $description, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MortalityEntriesTable extends MortalityEntries
    with TableInfo<$MortalityEntriesTable, MortalityEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MortalityEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mortalityIdMeta = const VerificationMeta(
    'mortalityId',
  );
  @override
  late final GeneratedColumn<String> mortalityId = GeneratedColumn<String>(
    'mortality_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES batches (batch_id)',
    ),
  );
  static const VerificationMeta _recordedByMeta = const VerificationMeta(
    'recordedBy',
  );
  @override
  late final GeneratedColumn<String> recordedBy = GeneratedColumn<String>(
    'recorded_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (count >= 1)',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    mortalityId,
    batchId,
    recordedBy,
    date,
    count,
    description,
    recordedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mortality_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MortalityEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mortality_id')) {
      context.handle(
        _mortalityIdMeta,
        mortalityId.isAcceptableOrUnknown(
          data['mortality_id']!,
          _mortalityIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mortalityIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('recorded_by')) {
      context.handle(
        _recordedByMeta,
        recordedBy.isAcceptableOrUnknown(data['recorded_by']!, _recordedByMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedByMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    } else if (isInserting) {
      context.missing(_countMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mortalityId};
  @override
  MortalityEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MortalityEntry(
      mortalityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mortality_id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      recordedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $MortalityEntriesTable createAlias(String alias) {
    return $MortalityEntriesTable(attachedDatabase, alias);
  }
}

class MortalityEntry extends DataClass implements Insertable<MortalityEntry> {
  final String mortalityId;
  final String batchId;
  final String recordedBy;
  final DateTime date;
  final int count;
  final String? description;
  final DateTime recordedAt;
  final DateTime syncedAt;
  const MortalityEntry({
    required this.mortalityId,
    required this.batchId,
    required this.recordedBy,
    required this.date,
    required this.count,
    this.description,
    required this.recordedAt,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mortality_id'] = Variable<String>(mortalityId);
    map['batch_id'] = Variable<String>(batchId);
    map['recorded_by'] = Variable<String>(recordedBy);
    map['date'] = Variable<DateTime>(date);
    map['count'] = Variable<int>(count);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  MortalityEntriesCompanion toCompanion(bool nullToAbsent) {
    return MortalityEntriesCompanion(
      mortalityId: Value(mortalityId),
      batchId: Value(batchId),
      recordedBy: Value(recordedBy),
      date: Value(date),
      count: Value(count),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      recordedAt: Value(recordedAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory MortalityEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MortalityEntry(
      mortalityId: serializer.fromJson<String>(json['mortalityId']),
      batchId: serializer.fromJson<String>(json['batchId']),
      recordedBy: serializer.fromJson<String>(json['recordedBy']),
      date: serializer.fromJson<DateTime>(json['date']),
      count: serializer.fromJson<int>(json['count']),
      description: serializer.fromJson<String?>(json['description']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mortalityId': serializer.toJson<String>(mortalityId),
      'batchId': serializer.toJson<String>(batchId),
      'recordedBy': serializer.toJson<String>(recordedBy),
      'date': serializer.toJson<DateTime>(date),
      'count': serializer.toJson<int>(count),
      'description': serializer.toJson<String?>(description),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  MortalityEntry copyWith({
    String? mortalityId,
    String? batchId,
    String? recordedBy,
    DateTime? date,
    int? count,
    Value<String?> description = const Value.absent(),
    DateTime? recordedAt,
    DateTime? syncedAt,
  }) => MortalityEntry(
    mortalityId: mortalityId ?? this.mortalityId,
    batchId: batchId ?? this.batchId,
    recordedBy: recordedBy ?? this.recordedBy,
    date: date ?? this.date,
    count: count ?? this.count,
    description: description.present ? description.value : this.description,
    recordedAt: recordedAt ?? this.recordedAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  MortalityEntry copyWithCompanion(MortalityEntriesCompanion data) {
    return MortalityEntry(
      mortalityId: data.mortalityId.present
          ? data.mortalityId.value
          : this.mortalityId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      recordedBy: data.recordedBy.present
          ? data.recordedBy.value
          : this.recordedBy,
      date: data.date.present ? data.date.value : this.date,
      count: data.count.present ? data.count.value : this.count,
      description: data.description.present
          ? data.description.value
          : this.description,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MortalityEntry(')
          ..write('mortalityId: $mortalityId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('count: $count, ')
          ..write('description: $description, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    mortalityId,
    batchId,
    recordedBy,
    date,
    count,
    description,
    recordedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MortalityEntry &&
          other.mortalityId == this.mortalityId &&
          other.batchId == this.batchId &&
          other.recordedBy == this.recordedBy &&
          other.date == this.date &&
          other.count == this.count &&
          other.description == this.description &&
          other.recordedAt == this.recordedAt &&
          other.syncedAt == this.syncedAt);
}

class MortalityEntriesCompanion extends UpdateCompanion<MortalityEntry> {
  final Value<String> mortalityId;
  final Value<String> batchId;
  final Value<String> recordedBy;
  final Value<DateTime> date;
  final Value<int> count;
  final Value<String?> description;
  final Value<DateTime> recordedAt;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const MortalityEntriesCompanion({
    this.mortalityId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.date = const Value.absent(),
    this.count = const Value.absent(),
    this.description = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MortalityEntriesCompanion.insert({
    required String mortalityId,
    required String batchId,
    required String recordedBy,
    required DateTime date,
    required int count,
    this.description = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mortalityId = Value(mortalityId),
       batchId = Value(batchId),
       recordedBy = Value(recordedBy),
       date = Value(date),
       count = Value(count);
  static Insertable<MortalityEntry> custom({
    Expression<String>? mortalityId,
    Expression<String>? batchId,
    Expression<String>? recordedBy,
    Expression<DateTime>? date,
    Expression<int>? count,
    Expression<String>? description,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mortalityId != null) 'mortality_id': mortalityId,
      if (batchId != null) 'batch_id': batchId,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (date != null) 'date': date,
      if (count != null) 'count': count,
      if (description != null) 'description': description,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MortalityEntriesCompanion copyWith({
    Value<String>? mortalityId,
    Value<String>? batchId,
    Value<String>? recordedBy,
    Value<DateTime>? date,
    Value<int>? count,
    Value<String?>? description,
    Value<DateTime>? recordedAt,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return MortalityEntriesCompanion(
      mortalityId: mortalityId ?? this.mortalityId,
      batchId: batchId ?? this.batchId,
      recordedBy: recordedBy ?? this.recordedBy,
      date: date ?? this.date,
      count: count ?? this.count,
      description: description ?? this.description,
      recordedAt: recordedAt ?? this.recordedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mortalityId.present) {
      map['mortality_id'] = Variable<String>(mortalityId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (recordedBy.present) {
      map['recorded_by'] = Variable<String>(recordedBy.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MortalityEntriesCompanion(')
          ..write('mortalityId: $mortalityId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('count: $count, ')
          ..write('description: $description, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FeedEntriesTable extends FeedEntries
    with TableInfo<$FeedEntriesTable, FeedEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FeedEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _feedEntryIdMeta = const VerificationMeta(
    'feedEntryId',
  );
  @override
  late final GeneratedColumn<String> feedEntryId = GeneratedColumn<String>(
    'feed_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES batches (batch_id)',
    ),
  );
  static const VerificationMeta _recordedByMeta = const VerificationMeta(
    'recordedBy',
  );
  @override
  late final GeneratedColumn<String> recordedBy = GeneratedColumn<String>(
    'recorded_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (quantity > 0)',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    feedEntryId,
    batchId,
    recordedBy,
    date,
    quantity,
    recordedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'feed_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<FeedEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('feed_entry_id')) {
      context.handle(
        _feedEntryIdMeta,
        feedEntryId.isAcceptableOrUnknown(
          data['feed_entry_id']!,
          _feedEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_feedEntryIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('recorded_by')) {
      context.handle(
        _recordedByMeta,
        recordedBy.isAcceptableOrUnknown(data['recorded_by']!, _recordedByMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedByMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {feedEntryId};
  @override
  FeedEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FeedEntry(
      feedEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_entry_id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      recordedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $FeedEntriesTable createAlias(String alias) {
    return $FeedEntriesTable(attachedDatabase, alias);
  }
}

class FeedEntry extends DataClass implements Insertable<FeedEntry> {
  final String feedEntryId;
  final String batchId;
  final String recordedBy;
  final DateTime date;
  final double quantity;
  final DateTime recordedAt;
  final DateTime syncedAt;
  const FeedEntry({
    required this.feedEntryId,
    required this.batchId,
    required this.recordedBy,
    required this.date,
    required this.quantity,
    required this.recordedAt,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['feed_entry_id'] = Variable<String>(feedEntryId);
    map['batch_id'] = Variable<String>(batchId);
    map['recorded_by'] = Variable<String>(recordedBy);
    map['date'] = Variable<DateTime>(date);
    map['quantity'] = Variable<double>(quantity);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  FeedEntriesCompanion toCompanion(bool nullToAbsent) {
    return FeedEntriesCompanion(
      feedEntryId: Value(feedEntryId),
      batchId: Value(batchId),
      recordedBy: Value(recordedBy),
      date: Value(date),
      quantity: Value(quantity),
      recordedAt: Value(recordedAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory FeedEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FeedEntry(
      feedEntryId: serializer.fromJson<String>(json['feedEntryId']),
      batchId: serializer.fromJson<String>(json['batchId']),
      recordedBy: serializer.fromJson<String>(json['recordedBy']),
      date: serializer.fromJson<DateTime>(json['date']),
      quantity: serializer.fromJson<double>(json['quantity']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'feedEntryId': serializer.toJson<String>(feedEntryId),
      'batchId': serializer.toJson<String>(batchId),
      'recordedBy': serializer.toJson<String>(recordedBy),
      'date': serializer.toJson<DateTime>(date),
      'quantity': serializer.toJson<double>(quantity),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  FeedEntry copyWith({
    String? feedEntryId,
    String? batchId,
    String? recordedBy,
    DateTime? date,
    double? quantity,
    DateTime? recordedAt,
    DateTime? syncedAt,
  }) => FeedEntry(
    feedEntryId: feedEntryId ?? this.feedEntryId,
    batchId: batchId ?? this.batchId,
    recordedBy: recordedBy ?? this.recordedBy,
    date: date ?? this.date,
    quantity: quantity ?? this.quantity,
    recordedAt: recordedAt ?? this.recordedAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  FeedEntry copyWithCompanion(FeedEntriesCompanion data) {
    return FeedEntry(
      feedEntryId: data.feedEntryId.present
          ? data.feedEntryId.value
          : this.feedEntryId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      recordedBy: data.recordedBy.present
          ? data.recordedBy.value
          : this.recordedBy,
      date: data.date.present ? data.date.value : this.date,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FeedEntry(')
          ..write('feedEntryId: $feedEntryId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    feedEntryId,
    batchId,
    recordedBy,
    date,
    quantity,
    recordedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FeedEntry &&
          other.feedEntryId == this.feedEntryId &&
          other.batchId == this.batchId &&
          other.recordedBy == this.recordedBy &&
          other.date == this.date &&
          other.quantity == this.quantity &&
          other.recordedAt == this.recordedAt &&
          other.syncedAt == this.syncedAt);
}

class FeedEntriesCompanion extends UpdateCompanion<FeedEntry> {
  final Value<String> feedEntryId;
  final Value<String> batchId;
  final Value<String> recordedBy;
  final Value<DateTime> date;
  final Value<double> quantity;
  final Value<DateTime> recordedAt;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const FeedEntriesCompanion({
    this.feedEntryId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.date = const Value.absent(),
    this.quantity = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FeedEntriesCompanion.insert({
    required String feedEntryId,
    required String batchId,
    required String recordedBy,
    required DateTime date,
    required double quantity,
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : feedEntryId = Value(feedEntryId),
       batchId = Value(batchId),
       recordedBy = Value(recordedBy),
       date = Value(date),
       quantity = Value(quantity);
  static Insertable<FeedEntry> custom({
    Expression<String>? feedEntryId,
    Expression<String>? batchId,
    Expression<String>? recordedBy,
    Expression<DateTime>? date,
    Expression<double>? quantity,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (feedEntryId != null) 'feed_entry_id': feedEntryId,
      if (batchId != null) 'batch_id': batchId,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (date != null) 'date': date,
      if (quantity != null) 'quantity': quantity,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FeedEntriesCompanion copyWith({
    Value<String>? feedEntryId,
    Value<String>? batchId,
    Value<String>? recordedBy,
    Value<DateTime>? date,
    Value<double>? quantity,
    Value<DateTime>? recordedAt,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return FeedEntriesCompanion(
      feedEntryId: feedEntryId ?? this.feedEntryId,
      batchId: batchId ?? this.batchId,
      recordedBy: recordedBy ?? this.recordedBy,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      recordedAt: recordedAt ?? this.recordedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (feedEntryId.present) {
      map['feed_entry_id'] = Variable<String>(feedEntryId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (recordedBy.present) {
      map['recorded_by'] = Variable<String>(recordedBy.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FeedEntriesCompanion(')
          ..write('feedEntryId: $feedEntryId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('quantity: $quantity, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeightSamplesTable extends WeightSamples
    with TableInfo<$WeightSamplesTable, WeightSample> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeightSamplesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _weightSampleIdMeta = const VerificationMeta(
    'weightSampleId',
  );
  @override
  late final GeneratedColumn<String> weightSampleId = GeneratedColumn<String>(
    'weight_sample_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES batches (batch_id)',
    ),
  );
  static const VerificationMeta _recordedByMeta = const VerificationMeta(
    'recordedBy',
  );
  @override
  late final GeneratedColumn<String> recordedBy = GeneratedColumn<String>(
    'recorded_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sampleWeightMeta = const VerificationMeta(
    'sampleWeight',
  );
  @override
  late final GeneratedColumn<double> sampleWeight = GeneratedColumn<double>(
    'sample_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (sample_weight > 0)',
  );
  static const VerificationMeta _sampleCountMeta = const VerificationMeta(
    'sampleCount',
  );
  @override
  late final GeneratedColumn<int> sampleCount = GeneratedColumn<int>(
    'sample_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (sample_count > 0)',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    weightSampleId,
    batchId,
    recordedBy,
    date,
    sampleWeight,
    sampleCount,
    recordedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weight_samples';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeightSample> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('weight_sample_id')) {
      context.handle(
        _weightSampleIdMeta,
        weightSampleId.isAcceptableOrUnknown(
          data['weight_sample_id']!,
          _weightSampleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weightSampleIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('recorded_by')) {
      context.handle(
        _recordedByMeta,
        recordedBy.isAcceptableOrUnknown(data['recorded_by']!, _recordedByMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedByMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('sample_weight')) {
      context.handle(
        _sampleWeightMeta,
        sampleWeight.isAcceptableOrUnknown(
          data['sample_weight']!,
          _sampleWeightMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sampleWeightMeta);
    }
    if (data.containsKey('sample_count')) {
      context.handle(
        _sampleCountMeta,
        sampleCount.isAcceptableOrUnknown(
          data['sample_count']!,
          _sampleCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sampleCountMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {weightSampleId};
  @override
  WeightSample map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeightSample(
      weightSampleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weight_sample_id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      recordedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      sampleWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sample_weight'],
      )!,
      sampleCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sample_count'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $WeightSamplesTable createAlias(String alias) {
    return $WeightSamplesTable(attachedDatabase, alias);
  }
}

class WeightSample extends DataClass implements Insertable<WeightSample> {
  final String weightSampleId;
  final String batchId;
  final String recordedBy;
  final DateTime date;
  final double sampleWeight;
  final int sampleCount;
  final DateTime recordedAt;
  final DateTime syncedAt;
  const WeightSample({
    required this.weightSampleId,
    required this.batchId,
    required this.recordedBy,
    required this.date,
    required this.sampleWeight,
    required this.sampleCount,
    required this.recordedAt,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['weight_sample_id'] = Variable<String>(weightSampleId);
    map['batch_id'] = Variable<String>(batchId);
    map['recorded_by'] = Variable<String>(recordedBy);
    map['date'] = Variable<DateTime>(date);
    map['sample_weight'] = Variable<double>(sampleWeight);
    map['sample_count'] = Variable<int>(sampleCount);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  WeightSamplesCompanion toCompanion(bool nullToAbsent) {
    return WeightSamplesCompanion(
      weightSampleId: Value(weightSampleId),
      batchId: Value(batchId),
      recordedBy: Value(recordedBy),
      date: Value(date),
      sampleWeight: Value(sampleWeight),
      sampleCount: Value(sampleCount),
      recordedAt: Value(recordedAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory WeightSample.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeightSample(
      weightSampleId: serializer.fromJson<String>(json['weightSampleId']),
      batchId: serializer.fromJson<String>(json['batchId']),
      recordedBy: serializer.fromJson<String>(json['recordedBy']),
      date: serializer.fromJson<DateTime>(json['date']),
      sampleWeight: serializer.fromJson<double>(json['sampleWeight']),
      sampleCount: serializer.fromJson<int>(json['sampleCount']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'weightSampleId': serializer.toJson<String>(weightSampleId),
      'batchId': serializer.toJson<String>(batchId),
      'recordedBy': serializer.toJson<String>(recordedBy),
      'date': serializer.toJson<DateTime>(date),
      'sampleWeight': serializer.toJson<double>(sampleWeight),
      'sampleCount': serializer.toJson<int>(sampleCount),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  WeightSample copyWith({
    String? weightSampleId,
    String? batchId,
    String? recordedBy,
    DateTime? date,
    double? sampleWeight,
    int? sampleCount,
    DateTime? recordedAt,
    DateTime? syncedAt,
  }) => WeightSample(
    weightSampleId: weightSampleId ?? this.weightSampleId,
    batchId: batchId ?? this.batchId,
    recordedBy: recordedBy ?? this.recordedBy,
    date: date ?? this.date,
    sampleWeight: sampleWeight ?? this.sampleWeight,
    sampleCount: sampleCount ?? this.sampleCount,
    recordedAt: recordedAt ?? this.recordedAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  WeightSample copyWithCompanion(WeightSamplesCompanion data) {
    return WeightSample(
      weightSampleId: data.weightSampleId.present
          ? data.weightSampleId.value
          : this.weightSampleId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      recordedBy: data.recordedBy.present
          ? data.recordedBy.value
          : this.recordedBy,
      date: data.date.present ? data.date.value : this.date,
      sampleWeight: data.sampleWeight.present
          ? data.sampleWeight.value
          : this.sampleWeight,
      sampleCount: data.sampleCount.present
          ? data.sampleCount.value
          : this.sampleCount,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeightSample(')
          ..write('weightSampleId: $weightSampleId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('sampleWeight: $sampleWeight, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    weightSampleId,
    batchId,
    recordedBy,
    date,
    sampleWeight,
    sampleCount,
    recordedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeightSample &&
          other.weightSampleId == this.weightSampleId &&
          other.batchId == this.batchId &&
          other.recordedBy == this.recordedBy &&
          other.date == this.date &&
          other.sampleWeight == this.sampleWeight &&
          other.sampleCount == this.sampleCount &&
          other.recordedAt == this.recordedAt &&
          other.syncedAt == this.syncedAt);
}

class WeightSamplesCompanion extends UpdateCompanion<WeightSample> {
  final Value<String> weightSampleId;
  final Value<String> batchId;
  final Value<String> recordedBy;
  final Value<DateTime> date;
  final Value<double> sampleWeight;
  final Value<int> sampleCount;
  final Value<DateTime> recordedAt;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const WeightSamplesCompanion({
    this.weightSampleId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.date = const Value.absent(),
    this.sampleWeight = const Value.absent(),
    this.sampleCount = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeightSamplesCompanion.insert({
    required String weightSampleId,
    required String batchId,
    required String recordedBy,
    required DateTime date,
    required double sampleWeight,
    required int sampleCount,
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : weightSampleId = Value(weightSampleId),
       batchId = Value(batchId),
       recordedBy = Value(recordedBy),
       date = Value(date),
       sampleWeight = Value(sampleWeight),
       sampleCount = Value(sampleCount);
  static Insertable<WeightSample> custom({
    Expression<String>? weightSampleId,
    Expression<String>? batchId,
    Expression<String>? recordedBy,
    Expression<DateTime>? date,
    Expression<double>? sampleWeight,
    Expression<int>? sampleCount,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (weightSampleId != null) 'weight_sample_id': weightSampleId,
      if (batchId != null) 'batch_id': batchId,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (date != null) 'date': date,
      if (sampleWeight != null) 'sample_weight': sampleWeight,
      if (sampleCount != null) 'sample_count': sampleCount,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeightSamplesCompanion copyWith({
    Value<String>? weightSampleId,
    Value<String>? batchId,
    Value<String>? recordedBy,
    Value<DateTime>? date,
    Value<double>? sampleWeight,
    Value<int>? sampleCount,
    Value<DateTime>? recordedAt,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return WeightSamplesCompanion(
      weightSampleId: weightSampleId ?? this.weightSampleId,
      batchId: batchId ?? this.batchId,
      recordedBy: recordedBy ?? this.recordedBy,
      date: date ?? this.date,
      sampleWeight: sampleWeight ?? this.sampleWeight,
      sampleCount: sampleCount ?? this.sampleCount,
      recordedAt: recordedAt ?? this.recordedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (weightSampleId.present) {
      map['weight_sample_id'] = Variable<String>(weightSampleId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (recordedBy.present) {
      map['recorded_by'] = Variable<String>(recordedBy.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (sampleWeight.present) {
      map['sample_weight'] = Variable<double>(sampleWeight.value);
    }
    if (sampleCount.present) {
      map['sample_count'] = Variable<int>(sampleCount.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeightSamplesCompanion(')
          ..write('weightSampleId: $weightSampleId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('sampleWeight: $sampleWeight, ')
          ..write('sampleCount: $sampleCount, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaccinationEntriesTable extends VaccinationEntries
    with TableInfo<$VaccinationEntriesTable, VaccinationEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaccinationEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _vaccinationIdMeta = const VerificationMeta(
    'vaccinationId',
  );
  @override
  late final GeneratedColumn<String> vaccinationId = GeneratedColumn<String>(
    'vaccination_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES batches (batch_id)',
    ),
  );
  static const VerificationMeta _recordedByMeta = const VerificationMeta(
    'recordedBy',
  );
  @override
  late final GeneratedColumn<String> recordedBy = GeneratedColumn<String>(
    'recorded_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _vaccineNameMeta = const VerificationMeta(
    'vaccineName',
  );
  @override
  late final GeneratedColumn<String> vaccineName = GeneratedColumn<String>(
    'vaccine_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    vaccinationId,
    batchId,
    recordedBy,
    date,
    vaccineName,
    recordedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vaccination_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaccinationEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('vaccination_id')) {
      context.handle(
        _vaccinationIdMeta,
        vaccinationId.isAcceptableOrUnknown(
          data['vaccination_id']!,
          _vaccinationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vaccinationIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('recorded_by')) {
      context.handle(
        _recordedByMeta,
        recordedBy.isAcceptableOrUnknown(data['recorded_by']!, _recordedByMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedByMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('vaccine_name')) {
      context.handle(
        _vaccineNameMeta,
        vaccineName.isAcceptableOrUnknown(
          data['vaccine_name']!,
          _vaccineNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vaccineNameMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {vaccinationId};
  @override
  VaccinationEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaccinationEntry(
      vaccinationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vaccination_id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      recordedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      vaccineName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vaccine_name'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $VaccinationEntriesTable createAlias(String alias) {
    return $VaccinationEntriesTable(attachedDatabase, alias);
  }
}

class VaccinationEntry extends DataClass
    implements Insertable<VaccinationEntry> {
  final String vaccinationId;
  final String batchId;
  final String recordedBy;
  final DateTime date;
  final String vaccineName;
  final DateTime recordedAt;
  final DateTime syncedAt;
  const VaccinationEntry({
    required this.vaccinationId,
    required this.batchId,
    required this.recordedBy,
    required this.date,
    required this.vaccineName,
    required this.recordedAt,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['vaccination_id'] = Variable<String>(vaccinationId);
    map['batch_id'] = Variable<String>(batchId);
    map['recorded_by'] = Variable<String>(recordedBy);
    map['date'] = Variable<DateTime>(date);
    map['vaccine_name'] = Variable<String>(vaccineName);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  VaccinationEntriesCompanion toCompanion(bool nullToAbsent) {
    return VaccinationEntriesCompanion(
      vaccinationId: Value(vaccinationId),
      batchId: Value(batchId),
      recordedBy: Value(recordedBy),
      date: Value(date),
      vaccineName: Value(vaccineName),
      recordedAt: Value(recordedAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory VaccinationEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaccinationEntry(
      vaccinationId: serializer.fromJson<String>(json['vaccinationId']),
      batchId: serializer.fromJson<String>(json['batchId']),
      recordedBy: serializer.fromJson<String>(json['recordedBy']),
      date: serializer.fromJson<DateTime>(json['date']),
      vaccineName: serializer.fromJson<String>(json['vaccineName']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'vaccinationId': serializer.toJson<String>(vaccinationId),
      'batchId': serializer.toJson<String>(batchId),
      'recordedBy': serializer.toJson<String>(recordedBy),
      'date': serializer.toJson<DateTime>(date),
      'vaccineName': serializer.toJson<String>(vaccineName),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  VaccinationEntry copyWith({
    String? vaccinationId,
    String? batchId,
    String? recordedBy,
    DateTime? date,
    String? vaccineName,
    DateTime? recordedAt,
    DateTime? syncedAt,
  }) => VaccinationEntry(
    vaccinationId: vaccinationId ?? this.vaccinationId,
    batchId: batchId ?? this.batchId,
    recordedBy: recordedBy ?? this.recordedBy,
    date: date ?? this.date,
    vaccineName: vaccineName ?? this.vaccineName,
    recordedAt: recordedAt ?? this.recordedAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  VaccinationEntry copyWithCompanion(VaccinationEntriesCompanion data) {
    return VaccinationEntry(
      vaccinationId: data.vaccinationId.present
          ? data.vaccinationId.value
          : this.vaccinationId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      recordedBy: data.recordedBy.present
          ? data.recordedBy.value
          : this.recordedBy,
      date: data.date.present ? data.date.value : this.date,
      vaccineName: data.vaccineName.present
          ? data.vaccineName.value
          : this.vaccineName,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaccinationEntry(')
          ..write('vaccinationId: $vaccinationId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('vaccineName: $vaccineName, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    vaccinationId,
    batchId,
    recordedBy,
    date,
    vaccineName,
    recordedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaccinationEntry &&
          other.vaccinationId == this.vaccinationId &&
          other.batchId == this.batchId &&
          other.recordedBy == this.recordedBy &&
          other.date == this.date &&
          other.vaccineName == this.vaccineName &&
          other.recordedAt == this.recordedAt &&
          other.syncedAt == this.syncedAt);
}

class VaccinationEntriesCompanion extends UpdateCompanion<VaccinationEntry> {
  final Value<String> vaccinationId;
  final Value<String> batchId;
  final Value<String> recordedBy;
  final Value<DateTime> date;
  final Value<String> vaccineName;
  final Value<DateTime> recordedAt;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const VaccinationEntriesCompanion({
    this.vaccinationId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.date = const Value.absent(),
    this.vaccineName = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaccinationEntriesCompanion.insert({
    required String vaccinationId,
    required String batchId,
    required String recordedBy,
    required DateTime date,
    required String vaccineName,
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : vaccinationId = Value(vaccinationId),
       batchId = Value(batchId),
       recordedBy = Value(recordedBy),
       date = Value(date),
       vaccineName = Value(vaccineName);
  static Insertable<VaccinationEntry> custom({
    Expression<String>? vaccinationId,
    Expression<String>? batchId,
    Expression<String>? recordedBy,
    Expression<DateTime>? date,
    Expression<String>? vaccineName,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (vaccinationId != null) 'vaccination_id': vaccinationId,
      if (batchId != null) 'batch_id': batchId,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (date != null) 'date': date,
      if (vaccineName != null) 'vaccine_name': vaccineName,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaccinationEntriesCompanion copyWith({
    Value<String>? vaccinationId,
    Value<String>? batchId,
    Value<String>? recordedBy,
    Value<DateTime>? date,
    Value<String>? vaccineName,
    Value<DateTime>? recordedAt,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return VaccinationEntriesCompanion(
      vaccinationId: vaccinationId ?? this.vaccinationId,
      batchId: batchId ?? this.batchId,
      recordedBy: recordedBy ?? this.recordedBy,
      date: date ?? this.date,
      vaccineName: vaccineName ?? this.vaccineName,
      recordedAt: recordedAt ?? this.recordedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (vaccinationId.present) {
      map['vaccination_id'] = Variable<String>(vaccinationId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (recordedBy.present) {
      map['recorded_by'] = Variable<String>(recordedBy.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (vaccineName.present) {
      map['vaccine_name'] = Variable<String>(vaccineName.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaccinationEntriesCompanion(')
          ..write('vaccinationId: $vaccinationId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('vaccineName: $vaccineName, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HarvestEntriesTable extends HarvestEntries
    with TableInfo<$HarvestEntriesTable, HarvestEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HarvestEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _harvestIdMeta = const VerificationMeta(
    'harvestId',
  );
  @override
  late final GeneratedColumn<String> harvestId = GeneratedColumn<String>(
    'harvest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _batchIdMeta = const VerificationMeta(
    'batchId',
  );
  @override
  late final GeneratedColumn<String> batchId = GeneratedColumn<String>(
    'batch_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES batches (batch_id)',
    ),
  );
  static const VerificationMeta _recordedByMeta = const VerificationMeta(
    'recordedBy',
  );
  @override
  late final GeneratedColumn<String> recordedBy = GeneratedColumn<String>(
    'recorded_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _birdCountMeta = const VerificationMeta(
    'birdCount',
  );
  @override
  late final GeneratedColumn<int> birdCount = GeneratedColumn<int>(
    'bird_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (bird_count > 0)',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    harvestId,
    batchId,
    recordedBy,
    date,
    birdCount,
    recordedAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'harvest_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<HarvestEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('harvest_id')) {
      context.handle(
        _harvestIdMeta,
        harvestId.isAcceptableOrUnknown(data['harvest_id']!, _harvestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_harvestIdMeta);
    }
    if (data.containsKey('batch_id')) {
      context.handle(
        _batchIdMeta,
        batchId.isAcceptableOrUnknown(data['batch_id']!, _batchIdMeta),
      );
    } else if (isInserting) {
      context.missing(_batchIdMeta);
    }
    if (data.containsKey('recorded_by')) {
      context.handle(
        _recordedByMeta,
        recordedBy.isAcceptableOrUnknown(data['recorded_by']!, _recordedByMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedByMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('bird_count')) {
      context.handle(
        _birdCountMeta,
        birdCount.isAcceptableOrUnknown(data['bird_count']!, _birdCountMeta),
      );
    } else if (isInserting) {
      context.missing(_birdCountMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {harvestId};
  @override
  HarvestEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HarvestEntry(
      harvestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}harvest_id'],
      )!,
      batchId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}batch_id'],
      )!,
      recordedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      birdCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bird_count'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $HarvestEntriesTable createAlias(String alias) {
    return $HarvestEntriesTable(attachedDatabase, alias);
  }
}

class HarvestEntry extends DataClass implements Insertable<HarvestEntry> {
  final String harvestId;
  final String batchId;
  final String recordedBy;
  final DateTime date;
  final int birdCount;
  final DateTime recordedAt;
  final DateTime syncedAt;
  const HarvestEntry({
    required this.harvestId,
    required this.batchId,
    required this.recordedBy,
    required this.date,
    required this.birdCount,
    required this.recordedAt,
    required this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['harvest_id'] = Variable<String>(harvestId);
    map['batch_id'] = Variable<String>(batchId);
    map['recorded_by'] = Variable<String>(recordedBy);
    map['date'] = Variable<DateTime>(date);
    map['bird_count'] = Variable<int>(birdCount);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  HarvestEntriesCompanion toCompanion(bool nullToAbsent) {
    return HarvestEntriesCompanion(
      harvestId: Value(harvestId),
      batchId: Value(batchId),
      recordedBy: Value(recordedBy),
      date: Value(date),
      birdCount: Value(birdCount),
      recordedAt: Value(recordedAt),
      syncedAt: Value(syncedAt),
    );
  }

  factory HarvestEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HarvestEntry(
      harvestId: serializer.fromJson<String>(json['harvestId']),
      batchId: serializer.fromJson<String>(json['batchId']),
      recordedBy: serializer.fromJson<String>(json['recordedBy']),
      date: serializer.fromJson<DateTime>(json['date']),
      birdCount: serializer.fromJson<int>(json['birdCount']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'harvestId': serializer.toJson<String>(harvestId),
      'batchId': serializer.toJson<String>(batchId),
      'recordedBy': serializer.toJson<String>(recordedBy),
      'date': serializer.toJson<DateTime>(date),
      'birdCount': serializer.toJson<int>(birdCount),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  HarvestEntry copyWith({
    String? harvestId,
    String? batchId,
    String? recordedBy,
    DateTime? date,
    int? birdCount,
    DateTime? recordedAt,
    DateTime? syncedAt,
  }) => HarvestEntry(
    harvestId: harvestId ?? this.harvestId,
    batchId: batchId ?? this.batchId,
    recordedBy: recordedBy ?? this.recordedBy,
    date: date ?? this.date,
    birdCount: birdCount ?? this.birdCount,
    recordedAt: recordedAt ?? this.recordedAt,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  HarvestEntry copyWithCompanion(HarvestEntriesCompanion data) {
    return HarvestEntry(
      harvestId: data.harvestId.present ? data.harvestId.value : this.harvestId,
      batchId: data.batchId.present ? data.batchId.value : this.batchId,
      recordedBy: data.recordedBy.present
          ? data.recordedBy.value
          : this.recordedBy,
      date: data.date.present ? data.date.value : this.date,
      birdCount: data.birdCount.present ? data.birdCount.value : this.birdCount,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HarvestEntry(')
          ..write('harvestId: $harvestId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('birdCount: $birdCount, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    harvestId,
    batchId,
    recordedBy,
    date,
    birdCount,
    recordedAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HarvestEntry &&
          other.harvestId == this.harvestId &&
          other.batchId == this.batchId &&
          other.recordedBy == this.recordedBy &&
          other.date == this.date &&
          other.birdCount == this.birdCount &&
          other.recordedAt == this.recordedAt &&
          other.syncedAt == this.syncedAt);
}

class HarvestEntriesCompanion extends UpdateCompanion<HarvestEntry> {
  final Value<String> harvestId;
  final Value<String> batchId;
  final Value<String> recordedBy;
  final Value<DateTime> date;
  final Value<int> birdCount;
  final Value<DateTime> recordedAt;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const HarvestEntriesCompanion({
    this.harvestId = const Value.absent(),
    this.batchId = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.date = const Value.absent(),
    this.birdCount = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HarvestEntriesCompanion.insert({
    required String harvestId,
    required String batchId,
    required String recordedBy,
    required DateTime date,
    required int birdCount,
    this.recordedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : harvestId = Value(harvestId),
       batchId = Value(batchId),
       recordedBy = Value(recordedBy),
       date = Value(date),
       birdCount = Value(birdCount);
  static Insertable<HarvestEntry> custom({
    Expression<String>? harvestId,
    Expression<String>? batchId,
    Expression<String>? recordedBy,
    Expression<DateTime>? date,
    Expression<int>? birdCount,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (harvestId != null) 'harvest_id': harvestId,
      if (batchId != null) 'batch_id': batchId,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (date != null) 'date': date,
      if (birdCount != null) 'bird_count': birdCount,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HarvestEntriesCompanion copyWith({
    Value<String>? harvestId,
    Value<String>? batchId,
    Value<String>? recordedBy,
    Value<DateTime>? date,
    Value<int>? birdCount,
    Value<DateTime>? recordedAt,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return HarvestEntriesCompanion(
      harvestId: harvestId ?? this.harvestId,
      batchId: batchId ?? this.batchId,
      recordedBy: recordedBy ?? this.recordedBy,
      date: date ?? this.date,
      birdCount: birdCount ?? this.birdCount,
      recordedAt: recordedAt ?? this.recordedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (harvestId.present) {
      map['harvest_id'] = Variable<String>(harvestId.value);
    }
    if (batchId.present) {
      map['batch_id'] = Variable<String>(batchId.value);
    }
    if (recordedBy.present) {
      map['recorded_by'] = Variable<String>(recordedBy.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (birdCount.present) {
      map['bird_count'] = Variable<int>(birdCount.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HarvestEntriesCompanion(')
          ..write('harvestId: $harvestId, ')
          ..write('batchId: $batchId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('date: $date, ')
          ..write('birdCount: $birdCount, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SalesTable extends Sales with TableInfo<$SalesTable, Sale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _saleIdMeta = const VerificationMeta('saleId');
  @override
  late final GeneratedColumn<String> saleId = GeneratedColumn<String>(
    'sale_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _harvestIdMeta = const VerificationMeta(
    'harvestId',
  );
  @override
  late final GeneratedColumn<String> harvestId = GeneratedColumn<String>(
    'harvest_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES harvest_entries (harvest_id)',
    ),
  );
  static const VerificationMeta _recordedByMeta = const VerificationMeta(
    'recordedBy',
  );
  @override
  late final GeneratedColumn<String> recordedBy = GeneratedColumn<String>(
    'recorded_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (account_id)',
    ),
  );
  static const VerificationMeta _dispositionMeta = const VerificationMeta(
    'disposition',
  );
  @override
  late final GeneratedColumn<String> disposition = GeneratedColumn<String>(
    'disposition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (disposition IN (\'sale\',\'gift_cull\'))',
  );
  static const VerificationMeta _buyerNameMeta = const VerificationMeta(
    'buyerName',
  );
  @override
  late final GeneratedColumn<String> buyerName = GeneratedColumn<String>(
    'buyer_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pricingMethodMeta = const VerificationMeta(
    'pricingMethod',
  );
  @override
  late final GeneratedColumn<String> pricingMethod = GeneratedColumn<String>(
    'pricing_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (pricing_method IN (\'per_kg\',\'flat_total\')) NULL',
  );
  static const VerificationMeta _weightSoldMeta = const VerificationMeta(
    'weightSold',
  );
  @override
  late final GeneratedColumn<double> weightSold = GeneratedColumn<double>(
    'weight_sold',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pricePerUnitMeta = const VerificationMeta(
    'pricePerUnit',
  );
  @override
  late final GeneratedColumn<double> pricePerUnit = GeneratedColumn<double>(
    'price_per_unit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (amount >= 0)',
  );
  static const VerificationMeta _paymentStatusMeta = const VerificationMeta(
    'paymentStatus',
  );
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
    'payment_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (payment_status IN (\'paid\',\'pending\')) NULL',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    saleId,
    harvestId,
    recordedBy,
    disposition,
    buyerName,
    pricingMethod,
    weightSold,
    pricePerUnit,
    amount,
    paymentStatus,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<Sale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sale_id')) {
      context.handle(
        _saleIdMeta,
        saleId.isAcceptableOrUnknown(data['sale_id']!, _saleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_saleIdMeta);
    }
    if (data.containsKey('harvest_id')) {
      context.handle(
        _harvestIdMeta,
        harvestId.isAcceptableOrUnknown(data['harvest_id']!, _harvestIdMeta),
      );
    } else if (isInserting) {
      context.missing(_harvestIdMeta);
    }
    if (data.containsKey('recorded_by')) {
      context.handle(
        _recordedByMeta,
        recordedBy.isAcceptableOrUnknown(data['recorded_by']!, _recordedByMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedByMeta);
    }
    if (data.containsKey('disposition')) {
      context.handle(
        _dispositionMeta,
        disposition.isAcceptableOrUnknown(
          data['disposition']!,
          _dispositionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dispositionMeta);
    }
    if (data.containsKey('buyer_name')) {
      context.handle(
        _buyerNameMeta,
        buyerName.isAcceptableOrUnknown(data['buyer_name']!, _buyerNameMeta),
      );
    }
    if (data.containsKey('pricing_method')) {
      context.handle(
        _pricingMethodMeta,
        pricingMethod.isAcceptableOrUnknown(
          data['pricing_method']!,
          _pricingMethodMeta,
        ),
      );
    }
    if (data.containsKey('weight_sold')) {
      context.handle(
        _weightSoldMeta,
        weightSold.isAcceptableOrUnknown(data['weight_sold']!, _weightSoldMeta),
      );
    }
    if (data.containsKey('price_per_unit')) {
      context.handle(
        _pricePerUnitMeta,
        pricePerUnit.isAcceptableOrUnknown(
          data['price_per_unit']!,
          _pricePerUnitMeta,
        ),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('payment_status')) {
      context.handle(
        _paymentStatusMeta,
        paymentStatus.isAcceptableOrUnknown(
          data['payment_status']!,
          _paymentStatusMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {saleId};
  @override
  Sale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Sale(
      saleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sale_id'],
      )!,
      harvestId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}harvest_id'],
      )!,
      recordedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_by'],
      )!,
      disposition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}disposition'],
      )!,
      buyerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}buyer_name'],
      ),
      pricingMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pricing_method'],
      ),
      weightSold: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_sold'],
      ),
      pricePerUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price_per_unit'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      paymentStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_status'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SalesTable createAlias(String alias) {
    return $SalesTable(attachedDatabase, alias);
  }
}

class Sale extends DataClass implements Insertable<Sale> {
  final String saleId;
  final String harvestId;
  final String recordedBy;
  final String disposition;
  final String? buyerName;
  final String? pricingMethod;
  final double? weightSold;
  final double? pricePerUnit;
  final double amount;
  final String? paymentStatus;
  final DateTime createdAt;
  const Sale({
    required this.saleId,
    required this.harvestId,
    required this.recordedBy,
    required this.disposition,
    this.buyerName,
    this.pricingMethod,
    this.weightSold,
    this.pricePerUnit,
    required this.amount,
    this.paymentStatus,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sale_id'] = Variable<String>(saleId);
    map['harvest_id'] = Variable<String>(harvestId);
    map['recorded_by'] = Variable<String>(recordedBy);
    map['disposition'] = Variable<String>(disposition);
    if (!nullToAbsent || buyerName != null) {
      map['buyer_name'] = Variable<String>(buyerName);
    }
    if (!nullToAbsent || pricingMethod != null) {
      map['pricing_method'] = Variable<String>(pricingMethod);
    }
    if (!nullToAbsent || weightSold != null) {
      map['weight_sold'] = Variable<double>(weightSold);
    }
    if (!nullToAbsent || pricePerUnit != null) {
      map['price_per_unit'] = Variable<double>(pricePerUnit);
    }
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || paymentStatus != null) {
      map['payment_status'] = Variable<String>(paymentStatus);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SalesCompanion toCompanion(bool nullToAbsent) {
    return SalesCompanion(
      saleId: Value(saleId),
      harvestId: Value(harvestId),
      recordedBy: Value(recordedBy),
      disposition: Value(disposition),
      buyerName: buyerName == null && nullToAbsent
          ? const Value.absent()
          : Value(buyerName),
      pricingMethod: pricingMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(pricingMethod),
      weightSold: weightSold == null && nullToAbsent
          ? const Value.absent()
          : Value(weightSold),
      pricePerUnit: pricePerUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(pricePerUnit),
      amount: Value(amount),
      paymentStatus: paymentStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentStatus),
      createdAt: Value(createdAt),
    );
  }

  factory Sale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Sale(
      saleId: serializer.fromJson<String>(json['saleId']),
      harvestId: serializer.fromJson<String>(json['harvestId']),
      recordedBy: serializer.fromJson<String>(json['recordedBy']),
      disposition: serializer.fromJson<String>(json['disposition']),
      buyerName: serializer.fromJson<String?>(json['buyerName']),
      pricingMethod: serializer.fromJson<String?>(json['pricingMethod']),
      weightSold: serializer.fromJson<double?>(json['weightSold']),
      pricePerUnit: serializer.fromJson<double?>(json['pricePerUnit']),
      amount: serializer.fromJson<double>(json['amount']),
      paymentStatus: serializer.fromJson<String?>(json['paymentStatus']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'saleId': serializer.toJson<String>(saleId),
      'harvestId': serializer.toJson<String>(harvestId),
      'recordedBy': serializer.toJson<String>(recordedBy),
      'disposition': serializer.toJson<String>(disposition),
      'buyerName': serializer.toJson<String?>(buyerName),
      'pricingMethod': serializer.toJson<String?>(pricingMethod),
      'weightSold': serializer.toJson<double?>(weightSold),
      'pricePerUnit': serializer.toJson<double?>(pricePerUnit),
      'amount': serializer.toJson<double>(amount),
      'paymentStatus': serializer.toJson<String?>(paymentStatus),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Sale copyWith({
    String? saleId,
    String? harvestId,
    String? recordedBy,
    String? disposition,
    Value<String?> buyerName = const Value.absent(),
    Value<String?> pricingMethod = const Value.absent(),
    Value<double?> weightSold = const Value.absent(),
    Value<double?> pricePerUnit = const Value.absent(),
    double? amount,
    Value<String?> paymentStatus = const Value.absent(),
    DateTime? createdAt,
  }) => Sale(
    saleId: saleId ?? this.saleId,
    harvestId: harvestId ?? this.harvestId,
    recordedBy: recordedBy ?? this.recordedBy,
    disposition: disposition ?? this.disposition,
    buyerName: buyerName.present ? buyerName.value : this.buyerName,
    pricingMethod: pricingMethod.present
        ? pricingMethod.value
        : this.pricingMethod,
    weightSold: weightSold.present ? weightSold.value : this.weightSold,
    pricePerUnit: pricePerUnit.present ? pricePerUnit.value : this.pricePerUnit,
    amount: amount ?? this.amount,
    paymentStatus: paymentStatus.present
        ? paymentStatus.value
        : this.paymentStatus,
    createdAt: createdAt ?? this.createdAt,
  );
  Sale copyWithCompanion(SalesCompanion data) {
    return Sale(
      saleId: data.saleId.present ? data.saleId.value : this.saleId,
      harvestId: data.harvestId.present ? data.harvestId.value : this.harvestId,
      recordedBy: data.recordedBy.present
          ? data.recordedBy.value
          : this.recordedBy,
      disposition: data.disposition.present
          ? data.disposition.value
          : this.disposition,
      buyerName: data.buyerName.present ? data.buyerName.value : this.buyerName,
      pricingMethod: data.pricingMethod.present
          ? data.pricingMethod.value
          : this.pricingMethod,
      weightSold: data.weightSold.present
          ? data.weightSold.value
          : this.weightSold,
      pricePerUnit: data.pricePerUnit.present
          ? data.pricePerUnit.value
          : this.pricePerUnit,
      amount: data.amount.present ? data.amount.value : this.amount,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Sale(')
          ..write('saleId: $saleId, ')
          ..write('harvestId: $harvestId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('disposition: $disposition, ')
          ..write('buyerName: $buyerName, ')
          ..write('pricingMethod: $pricingMethod, ')
          ..write('weightSold: $weightSold, ')
          ..write('pricePerUnit: $pricePerUnit, ')
          ..write('amount: $amount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    saleId,
    harvestId,
    recordedBy,
    disposition,
    buyerName,
    pricingMethod,
    weightSold,
    pricePerUnit,
    amount,
    paymentStatus,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Sale &&
          other.saleId == this.saleId &&
          other.harvestId == this.harvestId &&
          other.recordedBy == this.recordedBy &&
          other.disposition == this.disposition &&
          other.buyerName == this.buyerName &&
          other.pricingMethod == this.pricingMethod &&
          other.weightSold == this.weightSold &&
          other.pricePerUnit == this.pricePerUnit &&
          other.amount == this.amount &&
          other.paymentStatus == this.paymentStatus &&
          other.createdAt == this.createdAt);
}

class SalesCompanion extends UpdateCompanion<Sale> {
  final Value<String> saleId;
  final Value<String> harvestId;
  final Value<String> recordedBy;
  final Value<String> disposition;
  final Value<String?> buyerName;
  final Value<String?> pricingMethod;
  final Value<double?> weightSold;
  final Value<double?> pricePerUnit;
  final Value<double> amount;
  final Value<String?> paymentStatus;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SalesCompanion({
    this.saleId = const Value.absent(),
    this.harvestId = const Value.absent(),
    this.recordedBy = const Value.absent(),
    this.disposition = const Value.absent(),
    this.buyerName = const Value.absent(),
    this.pricingMethod = const Value.absent(),
    this.weightSold = const Value.absent(),
    this.pricePerUnit = const Value.absent(),
    this.amount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SalesCompanion.insert({
    required String saleId,
    required String harvestId,
    required String recordedBy,
    required String disposition,
    this.buyerName = const Value.absent(),
    this.pricingMethod = const Value.absent(),
    this.weightSold = const Value.absent(),
    this.pricePerUnit = const Value.absent(),
    required double amount,
    this.paymentStatus = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : saleId = Value(saleId),
       harvestId = Value(harvestId),
       recordedBy = Value(recordedBy),
       disposition = Value(disposition),
       amount = Value(amount);
  static Insertable<Sale> custom({
    Expression<String>? saleId,
    Expression<String>? harvestId,
    Expression<String>? recordedBy,
    Expression<String>? disposition,
    Expression<String>? buyerName,
    Expression<String>? pricingMethod,
    Expression<double>? weightSold,
    Expression<double>? pricePerUnit,
    Expression<double>? amount,
    Expression<String>? paymentStatus,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (saleId != null) 'sale_id': saleId,
      if (harvestId != null) 'harvest_id': harvestId,
      if (recordedBy != null) 'recorded_by': recordedBy,
      if (disposition != null) 'disposition': disposition,
      if (buyerName != null) 'buyer_name': buyerName,
      if (pricingMethod != null) 'pricing_method': pricingMethod,
      if (weightSold != null) 'weight_sold': weightSold,
      if (pricePerUnit != null) 'price_per_unit': pricePerUnit,
      if (amount != null) 'amount': amount,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SalesCompanion copyWith({
    Value<String>? saleId,
    Value<String>? harvestId,
    Value<String>? recordedBy,
    Value<String>? disposition,
    Value<String?>? buyerName,
    Value<String?>? pricingMethod,
    Value<double?>? weightSold,
    Value<double?>? pricePerUnit,
    Value<double>? amount,
    Value<String?>? paymentStatus,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SalesCompanion(
      saleId: saleId ?? this.saleId,
      harvestId: harvestId ?? this.harvestId,
      recordedBy: recordedBy ?? this.recordedBy,
      disposition: disposition ?? this.disposition,
      buyerName: buyerName ?? this.buyerName,
      pricingMethod: pricingMethod ?? this.pricingMethod,
      weightSold: weightSold ?? this.weightSold,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      amount: amount ?? this.amount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (saleId.present) {
      map['sale_id'] = Variable<String>(saleId.value);
    }
    if (harvestId.present) {
      map['harvest_id'] = Variable<String>(harvestId.value);
    }
    if (recordedBy.present) {
      map['recorded_by'] = Variable<String>(recordedBy.value);
    }
    if (disposition.present) {
      map['disposition'] = Variable<String>(disposition.value);
    }
    if (buyerName.present) {
      map['buyer_name'] = Variable<String>(buyerName.value);
    }
    if (pricingMethod.present) {
      map['pricing_method'] = Variable<String>(pricingMethod.value);
    }
    if (weightSold.present) {
      map['weight_sold'] = Variable<double>(weightSold.value);
    }
    if (pricePerUnit.present) {
      map['price_per_unit'] = Variable<double>(pricePerUnit.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SalesCompanion(')
          ..write('saleId: $saleId, ')
          ..write('harvestId: $harvestId, ')
          ..write('recordedBy: $recordedBy, ')
          ..write('disposition: $disposition, ')
          ..write('buyerName: $buyerName, ')
          ..write('pricingMethod: $pricingMethod, ')
          ..write('weightSold: $weightSold, ')
          ..write('pricePerUnit: $pricePerUnit, ')
          ..write('amount: $amount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BusinessesTable businesses = $BusinessesTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $BatchesTable batches = $BatchesTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $MortalityEntriesTable mortalityEntries = $MortalityEntriesTable(
    this,
  );
  late final $FeedEntriesTable feedEntries = $FeedEntriesTable(this);
  late final $WeightSamplesTable weightSamples = $WeightSamplesTable(this);
  late final $VaccinationEntriesTable vaccinationEntries =
      $VaccinationEntriesTable(this);
  late final $HarvestEntriesTable harvestEntries = $HarvestEntriesTable(this);
  late final $SalesTable sales = $SalesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    businesses,
    accounts,
    batches,
    expenses,
    mortalityEntries,
    feedEntries,
    weightSamples,
    vaccinationEntries,
    harvestEntries,
    sales,
  ];
}

typedef $$BusinessesTableCreateCompanionBuilder =
    BusinessesCompanion Function({
      required String businessId,
      required String name,
      Value<String?> address,
      Value<String?> phone,
      Value<String?> businessType,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$BusinessesTableUpdateCompanionBuilder =
    BusinessesCompanion Function({
      Value<String> businessId,
      Value<String> name,
      Value<String?> address,
      Value<String?> phone,
      Value<String?> businessType,
      Value<String?> description,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$BusinessesTableReferences
    extends BaseReferences<_$AppDatabase, $BusinessesTable, Business> {
  $$BusinessesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AccountsTable, List<Account>> _accountsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.accounts,
    aliasName: $_aliasNameGenerator(
      db.businesses.businessId,
      db.accounts.businessId,
    ),
  );

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager($_db, $_db.accounts).filter(
      (f) => f.businessId.businessId.sqlEquals(
        $_itemColumn<String>('business_id')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BatchesTable, List<Batch>> _batchesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.batches,
    aliasName: $_aliasNameGenerator(
      db.businesses.businessId,
      db.batches.businessId,
    ),
  );

  $$BatchesTableProcessedTableManager get batchesRefs {
    final manager = $$BatchesTableTableManager($_db, $_db.batches).filter(
      (f) => f.businessId.businessId.sqlEquals(
        $_itemColumn<String>('business_id')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_batchesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BusinessesTableFilterComposer
    extends Composer<_$AppDatabase, $BusinessesTable> {
  $$BusinessesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accountsRefs(
    Expression<bool> Function($$AccountsTableFilterComposer f) f,
  ) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> batchesRefs(
    Expression<bool> Function($$BatchesTableFilterComposer f) f,
  ) {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BusinessesTableOrderingComposer
    extends Composer<_$AppDatabase, $BusinessesTable> {
  $$BusinessesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BusinessesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BusinessesTable> {
  $$BusinessesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get businessId => $composableBuilder(
    column: $table.businessId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get businessType => $composableBuilder(
    column: $table.businessType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> accountsRefs<T extends Object>(
    Expression<T> Function($$AccountsTableAnnotationComposer a) f,
  ) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> batchesRefs<T extends Object>(
    Expression<T> Function($$BatchesTableAnnotationComposer a) f,
  ) {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BusinessesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BusinessesTable,
          Business,
          $$BusinessesTableFilterComposer,
          $$BusinessesTableOrderingComposer,
          $$BusinessesTableAnnotationComposer,
          $$BusinessesTableCreateCompanionBuilder,
          $$BusinessesTableUpdateCompanionBuilder,
          (Business, $$BusinessesTableReferences),
          Business,
          PrefetchHooks Function({bool accountsRefs, bool batchesRefs})
        > {
  $$BusinessesTableTableManager(_$AppDatabase db, $BusinessesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BusinessesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BusinessesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BusinessesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> businessId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> businessType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessesCompanion(
                businessId: businessId,
                name: name,
                address: address,
                phone: phone,
                businessType: businessType,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String businessId,
                required String name,
                Value<String?> address = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> businessType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BusinessesCompanion.insert(
                businessId: businessId,
                name: name,
                address: address,
                phone: phone,
                businessType: businessType,
                description: description,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BusinessesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountsRefs = false, batchesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (accountsRefs) db.accounts,
                if (batchesRefs) db.batches,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (accountsRefs)
                    await $_getPrefetchedData<
                      Business,
                      $BusinessesTable,
                      Account
                    >(
                      currentTable: table,
                      referencedTable: $$BusinessesTableReferences
                          ._accountsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BusinessesTableReferences(
                            db,
                            table,
                            p0,
                          ).accountsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.businessId == item.businessId,
                          ),
                      typedResults: items,
                    ),
                  if (batchesRefs)
                    await $_getPrefetchedData<
                      Business,
                      $BusinessesTable,
                      Batch
                    >(
                      currentTable: table,
                      referencedTable: $$BusinessesTableReferences
                          ._batchesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BusinessesTableReferences(
                            db,
                            table,
                            p0,
                          ).batchesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.businessId == item.businessId,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BusinessesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BusinessesTable,
      Business,
      $$BusinessesTableFilterComposer,
      $$BusinessesTableOrderingComposer,
      $$BusinessesTableAnnotationComposer,
      $$BusinessesTableCreateCompanionBuilder,
      $$BusinessesTableUpdateCompanionBuilder,
      (Business, $$BusinessesTableReferences),
      Business,
      PrefetchHooks Function({bool accountsRefs, bool batchesRefs})
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String accountId,
      Value<String?> businessId,
      Value<String?> authUserId,
      required String role,
      required String name,
      required String email,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> accountId,
      Value<String?> businessId,
      Value<String?> authUserId,
      Value<String> role,
      Value<String> name,
      Value<String> email,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BusinessesTable _businessIdTable(_$AppDatabase db) =>
      db.businesses.createAlias(
        $_aliasNameGenerator(db.accounts.businessId, db.businesses.businessId),
      );

  $$BusinessesTableProcessedTableManager? get businessId {
    final $_column = $_itemColumn<String>('business_id');
    if ($_column == null) return null;
    final manager = $$BusinessesTableTableManager(
      $_db,
      $_db.businesses,
    ).filter((f) => f.businessId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$BatchesTable, List<Batch>> _assignedBatchesTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.batches,
    aliasName: $_aliasNameGenerator(
      db.accounts.accountId,
      db.batches.assignedStaffId,
    ),
  );

  $$BatchesTableProcessedTableManager get assignedBatches {
    final manager = $$BatchesTableTableManager($_db, $_db.batches).filter(
      (f) => f.assignedStaffId.accountId.sqlEquals(
        $_itemColumn<String>('account_id')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_assignedBatchesTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BatchesTable, List<Batch>> _closedBatchesTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.batches,
    aliasName: $_aliasNameGenerator(db.accounts.accountId, db.batches.closedBy),
  );

  $$BatchesTableProcessedTableManager get closedBatches {
    final manager = $$BatchesTableTableManager($_db, $_db.batches).filter(
      (f) =>
          f.closedBy.accountId.sqlEquals($_itemColumn<String>('account_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_closedBatchesTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: $_aliasNameGenerator(
      db.accounts.accountId,
      db.expenses.recordedBy,
    ),
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses).filter(
      (f) =>
          f.recordedBy.accountId.sqlEquals($_itemColumn<String>('account_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MortalityEntriesTable, List<MortalityEntry>>
  _mortalityEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mortalityEntries,
    aliasName: $_aliasNameGenerator(
      db.accounts.accountId,
      db.mortalityEntries.recordedBy,
    ),
  );

  $$MortalityEntriesTableProcessedTableManager get mortalityEntriesRefs {
    final manager =
        $$MortalityEntriesTableTableManager($_db, $_db.mortalityEntries).filter(
          (f) => f.recordedBy.accountId.sqlEquals(
            $_itemColumn<String>('account_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _mortalityEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FeedEntriesTable, List<FeedEntry>>
  _feedEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.feedEntries,
    aliasName: $_aliasNameGenerator(
      db.accounts.accountId,
      db.feedEntries.recordedBy,
    ),
  );

  $$FeedEntriesTableProcessedTableManager get feedEntriesRefs {
    final manager = $$FeedEntriesTableTableManager($_db, $_db.feedEntries)
        .filter(
          (f) => f.recordedBy.accountId.sqlEquals(
            $_itemColumn<String>('account_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_feedEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WeightSamplesTable, List<WeightSample>>
  _weightSamplesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.weightSamples,
    aliasName: $_aliasNameGenerator(
      db.accounts.accountId,
      db.weightSamples.recordedBy,
    ),
  );

  $$WeightSamplesTableProcessedTableManager get weightSamplesRefs {
    final manager = $$WeightSamplesTableTableManager($_db, $_db.weightSamples)
        .filter(
          (f) => f.recordedBy.accountId.sqlEquals(
            $_itemColumn<String>('account_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_weightSamplesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VaccinationEntriesTable, List<VaccinationEntry>>
  _vaccinationEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.vaccinationEntries,
        aliasName: $_aliasNameGenerator(
          db.accounts.accountId,
          db.vaccinationEntries.recordedBy,
        ),
      );

  $$VaccinationEntriesTableProcessedTableManager get vaccinationEntriesRefs {
    final manager =
        $$VaccinationEntriesTableTableManager(
          $_db,
          $_db.vaccinationEntries,
        ).filter(
          (f) => f.recordedBy.accountId.sqlEquals(
            $_itemColumn<String>('account_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _vaccinationEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HarvestEntriesTable, List<HarvestEntry>>
  _harvestEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.harvestEntries,
    aliasName: $_aliasNameGenerator(
      db.accounts.accountId,
      db.harvestEntries.recordedBy,
    ),
  );

  $$HarvestEntriesTableProcessedTableManager get harvestEntriesRefs {
    final manager = $$HarvestEntriesTableTableManager($_db, $_db.harvestEntries)
        .filter(
          (f) => f.recordedBy.accountId.sqlEquals(
            $_itemColumn<String>('account_id')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_harvestEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sales,
    aliasName: $_aliasNameGenerator(db.accounts.accountId, db.sales.recordedBy),
  );

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager($_db, $_db.sales).filter(
      (f) =>
          f.recordedBy.accountId.sqlEquals($_itemColumn<String>('account_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableFilterComposer get businessId {
    final $$BusinessesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businesses,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableFilterComposer(
            $db: $db,
            $table: $db.businesses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> assignedBatches(
    Expression<bool> Function($$BatchesTableFilterComposer f) f,
  ) {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.assignedStaffId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> closedBatches(
    Expression<bool> Function($$BatchesTableFilterComposer f) f,
  ) {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.closedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mortalityEntriesRefs(
    Expression<bool> Function($$MortalityEntriesTableFilterComposer f) f,
  ) {
    final $$MortalityEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.mortalityEntries,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MortalityEntriesTableFilterComposer(
            $db: $db,
            $table: $db.mortalityEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> feedEntriesRefs(
    Expression<bool> Function($$FeedEntriesTableFilterComposer f) f,
  ) {
    final $$FeedEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.feedEntries,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeedEntriesTableFilterComposer(
            $db: $db,
            $table: $db.feedEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> weightSamplesRefs(
    Expression<bool> Function($$WeightSamplesTableFilterComposer f) f,
  ) {
    final $$WeightSamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.weightSamples,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeightSamplesTableFilterComposer(
            $db: $db,
            $table: $db.weightSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> vaccinationEntriesRefs(
    Expression<bool> Function($$VaccinationEntriesTableFilterComposer f) f,
  ) {
    final $$VaccinationEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.vaccinationEntries,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaccinationEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vaccinationEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> harvestEntriesRefs(
    Expression<bool> Function($$HarvestEntriesTableFilterComposer f) f,
  ) {
    final $$HarvestEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.harvestEntries,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HarvestEntriesTableFilterComposer(
            $db: $db,
            $table: $db.harvestEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> salesRefs(
    Expression<bool> Function($$SalesTableFilterComposer f) f,
  ) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableOrderingComposer get businessId {
    final $$BusinessesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businesses,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableOrderingComposer(
            $db: $db,
            $table: $db.businesses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get authUserId => $composableBuilder(
    column: $table.authUserId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$BusinessesTableAnnotationComposer get businessId {
    final $$BusinessesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businesses,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableAnnotationComposer(
            $db: $db,
            $table: $db.businesses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> assignedBatches<T extends Object>(
    Expression<T> Function($$BatchesTableAnnotationComposer a) f,
  ) {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.assignedStaffId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> closedBatches<T extends Object>(
    Expression<T> Function($$BatchesTableAnnotationComposer a) f,
  ) {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.closedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mortalityEntriesRefs<T extends Object>(
    Expression<T> Function($$MortalityEntriesTableAnnotationComposer a) f,
  ) {
    final $$MortalityEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.mortalityEntries,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MortalityEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.mortalityEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> feedEntriesRefs<T extends Object>(
    Expression<T> Function($$FeedEntriesTableAnnotationComposer a) f,
  ) {
    final $$FeedEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.feedEntries,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeedEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.feedEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> weightSamplesRefs<T extends Object>(
    Expression<T> Function($$WeightSamplesTableAnnotationComposer a) f,
  ) {
    final $$WeightSamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.weightSamples,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeightSamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.weightSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> vaccinationEntriesRefs<T extends Object>(
    Expression<T> Function($$VaccinationEntriesTableAnnotationComposer a) f,
  ) {
    final $$VaccinationEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.accountId,
          referencedTable: $db.vaccinationEntries,
          getReferencedColumn: (t) => t.recordedBy,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VaccinationEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.vaccinationEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> harvestEntriesRefs<T extends Object>(
    Expression<T> Function($$HarvestEntriesTableAnnotationComposer a) f,
  ) {
    final $$HarvestEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.harvestEntries,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HarvestEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.harvestEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> salesRefs<T extends Object>(
    Expression<T> Function($$SalesTableAnnotationComposer a) f,
  ) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.recordedBy,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({
            bool businessId,
            bool assignedBatches,
            bool closedBatches,
            bool expensesRefs,
            bool mortalityEntriesRefs,
            bool feedEntriesRefs,
            bool weightSamplesRefs,
            bool vaccinationEntriesRefs,
            bool harvestEntriesRefs,
            bool salesRefs,
          })
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String?> businessId = const Value.absent(),
                Value<String?> authUserId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                accountId: accountId,
                businessId: businessId,
                authUserId: authUserId,
                role: role,
                name: name,
                email: email,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                Value<String?> businessId = const Value.absent(),
                Value<String?> authUserId = const Value.absent(),
                required String role,
                required String name,
                required String email,
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                accountId: accountId,
                businessId: businessId,
                authUserId: authUserId,
                role: role,
                name: name,
                email: email,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                businessId = false,
                assignedBatches = false,
                closedBatches = false,
                expensesRefs = false,
                mortalityEntriesRefs = false,
                feedEntriesRefs = false,
                weightSamplesRefs = false,
                vaccinationEntriesRefs = false,
                harvestEntriesRefs = false,
                salesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (assignedBatches) db.batches,
                    if (closedBatches) db.batches,
                    if (expensesRefs) db.expenses,
                    if (mortalityEntriesRefs) db.mortalityEntries,
                    if (feedEntriesRefs) db.feedEntries,
                    if (weightSamplesRefs) db.weightSamples,
                    if (vaccinationEntriesRefs) db.vaccinationEntries,
                    if (harvestEntriesRefs) db.harvestEntries,
                    if (salesRefs) db.sales,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (businessId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.businessId,
                                    referencedTable: $$AccountsTableReferences
                                        ._businessIdTable(db),
                                    referencedColumn: $$AccountsTableReferences
                                        ._businessIdTable(db)
                                        .businessId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (assignedBatches)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Batch
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._assignedBatchesTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).assignedBatches,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.assignedStaffId == item.accountId,
                              ),
                          typedResults: items,
                        ),
                      if (closedBatches)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Batch
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._closedBatchesTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).closedBatches,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.closedBy == item.accountId,
                              ),
                          typedResults: items,
                        ),
                      if (expensesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Expense
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordedBy == item.accountId,
                              ),
                          typedResults: items,
                        ),
                      if (mortalityEntriesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          MortalityEntry
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._mortalityEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).mortalityEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordedBy == item.accountId,
                              ),
                          typedResults: items,
                        ),
                      if (feedEntriesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          FeedEntry
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._feedEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).feedEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordedBy == item.accountId,
                              ),
                          typedResults: items,
                        ),
                      if (weightSamplesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          WeightSample
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._weightSamplesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).weightSamplesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordedBy == item.accountId,
                              ),
                          typedResults: items,
                        ),
                      if (vaccinationEntriesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          VaccinationEntry
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._vaccinationEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).vaccinationEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordedBy == item.accountId,
                              ),
                          typedResults: items,
                        ),
                      if (harvestEntriesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          HarvestEntry
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._harvestEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).harvestEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordedBy == item.accountId,
                              ),
                          typedResults: items,
                        ),
                      if (salesRefs)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          Sale
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._salesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).salesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recordedBy == item.accountId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({
        bool businessId,
        bool assignedBatches,
        bool closedBatches,
        bool expensesRefs,
        bool mortalityEntriesRefs,
        bool feedEntriesRefs,
        bool weightSamplesRefs,
        bool vaccinationEntriesRefs,
        bool harvestEntriesRefs,
        bool salesRefs,
      })
    >;
typedef $$BatchesTableCreateCompanionBuilder =
    BatchesCompanion Function({
      required String batchId,
      required String businessId,
      Value<String?> assignedStaffId,
      Value<String?> closedBy,
      required String batchName,
      Value<String?> breed,
      Value<String?> description,
      required int startingBirdCount,
      required DateTime startDate,
      Value<bool> isClosed,
      Value<DateTime> createdAt,
      Value<DateTime?> closedAt,
      Value<int> rowid,
    });
typedef $$BatchesTableUpdateCompanionBuilder =
    BatchesCompanion Function({
      Value<String> batchId,
      Value<String> businessId,
      Value<String?> assignedStaffId,
      Value<String?> closedBy,
      Value<String> batchName,
      Value<String?> breed,
      Value<String?> description,
      Value<int> startingBirdCount,
      Value<DateTime> startDate,
      Value<bool> isClosed,
      Value<DateTime> createdAt,
      Value<DateTime?> closedAt,
      Value<int> rowid,
    });

final class $$BatchesTableReferences
    extends BaseReferences<_$AppDatabase, $BatchesTable, Batch> {
  $$BatchesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BusinessesTable _businessIdTable(_$AppDatabase db) =>
      db.businesses.createAlias(
        $_aliasNameGenerator(db.batches.businessId, db.businesses.businessId),
      );

  $$BusinessesTableProcessedTableManager get businessId {
    final $_column = $_itemColumn<String>('business_id')!;

    final manager = $$BusinessesTableTableManager(
      $_db,
      $_db.businesses,
    ).filter((f) => f.businessId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_businessIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _assignedStaffIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.batches.assignedStaffId, db.accounts.accountId),
      );

  $$AccountsTableProcessedTableManager? get assignedStaffId {
    final $_column = $_itemColumn<String>('assigned_staff_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_assignedStaffIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _closedByTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.batches.closedBy, db.accounts.accountId),
      );

  $$AccountsTableProcessedTableManager? get closedBy {
    final $_column = $_itemColumn<String>('closed_by');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_closedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: $_aliasNameGenerator(db.batches.batchId, db.expenses.batchId),
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses).filter(
      (f) => f.batchId.batchId.sqlEquals($_itemColumn<String>('batch_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MortalityEntriesTable, List<MortalityEntry>>
  _mortalityEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mortalityEntries,
    aliasName: $_aliasNameGenerator(
      db.batches.batchId,
      db.mortalityEntries.batchId,
    ),
  );

  $$MortalityEntriesTableProcessedTableManager get mortalityEntriesRefs {
    final manager =
        $$MortalityEntriesTableTableManager($_db, $_db.mortalityEntries).filter(
          (f) => f.batchId.batchId.sqlEquals($_itemColumn<String>('batch_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _mortalityEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$FeedEntriesTable, List<FeedEntry>>
  _feedEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.feedEntries,
    aliasName: $_aliasNameGenerator(db.batches.batchId, db.feedEntries.batchId),
  );

  $$FeedEntriesTableProcessedTableManager get feedEntriesRefs {
    final manager = $$FeedEntriesTableTableManager($_db, $_db.feedEntries)
        .filter(
          (f) => f.batchId.batchId.sqlEquals($_itemColumn<String>('batch_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_feedEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WeightSamplesTable, List<WeightSample>>
  _weightSamplesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.weightSamples,
    aliasName: $_aliasNameGenerator(
      db.batches.batchId,
      db.weightSamples.batchId,
    ),
  );

  $$WeightSamplesTableProcessedTableManager get weightSamplesRefs {
    final manager = $$WeightSamplesTableTableManager($_db, $_db.weightSamples)
        .filter(
          (f) => f.batchId.batchId.sqlEquals($_itemColumn<String>('batch_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_weightSamplesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VaccinationEntriesTable, List<VaccinationEntry>>
  _vaccinationEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.vaccinationEntries,
        aliasName: $_aliasNameGenerator(
          db.batches.batchId,
          db.vaccinationEntries.batchId,
        ),
      );

  $$VaccinationEntriesTableProcessedTableManager get vaccinationEntriesRefs {
    final manager =
        $$VaccinationEntriesTableTableManager(
          $_db,
          $_db.vaccinationEntries,
        ).filter(
          (f) => f.batchId.batchId.sqlEquals($_itemColumn<String>('batch_id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _vaccinationEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HarvestEntriesTable, List<HarvestEntry>>
  _harvestEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.harvestEntries,
    aliasName: $_aliasNameGenerator(
      db.batches.batchId,
      db.harvestEntries.batchId,
    ),
  );

  $$HarvestEntriesTableProcessedTableManager get harvestEntriesRefs {
    final manager = $$HarvestEntriesTableTableManager($_db, $_db.harvestEntries)
        .filter(
          (f) => f.batchId.batchId.sqlEquals($_itemColumn<String>('batch_id')!),
        );

    final cache = $_typedResult.readTableOrNull(_harvestEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BatchesTableFilterComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get batchName => $composableBuilder(
    column: $table.batchName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startingBirdCount => $composableBuilder(
    column: $table.startingBirdCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BusinessesTableFilterComposer get businessId {
    final $$BusinessesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businesses,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableFilterComposer(
            $db: $db,
            $table: $db.businesses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get assignedStaffId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignedStaffId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get closedBy {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.closedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mortalityEntriesRefs(
    Expression<bool> Function($$MortalityEntriesTableFilterComposer f) f,
  ) {
    final $$MortalityEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.mortalityEntries,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MortalityEntriesTableFilterComposer(
            $db: $db,
            $table: $db.mortalityEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> feedEntriesRefs(
    Expression<bool> Function($$FeedEntriesTableFilterComposer f) f,
  ) {
    final $$FeedEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.feedEntries,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeedEntriesTableFilterComposer(
            $db: $db,
            $table: $db.feedEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> weightSamplesRefs(
    Expression<bool> Function($$WeightSamplesTableFilterComposer f) f,
  ) {
    final $$WeightSamplesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.weightSamples,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeightSamplesTableFilterComposer(
            $db: $db,
            $table: $db.weightSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> vaccinationEntriesRefs(
    Expression<bool> Function($$VaccinationEntriesTableFilterComposer f) f,
  ) {
    final $$VaccinationEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.vaccinationEntries,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VaccinationEntriesTableFilterComposer(
            $db: $db,
            $table: $db.vaccinationEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> harvestEntriesRefs(
    Expression<bool> Function($$HarvestEntriesTableFilterComposer f) f,
  ) {
    final $$HarvestEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.harvestEntries,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HarvestEntriesTableFilterComposer(
            $db: $db,
            $table: $db.harvestEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BatchesTableOrderingComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get batchId => $composableBuilder(
    column: $table.batchId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get batchName => $composableBuilder(
    column: $table.batchName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get breed => $composableBuilder(
    column: $table.breed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startingBirdCount => $composableBuilder(
    column: $table.startingBirdCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BusinessesTableOrderingComposer get businessId {
    final $$BusinessesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businesses,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableOrderingComposer(
            $db: $db,
            $table: $db.businesses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get assignedStaffId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignedStaffId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get closedBy {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.closedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BatchesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BatchesTable> {
  $$BatchesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get batchId =>
      $composableBuilder(column: $table.batchId, builder: (column) => column);

  GeneratedColumn<String> get batchName =>
      $composableBuilder(column: $table.batchName, builder: (column) => column);

  GeneratedColumn<String> get breed =>
      $composableBuilder(column: $table.breed, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startingBirdCount => $composableBuilder(
    column: $table.startingBirdCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<bool> get isClosed =>
      $composableBuilder(column: $table.isClosed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);

  $$BusinessesTableAnnotationComposer get businessId {
    final $$BusinessesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.businessId,
      referencedTable: $db.businesses,
      getReferencedColumn: (t) => t.businessId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BusinessesTableAnnotationComposer(
            $db: $db,
            $table: $db.businesses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get assignedStaffId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.assignedStaffId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get closedBy {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.closedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mortalityEntriesRefs<T extends Object>(
    Expression<T> Function($$MortalityEntriesTableAnnotationComposer a) f,
  ) {
    final $$MortalityEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.mortalityEntries,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MortalityEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.mortalityEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> feedEntriesRefs<T extends Object>(
    Expression<T> Function($$FeedEntriesTableAnnotationComposer a) f,
  ) {
    final $$FeedEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.feedEntries,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$FeedEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.feedEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> weightSamplesRefs<T extends Object>(
    Expression<T> Function($$WeightSamplesTableAnnotationComposer a) f,
  ) {
    final $$WeightSamplesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.weightSamples,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeightSamplesTableAnnotationComposer(
            $db: $db,
            $table: $db.weightSamples,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> vaccinationEntriesRefs<T extends Object>(
    Expression<T> Function($$VaccinationEntriesTableAnnotationComposer a) f,
  ) {
    final $$VaccinationEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.batchId,
          referencedTable: $db.vaccinationEntries,
          getReferencedColumn: (t) => t.batchId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$VaccinationEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.vaccinationEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> harvestEntriesRefs<T extends Object>(
    Expression<T> Function($$HarvestEntriesTableAnnotationComposer a) f,
  ) {
    final $$HarvestEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.harvestEntries,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HarvestEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.harvestEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BatchesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BatchesTable,
          Batch,
          $$BatchesTableFilterComposer,
          $$BatchesTableOrderingComposer,
          $$BatchesTableAnnotationComposer,
          $$BatchesTableCreateCompanionBuilder,
          $$BatchesTableUpdateCompanionBuilder,
          (Batch, $$BatchesTableReferences),
          Batch,
          PrefetchHooks Function({
            bool businessId,
            bool assignedStaffId,
            bool closedBy,
            bool expensesRefs,
            bool mortalityEntriesRefs,
            bool feedEntriesRefs,
            bool weightSamplesRefs,
            bool vaccinationEntriesRefs,
            bool harvestEntriesRefs,
          })
        > {
  $$BatchesTableTableManager(_$AppDatabase db, $BatchesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BatchesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BatchesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BatchesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> batchId = const Value.absent(),
                Value<String> businessId = const Value.absent(),
                Value<String?> assignedStaffId = const Value.absent(),
                Value<String?> closedBy = const Value.absent(),
                Value<String> batchName = const Value.absent(),
                Value<String?> breed = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> startingBirdCount = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchesCompanion(
                batchId: batchId,
                businessId: businessId,
                assignedStaffId: assignedStaffId,
                closedBy: closedBy,
                batchName: batchName,
                breed: breed,
                description: description,
                startingBirdCount: startingBirdCount,
                startDate: startDate,
                isClosed: isClosed,
                createdAt: createdAt,
                closedAt: closedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String batchId,
                required String businessId,
                Value<String?> assignedStaffId = const Value.absent(),
                Value<String?> closedBy = const Value.absent(),
                required String batchName,
                Value<String?> breed = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required int startingBirdCount,
                required DateTime startDate,
                Value<bool> isClosed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> closedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BatchesCompanion.insert(
                batchId: batchId,
                businessId: businessId,
                assignedStaffId: assignedStaffId,
                closedBy: closedBy,
                batchName: batchName,
                breed: breed,
                description: description,
                startingBirdCount: startingBirdCount,
                startDate: startDate,
                isClosed: isClosed,
                createdAt: createdAt,
                closedAt: closedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BatchesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                businessId = false,
                assignedStaffId = false,
                closedBy = false,
                expensesRefs = false,
                mortalityEntriesRefs = false,
                feedEntriesRefs = false,
                weightSamplesRefs = false,
                vaccinationEntriesRefs = false,
                harvestEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expensesRefs) db.expenses,
                    if (mortalityEntriesRefs) db.mortalityEntries,
                    if (feedEntriesRefs) db.feedEntries,
                    if (weightSamplesRefs) db.weightSamples,
                    if (vaccinationEntriesRefs) db.vaccinationEntries,
                    if (harvestEntriesRefs) db.harvestEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (businessId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.businessId,
                                    referencedTable: $$BatchesTableReferences
                                        ._businessIdTable(db),
                                    referencedColumn: $$BatchesTableReferences
                                        ._businessIdTable(db)
                                        .businessId,
                                  )
                                  as T;
                        }
                        if (assignedStaffId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.assignedStaffId,
                                    referencedTable: $$BatchesTableReferences
                                        ._assignedStaffIdTable(db),
                                    referencedColumn: $$BatchesTableReferences
                                        ._assignedStaffIdTable(db)
                                        .accountId,
                                  )
                                  as T;
                        }
                        if (closedBy) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.closedBy,
                                    referencedTable: $$BatchesTableReferences
                                        ._closedByTable(db),
                                    referencedColumn: $$BatchesTableReferences
                                        ._closedByTable(db)
                                        .accountId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expensesRefs)
                        await $_getPrefetchedData<
                          Batch,
                          $BatchesTable,
                          Expense
                        >(
                          currentTable: table,
                          referencedTable: $$BatchesTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.batchId == item.batchId,
                              ),
                          typedResults: items,
                        ),
                      if (mortalityEntriesRefs)
                        await $_getPrefetchedData<
                          Batch,
                          $BatchesTable,
                          MortalityEntry
                        >(
                          currentTable: table,
                          referencedTable: $$BatchesTableReferences
                              ._mortalityEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).mortalityEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.batchId == item.batchId,
                              ),
                          typedResults: items,
                        ),
                      if (feedEntriesRefs)
                        await $_getPrefetchedData<
                          Batch,
                          $BatchesTable,
                          FeedEntry
                        >(
                          currentTable: table,
                          referencedTable: $$BatchesTableReferences
                              ._feedEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).feedEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.batchId == item.batchId,
                              ),
                          typedResults: items,
                        ),
                      if (weightSamplesRefs)
                        await $_getPrefetchedData<
                          Batch,
                          $BatchesTable,
                          WeightSample
                        >(
                          currentTable: table,
                          referencedTable: $$BatchesTableReferences
                              ._weightSamplesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).weightSamplesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.batchId == item.batchId,
                              ),
                          typedResults: items,
                        ),
                      if (vaccinationEntriesRefs)
                        await $_getPrefetchedData<
                          Batch,
                          $BatchesTable,
                          VaccinationEntry
                        >(
                          currentTable: table,
                          referencedTable: $$BatchesTableReferences
                              ._vaccinationEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).vaccinationEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.batchId == item.batchId,
                              ),
                          typedResults: items,
                        ),
                      if (harvestEntriesRefs)
                        await $_getPrefetchedData<
                          Batch,
                          $BatchesTable,
                          HarvestEntry
                        >(
                          currentTable: table,
                          referencedTable: $$BatchesTableReferences
                              ._harvestEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BatchesTableReferences(
                                db,
                                table,
                                p0,
                              ).harvestEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.batchId == item.batchId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BatchesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BatchesTable,
      Batch,
      $$BatchesTableFilterComposer,
      $$BatchesTableOrderingComposer,
      $$BatchesTableAnnotationComposer,
      $$BatchesTableCreateCompanionBuilder,
      $$BatchesTableUpdateCompanionBuilder,
      (Batch, $$BatchesTableReferences),
      Batch,
      PrefetchHooks Function({
        bool businessId,
        bool assignedStaffId,
        bool closedBy,
        bool expensesRefs,
        bool mortalityEntriesRefs,
        bool feedEntriesRefs,
        bool weightSamplesRefs,
        bool vaccinationEntriesRefs,
        bool harvestEntriesRefs,
      })
    >;
typedef $$ExpensesTableCreateCompanionBuilder =
    ExpensesCompanion Function({
      required String expenseId,
      required String batchId,
      required String recordedBy,
      required String category,
      required DateTime date,
      Value<double?> quantity,
      Value<double?> unitPrice,
      required double amount,
      Value<String?> feedType,
      Value<String?> medicationName,
      Value<String?> description,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });
typedef $$ExpensesTableUpdateCompanionBuilder =
    ExpensesCompanion Function({
      Value<String> expenseId,
      Value<String> batchId,
      Value<String> recordedBy,
      Value<String> category,
      Value<DateTime> date,
      Value<double?> quantity,
      Value<double?> unitPrice,
      Value<double> amount,
      Value<String?> feedType,
      Value<String?> medicationName,
      Value<String?> description,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BatchesTable _batchIdTable(_$AppDatabase db) =>
      db.batches.createAlias(
        $_aliasNameGenerator(db.expenses.batchId, db.batches.batchId),
      );

  $$BatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<String>('batch_id')!;

    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.batchId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _recordedByTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.expenses.recordedBy, db.accounts.accountId),
      );

  $$AccountsTableProcessedTableManager get recordedBy {
    final $_column = $_itemColumn<String>('recorded_by')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedType => $composableBuilder(
    column: $table.feedType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BatchesTableFilterComposer get batchId {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get recordedBy {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get expenseId => $composableBuilder(
    column: $table.expenseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedType => $composableBuilder(
    column: $table.feedType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BatchesTableOrderingComposer get batchId {
    final $$BatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableOrderingComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get recordedBy {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get expenseId =>
      $composableBuilder(column: $table.expenseId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get feedType =>
      $composableBuilder(column: $table.feedType, builder: (column) => column);

  GeneratedColumn<String> get medicationName => $composableBuilder(
    column: $table.medicationName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$BatchesTableAnnotationComposer get batchId {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get recordedBy {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, $$ExpensesTableReferences),
          Expense,
          PrefetchHooks Function({bool batchId, bool recordedBy})
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> expenseId = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> recordedBy = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double?> quantity = const Value.absent(),
                Value<double?> unitPrice = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> feedType = const Value.absent(),
                Value<String?> medicationName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                expenseId: expenseId,
                batchId: batchId,
                recordedBy: recordedBy,
                category: category,
                date: date,
                quantity: quantity,
                unitPrice: unitPrice,
                amount: amount,
                feedType: feedType,
                medicationName: medicationName,
                description: description,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String expenseId,
                required String batchId,
                required String recordedBy,
                required String category,
                required DateTime date,
                Value<double?> quantity = const Value.absent(),
                Value<double?> unitPrice = const Value.absent(),
                required double amount,
                Value<String?> feedType = const Value.absent(),
                Value<String?> medicationName = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                expenseId: expenseId,
                batchId: batchId,
                recordedBy: recordedBy,
                category: category,
                date: date,
                quantity: quantity,
                unitPrice: unitPrice,
                amount: amount,
                feedType: feedType,
                medicationName: medicationName,
                description: description,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({batchId = false, recordedBy = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (batchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.batchId,
                                referencedTable: $$ExpensesTableReferences
                                    ._batchIdTable(db),
                                referencedColumn: $$ExpensesTableReferences
                                    ._batchIdTable(db)
                                    .batchId,
                              )
                              as T;
                    }
                    if (recordedBy) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordedBy,
                                referencedTable: $$ExpensesTableReferences
                                    ._recordedByTable(db),
                                referencedColumn: $$ExpensesTableReferences
                                    ._recordedByTable(db)
                                    .accountId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, $$ExpensesTableReferences),
      Expense,
      PrefetchHooks Function({bool batchId, bool recordedBy})
    >;
typedef $$MortalityEntriesTableCreateCompanionBuilder =
    MortalityEntriesCompanion Function({
      required String mortalityId,
      required String batchId,
      required String recordedBy,
      required DateTime date,
      required int count,
      Value<String?> description,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });
typedef $$MortalityEntriesTableUpdateCompanionBuilder =
    MortalityEntriesCompanion Function({
      Value<String> mortalityId,
      Value<String> batchId,
      Value<String> recordedBy,
      Value<DateTime> date,
      Value<int> count,
      Value<String?> description,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

final class $$MortalityEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $MortalityEntriesTable, MortalityEntry> {
  $$MortalityEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BatchesTable _batchIdTable(_$AppDatabase db) =>
      db.batches.createAlias(
        $_aliasNameGenerator(db.mortalityEntries.batchId, db.batches.batchId),
      );

  $$BatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<String>('batch_id')!;

    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.batchId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _recordedByTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(
          db.mortalityEntries.recordedBy,
          db.accounts.accountId,
        ),
      );

  $$AccountsTableProcessedTableManager get recordedBy {
    final $_column = $_itemColumn<String>('recorded_by')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MortalityEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MortalityEntriesTable> {
  $$MortalityEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get mortalityId => $composableBuilder(
    column: $table.mortalityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BatchesTableFilterComposer get batchId {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get recordedBy {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MortalityEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MortalityEntriesTable> {
  $$MortalityEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get mortalityId => $composableBuilder(
    column: $table.mortalityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BatchesTableOrderingComposer get batchId {
    final $$BatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableOrderingComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get recordedBy {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MortalityEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MortalityEntriesTable> {
  $$MortalityEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get mortalityId => $composableBuilder(
    column: $table.mortalityId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$BatchesTableAnnotationComposer get batchId {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get recordedBy {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MortalityEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MortalityEntriesTable,
          MortalityEntry,
          $$MortalityEntriesTableFilterComposer,
          $$MortalityEntriesTableOrderingComposer,
          $$MortalityEntriesTableAnnotationComposer,
          $$MortalityEntriesTableCreateCompanionBuilder,
          $$MortalityEntriesTableUpdateCompanionBuilder,
          (MortalityEntry, $$MortalityEntriesTableReferences),
          MortalityEntry,
          PrefetchHooks Function({bool batchId, bool recordedBy})
        > {
  $$MortalityEntriesTableTableManager(
    _$AppDatabase db,
    $MortalityEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MortalityEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MortalityEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MortalityEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> mortalityId = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> recordedBy = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MortalityEntriesCompanion(
                mortalityId: mortalityId,
                batchId: batchId,
                recordedBy: recordedBy,
                date: date,
                count: count,
                description: description,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String mortalityId,
                required String batchId,
                required String recordedBy,
                required DateTime date,
                required int count,
                Value<String?> description = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MortalityEntriesCompanion.insert(
                mortalityId: mortalityId,
                batchId: batchId,
                recordedBy: recordedBy,
                date: date,
                count: count,
                description: description,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MortalityEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({batchId = false, recordedBy = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (batchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.batchId,
                                referencedTable:
                                    $$MortalityEntriesTableReferences
                                        ._batchIdTable(db),
                                referencedColumn:
                                    $$MortalityEntriesTableReferences
                                        ._batchIdTable(db)
                                        .batchId,
                              )
                              as T;
                    }
                    if (recordedBy) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordedBy,
                                referencedTable:
                                    $$MortalityEntriesTableReferences
                                        ._recordedByTable(db),
                                referencedColumn:
                                    $$MortalityEntriesTableReferences
                                        ._recordedByTable(db)
                                        .accountId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MortalityEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MortalityEntriesTable,
      MortalityEntry,
      $$MortalityEntriesTableFilterComposer,
      $$MortalityEntriesTableOrderingComposer,
      $$MortalityEntriesTableAnnotationComposer,
      $$MortalityEntriesTableCreateCompanionBuilder,
      $$MortalityEntriesTableUpdateCompanionBuilder,
      (MortalityEntry, $$MortalityEntriesTableReferences),
      MortalityEntry,
      PrefetchHooks Function({bool batchId, bool recordedBy})
    >;
typedef $$FeedEntriesTableCreateCompanionBuilder =
    FeedEntriesCompanion Function({
      required String feedEntryId,
      required String batchId,
      required String recordedBy,
      required DateTime date,
      required double quantity,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });
typedef $$FeedEntriesTableUpdateCompanionBuilder =
    FeedEntriesCompanion Function({
      Value<String> feedEntryId,
      Value<String> batchId,
      Value<String> recordedBy,
      Value<DateTime> date,
      Value<double> quantity,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

final class $$FeedEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $FeedEntriesTable, FeedEntry> {
  $$FeedEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BatchesTable _batchIdTable(_$AppDatabase db) =>
      db.batches.createAlias(
        $_aliasNameGenerator(db.feedEntries.batchId, db.batches.batchId),
      );

  $$BatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<String>('batch_id')!;

    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.batchId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _recordedByTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.feedEntries.recordedBy, db.accounts.accountId),
      );

  $$AccountsTableProcessedTableManager get recordedBy {
    final $_column = $_itemColumn<String>('recorded_by')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$FeedEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $FeedEntriesTable> {
  $$FeedEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get feedEntryId => $composableBuilder(
    column: $table.feedEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BatchesTableFilterComposer get batchId {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get recordedBy {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeedEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $FeedEntriesTable> {
  $$FeedEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get feedEntryId => $composableBuilder(
    column: $table.feedEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BatchesTableOrderingComposer get batchId {
    final $$BatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableOrderingComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get recordedBy {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeedEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FeedEntriesTable> {
  $$FeedEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get feedEntryId => $composableBuilder(
    column: $table.feedEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$BatchesTableAnnotationComposer get batchId {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get recordedBy {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$FeedEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FeedEntriesTable,
          FeedEntry,
          $$FeedEntriesTableFilterComposer,
          $$FeedEntriesTableOrderingComposer,
          $$FeedEntriesTableAnnotationComposer,
          $$FeedEntriesTableCreateCompanionBuilder,
          $$FeedEntriesTableUpdateCompanionBuilder,
          (FeedEntry, $$FeedEntriesTableReferences),
          FeedEntry,
          PrefetchHooks Function({bool batchId, bool recordedBy})
        > {
  $$FeedEntriesTableTableManager(_$AppDatabase db, $FeedEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FeedEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FeedEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FeedEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> feedEntryId = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> recordedBy = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedEntriesCompanion(
                feedEntryId: feedEntryId,
                batchId: batchId,
                recordedBy: recordedBy,
                date: date,
                quantity: quantity,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String feedEntryId,
                required String batchId,
                required String recordedBy,
                required DateTime date,
                required double quantity,
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FeedEntriesCompanion.insert(
                feedEntryId: feedEntryId,
                batchId: batchId,
                recordedBy: recordedBy,
                date: date,
                quantity: quantity,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$FeedEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({batchId = false, recordedBy = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (batchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.batchId,
                                referencedTable: $$FeedEntriesTableReferences
                                    ._batchIdTable(db),
                                referencedColumn: $$FeedEntriesTableReferences
                                    ._batchIdTable(db)
                                    .batchId,
                              )
                              as T;
                    }
                    if (recordedBy) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordedBy,
                                referencedTable: $$FeedEntriesTableReferences
                                    ._recordedByTable(db),
                                referencedColumn: $$FeedEntriesTableReferences
                                    ._recordedByTable(db)
                                    .accountId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$FeedEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FeedEntriesTable,
      FeedEntry,
      $$FeedEntriesTableFilterComposer,
      $$FeedEntriesTableOrderingComposer,
      $$FeedEntriesTableAnnotationComposer,
      $$FeedEntriesTableCreateCompanionBuilder,
      $$FeedEntriesTableUpdateCompanionBuilder,
      (FeedEntry, $$FeedEntriesTableReferences),
      FeedEntry,
      PrefetchHooks Function({bool batchId, bool recordedBy})
    >;
typedef $$WeightSamplesTableCreateCompanionBuilder =
    WeightSamplesCompanion Function({
      required String weightSampleId,
      required String batchId,
      required String recordedBy,
      required DateTime date,
      required double sampleWeight,
      required int sampleCount,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });
typedef $$WeightSamplesTableUpdateCompanionBuilder =
    WeightSamplesCompanion Function({
      Value<String> weightSampleId,
      Value<String> batchId,
      Value<String> recordedBy,
      Value<DateTime> date,
      Value<double> sampleWeight,
      Value<int> sampleCount,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

final class $$WeightSamplesTableReferences
    extends BaseReferences<_$AppDatabase, $WeightSamplesTable, WeightSample> {
  $$WeightSamplesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BatchesTable _batchIdTable(_$AppDatabase db) =>
      db.batches.createAlias(
        $_aliasNameGenerator(db.weightSamples.batchId, db.batches.batchId),
      );

  $$BatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<String>('batch_id')!;

    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.batchId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _recordedByTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(
          db.weightSamples.recordedBy,
          db.accounts.accountId,
        ),
      );

  $$AccountsTableProcessedTableManager get recordedBy {
    final $_column = $_itemColumn<String>('recorded_by')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WeightSamplesTableFilterComposer
    extends Composer<_$AppDatabase, $WeightSamplesTable> {
  $$WeightSamplesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get weightSampleId => $composableBuilder(
    column: $table.weightSampleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sampleWeight => $composableBuilder(
    column: $table.sampleWeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BatchesTableFilterComposer get batchId {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get recordedBy {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeightSamplesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeightSamplesTable> {
  $$WeightSamplesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get weightSampleId => $composableBuilder(
    column: $table.weightSampleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sampleWeight => $composableBuilder(
    column: $table.sampleWeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BatchesTableOrderingComposer get batchId {
    final $$BatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableOrderingComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get recordedBy {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeightSamplesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeightSamplesTable> {
  $$WeightSamplesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get weightSampleId => $composableBuilder(
    column: $table.weightSampleId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get sampleWeight => $composableBuilder(
    column: $table.sampleWeight,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sampleCount => $composableBuilder(
    column: $table.sampleCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$BatchesTableAnnotationComposer get batchId {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get recordedBy {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeightSamplesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeightSamplesTable,
          WeightSample,
          $$WeightSamplesTableFilterComposer,
          $$WeightSamplesTableOrderingComposer,
          $$WeightSamplesTableAnnotationComposer,
          $$WeightSamplesTableCreateCompanionBuilder,
          $$WeightSamplesTableUpdateCompanionBuilder,
          (WeightSample, $$WeightSamplesTableReferences),
          WeightSample,
          PrefetchHooks Function({bool batchId, bool recordedBy})
        > {
  $$WeightSamplesTableTableManager(_$AppDatabase db, $WeightSamplesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeightSamplesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeightSamplesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeightSamplesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> weightSampleId = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> recordedBy = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> sampleWeight = const Value.absent(),
                Value<int> sampleCount = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightSamplesCompanion(
                weightSampleId: weightSampleId,
                batchId: batchId,
                recordedBy: recordedBy,
                date: date,
                sampleWeight: sampleWeight,
                sampleCount: sampleCount,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String weightSampleId,
                required String batchId,
                required String recordedBy,
                required DateTime date,
                required double sampleWeight,
                required int sampleCount,
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeightSamplesCompanion.insert(
                weightSampleId: weightSampleId,
                batchId: batchId,
                recordedBy: recordedBy,
                date: date,
                sampleWeight: sampleWeight,
                sampleCount: sampleCount,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WeightSamplesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({batchId = false, recordedBy = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (batchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.batchId,
                                referencedTable: $$WeightSamplesTableReferences
                                    ._batchIdTable(db),
                                referencedColumn: $$WeightSamplesTableReferences
                                    ._batchIdTable(db)
                                    .batchId,
                              )
                              as T;
                    }
                    if (recordedBy) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordedBy,
                                referencedTable: $$WeightSamplesTableReferences
                                    ._recordedByTable(db),
                                referencedColumn: $$WeightSamplesTableReferences
                                    ._recordedByTable(db)
                                    .accountId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WeightSamplesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeightSamplesTable,
      WeightSample,
      $$WeightSamplesTableFilterComposer,
      $$WeightSamplesTableOrderingComposer,
      $$WeightSamplesTableAnnotationComposer,
      $$WeightSamplesTableCreateCompanionBuilder,
      $$WeightSamplesTableUpdateCompanionBuilder,
      (WeightSample, $$WeightSamplesTableReferences),
      WeightSample,
      PrefetchHooks Function({bool batchId, bool recordedBy})
    >;
typedef $$VaccinationEntriesTableCreateCompanionBuilder =
    VaccinationEntriesCompanion Function({
      required String vaccinationId,
      required String batchId,
      required String recordedBy,
      required DateTime date,
      required String vaccineName,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });
typedef $$VaccinationEntriesTableUpdateCompanionBuilder =
    VaccinationEntriesCompanion Function({
      Value<String> vaccinationId,
      Value<String> batchId,
      Value<String> recordedBy,
      Value<DateTime> date,
      Value<String> vaccineName,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

final class $$VaccinationEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $VaccinationEntriesTable,
          VaccinationEntry
        > {
  $$VaccinationEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BatchesTable _batchIdTable(_$AppDatabase db) =>
      db.batches.createAlias(
        $_aliasNameGenerator(db.vaccinationEntries.batchId, db.batches.batchId),
      );

  $$BatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<String>('batch_id')!;

    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.batchId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _recordedByTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(
          db.vaccinationEntries.recordedBy,
          db.accounts.accountId,
        ),
      );

  $$AccountsTableProcessedTableManager get recordedBy {
    final $_column = $_itemColumn<String>('recorded_by')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$VaccinationEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $VaccinationEntriesTable> {
  $$VaccinationEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get vaccinationId => $composableBuilder(
    column: $table.vaccinationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vaccineName => $composableBuilder(
    column: $table.vaccineName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BatchesTableFilterComposer get batchId {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get recordedBy {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VaccinationEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $VaccinationEntriesTable> {
  $$VaccinationEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get vaccinationId => $composableBuilder(
    column: $table.vaccinationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vaccineName => $composableBuilder(
    column: $table.vaccineName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BatchesTableOrderingComposer get batchId {
    final $$BatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableOrderingComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get recordedBy {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VaccinationEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaccinationEntriesTable> {
  $$VaccinationEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get vaccinationId => $composableBuilder(
    column: $table.vaccinationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get vaccineName => $composableBuilder(
    column: $table.vaccineName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$BatchesTableAnnotationComposer get batchId {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get recordedBy {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VaccinationEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaccinationEntriesTable,
          VaccinationEntry,
          $$VaccinationEntriesTableFilterComposer,
          $$VaccinationEntriesTableOrderingComposer,
          $$VaccinationEntriesTableAnnotationComposer,
          $$VaccinationEntriesTableCreateCompanionBuilder,
          $$VaccinationEntriesTableUpdateCompanionBuilder,
          (VaccinationEntry, $$VaccinationEntriesTableReferences),
          VaccinationEntry,
          PrefetchHooks Function({bool batchId, bool recordedBy})
        > {
  $$VaccinationEntriesTableTableManager(
    _$AppDatabase db,
    $VaccinationEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaccinationEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaccinationEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaccinationEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> vaccinationId = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> recordedBy = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> vaccineName = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaccinationEntriesCompanion(
                vaccinationId: vaccinationId,
                batchId: batchId,
                recordedBy: recordedBy,
                date: date,
                vaccineName: vaccineName,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String vaccinationId,
                required String batchId,
                required String recordedBy,
                required DateTime date,
                required String vaccineName,
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaccinationEntriesCompanion.insert(
                vaccinationId: vaccinationId,
                batchId: batchId,
                recordedBy: recordedBy,
                date: date,
                vaccineName: vaccineName,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$VaccinationEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({batchId = false, recordedBy = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (batchId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.batchId,
                                referencedTable:
                                    $$VaccinationEntriesTableReferences
                                        ._batchIdTable(db),
                                referencedColumn:
                                    $$VaccinationEntriesTableReferences
                                        ._batchIdTable(db)
                                        .batchId,
                              )
                              as T;
                    }
                    if (recordedBy) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordedBy,
                                referencedTable:
                                    $$VaccinationEntriesTableReferences
                                        ._recordedByTable(db),
                                referencedColumn:
                                    $$VaccinationEntriesTableReferences
                                        ._recordedByTable(db)
                                        .accountId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$VaccinationEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaccinationEntriesTable,
      VaccinationEntry,
      $$VaccinationEntriesTableFilterComposer,
      $$VaccinationEntriesTableOrderingComposer,
      $$VaccinationEntriesTableAnnotationComposer,
      $$VaccinationEntriesTableCreateCompanionBuilder,
      $$VaccinationEntriesTableUpdateCompanionBuilder,
      (VaccinationEntry, $$VaccinationEntriesTableReferences),
      VaccinationEntry,
      PrefetchHooks Function({bool batchId, bool recordedBy})
    >;
typedef $$HarvestEntriesTableCreateCompanionBuilder =
    HarvestEntriesCompanion Function({
      required String harvestId,
      required String batchId,
      required String recordedBy,
      required DateTime date,
      required int birdCount,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });
typedef $$HarvestEntriesTableUpdateCompanionBuilder =
    HarvestEntriesCompanion Function({
      Value<String> harvestId,
      Value<String> batchId,
      Value<String> recordedBy,
      Value<DateTime> date,
      Value<int> birdCount,
      Value<DateTime> recordedAt,
      Value<DateTime> syncedAt,
      Value<int> rowid,
    });

final class $$HarvestEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $HarvestEntriesTable, HarvestEntry> {
  $$HarvestEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BatchesTable _batchIdTable(_$AppDatabase db) =>
      db.batches.createAlias(
        $_aliasNameGenerator(db.harvestEntries.batchId, db.batches.batchId),
      );

  $$BatchesTableProcessedTableManager get batchId {
    final $_column = $_itemColumn<String>('batch_id')!;

    final manager = $$BatchesTableTableManager(
      $_db,
      $_db.batches,
    ).filter((f) => f.batchId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_batchIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _recordedByTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(
          db.harvestEntries.recordedBy,
          db.accounts.accountId,
        ),
      );

  $$AccountsTableProcessedTableManager get recordedBy {
    final $_column = $_itemColumn<String>('recorded_by')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SalesTable, List<Sale>> _salesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.sales,
    aliasName: $_aliasNameGenerator(
      db.harvestEntries.harvestId,
      db.sales.harvestId,
    ),
  );

  $$SalesTableProcessedTableManager get salesRefs {
    final manager = $$SalesTableTableManager($_db, $_db.sales).filter(
      (f) =>
          f.harvestId.harvestId.sqlEquals($_itemColumn<String>('harvest_id')!),
    );

    final cache = $_typedResult.readTableOrNull(_salesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HarvestEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $HarvestEntriesTable> {
  $$HarvestEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get harvestId => $composableBuilder(
    column: $table.harvestId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get birdCount => $composableBuilder(
    column: $table.birdCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$BatchesTableFilterComposer get batchId {
    final $$BatchesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableFilterComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get recordedBy {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> salesRefs(
    Expression<bool> Function($$SalesTableFilterComposer f) f,
  ) {
    final $$SalesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.harvestId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.harvestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableFilterComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HarvestEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $HarvestEntriesTable> {
  $$HarvestEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get harvestId => $composableBuilder(
    column: $table.harvestId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get birdCount => $composableBuilder(
    column: $table.birdCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$BatchesTableOrderingComposer get batchId {
    final $$BatchesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableOrderingComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get recordedBy {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HarvestEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HarvestEntriesTable> {
  $$HarvestEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get harvestId =>
      $composableBuilder(column: $table.harvestId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get birdCount =>
      $composableBuilder(column: $table.birdCount, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  $$BatchesTableAnnotationComposer get batchId {
    final $$BatchesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.batchId,
      referencedTable: $db.batches,
      getReferencedColumn: (t) => t.batchId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BatchesTableAnnotationComposer(
            $db: $db,
            $table: $db.batches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get recordedBy {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> salesRefs<T extends Object>(
    Expression<T> Function($$SalesTableAnnotationComposer a) f,
  ) {
    final $$SalesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.harvestId,
      referencedTable: $db.sales,
      getReferencedColumn: (t) => t.harvestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SalesTableAnnotationComposer(
            $db: $db,
            $table: $db.sales,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HarvestEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HarvestEntriesTable,
          HarvestEntry,
          $$HarvestEntriesTableFilterComposer,
          $$HarvestEntriesTableOrderingComposer,
          $$HarvestEntriesTableAnnotationComposer,
          $$HarvestEntriesTableCreateCompanionBuilder,
          $$HarvestEntriesTableUpdateCompanionBuilder,
          (HarvestEntry, $$HarvestEntriesTableReferences),
          HarvestEntry,
          PrefetchHooks Function({
            bool batchId,
            bool recordedBy,
            bool salesRefs,
          })
        > {
  $$HarvestEntriesTableTableManager(
    _$AppDatabase db,
    $HarvestEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HarvestEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HarvestEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HarvestEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> harvestId = const Value.absent(),
                Value<String> batchId = const Value.absent(),
                Value<String> recordedBy = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> birdCount = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HarvestEntriesCompanion(
                harvestId: harvestId,
                batchId: batchId,
                recordedBy: recordedBy,
                date: date,
                birdCount: birdCount,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String harvestId,
                required String batchId,
                required String recordedBy,
                required DateTime date,
                required int birdCount,
                Value<DateTime> recordedAt = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HarvestEntriesCompanion.insert(
                harvestId: harvestId,
                batchId: batchId,
                recordedBy: recordedBy,
                date: date,
                birdCount: birdCount,
                recordedAt: recordedAt,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HarvestEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({batchId = false, recordedBy = false, salesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (salesRefs) db.sales],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (batchId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.batchId,
                                    referencedTable:
                                        $$HarvestEntriesTableReferences
                                            ._batchIdTable(db),
                                    referencedColumn:
                                        $$HarvestEntriesTableReferences
                                            ._batchIdTable(db)
                                            .batchId,
                                  )
                                  as T;
                        }
                        if (recordedBy) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.recordedBy,
                                    referencedTable:
                                        $$HarvestEntriesTableReferences
                                            ._recordedByTable(db),
                                    referencedColumn:
                                        $$HarvestEntriesTableReferences
                                            ._recordedByTable(db)
                                            .accountId,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (salesRefs)
                        await $_getPrefetchedData<
                          HarvestEntry,
                          $HarvestEntriesTable,
                          Sale
                        >(
                          currentTable: table,
                          referencedTable: $$HarvestEntriesTableReferences
                              ._salesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HarvestEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).salesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.harvestId == item.harvestId,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HarvestEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HarvestEntriesTable,
      HarvestEntry,
      $$HarvestEntriesTableFilterComposer,
      $$HarvestEntriesTableOrderingComposer,
      $$HarvestEntriesTableAnnotationComposer,
      $$HarvestEntriesTableCreateCompanionBuilder,
      $$HarvestEntriesTableUpdateCompanionBuilder,
      (HarvestEntry, $$HarvestEntriesTableReferences),
      HarvestEntry,
      PrefetchHooks Function({bool batchId, bool recordedBy, bool salesRefs})
    >;
typedef $$SalesTableCreateCompanionBuilder =
    SalesCompanion Function({
      required String saleId,
      required String harvestId,
      required String recordedBy,
      required String disposition,
      Value<String?> buyerName,
      Value<String?> pricingMethod,
      Value<double?> weightSold,
      Value<double?> pricePerUnit,
      required double amount,
      Value<String?> paymentStatus,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$SalesTableUpdateCompanionBuilder =
    SalesCompanion Function({
      Value<String> saleId,
      Value<String> harvestId,
      Value<String> recordedBy,
      Value<String> disposition,
      Value<String?> buyerName,
      Value<String?> pricingMethod,
      Value<double?> weightSold,
      Value<double?> pricePerUnit,
      Value<double> amount,
      Value<String?> paymentStatus,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$SalesTableReferences
    extends BaseReferences<_$AppDatabase, $SalesTable, Sale> {
  $$SalesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HarvestEntriesTable _harvestIdTable(_$AppDatabase db) =>
      db.harvestEntries.createAlias(
        $_aliasNameGenerator(db.sales.harvestId, db.harvestEntries.harvestId),
      );

  $$HarvestEntriesTableProcessedTableManager get harvestId {
    final $_column = $_itemColumn<String>('harvest_id')!;

    final manager = $$HarvestEntriesTableTableManager(
      $_db,
      $_db.harvestEntries,
    ).filter((f) => f.harvestId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_harvestIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _recordedByTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.sales.recordedBy, db.accounts.accountId),
      );

  $$AccountsTableProcessedTableManager get recordedBy {
    final $_column = $_itemColumn<String>('recorded_by')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountId.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recordedByTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SalesTableFilterComposer extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get disposition => $composableBuilder(
    column: $table.disposition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get buyerName => $composableBuilder(
    column: $table.buyerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pricingMethod => $composableBuilder(
    column: $table.pricingMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightSold => $composableBuilder(
    column: $table.weightSold,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pricePerUnit => $composableBuilder(
    column: $table.pricePerUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$HarvestEntriesTableFilterComposer get harvestId {
    final $$HarvestEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.harvestId,
      referencedTable: $db.harvestEntries,
      getReferencedColumn: (t) => t.harvestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HarvestEntriesTableFilterComposer(
            $db: $db,
            $table: $db.harvestEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get recordedBy {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalesTableOrderingComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get saleId => $composableBuilder(
    column: $table.saleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get disposition => $composableBuilder(
    column: $table.disposition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get buyerName => $composableBuilder(
    column: $table.buyerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pricingMethod => $composableBuilder(
    column: $table.pricingMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightSold => $composableBuilder(
    column: $table.weightSold,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pricePerUnit => $composableBuilder(
    column: $table.pricePerUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$HarvestEntriesTableOrderingComposer get harvestId {
    final $$HarvestEntriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.harvestId,
      referencedTable: $db.harvestEntries,
      getReferencedColumn: (t) => t.harvestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HarvestEntriesTableOrderingComposer(
            $db: $db,
            $table: $db.harvestEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get recordedBy {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SalesTable> {
  $$SalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get saleId =>
      $composableBuilder(column: $table.saleId, builder: (column) => column);

  GeneratedColumn<String> get disposition => $composableBuilder(
    column: $table.disposition,
    builder: (column) => column,
  );

  GeneratedColumn<String> get buyerName =>
      $composableBuilder(column: $table.buyerName, builder: (column) => column);

  GeneratedColumn<String> get pricingMethod => $composableBuilder(
    column: $table.pricingMethod,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightSold => $composableBuilder(
    column: $table.weightSold,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pricePerUnit => $composableBuilder(
    column: $table.pricePerUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
    column: $table.paymentStatus,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$HarvestEntriesTableAnnotationComposer get harvestId {
    final $$HarvestEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.harvestId,
      referencedTable: $db.harvestEntries,
      getReferencedColumn: (t) => t.harvestId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HarvestEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.harvestEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get recordedBy {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recordedBy,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SalesTable,
          Sale,
          $$SalesTableFilterComposer,
          $$SalesTableOrderingComposer,
          $$SalesTableAnnotationComposer,
          $$SalesTableCreateCompanionBuilder,
          $$SalesTableUpdateCompanionBuilder,
          (Sale, $$SalesTableReferences),
          Sale,
          PrefetchHooks Function({bool harvestId, bool recordedBy})
        > {
  $$SalesTableTableManager(_$AppDatabase db, $SalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> saleId = const Value.absent(),
                Value<String> harvestId = const Value.absent(),
                Value<String> recordedBy = const Value.absent(),
                Value<String> disposition = const Value.absent(),
                Value<String?> buyerName = const Value.absent(),
                Value<String?> pricingMethod = const Value.absent(),
                Value<double?> weightSold = const Value.absent(),
                Value<double?> pricePerUnit = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<String?> paymentStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesCompanion(
                saleId: saleId,
                harvestId: harvestId,
                recordedBy: recordedBy,
                disposition: disposition,
                buyerName: buyerName,
                pricingMethod: pricingMethod,
                weightSold: weightSold,
                pricePerUnit: pricePerUnit,
                amount: amount,
                paymentStatus: paymentStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String saleId,
                required String harvestId,
                required String recordedBy,
                required String disposition,
                Value<String?> buyerName = const Value.absent(),
                Value<String?> pricingMethod = const Value.absent(),
                Value<double?> weightSold = const Value.absent(),
                Value<double?> pricePerUnit = const Value.absent(),
                required double amount,
                Value<String?> paymentStatus = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SalesCompanion.insert(
                saleId: saleId,
                harvestId: harvestId,
                recordedBy: recordedBy,
                disposition: disposition,
                buyerName: buyerName,
                pricingMethod: pricingMethod,
                weightSold: weightSold,
                pricePerUnit: pricePerUnit,
                amount: amount,
                paymentStatus: paymentStatus,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SalesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({harvestId = false, recordedBy = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (harvestId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.harvestId,
                                referencedTable: $$SalesTableReferences
                                    ._harvestIdTable(db),
                                referencedColumn: $$SalesTableReferences
                                    ._harvestIdTable(db)
                                    .harvestId,
                              )
                              as T;
                    }
                    if (recordedBy) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recordedBy,
                                referencedTable: $$SalesTableReferences
                                    ._recordedByTable(db),
                                referencedColumn: $$SalesTableReferences
                                    ._recordedByTable(db)
                                    .accountId,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SalesTable,
      Sale,
      $$SalesTableFilterComposer,
      $$SalesTableOrderingComposer,
      $$SalesTableAnnotationComposer,
      $$SalesTableCreateCompanionBuilder,
      $$SalesTableUpdateCompanionBuilder,
      (Sale, $$SalesTableReferences),
      Sale,
      PrefetchHooks Function({bool harvestId, bool recordedBy})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BusinessesTableTableManager get businesses =>
      $$BusinessesTableTableManager(_db, _db.businesses);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$BatchesTableTableManager get batches =>
      $$BatchesTableTableManager(_db, _db.batches);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$MortalityEntriesTableTableManager get mortalityEntries =>
      $$MortalityEntriesTableTableManager(_db, _db.mortalityEntries);
  $$FeedEntriesTableTableManager get feedEntries =>
      $$FeedEntriesTableTableManager(_db, _db.feedEntries);
  $$WeightSamplesTableTableManager get weightSamples =>
      $$WeightSamplesTableTableManager(_db, _db.weightSamples);
  $$VaccinationEntriesTableTableManager get vaccinationEntries =>
      $$VaccinationEntriesTableTableManager(_db, _db.vaccinationEntries);
  $$HarvestEntriesTableTableManager get harvestEntries =>
      $$HarvestEntriesTableTableManager(_db, _db.harvestEntries);
  $$SalesTableTableManager get sales =>
      $$SalesTableTableManager(_db, _db.sales);
}
