// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_lesson.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SavedLesson {

 String get id; LessonKit get kit; LessonContext get context; DateTime get savedAt; String? get sourceImagePath;
/// Create a copy of SavedLesson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SavedLessonCopyWith<SavedLesson> get copyWith => _$SavedLessonCopyWithImpl<SavedLesson>(this as SavedLesson, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SavedLesson&&(identical(other.id, id) || other.id == id)&&(identical(other.kit, kit) || other.kit == kit)&&(identical(other.context, context) || other.context == context)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.sourceImagePath, sourceImagePath) || other.sourceImagePath == sourceImagePath));
}


@override
int get hashCode => Object.hash(runtimeType,id,kit,context,savedAt,sourceImagePath);

@override
String toString() {
  return 'SavedLesson(id: $id, kit: $kit, context: $context, savedAt: $savedAt, sourceImagePath: $sourceImagePath)';
}


}

/// @nodoc
abstract mixin class $SavedLessonCopyWith<$Res>  {
  factory $SavedLessonCopyWith(SavedLesson value, $Res Function(SavedLesson) _then) = _$SavedLessonCopyWithImpl;
@useResult
$Res call({
 String id, LessonKit kit, LessonContext context, DateTime savedAt, String? sourceImagePath
});


$LessonKitCopyWith<$Res> get kit;$LessonContextCopyWith<$Res> get context;

}
/// @nodoc
class _$SavedLessonCopyWithImpl<$Res>
    implements $SavedLessonCopyWith<$Res> {
  _$SavedLessonCopyWithImpl(this._self, this._then);

  final SavedLesson _self;
  final $Res Function(SavedLesson) _then;

/// Create a copy of SavedLesson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kit = null,Object? context = null,Object? savedAt = null,Object? sourceImagePath = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kit: null == kit ? _self.kit : kit // ignore: cast_nullable_to_non_nullable
as LessonKit,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as LessonContext,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sourceImagePath: freezed == sourceImagePath ? _self.sourceImagePath : sourceImagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SavedLesson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonKitCopyWith<$Res> get kit {
  
  return $LessonKitCopyWith<$Res>(_self.kit, (value) {
    return _then(_self.copyWith(kit: value));
  });
}/// Create a copy of SavedLesson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonContextCopyWith<$Res> get context {
  
  return $LessonContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}


/// Adds pattern-matching-related methods to [SavedLesson].
extension SavedLessonPatterns on SavedLesson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SavedLesson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SavedLesson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SavedLesson value)  $default,){
final _that = this;
switch (_that) {
case _SavedLesson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SavedLesson value)?  $default,){
final _that = this;
switch (_that) {
case _SavedLesson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  LessonKit kit,  LessonContext context,  DateTime savedAt,  String? sourceImagePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SavedLesson() when $default != null:
return $default(_that.id,_that.kit,_that.context,_that.savedAt,_that.sourceImagePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  LessonKit kit,  LessonContext context,  DateTime savedAt,  String? sourceImagePath)  $default,) {final _that = this;
switch (_that) {
case _SavedLesson():
return $default(_that.id,_that.kit,_that.context,_that.savedAt,_that.sourceImagePath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  LessonKit kit,  LessonContext context,  DateTime savedAt,  String? sourceImagePath)?  $default,) {final _that = this;
switch (_that) {
case _SavedLesson() when $default != null:
return $default(_that.id,_that.kit,_that.context,_that.savedAt,_that.sourceImagePath);case _:
  return null;

}
}

}

/// @nodoc


class _SavedLesson implements SavedLesson {
  const _SavedLesson({required this.id, required this.kit, required this.context, required this.savedAt, this.sourceImagePath});
  

@override final  String id;
@override final  LessonKit kit;
@override final  LessonContext context;
@override final  DateTime savedAt;
@override final  String? sourceImagePath;

/// Create a copy of SavedLesson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SavedLessonCopyWith<_SavedLesson> get copyWith => __$SavedLessonCopyWithImpl<_SavedLesson>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SavedLesson&&(identical(other.id, id) || other.id == id)&&(identical(other.kit, kit) || other.kit == kit)&&(identical(other.context, context) || other.context == context)&&(identical(other.savedAt, savedAt) || other.savedAt == savedAt)&&(identical(other.sourceImagePath, sourceImagePath) || other.sourceImagePath == sourceImagePath));
}


@override
int get hashCode => Object.hash(runtimeType,id,kit,context,savedAt,sourceImagePath);

@override
String toString() {
  return 'SavedLesson(id: $id, kit: $kit, context: $context, savedAt: $savedAt, sourceImagePath: $sourceImagePath)';
}


}

/// @nodoc
abstract mixin class _$SavedLessonCopyWith<$Res> implements $SavedLessonCopyWith<$Res> {
  factory _$SavedLessonCopyWith(_SavedLesson value, $Res Function(_SavedLesson) _then) = __$SavedLessonCopyWithImpl;
@override @useResult
$Res call({
 String id, LessonKit kit, LessonContext context, DateTime savedAt, String? sourceImagePath
});


@override $LessonKitCopyWith<$Res> get kit;@override $LessonContextCopyWith<$Res> get context;

}
/// @nodoc
class __$SavedLessonCopyWithImpl<$Res>
    implements _$SavedLessonCopyWith<$Res> {
  __$SavedLessonCopyWithImpl(this._self, this._then);

  final _SavedLesson _self;
  final $Res Function(_SavedLesson) _then;

/// Create a copy of SavedLesson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kit = null,Object? context = null,Object? savedAt = null,Object? sourceImagePath = freezed,}) {
  return _then(_SavedLesson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kit: null == kit ? _self.kit : kit // ignore: cast_nullable_to_non_nullable
as LessonKit,context: null == context ? _self.context : context // ignore: cast_nullable_to_non_nullable
as LessonContext,savedAt: null == savedAt ? _self.savedAt : savedAt // ignore: cast_nullable_to_non_nullable
as DateTime,sourceImagePath: freezed == sourceImagePath ? _self.sourceImagePath : sourceImagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SavedLesson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonKitCopyWith<$Res> get kit {
  
  return $LessonKitCopyWith<$Res>(_self.kit, (value) {
    return _then(_self.copyWith(kit: value));
  });
}/// Create a copy of SavedLesson
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LessonContextCopyWith<$Res> get context {
  
  return $LessonContextCopyWith<$Res>(_self.context, (value) {
    return _then(_self.copyWith(context: value));
  });
}
}

// dart format on
