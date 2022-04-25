trigger SurveyResponseTrigger on qualtrics__Survey_Response__c(after insert) {
  for (qualtrics__Survey_Response__c sr : Trigger.new) {
    String surveyId = sr.qualtrics__Q_SurveyID__c;
    String responseId = sr.Response_ID__c;
    SurveyResponseTriggerHandler.processSurveyResponse(
      sr.Id,
      sr.qualtrics__Q_SurveyID__c,
      sr.Response_ID__c,
      sr.Email__c
    );
  }

}