// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'explanation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Explanation _$ExplanationFromJson(Map<String, dynamic> json) => _Explanation(
  sessionIndex: (json['sessionIndex'] as num).toInt(),
  text: json['text'] as String,
);

Map<String, dynamic> _$ExplanationToJson(_Explanation instance) =>
    <String, dynamic>{
      'sessionIndex': instance.sessionIndex,
      'text': instance.text,
    };
