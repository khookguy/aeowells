@isTest
private class SurveyResponseTrigger_Test {
  @isTest
  static void surveyTrigger_pass_test() {
    Test.setMock(
      HttpCalloutMock.class,
      new QualtricsMock.GetSurveyResponseMockPass()
    );
    qualtrics__Survey_Response__c surveyResponse = new qualtrics__Survey_Response__c();
    surveyResponse.Response_ID__c = 'R_264EqlGMmYU3s6R';
    surveyResponse.qualtrics__Q_SurveyID__c = 'SV_80xQ0CkJkWw6zHw';
    surveyResponse.Email__c = 'test@testing.com';
    Test.startTest();
    insert surveyResponse;
    Test.stopTest();
    qualtrics__Survey_Response__c sr = [
      SELECT
        Id,
        Response_ID__c,
        qualtrics__Q_SurveyID__c,
        Full_Survey_Response__c
      FROM qualtrics__Survey_Response__c
      WHERE
        Response_ID__c = 'R_264EqlGMmYU3s6R'
        AND qualtrics__Q_SurveyID__c = 'SV_80xQ0CkJkWw6zHw'
      LIMIT 1
    ];
    System.assertNotEquals(null, sr, 'Survey Response object was not found');
    System.assertNotEquals(
      null,
      sr.Full_Survey_Response__c,
      'Full survey response (JSON) has not been added to the record'
    );
    Map<String, Object> fullSurveyResponse = (Map<String, Object>) JSON.deserializeUntyped(
      sr.Full_Survey_Response__c
    );
    Map<String, Object> result = (Map<String, Object>) fullSurveyResponse.get(
      'result'
    );
    System.assertNotEquals(
      null,
      result,
      'Full survey result should not have a null result'
    );
    Map<String, Object> values = (Map<String, Object>) result.get('values');
    System.assertNotEquals(
      null,
      values,
      'Full survey values should not have a null result'
    );
    String aeo_user_id = (String) values.get('aeo_user_id');
    System.assertEquals(
      'ao9jurit8',
      aeo_user_id,
      'AEO User Id does not match embedded data from test object'
    );
  }

  @isTest
  static void getSurveyResponse_fail_test() {
    Test.setMock(
      HttpCalloutMock.class,
      new QualtricsMock.GetSurveyResponseMockFail()
    );
    qualtrics__Survey_Response__c surveyResponse = new qualtrics__Survey_Response__c();
    surveyResponse.Response_ID__c = 'R_264EqlGMmYU3s6R';
    surveyResponse.qualtrics__Q_SurveyID__c = 'SV_80xQ0CkJkWw6zHw';
    CalloutException ce = null;
    try {
      Test.startTest();
      insert surveyResponse;
      Test.stopTest();
    } catch (CalloutException e) {
      ce = e;
    }
    qualtrics__Survey_Response__c sr = [
      SELECT
        Id,
        Response_ID__c,
        qualtrics__Q_SurveyID__c,
        Full_Survey_Response__c
      FROM qualtrics__Survey_Response__c
      WHERE
        Response_ID__c = 'R_264EqlGMmYU3s6R'
        AND qualtrics__Q_SurveyID__c = 'SV_80xQ0CkJkWw6zHw'
      LIMIT 1
    ];
    System.assertNotEquals(null, sr, 'Survey Response object was not found');
    System.assertEquals(
      null,
      sr.Full_Survey_Response__c,
      'Full survey response (JSON) should not been added to the record'
    );
    System.assertNotEquals(null, ce, 'Exception should have been thrown.');
  }
}