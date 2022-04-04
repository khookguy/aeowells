public class SurveyResponseParser {
  public static String generateBHAPayload(String fullSurveyResponse) {
    Map<String, Object> fsr = (Map<String, Object>) JSON.deserializeUntyped(
      fullSurveyResponse
    );
    Map<String, Object> result = (Map<String, Object>) fsr.get('result');
    String responseId = (String) result.get('responseId');
    Map<String, Object> values = (Map<String, Object>) result.get('values');
    String completionDate = (String) values.get('endDate');
    String surveyId = (String) values.get('SurveyID');
    List<String> availableCourseGroups = new List<String>{
      'Introduction to Customer Acquisition',
      'Introduction to Customer Relationships',
      'Introduction to Finances',
      'Advanced Finances',
      'Introduction to Business Software',
      'Introduction to Human Resources',
      'Industry Focused',
      'Introduction to eCommerce',
      'Introduction to Legal Essentials',
      'Advanced Marketing Strategy',
      'Introduction to Operations',
      'Introduction to Partnerships',
      'Introduction to Payment Processing',
      'Business Health Homework',
      'Introduction to Supplier Inclusion',
      'Introduction to Transition Planning',
      'Introduction to Web Tools'
    };
    List<String> courseGroupList = new List<String>();
    for (String course_group : availableCourseGroups) {
      String course_group_description = (String) values.get(course_group);
      if (String.isNotBlank(course_group_description)) {
        courseGroupList.add(course_group);
      }
    }
    Map<String, Object> bha = new Map<String, Object>();
    bha.put('completion_date', completionDate);
    bha.put('survey_id', surveyId);
    bha.put('response_id', responseId);
    Map<String, Object> payload = new Map<String, Object>();
    payload.put('business_health_assessment', bha);
    payload.put('course_groups', courseGroupList);
    String payloadString = JSON.serialize(payload);
    return payloadString;

    // return '{"business_health_assessment":{"completion_date":"20220331","survey_id":"survey_id","response_id":"response_id"}, "course_groups":["group1","group2"]}';
  }
}
