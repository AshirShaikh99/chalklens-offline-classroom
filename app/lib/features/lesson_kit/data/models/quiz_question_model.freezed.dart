// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quiz_question_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuizQuestionModel {

 String get question; String? get expectedAnswer;
/// Create a copy of QuizQuestionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuizQuestionModelCopyWith<QuizQuestionModel> get copyWith => _$QuizQuestionModelCopyWithImpl<QuizQuestionModel>(this as QuizQuestionModel, _$identity);

  /// Serializes this QuizQuestionModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuizQuestionModel&&(identical(other.question, question) || other.question == question)&&(identical(other.expectedAnswer, expectedAnswer) || other.expectedAnswer == expectedAnswer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,question,expectedAnswer);

@override
String toString() {
  return 'QuizQuestionModel(question: $question, expectedAnswer: $expectedAnswer)';
}


}

/// @nodoc
abstract mixin class $QuizQuestionModelCopyWith<$Res>  {
  factory $QuizQuestionModelCopyWith(QuizQuestionModel value, $Res Function(QuizQuestionModel) _then) = _$QuizQuestionModelCopyWithImpl;
@useResult
$Res call({
 String question, String? expectedAnswer
});




}
/// @nodoc
class _$QuizQuestionModelCopyWithImpl<$Res>
    implements $QuizQuestionModelCopyWith<$Res> {
  _$QuizQuestionModelCopyWithImpl(this._self, this._then);

  final QuizQuestionModel _self;
  final $Res Function(QuizQuestionModel) _then;

/// Create a copy of QuizQuestionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? question = null,Object? expectedAnswer = freezed,}) {
  return _then(_self.copyWith(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,expectedAnswer: freezed == expectedAnswer ? _self.expectedAnswer : expectedAnswer // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuizQuestionModel].
extension QuizQuestionModelPatterns on QuizQuestionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuizQuestionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuizQuestionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuizQuestionModel value)  $default,){
final _that = this;
switch (_that) {
case _QuizQuestionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuizQuestionModel value)?  $default,){
final _that = this;
switch (_that) {
case _QuizQuestionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String question,  String? expectedAnswer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuizQuestionModel() when $default != null:
return $default(_that.question,_that.expectedAnswer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String question,  String? expectedAnswer)  $default,) {final _that = this;
switch (_that) {
case _QuizQuestionModel():
return $default(_that.question,_that.expectedAnswer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String question,  String? expectedAnswer)?  $default,) {final _that = this;
switch (_that) {
case _QuizQuestionModel() when $default != null:
return $default(_that.question,_that.expectedAnswer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuizQuestionModel extends QuizQuestionModel {
  const _QuizQuestionModel({required this.question, this.expectedAnswer}): super._();
  factory _QuizQuestionModel.fromJson(Map<String, dynamic> json) => _$QuizQuestionModelFromJson(json);

@override final  String question;
@override final  String? expectedAnswer;

/// Create a copy of QuizQuestionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuizQuestionModelCopyWith<_QuizQuestionModel> get copyWith => __$QuizQuestionModelCopyWithImpl<_QuizQuestionModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuizQuestionModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuizQuestionModel&&(identical(other.question, question) || other.question == question)&&(identical(other.expectedAnswer, expectedAnswer) || other.expectedAnswer == expectedAnswer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,question,expectedAnswer);

@override
String toString() {
  return 'QuizQuestionModel(question: $question, expectedAnswer: $expectedAnswer)';
}


}

/// @nodoc
abstract mixin class _$QuizQuestionModelCopyWith<$Res> implements $QuizQuestionModelCopyWith<$Res> {
  factory _$QuizQuestionModelCopyWith(_QuizQuestionModel value, $Res Function(_QuizQuestionModel) _then) = __$QuizQuestionModelCopyWithImpl;
@override @useResult
$Res call({
 String question, String? expectedAnswer
});




}
/// @nodoc
class __$QuizQuestionModelCopyWithImpl<$Res>
    implements _$QuizQuestionModelCopyWith<$Res> {
  __$QuizQuestionModelCopyWithImpl(this._self, this._then);

  final _QuizQuestionModel _self;
  final $Res Function(_QuizQuestionModel) _then;

/// Create a copy of QuizQuestionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? question = null,Object? expectedAnswer = freezed,}) {
  return _then(_QuizQuestionModel(
question: null == question ? _self.question : question // ignore: cast_nullable_to_non_nullable
as String,expectedAnswer: freezed == expectedAnswer ? _self.expectedAnswer : expectedAnswer // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
