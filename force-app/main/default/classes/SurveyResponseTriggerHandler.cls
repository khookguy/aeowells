public class SurveyResponseTriggerHandler {
  public static String BHA_SURVEY_ID_WELLS = 'SV_3q0Wqi06cXPQdE2';
  public static String POST_COACHING_SURVEY_ID_WELLS = 'SV_7Uw61uxmEjT8mkC';
  public static String SURVEY_TYPE_BHA = 'BHA';
  public static String SURVEY_TYPE_POST_COACHING = 'Post-Coaching';

  public static void processSurveyResponse(
    Id srId,
    String surveyId,
    String responseId,
    String email
  ) {
    if (surveyId == BHA_SURVEY_ID_WELLS) {
      processBHASurveyResponse(srId, surveyId, responseId, email);
    }
    if (surveyId == POST_COACHING_SURVEY_ID_WELLS) {
      processPostCoachingSurveyResponse(srId, surveyId, responseId, email);
    }
  }

  @future(callout=true)
  /**
   * @description Call the Qualtrics API to get the full survery response as JSON and store it in the Survey Response
   * object. Update the program member status to 'BHA Completed'. Activate RESILI using details from the survey
   * respsonse. Notify the cohort members via email.
   *
   * The Qualtrics and RESILI callouts are bundled together in this one method because they both need to complete
   * before the DML to save the survey response can be executed.
   *
   * @param srId        The Salesforce ID of the Survey Response object where the response JSON will be stored
   * @param  surveyId   The Qualtrics survey ID for the survey corresponding to the response being requested
   * @param  responseId The Qualtrics ID of the survey response being requested
   * @param  email      The email of the user who took the survey and should be activated in RESILI
   */
  public static void processBHASurveyResponse(
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

    // get the program membership record and notify the cohort
    Program_Membership__c programMembership = getProgramMembershipFromSurveyResponse(
      surveyId,
      email,
      SURVEY_TYPE_BHA
    );
    Notification.notifyCohortMembers(
      programMembership,
      Notification.BHA_COMPLETED
    );

    /*
     * The DML operations.  These needs to happen after the callouts to Qualtrics and RESILI have completed.
     * See: https://help.salesforce.com/s/articleView?id=000326129&type=1
     */

    /*
     * Save the JSON response object retrieved from Qualtrics in the Survey Response.
     */
    qualtrics__Survey_Response__c srUpdate = new qualtrics__Survey_Response__c(
      id = srId
    );
    srUpdate.Full_Survey_Response__c = surveyResponse;
    update srUpdate;

    /*
     * Save the survey response ID to the Program Membership
     */
    programMembership.BHA_Survey_Response_ID__c = responseId;
    programMembership.Member_Status__c = 'BHA Completed';
    update programMembership;
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

  /**
   * @description Update the program member status to 'Post-Coaching Survey Completed'. Notify the cohort
   * members via email.
   *
   * @param srId        The Salesforce ID of the Survey Response object where the response JSON will be stored
   * @param  surveyId   The Qualtrics survey ID for the survey corresponding to the response being requested
   * @param  responseId The Qualtrics ID of the survey response being requested
   * @param  email      The email of the user who took the survey and should be activated in RESILI
   */
  public static void processPostCoachingSurveyResponse(
    Id srId,
    String surveyId,
    String responseId,
    String email
  ) {
    // get the program membership record and notify the cohort
    Program_Membership__c programMembership = getProgramMembershipFromSurveyResponse(
      surveyId,
      email,
      SURVEY_TYPE_POST_COACHING
    );
    Notification.notifyCohortMembers(
      programMembership,
      Notification.POST_COACHING_COMPLETED
    );
    programMembership.Post_Coaching_Survey_Response_ID__c = responseId;
    programMembership.Member_Status__c = 'Post-Coaching Survey Completed';
    update programMembership;
  }

  /**
   * @description Get the program membership object instance for the user who completed the survey. The survey ID
   * should correspond uniquely to a program.  Since the entrepreneur belongs to only one cohort per program, we can
   * also uniquely identify the cohort and retrieve the program membership object.
   *
   * @param  surveyId the Id of the survey completed
   * @param  email    the email of the entrepreneur taking the survey
   * @param  surveyType the type of survey for the response
   * @return          the program membership object for the entrepreneur taking the survey
   */
  public static Program_Membership__c getProgramMembershipFromSurveyResponse(
    String surveyId,
    String email,
    String surveyType
  ) {
    List<Program__c> programList = null;
    if (surveyType == SURVEY_TYPE_BHA) {
      programList = [
        SELECT Id, Name
        FROM Program__c
        WHERE BHA_Survey_ID__c = :surveyId
        LIMIT 1
      ];
    } else if (surveyType == SURVEY_TYPE_POST_COACHING) {
      programList = [
        SELECT Id, Name
        FROM Program__c
        WHERE Post_Coaching_Survey_ID__c = :surveyId
        LIMIT 1
      ];
    }
    Program__c program = null;
    if (programList.size() > 0) {
      program = programList[0];
    }
    List<Contact> contactList = [
      SELECT Id, Email
      FROM Contact
      WHERE Email = :email
      LIMIT 1
    ];
    Contact contact = null;
    if (contactList.size() > 0) {
      contact = contactList[0];
    }
    List<Program_Membership__c> programMembershipList = [
      SELECT
        Id,
        Program__c,
        Cohort__c,
        Individual__c,
        BHA_Survey_ID__c,
        BHA_Survey_Response_ID__c,
        Post_Coaching_Survey_ID__c,
        Post_Coaching_Survey_Response_ID__c
      FROM Program_Membership__c
      WHERE Program__c = :program.Id AND Individual__c = :contact.Id
      LIMIT 1
    ];
    Program_Membership__c programMembership = null;
    if (programMembershipList.size() > 0) {
      programMembership = programMembershipList[0];
    }
    return programMembership;
  }
}
