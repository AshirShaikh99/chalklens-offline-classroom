// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_lesson_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SavedLessonModel {

 String get id; LessonKitModel get kit; LessonContextModel get context; DateTime get savedAt;
/// Create a copy of SavedLessonModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedLessonModelCopyWith<SavedLessonModel> get copyWith => _$SavedLessonModelCopyWithImpl<SavedLessonModel>(this as SavedLessonModel, _$identity);

  /// Serializes this SavedLessonModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedLessonModel&&(identical(other.id, id) || other.id == id)&&(identical(other.kit, kit) || other.kit == kit)&&(identical(other.context, context) || other.context == context)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kit,context,savedAt);

@override
String toString() {
  return 'SavedLessonModel(id: $id, kit: $kit, context: $context, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class $SavedLessonModelCopyWith<$Res>  {
  factory $SavedLessonModelCopyWith(SavedLessonModel value, $Res Function(SavedLessonModel) _then) = _$SavedLessonModelCopyWithImpl;
@useResult
$Res call({
 String id, LessonKitModel kit, LessonContextModel context, DateTime savedAt
});


$LessonKitModelCopyWith<$Res> get kit;$LessonContextModelCopyWith<$Res> get context;

}
/// @nodoc
class _$SavedLessonModelCopyWithImpl<$Res>
    implements $SavedLessonModelCopyWith<$Res> {
  _$SavedLessonModelCopyWithImpl(this._self, this._then);

  final SavedLessonModel _self;
  final $Res Function(SavedLessonModel) _then;

/// Create a copy of SavedLessonModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kit = null,Object? context = null,Object? savedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kit: null == kit ? _self.kit : kit // ignore: cast_nullable_to_non_nullable
as LessonKitModel,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as LessonContextModel,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of SavedLessonModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonKitModelCopyWith<$Res> get kit {
  
  return $LessonKitModelCopyWith<$Res>(_self.kit, (value) {
    return _then(_self.copyWith(kit: value));
  });
}/// Create a copy of SavedLessonModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonContextModelCopyWith<$Res> get context {
  
  return $LessonContextModelCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}


/// Adds pattern-matching-related methods to [SavedLessonModel].
extension SavedLessonModelPatterns on SavedLessonModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedLessonModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedLessonModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedLessonModel value)  $default,){
final _that = this;
switch (_that) {
case _SavedLessonModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedLessonModel value)?  $default,){
final _that = this;
switch (_that) {
case _SavedLessonModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  LessonKitModel kit,  LessonContextModel context,  DateTime savedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedLessonModel() when $default != null:
return $default(_that.id,_that.kit,_that.context,_that.savedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  LessonKitModel kit,  LessonContextModel context,  DateTime savedAt)  $default,) {final _that = this;
switch (_that) {
case _SavedLessonModel():
return $default(_that.id,_that.kit,_that.context,_that.savedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  LessonKitModel kit,  LessonContextModel context,  DateTime savedAt)?  $default,) {final _that = this;
switch (_that) {
case _SavedLessonModel() when $default != null:
return $default(_that.id,_that.kit,_that.context,_that.savedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SavedLessonModel extends SavedLessonModel {
  const _SavedLessonModel({required this.id, required this.kit, required this.context, required this.savedAt}): super._();
  factory _SavedLessonModel.fromJson(Map<String, dynamic> json) => _$SavedLessonModelFromJson(json);

@override final  String id;
@override final  LessonKitModel kit;
@override final  LessonContextModel context;
@override final  DateTime savedAt;

/// Create a copy of SavedLessonModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedLessonModelCopyWith<_SavedLessonModel> get copyWith => __$SavedLessonModelCopyWithImpl<_SavedLessonModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SavedLessonModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedLessonModel&&(identical(other.id, id) || other.id == id)&&(identical(other.kit, kit) || other.kit == kit)&&(identical(other.context, context) || other.context == context)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kit,context,savedAt);

@override
String toString() {
  return 'SavedLessonModel(id: $id, kit: $kit, context: $context, savedAt: $savedAt)';
}


}

/// @nodoc
abstract mixin class _$SavedLessonModelCopyWith<$Res> implements $SavedLessonModelCopyWith<$Res> {
  factory _$SavedLessonModelCopyWith(_SavedLessonModel value, $Res Function(_SavedLessonModel) _then) = __$SavedLessonModelCopyWithImpl;
@override @useResult
$Res call({
 String id, LessonKitModel kit, LessonContextModel context, DateTime savedAt
});


@override $LessonKitModelCopyWith<$Res> get kit;@override $LessonContextModelCopyWith<$Res> get context;

}
/// @nodoc
class __$SavedLessonModelCopyWithImpl<$Res>
    implements _$SavedLessonModelCopyWith<$Res> {
  __$SavedLessonModelCopyWithImpl(this._self, this._then);

  final _SavedLessonModel _self;
  final $Res Function(_SavedLessonModel) _then;

/// Create a copy of SavedLessonModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kit = null,Object? context = null,Object? savedAt = null,}) {
  return _then(_SavedLessonModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kit: null == kit ? _self.kit : kit // ignore: cast_nullable_to_non_nullable
as LessonKitModel,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as LessonContextModel,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of SavedLessonModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonKitModelCopyWith<$Res> get kit {
  
  return $LessonKitModelCopyWith<$Res>(_self.kit, (value) {
    return _then(_self.copyWith(kit: value));
  });
}/// Create a copy of SavedLessonModel
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonContextModelCopyWith<$Res> get context {
  
  return $LessonContextModelCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

// dart format on
