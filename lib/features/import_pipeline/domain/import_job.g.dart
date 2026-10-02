// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SkippedStep _$SkippedStepFromJson(Map<String, dynamic> json) => _SkippedStep(
  reason: $enumDecode(_$SkipReasonEnumMap, json['reason']),
  failureCode: json['failureCode'] as String?,
);

Map<String, dynamic> _$SkippedStepToJson(_SkippedStep instance) =>
    <String, dynamic>{
      'reason': _$SkipReasonEnumMap[instance.reason]!,
      'failureCode': instance.failureCode,
    };

const _$SkipReasonEnumMap = {
  SkipReason.notApplicable: 'notApplicable',
  SkipReason.captionOnly: 'captionOnly',
  SkipReason.failed: 'failed',
  SkipReason.notAVideo: 'notAVideo',
  SkipReason.videoBlocked: 'videoBlocked',
  SkipReason.videoTooLong: 'videoTooLong',
  SkipReason.noAudio: 'noAudio',
  SkipReason.noModel: 'noModel',
  SkipReason.cpuUnsupported: 'cpuUnsupported',
  SkipReason.platformSubtitles: 'platformSubtitles',
};

_ImportJobData _$ImportJobDataFromJson(Map<String, dynamic> json) =>
    _ImportJobData(
      skippedSteps:
          (json['skippedSteps'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              $enumDecode(_$ImportStatusEnumMap, k),
              SkippedStep.fromJson(e as Map<String, dynamic>),
            ),
          ) ??
          const {},
      captionOnly: json['captionOnly'] as bool? ?? false,
      alreadyImported: json['alreadyImported'] as bool? ?? false,
      caption: json['caption'] as String?,
      authorName: json['authorName'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      videoUrl: json['videoUrl'] as String?,
      videoHeaders: (json['videoHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      videoDurationSeconds: (json['videoDurationSeconds'] as num?)?.toDouble(),
      videoPath: json['videoPath'] as String?,
      subtitlesPath: json['subtitlesPath'] as String?,
      audioPath: json['audioPath'] as String?,
      transcript: json['transcript'] as String?,
      transcriptQuality: $enumDecodeNullable(
        _$TranscriptQualityEnumMap,
        json['transcriptQuality'],
      ),
      transcriptSource: $enumDecodeNullable(
        _$TranscriptSourceEnumMap,
        json['transcriptSource'],
      ),
      extraction: json['extraction'] as Map<String, dynamic>?,
      extractionModel: json['extractionModel'] as String?,
    );

Map<String, dynamic> _$ImportJobDataToJson(
  _ImportJobData instance,
) => <String, dynamic>{
  'skippedSteps': instance.skippedSteps.map(
    (k, e) => MapEntry(_$ImportStatusEnumMap[k]!, e.toJson()),
  ),
  'captionOnly': instance.captionOnly,
  'alreadyImported': instance.alreadyImported,
  'caption': instance.caption,
  'authorName': instance.authorName,
  'thumbnailUrl': instance.thumbnailUrl,
  'thumbnailPath': instance.thumbnailPath,
  'videoUrl': instance.videoUrl,
  'videoHeaders': instance.videoHeaders,
  'videoDurationSeconds': instance.videoDurationSeconds,
  'videoPath': instance.videoPath,
  'subtitlesPath': instance.subtitlesPath,
  'audioPath': instance.audioPath,
  'transcript': instance.transcript,
  'transcriptQuality': _$TranscriptQualityEnumMap[instance.transcriptQuality],
  'transcriptSource': _$TranscriptSourceEnumMap[instance.transcriptSource],
  'extraction': instance.extraction,
  'extractionModel': instance.extractionModel,
};

const _$ImportStatusEnumMap = {
  ImportStatus.received: 'received',
  ImportStatus.normalized: 'normalized',
  ImportStatus.metadata: 'metadata',
  ImportStatus.media: 'media',
  ImportStatus.audio: 'audio',
  ImportStatus.transcribed: 'transcribed',
  ImportStatus.extracted: 'extracted',
  ImportStatus.nutrition: 'nutrition',
  ImportStatus.completed: 'completed',
  ImportStatus.failed: 'failed',
};

const _$TranscriptQualityEnumMap = {
  TranscriptQuality.ok: 'ok',
  TranscriptQuality.low: 'low',
  TranscriptQuality.empty: 'empty',
  TranscriptQuality.none: 'none',
};

const _$TranscriptSourceEnumMap = {
  TranscriptSource.platformSubtitles: 'platformSubtitles',
  TranscriptSource.whisper: 'whisper',
};
