trigger SurveyResponseTrigger on qualtrics__Survey_Response__c(after insert) {
  for (qualtrics__Survey_Response__c sr : Trigger.new) {
    String surveyId = sr.qualtrics__Q_SurveyID__c;
    String responseId = sr.Response_ID__c;
    SurveyResponseTriggerHandler.getFullSurveyResponse(
      sr.Id,
      surveyId,
      responseId
    );
    SurveyResponseTriggerHandler.activateResili(sr.Id, sr.Email__c);
  }

}