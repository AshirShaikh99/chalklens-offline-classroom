// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lesson_kit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LessonKit {

 String get lessonTitle; String get grade; String get subject; AppLanguage get language; List<String> get sourceConcepts; List<String> get likelyMisconceptions; List<String> get teacherMoves; List<String> get checksForUnderstanding; List<String> get learningObjectives; String get simpleExplanation; List<String> get blackboardNotes; String get localExample; List<QuizQuestion> get oralQuiz; String get groupActivity; List<String> get homework; List<GlossaryTerm> get glossary; String get easyVersion; double get confidence;
/// Create a copy of LessonKit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LessonKitCopyWith<LessonKit> get copyWith => _$LessonKitCopyWithImpl<LessonKit>(this as LessonKit, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LessonKit&&(identical(other.lessonTitle, lessonTitle) || other.lessonTitle == lessonTitle)&&(identical(other.grade, grade) || other.grade == grade)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other.sourceConcepts, sourceConcepts)&&const DeepCollectionEquality().equals(other.likelyMisconceptions, likelyMisconceptions)&&const DeepCollectionEquality().equals(other.teacherMoves, teacherMoves)&&const DeepCollectionEquality().equals(other.checksForUnderstanding, checksForUnderstanding)&&const DeepCollectionEquality().equals(other.learningObjectives, learningObjectives)&&(identical(other.simpleExplanation, simpleExplanation) || other.simpleExplanation == simpleExplanation)&&const DeepCollectionEquality().equals(other.blackboardNotes, blackboardNotes)&&(identical(other.localExample, localExample) || other.localExample == localExample)&&const DeepCollectionEquality().equals(other.oralQuiz, oralQuiz)&&(identical(other.groupActivity, groupActivity) || other.groupActivity == groupActivity)&&const DeepCollectionEquality().equals(other.homework, homework)&&const DeepCollectionEquality().equals(other.glossary, glossary)&&(identical(other.easyVersion, easyVersion) || other.easyVersion == easyVersion)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,lessonTitle,grade,subject,language,const DeepCollectionEquality().hash(sourceConcepts),const DeepCollectionEquality().hash(likelyMisconceptions),const DeepCollectionEquality().hash(teacherMoves),const DeepCollectionEquality().hash(checksForUnderstanding),const DeepCollectionEquality().hash(learningObjectives),simpleExplanation,const DeepCollectionEquality().hash(blackboardNotes),localExample,const DeepCollectionEquality().hash(oralQuiz),groupActivity,const DeepCollectionEquality().hash(homework),const DeepCollectionEquality().hash(glossary),easyVersion,confidence);

@override
String toString() {
  return 'LessonKit(lessonTitle: $lessonTitle, grade: $grade, subject: $subject, language: $language, sourceConcepts: $sourceConcepts, likelyMisconceptions: $likelyMisconceptions, teacherMoves: $teacherMoves, checksForUnderstanding: $checksForUnderstanding, learningObjectives: $learningObjectives, simpleExplanation: $simpleExplanation, blackboardNotes: $blackboardNotes, localExample: $localExample, oralQuiz: $oralQuiz, groupActivity: $groupActivity, homework: $homework, glossary: $glossary, easyVersion: $easyVersion, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $LessonKitCopyWith<$Res>  {
  factory $LessonKitCopyWith(LessonKit value, $Res Function(LessonKit) _then) = _$LessonKitCopyWithImpl;
@useResult
$Res call({
 String lessonTitle, String grade, String subject, AppLanguage language, List<String> sourceConcepts, List<String> likelyMisconceptions, List<String> teacherMoves, List<String> checksForUnderstanding, List<String> learningObjectives, String simpleExplanation, List<String> blackboardNotes, String localExample, List<QuizQuestion> oralQuiz, String groupActivity, List<String> homework, List<GlossaryTerm> glossary, String easyVersion, double confidence
});




}
/// @nodoc
class _$LessonKitCopyWithImpl<$Res>
    implements $LessonKitCopyWith<$Res> {
  _$LessonKitCopyWithImpl(this._self, this._then);

  final LessonKit _self;
  final $Res Function(LessonKit) _then;

/// Create a copy of LessonKit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lessonTitle = null,Object? grade = null,Object? subject = null,Object? language = null,Object? sourceConcepts = null,Object? likelyMisconceptions = null,Object? teacherMoves = null,Object? checksForUnderstanding = null,Object? learningObjectives = null,Object? simpleExplanation = null,Object? blackboardNotes = null,Object? localExample = null,Object? oralQuiz = null,Object? groupActivity = null,Object? homework = null,Object? glossary = null,Object? easyVersion = null,Object? confidence = null,}) {
  return _then(_self.copyWith(
lessonTitle: null == lessonTitle ? _self.lessonTitle : lessonTitle // ignore: cast_nullable_to_non_nullable
as String,grade: null == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as AppLanguage,sourceConcepts: null == sourceConcepts ? _self.sourceConcepts : sourceConcepts // ignore: cast_nullable_to_non_nullable
as List<String>,likelyMisconceptions: null == likelyMisconceptions ? _self.likelyMisconceptions : likelyMisconceptions // ignore: cast_nullable_to_non_nullable
as List<String>,teacherMoves: null == teacherMoves ? _self.teacherMoves : teacherMoves // ignore: cast_nullable_to_non_nullable
as List<String>,checksForUnderstanding: null == checksForUnderstanding ? _self.checksForUnderstanding : checksForUnderstanding // ignore: cast_nullable_to_non_nullable
as List<String>,learningObjectives: null == learningObjectives ? _self.learningObjectives : learningObjectives // ignore: cast_nullable_to_non_nullable
as List<String>,simpleExplanation: null == simpleExplanation ? _self.simpleExplanation : simpleExplanation // ignore: cast_nullable_to_non_nullable
as String,blackboardNotes: null == blackboardNotes ? _self.blackboardNotes : blackboardNotes // ignore: cast_nullable_to_non_nullable
as List<String>,localExample: null == localExample ? _self.localExample : localExample // ignore: cast_nullable_to_non_nullable
as String,oralQuiz: null == oralQuiz ? _self.oralQuiz : oralQuiz // ignore: cast_nullable_to_non_nullable
as List<QuizQuestion>,groupActivity: null == groupActivity ? _self.groupActivity : groupActivity // ignore: cast_nullable_to_non_nullable
as String,homework: null == homework ? _self.homework : homework // ignore: cast_nullable_to_non_nullable
as List<String>,glossary: null == glossary ? _self.glossary : glossary // ignore: cast_nullable_to_non_nullable
as List<GlossaryTerm>,easyVersion: null == easyVersion ? _self.easyVersion : easyVersion // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [LessonKit].
extension LessonKitPatterns on LessonKit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LessonKit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LessonKit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LessonKit value)  $default,){
final _that = this;
switch (_that) {
case _LessonKit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LessonKit value)?  $default,){
final _that = this;
switch (_that) {
case _LessonKit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String lessonTitle,  String grade,  String subject,  AppLanguage language,  List<String> sourceConcepts,  List<String> likelyMisconceptions,  List<String> teacherMoves,  List<String> checksForUnderstanding,  List<String> learningObjectives,  String simpleExplanation,  List<String> blackboardNotes,  String localExample,  List<QuizQuestion> oralQuiz,  String groupActivity,  List<String> homework,  List<GlossaryTerm> glossary,  String easyVersion,  double confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LessonKit() when $default != null:
return $default(_that.lessonTitle,_that.grade,_that.subject,_that.language,_that.sourceConcepts,_that.likelyMisconceptions,_that.teacherMoves,_that.checksForUnderstanding,_that.learningObjectives,_that.simpleExplanation,_that.blackboardNotes,_that.localExample,_that.oralQuiz,_that.groupActivity,_that.homework,_that.glossary,_that.easyVersion,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String lessonTitle,  String grade,  String subject,  AppLanguage language,  List<String> sourceConcepts,  List<String> likelyMisconceptions,  List<String> teacherMoves,  List<String> checksForUnderstanding,  List<String> learningObjectives,  String simpleExplanation,  List<String> blackboardNotes,  String localExample,  List<QuizQuestion> oralQuiz,  String groupActivity,  List<String> homework,  List<GlossaryTerm> glossary,  String easyVersion,  double confidence)  $default,) {final _that = this;
switch (_that) {
case _LessonKit():
return $default(_that.lessonTitle,_that.grade,_that.subject,_that.language,_that.sourceConcepts,_that.likelyMisconceptions,_that.teacherMoves,_that.checksForUnderstanding,_that.learningObjectives,_that.simpleExplanation,_that.blackboardNotes,_that.localExample,_that.oralQuiz,_that.groupActivity,_that.homework,_that.glossary,_that.easyVersion,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String lessonTitle,  String grade,  String subject,  AppLanguage language,  List<String> sourceConcepts,  List<String> likelyMisconceptions,  List<String> teacherMoves,  List<String> checksForUnderstanding,  List<String> learningObjectives,  String simpleExplanation,  List<String> blackboardNotes,  String localExample,  List<QuizQuestion> oralQuiz,  String groupActivity,  List<String> homework,  List<GlossaryTerm> glossary,  String easyVersion,  double confidence)?  $default,) {final _that = this;
switch (_that) {
case _LessonKit() when $default != null:
return $default(_that.lessonTitle,_that.grade,_that.subject,_that.language,_that.sourceConcepts,_that.likelyMisconceptions,_that.teacherMoves,_that.checksForUnderstanding,_that.learningObjectives,_that.simpleExplanation,_that.blackboardNotes,_that.localExample,_that.oralQuiz,_that.groupActivity,_that.homework,_that.glossary,_that.easyVersion,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc


class _LessonKit implements LessonKit {
  const _LessonKit({required this.lessonTitle, required this.grade, required this.subject, required this.language, final  List<String> sourceConcepts = const <String>[], final  List<String> likelyMisconceptions = const <String>[], final  List<String> teacherMoves = const <String>[], final  List<String> checksForUnderstanding = const <String>[], final  List<String> learningObjectives = const <String>[], required this.simpleExplanation, final  List<String> blackboardNotes = const <String>[], this.localExample = '', final  List<QuizQuestion> oralQuiz = const <QuizQuestion>[], this.groupActivity = '', final  List<String> homework = const <String>[], final  List<GlossaryTerm> glossary = const <GlossaryTerm>[], this.easyVersion = '', this.confidence = 0.0}): _sourceConcepts = sourceConcepts,_likelyMisconceptions = likelyMisconceptions,_teacherMoves = teacherMoves,_checksForUnderstanding = checksForUnderstanding,_learningObjectives = learningObjectives,_blackboardNotes = blackboardNotes,_oralQuiz = oralQuiz,_homework = homework,_glossary = glossary;
  

@override final  String lessonTitle;
@override final  String grade;
@override final  String subject;
@override final  AppLanguage language;
 final  List<String> _sourceConcepts;
@override@JsonKey() List<String> get sourceConcepts {
  if (_sourceConcepts is EqualUnmodifiableListView) return _sourceConcepts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sourceConcepts);
}

 final  List<String> _likelyMisconceptions;
@override@JsonKey() List<String> get likelyMisconceptions {
  if (_likelyMisconceptions is EqualUnmodifiableListView) return _likelyMisconceptions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_likelyMisconceptions);
}

 final  List<String> _teacherMoves;
@override@JsonKey() List<String> get teacherMoves {
  if (_teacherMoves is EqualUnmodifiableListView) return _teacherMoves;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_teacherMoves);
}

 final  List<String> _checksForUnderstanding;
@override@JsonKey() List<String> get checksForUnderstanding {
  if (_checksForUnderstanding is EqualUnmodifiableListView) return _checksForUnderstanding;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_checksForUnderstanding);
}

 final  List<String> _learningObjectives;
@override@JsonKey() List<String> get learningObjectives {
  if (_learningObjectives is EqualUnmodifiableListView) return _learningObjectives;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_learningObjectives);
}

@override final  String simpleExplanation;
 final  List<String> _blackboardNotes;
@override@JsonKey() List<String> get blackboardNotes {
  if (_blackboardNotes is EqualUnmodifiableListView) return _blackboardNotes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_blackboardNotes);
}

@override@JsonKey() final  String localExample;
 final  List<QuizQuestion> _oralQuiz;
@override@JsonKey() List<QuizQuestion> get oralQuiz {
  if (_oralQuiz is EqualUnmodifiableListView) return _oralQuiz;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_oralQuiz);
}

@override@JsonKey() final  String groupActivity;
 final  List<String> _homework;
@override@JsonKey() List<String> get homework {
  if (_homework is EqualUnmodifiableListView) return _homework;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_homework);
}

 final  List<GlossaryTerm> _glossary;
@override@JsonKey() List<GlossaryTerm> get glossary {
  if (_glossary is EqualUnmodifiableListView) return _glossary;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_glossary);
}

@override@JsonKey() final  String easyVersion;
@override@JsonKey() final  double confidence;

/// Create a copy of LessonKit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LessonKitCopyWith<_LessonKit> get copyWith => __$LessonKitCopyWithImpl<_LessonKit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LessonKit&&(identical(other.lessonTitle, lessonTitle) || other.lessonTitle == lessonTitle)&&(identical(other.grade, grade) || other.grade == grade)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.language, language) || other.language == language)&&const DeepCollectionEquality().equals(other._sourceConcepts, _sourceConcepts)&&const DeepCollectionEquality().equals(other._likelyMisconceptions, _likelyMisconceptions)&&const DeepCollectionEquality().equals(other._teacherMoves, _teacherMoves)&&const DeepCollectionEquality().equals(other._checksForUnderstanding, _checksForUnderstanding)&&const DeepCollectionEquality().equals(other._learningObjectives, _learningObjectives)&&(identical(other.simpleExplanation, simpleExplanation) || other.simpleExplanation == simpleExplanation)&&const DeepCollectionEquality().equals(other._blackboardNotes, _blackboardNotes)&&(identical(other.localExample, localExample) || other.localExample == localExample)&&const DeepCollectionEquality().equals(other._oralQuiz, _oralQuiz)&&(identical(other.groupActivity, groupActivity) || other.groupActivity == groupActivity)&&const DeepCollectionEquality().equals(other._homework, _homework)&&const DeepCollectionEquality().equals(other._glossary, _glossary)&&(identical(other.easyVersion, easyVersion) || other.easyVersion == easyVersion)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,lessonTitle,grade,subject,language,const DeepCollectionEquality().hash(_sourceConcepts),const DeepCollectionEquality().hash(_likelyMisconceptions),const DeepCollectionEquality().hash(_teacherMoves),const DeepCollectionEquality().hash(_checksForUnderstanding),const DeepCollectionEquality().hash(_learningObjectives),simpleExplanation,const DeepCollectionEquality().hash(_blackboardNotes),localExample,const DeepCollectionEquality().hash(_oralQuiz),groupActivity,const DeepCollectionEquality().hash(_homework),const DeepCollectionEquality().hash(_glossary),easyVersion,confidence);

@override
String toString() {
  return 'LessonKit(lessonTitle: $lessonTitle, grade: $grade, subject: $subject, language: $language, sourceConcepts: $sourceConcepts, likelyMisconceptions: $likelyMisconceptions, teacherMoves: $teacherMoves, checksForUnderstanding: $checksForUnderstanding, learningObjectives: $learningObjectives, simpleExplanation: $simpleExplanation, blackboardNotes: $blackboardNotes, localExample: $localExample, oralQuiz: $oralQuiz, groupActivity: $groupActivity, homework: $homework, glossary: $glossary, easyVersion: $easyVersion, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$LessonKitCopyWith<$Res> implements $LessonKitCopyWith<$Res> {
  factory _$LessonKitCopyWith(_LessonKit value, $Res Function(_LessonKit) _then) = __$LessonKitCopyWithImpl;
@override @useResult
$Res call({
 String lessonTitle, String grade, String subject, AppLanguage language, List<String> sourceConcepts, List<String> likelyMisconceptions, List<String> teacherMoves, List<String> checksForUnderstanding, List<String> learningObjectives, String simpleExplanation, List<String> blackboardNotes, String localExample, List<QuizQuestion> oralQuiz, String groupActivity, List<String> homework, List<GlossaryTerm> glossary, String easyVersion, double confidence
});




}
/// @nodoc
class __$LessonKitCopyWithImpl<$Res>
    implements _$LessonKitCopyWith<$Res> {
  __$LessonKitCopyWithImpl(this._self, this._then);

  final _LessonKit _self;
  final $Res Function(_LessonKit) _then;

/// Create a copy of LessonKit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lessonTitle = null,Object? grade = null,Object? subject = null,Object? language = null,Object? sourceConcepts = null,Object? likelyMisconceptions = null,Object? teacherMoves = null,Object? checksForUnderstanding = null,Object? learningObjectives = null,Object? simpleExplanation = null,Object? blackboardNotes = null,Object? localExample = null,Object? oralQuiz = null,Object? groupActivity = null,Object? homework = null,Object? glossary = null,Object? easyVersion = null,Object? confidence = null,}) {
  return _then(_LessonKit(
lessonTitle: null == lessonTitle ? _self.lessonTitle : lessonTitle // ignore: cast_nullable_to_non_nullable
as String,grade: null == grade ? _self.grade : grade // ignore: cast_nullable_to_non_nullable
as String,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,language: null == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as AppLanguage,sourceConcepts: null == sourceConcepts ? _self._sourceConcepts : sourceConcepts // ignore: cast_nullable_to_non_nullable
as List<String>,likelyMisconceptions: null == likelyMisconceptions ? _self._likelyMisconceptions : likelyMisconceptions // ignore: cast_nullable_to_non_nullable
as List<String>,teacherMoves: null == teacherMoves ? _self._teacherMoves : teacherMoves // ignore: cast_nullable_to_non_nullable
as List<String>,checksForUnderstanding: null == checksForUnderstanding ? _self._checksForUnderstanding : checksForUnderstanding // ignore: cast_nullable_to_non_nullable
as List<String>,learningObjectives: null == learningObjectives ? _self._learningObjectives : learningObjectives // ignore: cast_nullable_to_non_nullable
as List<String>,simpleExplanation: null == simpleExplanation ? _self.simpleExplanation : simpleExplanation // ignore: cast_nullable_to_non_nullable
as String,blackboardNotes: null == blackboardNotes ? _self._blackboardNotes : blackboardNotes // ignore: cast_nullable_to_non_nullable
as List<String>,localExample: null == localExample ? _self.localExample : localExample // ignore: cast_nullable_to_non_nullable
as String,oralQuiz: null == oralQuiz ? _self._oralQuiz : oralQuiz // ignore: cast_nullable_to_non_nullable
as List<QuizQuestion>,groupActivity: null == groupActivity ? _self.groupActivity : groupActivity // ignore: cast_nullable_to_non_nullable
as String,homework: null == homework ? _self._homework : homework // ignore: cast_nullable_to_non_nullable
as List<String>,glossary: null == glossary ? _self._glossary : glossary // ignore: cast_nullable_to_non_nullable
as List<GlossaryTerm>,easyVersion: null == easyVersion ? _self.easyVersion : easyVersion // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
