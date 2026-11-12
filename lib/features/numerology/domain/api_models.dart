import '../../../core/network/api_failure.dart';
import '../../profiles/domain/profile_validation.dart';

typedef Json = Map<String, dynamic>;
Never schemaError() => throw const ApiFailure(ApiFailureKind.malformed);
Json object(Object? value) =>
    value is Map<String, dynamic> ? value : schemaError();
String text(Object? value) =>
    value is String && value.isNotEmpty ? value : schemaError();
int integer(Object? value) => value is int ? value : schemaError();
int indexValue(Object? value) {
  final number = integer(value);
  return (number >= 1 && number <= 9) || const {11, 22, 33}.contains(number)
      ? number
      : schemaError();
}

int baseNumber(Object? value) {
  final number = integer(value);
  return number >= 1 && number <= 9 ? number : schemaError();
}

void validateNumberPair(int value, int baseValue) {
  const bases = {11: 2, 22: 4, 33: 6};
  if ((bases[value] ?? value) != baseValue) schemaError();
}

bool boolean(Object? value) => value is bool ? value : schemaError();
List<T> array<T>(Object? value, T Function(Object?) parse) =>
    value is List ? List<T>.unmodifiable(value.map(parse)) : schemaError();
String calendarDate(Object? value) {
  final date = text(value);
  return ProfileValidation.isCalendarDate(date) ? date : schemaError();
}

String localCalendarDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

enum IndexType {
  lifePath,
  expression,
  soulUrge,
  personality,
  birthday,
  attitude,
  maturity,
  personalYear,
  personalMonth,
}

IndexType indexType(Object? value) => IndexType.values.firstWhere(
  (type) => type.name == value,
  orElse: () => schemaError(),
);
String formatIndexValue(int value, int baseValue) =>
    const {11, 22, 33}.contains(value) ? '$value/$baseValue' : '$value';

/// Retains additive fields for lossless private cache round trips.
class ApiModel {
  ApiModel(Json json) : json = Map<String, dynamic>.unmodifiable(json);
  final Json json;
}

class CalculationStep extends ApiModel {
  CalculationStep.fromJson(Json j)
    : label = text(j['label']),
      operation = text(j['operation']),
      inputs = array(j['inputs'], integer),
      result = integer(j['result']),
      inputLabels =
          j['inputLabels'] == null ? null : array(j['inputLabels'], text),
      super(j);
  final String label;
  final String operation;
  final List<int> inputs;
  final int result;
  final List<String>? inputLabels;
}

class IndexResult extends ApiModel {
  IndexResult.fromJson(Json j)
    : type = indexType(j['type']),
      value = indexValue(j['value']),
      baseValue = baseNumber(j['baseValue']),
      steps = array(j['steps'], (v) => CalculationStep.fromJson(object(v))),
      referenceDate =
          j['referenceDate'] == null ? null : calendarDate(j['referenceDate']),
      super(j) {
    validateNumberPair(value, baseValue);
  }
  final IndexType type;
  final int value;
  final int baseValue;
  final List<CalculationStep> steps;
  final String? referenceDate;
}

class NameLetter extends ApiModel {
  NameLetter.fromJson(Json j)
    : letter = text(j['letter']),
      value = indexValue(j['value']),
      group = text(j['group']),
      super(j);
  final String letter;
  final int value;
  final String group;
}

class NameAnalysis extends ApiModel {
  NameAnalysis.fromJson(Json j)
    : normalizedName = text(j['normalizedName']),
      letters = array(j['letters'], (v) => NameLetter.fromJson(object(v))),
      nameTotal = integer(j['nameTotal']),
      vowelTotal = integer(j['vowelTotal']),
      consonantTotal = integer(j['consonantTotal']),
      super(j);
  final String normalizedName;
  final List<NameLetter> letters;
  final int nameTotal;
  final int vowelTotal;
  final int consonantTotal;
}

class InterpretationSummary extends ApiModel {
  InterpretationSummary.fromJson(Json j)
    : index = indexType(j['index']),
      value = indexValue(j['value']),
      baseValue = baseNumber(j['baseValue']),
      title = text(j['title']),
      subtitle = text(j['subtitle']),
      tagline = text(j['tagline']),
      summary = text(j['summary']),
      keywords = array(j['keywords'], text),
      super(j) {
    validateNumberPair(value, baseValue);
  }
  final IndexType index;
  final int value;
  final int baseValue;
  final String title;
  final String subtitle;
  final String tagline;
  final String summary;
  final List<String> keywords;
}

class InterpretationPoint extends ApiModel {
  InterpretationPoint.fromJson(Json j)
    : title = text(j['title']),
      description = text(j['description']),
      super(j);
  final String title;
  final String description;
}

class FullInterpretation extends ApiModel {
  FullInterpretation.fromJson(Json j)
    : index = indexType(j['index']),
      value = indexValue(j['value']),
      baseValue = baseNumber(j['baseValue']),
      title = text(j['title']),
      subtitle = text(j['subtitle']),
      tagline = text(j['tagline']),
      summary = text(j['summary']),
      essence = text(j['essence']),
      relationships = text(j['relationships']),
      careerAndGrowth = text(j['careerAndGrowth']),
      lifeLesson = text(j['lifeLesson']),
      reflection = text(j['reflection']),
      affirmation = text(j['affirmation']),
      suggestedAction = text(j['suggestedAction']),
      strengths = array(
        j['strengths'],
        (v) => InterpretationPoint.fromJson(object(v)),
      ),
      challenges = array(
        j['challenges'],
        (v) => InterpretationPoint.fromJson(object(v)),
      ),
      keywords = array(j['keywords'], text),
      periodFocus = j['periodFocus'] == null ? null : text(j['periodFocus']),
      super(j) {
    validateNumberPair(value, baseValue);
  }
  final IndexType index;
  final int value;
  final int baseValue;
  final String title;
  final String subtitle;
  final String tagline;
  final String summary;
  final String essence;
  final String relationships;
  final String careerAndGrowth;
  final String lifeLesson;
  final String reflection;
  final String affirmation;
  final String suggestedAction;
  final List<InterpretationPoint> strengths;
  final List<InterpretationPoint> challenges;
  final List<String> keywords;
  final String? periodFocus;
}

class ArticleResult extends ApiModel {
  ArticleResult.fromJson(Json j)
    : calculationVersion = text(j['calculationVersion']),
      contentVersion = text(j['contentVersion']),
      locale = text(j['locale']),
      interpretation = FullInterpretation.fromJson(object(j['interpretation'])),
      super(j);
  final String calculationVersion;
  final String contentVersion;
  final String locale;
  final FullInterpretation interpretation;
}

class BackendFeatures extends ApiModel {
  BackendFeatures.fromJson(Json j)
    : calculations = boolean(j['calculations']),
      interpretationSummaries = boolean(j['interpretationSummaries']),
      fullInterpretations = boolean(j['fullInterpretations']),
      definitions = boolean(j['definitions']),
      super(j);
  final bool calculations;
  final bool interpretationSummaries;
  final bool fullInterpretations;
  final bool definitions;
}

class BackendConfig extends ApiModel {
  BackendConfig.fromJson(Json j)
    : apiVersion = text(j['apiVersion']),
      calculationVersion = text(j['calculationVersion']),
      defaultLocale = text(j['defaultLocale']),
      supportedLocales = array(j['supportedLocales'], text),
      maxRequestBytes = integer(j['maxRequestBytes']),
      calculationAvailable = boolean(j['calculationAvailable']),
      features = BackendFeatures.fromJson(object(j['features'])),
      super(j);
  final String apiVersion;
  final String calculationVersion;
  final String defaultLocale;
  final List<String> supportedLocales;
  final int maxRequestBytes;
  final bool calculationAvailable;
  final BackendFeatures features;
}

class HealthResult extends ApiModel {
  HealthResult.fromJson(Json j)
    : status = text(j['status']),
      apiVersion = text(j['apiVersion']),
      super(j);
  final String status;
  final String apiVersion;
}

class IndexDefinition extends ApiModel {
  IndexDefinition.fromJson(Json j)
    : type = indexType(j['type']),
      title = text(j['title']),
      englishTitle = text(j['englishTitle']),
      description = text(j['description']),
      source = text(j['source']),
      displayOrder = integer(j['displayOrder']),
      supportsMasterNumbers = boolean(j['supportsMasterNumbers']),
      availableValues = array(j['availableValues'], integer),
      supportedValues = array(j['supportedValues'], integer),
      super(j);
  final IndexType type;
  final String title;
  final String englishTitle;
  final String description;
  final String source;
  final int displayOrder;
  final bool supportsMasterNumbers;
  final List<int> availableValues;
  final List<int> supportedValues;
}

class MissingContent extends ApiModel {
  MissingContent.fromJson(Json j)
    : index = indexType(j['index']),
      values = array(j['values'], integer),
      super(j);
  final IndexType index;
  final List<int> values;
}

class DefinitionsResult extends ApiModel {
  DefinitionsResult.fromJson(Json j)
    : calculationVersion = text(j['calculationVersion']),
      contentVersion = text(j['contentVersion']),
      locale = text(j['locale']),
      status = text(j['status']),
      plannedIndices = array(j['plannedIndices'], indexType),
      definitions = array(
        j['definitions'],
        (v) => IndexDefinition.fromJson(object(v)),
      ),
      missingContent = array(
        j['missingContent'],
        (v) => MissingContent.fromJson(object(v)),
      ),
      super(j);
  final String calculationVersion;
  final String contentVersion;
  final String locale;
  final String status;
  final List<IndexType> plannedIndices;
  final List<IndexDefinition> definitions;
  final List<MissingContent> missingContent;
}

class CalculationResult extends ApiModel {
  CalculationResult.fromJson(Json j)
    : calculationVersion = text(j['calculationVersion']),
      contentVersion = text(j['contentVersion']),
      locale = text(j['locale']),
      referenceDate = calendarDate(j['referenceDate']),
      name = NameAnalysis.fromJson(object(j['name'])),
      indices = Map.unmodifiable({
        for (final t in IndexType.values)
          t: IndexResult.fromJson(object(object(j['indices'])[t.name])),
      }),
      interpretations = Map.unmodifiable({
        for (final t in IndexType.values)
          t: InterpretationSummary.fromJson(
            object(object(j['interpretations'])[t.name]),
          ),
      }),
      super(j) {
    for (final t in IndexType.values) {
      final i = indices[t]!;
      final summary = interpretations[t]!;
      if (i.type != t ||
          summary.index != t ||
          summary.value != i.value ||
          summary.baseValue != i.baseValue ||
          (i.referenceDate != null && i.referenceDate != referenceDate))
        schemaError();
    }
  }
  final String calculationVersion, contentVersion, referenceDate, locale;
  final NameAnalysis name;
  final Map<IndexType, IndexResult> indices;
  final Map<IndexType, InterpretationSummary> interpretations;
}

/// Explicit date-only request; backend remains the sole calculation authority.
class CalculateRequest {
  CalculateRequest({
    required this.fullName,
    required this.birthDate,
    required this.referenceDate,
    this.locale = 'vi',
  }) {
    calendarDate(birthDate);
    calendarDate(referenceDate);
  }
  final String fullName, birthDate, referenceDate, locale;
  Json toJson() => {
    'fullName': fullName,
    'birthDate': birthDate,
    'referenceDate': referenceDate,
    'locale': locale,
  };
}
