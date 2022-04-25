@isTest
private class SurveyResponseTrigger_Test {
  @isTest
  static void surveyTrigger_bha_wells_pass_test() {
    Test.setMock(
      HttpCalloutMock.class,
      new QualtricsMock.GetSurveyResponseMockPass()
    );
    qualtrics__Survey_Response__c surveyResponse = new qualtrics__Survey_Response__c();
    surveyResponse.Response_ID__c = 'R_264EqlGMmYU3s6R';
    surveyResponse.qualtrics__Q_SurveyID__c = SurveyResponseTriggerHandler.BHA_SURVEY_ID_WELLS;
    surveyResponse.Email__c = 'test@testing.com';
    Contact contact = new Contact(
      FirstName = 'Tester',
      LastName = 'Testing',
      Email = 'test@testing.com'
    );
    Account cohort = new Account(Name = 'Test Cohort');
    Program__c program = new Program__c(
      Name = 'Test Program',
      BHA_Survey_ID__c = SurveyResponseTriggerHandler.BHA_SURVEY_ID_WELLS,
      Post_Coaching_Survey_ID__c = SurveyResponseTriggerHandler.POST_COACHING_SURVEY_ID_WELLS
    );
    insert contact;
    insert cohort;
    insert program;
    Contact persistedContact = [
      SELECT Id
      FROM Contact
      WHERE Email = :contact.Email
      LIMIT 1
    ];
    Account persistedCohort = [
      SELECT Id
      FROM Account
      WHERE Name = :cohort.Name
      LIMIT 1
    ];
    Program__c persistedProgram = [
      SELECT Id
      FROM Program__c
      WHERE Name = :program.Name
      LIMIT 1
    ];
    Program_Membership__c prgMembership = new Program_Membership__c();
    prgMembership.Individual__c = persistedContact.Id;
    prgMembership.Cohort__c = persistedCohort.Id;
    prgMembership.Program__c = persistedProgram.Id;
    insert prgMembership;
    Contact cohortMember = new Contact(
      FirstName = 'Memby',
      LastName = 'Ofcohort',
      Email = 'memby@cohorticus.com',
      AccountId = persistedCohort.Id
    );
    insert cohortMember;

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
        AND qualtrics__Q_SurveyID__c = :SurveyResponseTriggerHandler.BHA_SURVEY_ID_WELLS
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
    Program_Membership__c programMembership = SurveyResponseTriggerHandler.getProgramMembershipFromSurveyResponse(
      surveyResponse.qualtrics__Q_SurveyID__c,
      surveyResponse.Email__c,
      SurveyResponseTriggerHandler.SURVEY_TYPE_BHA
    );
    System.assertNotEquals(
      null,
      programMembership.BHA_Survey_Response_ID__c,
      'BHA survey response ID was not added to program membership object instance'
    );
    System.assertEquals(
      surveyResponse.Response_ID__c,
      programMembership.BHA_Survey_Response_ID__c,
      'Wrong BHA survey response ID added to program membership object instance'
    );
    System.assertNotEquals(
      null,
      programMembership.BHA_Survey_ID__c,
      'BHA survey ID was not added to program membership object instance'
    );
    System.assertEquals(
      surveyResponse.qualtrics__Q_SurveyID__c,
      programMembership.BHA_Survey_ID__c,
      'Wrong BHA survey ID added to program membership object instance'
    );
  }

  @isTest
  static void getSurveyResponse_bha_wells_fail_test() {
    Test.setMock(
      HttpCalloutMock.class,
      new QualtricsMock.GetSurveyResponseMockFail()
    );
    qualtrics__Survey_Response__c surveyResponse = new qualtrics__Survey_Response__c();
    surveyResponse.Response_ID__c = 'R_264EqlGMmYU3s6R';
    surveyResponse.qualtrics__Q_SurveyID__c = SurveyResponseTriggerHandler.BHA_SURVEY_ID_WELLS;
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
        AND qualtrics__Q_SurveyID__c = :SurveyResponseTriggerHandler.BHA_SURVEY_ID_WELLS
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

  @isTest
  static void surveyTrigger_post_coaching_wells_pass_test() {
    Test.setMock(
      HttpCalloutMock.class,
      new QualtricsMock.GetSurveyResponseMockPass()
    );
    qualtrics__Survey_Response__c surveyResponse = new qualtrics__Survey_Response__c();
    surveyResponse.Response_ID__c = 'R_264EqlGMmYU3s6R';
    surveyResponse.qualtrics__Q_SurveyID__c = SurveyResponseTriggerHandler.POST_COACHING_SURVEY_ID_WELLS;
    surveyResponse.Email__c = 'test@testing.com';
    Contact contact = new Contact(
      FirstName = 'Tester',
      LastName = 'Testing',
      Email = 'test@testing.com'
    );
    Account cohort = new Account(Name = 'Test Cohort');
    Program__c program = new Program__c(
      Name = 'Test Program',
      BHA_Survey_ID__c = SurveyResponseTriggerHandler.BHA_SURVEY_ID_WELLS,
      Post_Coaching_Survey_ID__c = SurveyResponseTriggerHandler.POST_COACHING_SURVEY_ID_WELLS
    );
    insert contact;
    insert cohort;
    insert program;
    Contact persistedContact = [
      SELECT Id
      FROM Contact
      WHERE Email = :contact.Email
      LIMIT 1
    ];
    Account persistedCohort = [
      SELECT Id
      FROM Account
      WHERE Name = :cohort.Name
      LIMIT 1
    ];
    Program__c persistedProgram = [
      SELECT Id
      FROM Program__c
      WHERE Name = :program.Name
      LIMIT 1
    ];
    Program_Membership__c prgMembership = new Program_Membership__c();
    prgMembership.Individual__c = persistedContact.Id;
    prgMembership.Cohort__c = persistedCohort.Id;
    prgMembership.Program__c = persistedProgram.Id;
    insert prgMembership;
    Contact cohortMember = new Contact(
      FirstName = 'Memby',
      LastName = 'Ofcohort',
      Email = 'memby@cohorticus.com',
      AccountId = persistedCohort.Id
    );
    insert cohortMember;

    Test.startTest();
    insert surveyResponse;
    Test.stopTest();
    qualtrics__Survey_Response__c sr = [
      SELECT Id, Response_ID__c, qualtrics__Q_SurveyID__c
      FROM qualtrics__Survey_Response__c
      WHERE
        Response_ID__c = 'R_264EqlGMmYU3s6R'
        AND qualtrics__Q_SurveyID__c = :SurveyResponseTriggerHandler.POST_COACHING_SURVEY_ID_WELLS
      LIMIT 1
    ];
    System.assertNotEquals(null, sr, 'Survey Response object was not found');
    Program_Membership__c programMembership = SurveyResponseTriggerHandler.getProgramMembershipFromSurveyResponse(
      surveyResponse.qualtrics__Q_SurveyID__c,
      surveyResponse.Email__c,
      SurveyResponseTriggerHandler.SURVEY_TYPE_POST_COACHING
    );
    System.assertNotEquals(
      null,
      programMembership.Post_Coaching_Survey_Response_ID__c,
      'Post-Coaching survey response ID was not added to program membership object instance'
    );
    System.assertEquals(
      surveyResponse.Response_ID__c,
      programMembership.Post_Coaching_Survey_Response_ID__c,
      'Wrong post-coaching survey response ID added to program membership object instance'
    );
    System.assertNotEquals(
      null,
      programMembership.Post_Coaching_Survey_ID__c,
      'Post-Coaching Survey ID was not added to program membership object instance'
    );
    System.assertEquals(
      surveyResponse.qualtrics__Q_SurveyID__c,
      programMembership.Post_Coaching_Survey_ID__c,
      'Wrong post-coaching survey ID added to program membership object instance'
    );
  }
}
