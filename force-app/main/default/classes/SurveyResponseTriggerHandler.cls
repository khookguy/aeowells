public class SurveyResponseTriggerHandler {
  @future(callout=true)
  public static void getFullSurveyResponse(
    Id srId,
    String surveyId,
    String responseId
  ) {
    String authToken = QualtricsSurvey.getAuthToken();
    String surveyResponse = QualtricsSurvey.getSurveyResponse(
      authToken,
      surveyId,
      responseId
    );
    qualtrics__Survey_Response__c srUpdate = new qualtrics__Survey_Response__c(
      id = srId
    );
    srUpdate.Full_Survey_Response__c = surveyResponse;
    update srUpdate;
  }

  @future(callout=true)
  public static void activateResili(Id srId, String email) {
    qualtrics__Survey_Response__c surveyResponse = [
      SELECT Id, Full_Survey_Response__c
      FROM qualtrics__Survey_Response__c
      WHERE Id = :srId
      LIMIT 1
    ];
    String bhaPayload = generateBHAPayload(
      surveyResponse.Full_Survey_Response__c
    );
    Resili.activate(email, bhaPayload);
  }

  public static String generateBHAPayload(String fullSurveyResponse) {
    return '{"business_health_assessment":{"completion_date":"20220331","survey_id":"survey_id","response_id":"response_id"}, "course_groups":["group1","group2"]}';
  }
}