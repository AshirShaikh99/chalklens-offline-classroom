// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'glossary_term_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GlossaryTermModel {

 String get term; String get meaning; String? get example;
/// Create a copy of GlossaryTermModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GlossaryTermModelCopyWith<GlossaryTermModel> get copyWith => _$GlossaryTermModelCopyWithImpl<GlossaryTermModel>(this as GlossaryTermModel, _$identity);

  /// Serializes this GlossaryTermModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GlossaryTermModel&&(identical(other.term, term) || other.term == term)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.example, example) || other.example == example));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,term,meaning,example);

@override
String toString() {
  return 'GlossaryTermModel(term: $term, meaning: $meaning, example: $example)';
}


}

/// @nodoc
abstract mixin class $GlossaryTermModelCopyWith<$Res>  {
  factory $GlossaryTermModelCopyWith(GlossaryTermModel value, $Res Function(GlossaryTermModel) _then) = _$GlossaryTermModelCopyWithImpl;
@useResult
$Res call({
 String term, String meaning, String? example
});




}
/// @nodoc
class _$GlossaryTermModelCopyWithImpl<$Res>
    implements $GlossaryTermModelCopyWith<$Res> {
  _$GlossaryTermModelCopyWithImpl(this._self, this._then);

  final GlossaryTermModel _self;
  final $Res Function(GlossaryTermModel) _then;

/// Create a copy of GlossaryTermModel
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


/// Adds pattern-matching-related methods to [GlossaryTermModel].
extension GlossaryTermModelPatterns on GlossaryTermModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GlossaryTermModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GlossaryTermModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GlossaryTermModel value)  $default,){
final _that = this;
switch (_that) {
case _GlossaryTermModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GlossaryTermModel value)?  $default,){
final _that = this;
switch (_that) {
case _GlossaryTermModel() when $default != null:
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
case _GlossaryTermModel() when $default != null:
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
case _GlossaryTermModel():
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
case _GlossaryTermModel() when $default != null:
return $default(_that.term,_that.meaning,_that.example);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GlossaryTermModel extends GlossaryTermModel {
  const _GlossaryTermModel({required this.term, required this.meaning, this.example}): super._();
  factory _GlossaryTermModel.fromJson(Map<String, dynamic> json) => _$GlossaryTermModelFromJson(json);

@override final  String term;
@override final  String meaning;
@override final  String? example;

/// Create a copy of GlossaryTermModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GlossaryTermModelCopyWith<_GlossaryTermModel> get copyWith => __$GlossaryTermModelCopyWithImpl<_GlossaryTermModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GlossaryTermModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GlossaryTermModel&&(identical(other.term, term) || other.term == term)&&(identical(other.meaning, meaning) || other.meaning == meaning)&&(identical(other.example, example) || other.example == example));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,term,meaning,example);

@override
String toString() {
  return 'GlossaryTermModel(term: $term, meaning: $meaning, example: $example)';
}


}

/// @nodoc
abstract mixin class _$GlossaryTermModelCopyWith<$Res> implements $GlossaryTermModelCopyWith<$Res> {
  factory _$GlossaryTermModelCopyWith(_GlossaryTermModel value, $Res Function(_GlossaryTermModel) _then) = __$GlossaryTermModelCopyWithImpl;
@override @useResult
$Res call({
 String term, String meaning, String? example
});




}
/// @nodoc
class __$GlossaryTermModelCopyWithImpl<$Res>
    implements _$GlossaryTermModelCopyWith<$Res> {
  __$GlossaryTermModelCopyWithImpl(this._self, this._then);

  final _GlossaryTermModel _self;
  final $Res Function(_GlossaryTermModel) _then;

/// Create a copy of GlossaryTermModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? term = null,Object? meaning = null,Object? example = freezed,}) {
  return _then(_GlossaryTermModel(
term: null == term ? _self.term : term // ignore: cast_nullable_to_non_nullable
as String,meaning: null == meaning ? _self.meaning : meaning // ignore: cast_nullable_to_non_nullable
as String,example: freezed == example ? _self.example : example // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
