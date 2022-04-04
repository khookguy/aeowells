@isTest
public class SurveyResponseParser_Test {
  
  @isTest
  static void generateBHAPayload_test() {
    StaticResource fsrResource = [
      SELECT Id, Body
      FROM StaticResource
      WHERE Name = 'SurveyFullResponse_WellsFargo'
      LIMIT 1
    ];
    String fullResponseTestData = fsrResource.Body.toString();
    String bhaPayload = SurveyResponseParser.generateBHAPayload(
      fullResponseTestData
    );
    System.assertNotEquals(
      null,
      fullResponseTestData,
      'Full Response JSON test data from the static resource should not be null'
    );
    System.assert(String.isNotBlank(bhaPayload), 'The returned BHA payload should not be empty');
    Map<String,Object> bhaPayloadMap = (Map<String,Object>) JSON.deserializeUntyped(bhaPayload);
    Object bhaObj = bhaPayloadMap.get('business_health_assessment');
    System.assertNotEquals(null, bhaObj, 'business_health_assessment data should not be null');
    Map<String,Object> bhaStats = (Map<String,Object>) bhaObj;
    String completionDate = (String) bhaStats.get('completion_date');
    System.assertEquals('2022-03-30T15:57:36Z', completionDate, 'completion_date should match test data');
    String surveyId = (String) bhaStats.get('survey_id');
    System.assertEquals('SV_3q0Wqi06cXPQdE2', surveyId, 'survey_id should match test data');
    String responseId = (String) bhaStats.get('response_id');
    System.assertEquals('R_21hprVOMTDs0PpV', responseId, 'response_id should match test data');
    List<Object> courseGroupList = (List<Object>) bhaPayloadMap.get('course_groups');
    System.assertNotEquals(null, courseGroupList, 'course_group data should not be null');
    System.assertEquals(12, courseGroupList.size(), 'course_group should have 12 course groups as in the test data');
    System.assert(courseGroupList.contains('Introduction to Business Software'), 'course_group should contain Introduction to Business Software');
    System.assert(courseGroupList.contains('Advanced Marketing Strategy'), 'course_group should contain Advanced Marketing Strategy');
    
  }
}