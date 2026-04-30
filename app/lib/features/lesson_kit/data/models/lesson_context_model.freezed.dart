// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson_context_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LessonContextModel {

 String get grade; String get subject; AppLanguage get language; int get classDurationMinutes; StudentLevel get studentLevel;
/// Create a copy of LessonContextModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonContextModelCopyWith<LessonContextModel> get copyWith => _$LessonContextModelCopyWithImpl<LessonContextModel>(this as LessonContextModel, _$identity);

  /// Serializes this LessonContextModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonContextModel&&(identical(other.grade, grade) || other.grade == grade)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.language, language) || other.language == language)&&(identical(other.classDurationMinutes, classDurationMinutes) || other.classDurationMinutes == classDurationMinutes)&&(identical(other.studentLevel, studentLevel) || other.studentLevel == studentLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,grade,subject,language,classDurationMinutes,studentLevel);

@override
String toString() {
  return 'LessonContextModel(grade: $grade, subject: $subject, language: $language, classDurationMinutes: $classDurationMinutes, studentLevel: $studentLevel)';
}


}

/// @nodoc
abstract mixin class $LessonContextModelCopyWith<$Res>  {
  factory $LessonContextModelCopyWith(LessonContextModel value, $Res Function(LessonContextModel) _then) = _$LessonContextModelCopyWithImpl;
@useResult
$Res call({
 String grade, String subject, AppLanguage language, int classDurationMinutes, StudentLevel studentLevel
});




}
/// @nodoc
class _$LessonContextModelCopyWithImpl<$Res>
    implements $LessonContextModelCopyWith<$Res> {
  _$LessonContextModelCopyWithImpl(this._self, this._then);

  final LessonContextModel _self;
  final $Res Function(LessonContextModel) _then;

/// Create a copy of LessonContextModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? grade = null,Object? subject = null,Object? language = null,Object? classDurationMinutes = null,Object? studentLevel = null,}) {
  return _then(_self.copyWith(
grade: null == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as AppLanguage,classDurationMinutes: null == classDurationMinutes ? _self.classDurationMinutes : classDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,studentLevel: null == studentLevel ? _self.studentLevel : studentLevel // ignore: cast_nullable_to_non_nullable
as StudentLevel,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonContextModel].
extension LessonContextModelPatterns on LessonContextModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonContextModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonContextModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonContextModel value)  $default,){
final _that = this;
switch (_that) {
case _LessonContextModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonContextModel value)?  $default,){
final _that = this;
switch (_that) {
case _LessonContextModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String grade,  String subject,  AppLanguage language,  int classDurationMinutes,  StudentLevel studentLevel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonContextModel() when $default != null:
return $default(_that.grade,_that.subject,_that.language,_that.classDurationMinutes,_that.studentLevel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String grade,  String subject,  AppLanguage language,  int classDurationMinutes,  StudentLevel studentLevel)  $default,) {final _that = this;
switch (_that) {
case _LessonContextModel():
return $default(_that.grade,_that.subject,_that.language,_that.classDurationMinutes,_that.studentLevel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String grade,  String subject,  AppLanguage language,  int classDurationMinutes,  StudentLevel studentLevel)?  $default,) {final _that = this;
switch (_that) {
case _LessonContextModel() when $default != null:
return $default(_that.grade,_that.subject,_that.language,_that.classDurationMinutes,_that.studentLevel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LessonContextModel extends LessonContextModel {
  const _LessonContextModel({required this.grade, required this.subject, required this.language, this.classDurationMinutes = 35, this.studentLevel = StudentLevel.standard}): super._();
  factory _LessonContextModel.fromJson(Map<String, dynamic> json) => _$LessonContextModelFromJson(json);

@override final  String grade;
@override final  String subject;
@override final  AppLanguage language;
@override@JsonKey() final  int classDurationMinutes;
@override@JsonKey() final  StudentLevel studentLevel;

/// Create a copy of LessonContextModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonContextModelCopyWith<_LessonContextModel> get copyWith => __$LessonContextModelCopyWithImpl<_LessonContextModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LessonContextModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonContextModel&&(identical(other.grade, grade) || other.grade == grade)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.language, language) || other.language == language)&&(identical(other.classDurationMinutes, classDurationMinutes) || other.classDurationMinutes == classDurationMinutes)&&(identical(other.studentLevel, studentLevel) || other.studentLevel == studentLevel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,grade,subject,language,classDurationMinutes,studentLevel);

@override
String toString() {
  return 'LessonContextModel(grade: $grade, subject: $subject, language: $language, classDurationMinutes: $classDurationMinutes, studentLevel: $studentLevel)';
}


}

/// @nodoc
abstract mixin class _$LessonContextModelCopyWith<$Res> implements $LessonContextModelCopyWith<$Res> {
  factory _$LessonContextModelCopyWith(_LessonContextModel value, $Res Function(_LessonContextModel) _then) = __$LessonContextModelCopyWithImpl;
@override @useResult
$Res call({
 String grade, String subject, AppLanguage language, int classDurationMinutes, StudentLevel studentLevel
});




}
/// @nodoc
class __$LessonContextModelCopyWithImpl<$Res>
    implements _$LessonContextModelCopyWith<$Res> {
  __$LessonContextModelCopyWithImpl(this._self, this._then);

  final _LessonContextModel _self;
  final $Res Function(_LessonContextModel) _then;

/// Create a copy of LessonContextModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? grade = null,Object? subject = null,Object? language = null,Object? classDurationMinutes = null,Object? studentLevel = null,}) {
  return _then(_LessonContextModel(
grade: null == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as AppLanguage,classDurationMinutes: null == classDurationMinutes ? _self.classDurationMinutes : classDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,studentLevel: null == studentLevel ? _self.studentLevel : studentLevel // ignore: cast_nullable_to_non_nullable
as StudentLevel,
  ));
}


}

// dart format on
