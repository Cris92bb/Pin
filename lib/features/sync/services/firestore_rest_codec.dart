/// Bi-directional codec for translating standard Dart maps to/from
/// Google Cloud Firestore REST API document representations.
class FirestoreRestCodec {
  /// Encodes a standard Dart Map of field values into Firestore REST `fields` format:
  /// `{ "field_name": { "stringValue": "..." } }`
  static Map<String, dynamic> encodeFields(Map<String, dynamic> dartMap) {
    final Map<String, dynamic> fields = {};
    for (final entry in dartMap.entries) {
      final val = entry.value;
      if (val == null) {
        fields[entry.key] = {'nullValue': null};
      } else {
        fields[entry.key] = encodeValue(val);
      }
    }
    return fields;
  }

  /// Encodes an individual Dart value into a Firestore typed value map.
  static Map<String, dynamic> encodeValue(dynamic value) {
    if (value == null) {
      return {'nullValue': null};
    } else if (value is bool) {
      return {'booleanValue': value};
    } else if (value is int) {
      return {'integerValue': value.toString()};
    } else if (value is double) {
      return {'doubleValue': value};
    } else if (value is String) {
      return {'stringValue': value};
    } else if (value is DateTime) {
      return {'timestampValue': value.toUtc().toIso8601String()};
    } else if (value is List) {
      final values = value.map((item) => encodeValue(item)).toList();
      return {
        'arrayValue': values.isEmpty ? {} : {'values': values},
      };
    } else if (value is Map<String, dynamic>) {
      return {
        'mapValue': {
          'fields': encodeFields(value),
        },
      };
    } else if (value is Map) {
      return {
        'mapValue': {
          'fields': encodeFields(Map<String, dynamic>.from(value)),
        },
      };
    } else {
      return {'stringValue': value.toString()};
    }
  }

  /// Decodes Firestore REST `fields` map into a standard Dart Map.
  static Map<String, dynamic> decodeFields(Map<String, dynamic> firestoreFields) {
    final Map<String, dynamic> result = {};
    for (final entry in firestoreFields.entries) {
      if (entry.value is Map<String, dynamic>) {
        result[entry.key] = decodeValue(entry.value as Map<String, dynamic>);
      } else if (entry.value is Map) {
        result[entry.key] = decodeValue(Map<String, dynamic>.from(entry.value as Map));
      }
    }
    return result;
  }

  /// Decodes a Firestore typed value map back into a native Dart primitive/collection.
  static dynamic decodeValue(Map<String, dynamic> valueMap) {
    if (valueMap.containsKey('nullValue')) {
      return null;
    } else if (valueMap.containsKey('stringValue')) {
      return valueMap['stringValue'];
    } else if (valueMap.containsKey('booleanValue')) {
      return valueMap['booleanValue'] as bool;
    } else if (valueMap.containsKey('integerValue')) {
      final str = valueMap['integerValue'] as String;
      return int.tryParse(str) ?? 0;
    } else if (valueMap.containsKey('doubleValue')) {
      final val = valueMap['doubleValue'];
      return val is num ? val.toDouble() : 0.0;
    } else if (valueMap.containsKey('timestampValue')) {
      return DateTime.tryParse(valueMap['timestampValue'] as String);
    } else if (valueMap.containsKey('arrayValue')) {
      final arr = valueMap['arrayValue'];
      if (arr is Map && arr.containsKey('values')) {
        final list = arr['values'] as List<dynamic>;
        return list
            .map((item) => decodeValue(item is Map<String, dynamic>
                ? item
                : Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return [];
    } else if (valueMap.containsKey('mapValue')) {
      final map = valueMap['mapValue'];
      if (map is Map && map.containsKey('fields')) {
        return decodeFields(Map<String, dynamic>.from(map['fields'] as Map));
      }
      return <String, dynamic>{};
    }
    return null;
  }
}
