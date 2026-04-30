// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'glossary_term.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GlossaryTerm {

 String get term; String get meaning; String? get example;
/// Create a copy of GlossaryTerm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GlossaryTermCopyWith<GlossaryTerm> get copyWith => _$GlossaryTermCopyWithImpl<GlossaryTerm>(this as GlossaryTerm, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GlossaryTerm&&(identical(other.term, term) || other.term == term)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.example, example) || other.example == example));
}


@override
int get hashCode => Object.hash(runtimeType,term,meaning,example);

@override
String toString() {
  return 'GlossaryTerm(term: $term, meaning: $meaning, example: $example)';
}


}

/// @nodoc
abstract mixin class $GlossaryTermCopyWith<$Res>  {
  factory $GlossaryTermCopyWith(GlossaryTerm value, $Res Function(GlossaryTerm) _then) = _$GlossaryTermCopyWithImpl;
@useResult
$Res call({
 String term, String meaning, String? example
});




}
/// @nodoc
class _$GlossaryTermCopyWithImpl<$Res>
    implements $GlossaryTermCopyWith<$Res> {
  _$GlossaryTermCopyWithImpl(this._self, this._then);

  final GlossaryTerm _self;
  final $Res Function(GlossaryTerm) _then;

/// Create a copy of GlossaryTerm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? term = null,Object? meaning = null,Object? example = freezed,}) {
  return _then(_self.copyWith(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,example: freezed == example ? _self.example : example // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GlossaryTerm].
extension GlossaryTermPatterns on GlossaryTerm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GlossaryTerm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GlossaryTerm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GlossaryTerm value)  $default,){
final _that = this;
switch (_that) {
case _GlossaryTerm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GlossaryTerm value)?  $default,){
final _that = this;
switch (_that) {
case _GlossaryTerm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String term,  String meaning,  String? example)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GlossaryTerm() when $default != null:
return $default(_that.term,_that.meaning,_that.example);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String term,  String meaning,  String? example)  $default,) {final _that = this;
switch (_that) {
case _GlossaryTerm():
return $default(_that.term,_that.meaning,_that.example);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String term,  String meaning,  String? example)?  $default,) {final _that = this;
switch (_that) {
case _GlossaryTerm() when $default != null:
return $default(_that.term,_that.meaning,_that.example);case _:
  return null;

}
}

}

/// @nodoc


class _GlossaryTerm implements GlossaryTerm {
  const _GlossaryTerm({required this.term, required this.meaning, this.example});
  

@override final  String term;
@override final  String meaning;
@override final  String? example;

/// Create a copy of GlossaryTerm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GlossaryTermCopyWith<_GlossaryTerm> get copyWith => __$GlossaryTermCopyWithImpl<_GlossaryTerm>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GlossaryTerm&&(identical(other.term, term) || other.term == term)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.example, example) || other.example == example));
}


@override
int get hashCode => Object.hash(runtimeType,term,meaning,example);

@override
String toString() {
  return 'GlossaryTerm(term: $term, meaning: $meaning, example: $example)';
}


}

/// @nodoc
abstract mixin class _$GlossaryTermCopyWith<$Res> implements $GlossaryTermCopyWith<$Res> {
  factory _$GlossaryTermCopyWith(_GlossaryTerm value, $Res Function(_GlossaryTerm) _then) = __$GlossaryTermCopyWithImpl;
@override @useResult
$Res call({
 String term, String meaning, String? example
});




}
/// @nodoc
class __$GlossaryTermCopyWithImpl<$Res>
    implements _$GlossaryTermCopyWith<$Res> {
  __$GlossaryTermCopyWithImpl(this._self, this._then);

  final _GlossaryTerm _self;
  final $Res Function(_GlossaryTerm) _then;

/// Create a copy of GlossaryTerm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? term = null,Object? meaning = null,Object? example = freezed,}) {
  return _then(_GlossaryTerm(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,example: freezed == example ? _self.example : example // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
