@isTest
public class SurveyResponseTriggerHandler_Test {
  @isTest
  static void generateBHAPayload_test() {
    StaticResource fsrResource = [
      SELECT Id, Body
      FROM StaticResource
      WHERE Name = 'SurveyFullResponse_WellsFargo'
      LIMIT 1
    ];
    String fullResponseTestData = fsrResource.Body.toString();
    String bhaPayload = SurveyResponseTriggerHandler.generateBHAPayload(
      fullResponseTestData
    );
    System.assertNotEquals(
      null,
      fullResponseTestData,
      'Full Response JSON should not be null'
    );
    System.assertNotEquals(null, bhaPayload, 'BHA payload should not be null');
  }
}