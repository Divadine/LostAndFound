class DynamicFieldsModel {
  final int id;
  final String displayName;
  final DynamicFieldType   fieldType;
  final String dropdownMaster;
  final bool isRequired;
  final int? fieldLength;
  final String fieldValidation;

  DynamicFieldsModel({required this.id, required this.displayName, required this.fieldType, required this.dropdownMaster, required this.isRequired, this.fieldLength, this.fieldValidation = '',});

  @override
  String toString() {
    return 'DynamicFieldsModel('
        'id: $id, '
        'displayName: $displayName, '
        'fieldType: $fieldType, '
        'dropdownMaster: $dropdownMaster, '
        'isRequired: $isRequired'
        ')';
  }
  factory DynamicFieldsModel.fromJson(Map<String,dynamic> json) {
    return DynamicFieldsModel(
        id: json['id'],
        displayName: json['display_name'],
        fieldType: _parseFieldType(json['field_type']),
        dropdownMaster: json['dropdown_master'] ?? '',
        isRequired: json['is_required'] == 1 || json['is_required'] == true || json['is_required'] == '1',
        fieldLength: int.tryParse('${json['field_length'] ?? ''}'),
        fieldValidation: (json['field_validation'] ?? '').toString().toLowerCase().trim(),
    );
  }

}

enum DynamicFieldType { dropdown, text, textarea, unknown }

DynamicFieldType _parseFieldType(String? raw) {
  switch (raw) {
    case 'dropdown':
      return DynamicFieldType.dropdown;
    case 'text':
      return DynamicFieldType.text;
    case 'textarea':
      return DynamicFieldType.textarea;
    default:
      return DynamicFieldType.unknown;
  }


}