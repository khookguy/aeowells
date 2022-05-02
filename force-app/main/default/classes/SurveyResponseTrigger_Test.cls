@isTest
public with sharing class SurveyResponseTrigger_Test {
  private static final String BHA_SURVEY_RESPONSE_ID = 'R_264EqlGMmYU3s6R';
  private static final String BHA_SURVEY_ID = SurveyResponseTriggerHandler.BHA_SURVEY_ID_WELLS;
  private static final String POST_COACHING_SURVEY_ID = SurveyResponseTriggerHandler.POST_COACHING_SURVEY_ID_WELLS;
  private static final String ENTREPRENEUR_FIRST_NAME = 'Sam';
  private static final String ENTREPRENEUR_LAST_NAME = 'Waterstone';
  private static final String ENTREPRENEUR_EMAIL = 'sam.waterstone@privateidaho.com';
  private static final String ENTREPRENEUR_BIZ_NAME = 'Private Idaho';
  private static final String PROGRAM_NAME = 'Spudzone';
  private static final String COHORT_NAME = 'Fry Distribution';
  private static final String COHORT_MEMBER1_EMAIL = 'cohort1@frydistribution.com';
  private static final String COHORT_MEMBER2_EMAIL = 'cohort2@frydistribution.com';


    /**
     * @description create records used in tests
     */
  @testSetup static void setup() {
    Contact entrepreneur = new Contact(
      FirstName = ENTREPRENEUR_FIRST_NAME,
      LastName = ENTREPRENEUR_LAST_NAME,
      Email = ENTREPRENEUR_EMAIL
    );
    Account cohort = new Account(Name = COHORT_NAME);
    Program__c program = new Program__c(
      Name = PROGRAM_NAME,
      BHA_Survey_ID__c = BHA_SURVEY_ID,
      Post_Coaching_Survey_ID__c = POST_COACHING_SURVEY_ID
    );
    insert entrepreneur;
    insert cohort;
    insert program;
    Contact presistedEntrepreneur = [
      SELECT Id
      FROM Contact
      WHERE Email = :ENTREPRENEUR_EMAIL
      LIMIT 1
    ];
    Account persistedCohort = [
      SELECT Id
      FROM Account
      WHERE Name = :COHORT_NAME
      LIMIT 1
    ];
    Program__c persistedProgram = [
      SELECT Id
      FROM Program__c
      WHERE Name = :PROGRAM_NAME
      LIMIT 1
    ];
    Program_Membership__c prgMembership = new Program_Membership__c();
    prgMembership.Individual__c = presistedEntrepreneur.Id;
    prgMembership.Cohort__c = persistedCohort.Id;
    prgMembership.Program__c = persistedProgram.Id;
    insert prgMembership;
    Contact cohortMember1 = new Contact(
      FirstName = 'Memby1',
      LastName = 'Ofcohort',
      Email = COHORT_MEMBER1_EMAIL,
      AccountId = persistedCohort.Id
    );
    Contact cohortMember2 = new Contact(
      FirstName = 'Memby2',
      LastName = 'Ofcohort',
      Email = COHORT_MEMBER2_EMAIL,
      AccountId = persistedCohort.Id
    );
    insert cohortMember1;
    insert cohortMember2;
  }


  @isTest
  static void surveyTrigger_bha_wells_pass_test() {
    Test.setMock(
      HttpCalloutMock.class,
      new QualtricsMock.GetSurveyResponseMockPass()
    );

    // set status as resili account created
    Program_Membership__c setupProgMemb = [SELECT Id FROM Program_Membership__c WHERE Member_Email__c = :ENTREPRENEUR_EMAIL LIMIT 1];
    setupProgMemb.Member_Status__c = Notification.NEW_RESILI_ACCOUNT_CREATED;
    update setupProgMemb;

    // create a survey response
    qualtrics__Survey_Response__c surveyResponse = new qualtrics__Survey_Response__c();
    surveyResponse.Response_ID__c = BHA_SURVEY_RESPONSE_ID;
    surveyResponse.qualtrics__Q_SurveyID__c = BHA_SURVEY_ID;
    surveyResponse.Email__c = ENTREPRENEUR_EMAIL;

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
        Response_ID__c = :BHA_SURVEY_RESPONSE_ID
        AND qualtrics__Q_SurveyID__c = :BHA_SURVEY_ID
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
    System.assertEquals(Notification.BHA_COMPLETED, programMembership.Member_Status__c);
    Integer emailSends = Limits.getEmailInvocations();
  }

  @isTest
  static void getSurveyResponse_bha_wells_fail_test() {
    Test.setMock(
      HttpCalloutMock.class,
      new QualtricsMock.GetSurveyResponseMockFail()
    );

    // create a survey response
    qualtrics__Survey_Response__c surveyResponse = new qualtrics__Survey_Response__c();
    surveyResponse.Response_ID__c = BHA_SURVEY_RESPONSE_ID;
    surveyResponse.qualtrics__Q_SurveyID__c = BHA_SURVEY_ID;
    surveyResponse.Email__c = ENTREPRENEUR_EMAIL;

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
        Response_ID__c = :BHA_SURVEY_RESPONSE_ID
        AND qualtrics__Q_SurveyID__c = :BHA_SURVEY_ID
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


    // set status as bha completed
    Program_Membership__c setupProgMemb = [SELECT Id FROM Program_Membership__c WHERE Member_Email__c = :ENTREPRENEUR_EMAIL LIMIT 1];
    setupProgMemb.Member_Status__c = Notification.BHA_COMPLETED;
    update setupProgMemb;

    // create a survey response
    qualtrics__Survey_Response__c surveyResponse = new qualtrics__Survey_Response__c();
    surveyResponse.Response_ID__c = BHA_SURVEY_RESPONSE_ID;
    surveyResponse.qualtrics__Q_SurveyID__c = POST_COACHING_SURVEY_ID;
    surveyResponse.Email__c = ENTREPRENEUR_EMAIL;

    Test.startTest();
    insert surveyResponse;
    Test.stopTest();
    qualtrics__Survey_Response__c sr = [
      SELECT Id, Response_ID__c, qualtrics__Q_SurveyID__c
      FROM qualtrics__Survey_Response__c
      WHERE
        Response_ID__c = :BHA_SURVEY_RESPONSE_ID
        AND qualtrics__Q_SurveyID__c = :POST_COACHING_SURVEY_ID
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