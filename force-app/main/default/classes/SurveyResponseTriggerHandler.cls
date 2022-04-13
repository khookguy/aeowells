public class SurveyResponseTriggerHandler {
  @future(callout=true)
  /**
   * @description Call the Qualtrics API to get the full survery response as JSON and store it in the Survey Response
   * object. Activate RESILI using details from the survey respsonse.
   * 
   * The Qualtrics and RESILI callouts are bundled together in this one method because they both need to complete 
   * before the DML to save the survey response can be saved.
   * 
   * @param srId        The Salesforce ID of the Survey Response object where the response JSON will be stored
   * @param  surveyId   The Qualtrics survey ID for the survey corresponding to the response being requested
   * @param  responseId The Qualtrics ID of the survey response being requested
   * @param  email      The email of the user who took the survey and should be activated in RESILI
   */
  public static void getFullSurveyResponseFromQualtricsAndActivateResili(
    Id srId,
    String surveyId,
    String responseId,
    String email
  ) {
    String surveyResponse = SurveyResponseTriggerHandler.getFullSurveyResponseFromQualtrics(
      surveyId,
      responseId
    );
    String bhaPayload = SurveyResponseParser.generateBHAPayload(surveyResponse);
    Resili.activate(email, bhaPayload);
    /*
     * Save the JSON response object retrieved from Qualtrics in the Survey Response. The DML operation needs to
     * happen after the callouts to Qualtrics and RESILI have completed.
     * See: https://help.salesforce.com/s/articleView?id=000326129&type=1
     */
    qualtrics__Survey_Response__c srUpdate = new qualtrics__Survey_Response__c(
      id = srId
    );
    srUpdate.Full_Survey_Response__c = surveyResponse;
    update srUpdate;
  }

  /**
   * @description Callout to Qualtrics API to get the full survey response as JSON.
   * @param  surveyId   The Qualtrics survey ID for the survey corresponding to the response being requested
   * @param  responseId The Qualtrics ID of the survey response being requested
   * @return            The survey response as JSON string or null if not returned from Qualtrics
   */
  public static String getFullSurveyResponseFromQualtrics(
    String surveyId,
    String responseId
  ) {
    String authToken = QualtricsSurvey.getAuthToken();
    String surveyResponse = QualtricsSurvey.getSurveyResponse(
      authToken,
      surveyId,
      responseId
    );
    return surveyResponse;
  }
}