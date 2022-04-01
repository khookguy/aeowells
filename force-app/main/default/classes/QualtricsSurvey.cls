public class QualtricsSurvey {
  public static String getAuthToken() {
    Http h = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:Qualtrics_Auth_Token');
    req.setMethod('POST');
    req.setBody('grant_type=client_credentials&scope=read:survey_responses');
    HttpResponse res = h.send(req);
    if (res.getStatusCode() != 200) {
      CalloutException e = new CalloutException();
      e.setMessage(
        'Error getting qualtrics auth token: ' +
        res.getStatusCode() +
        ' ' +
        res.getStatus()
      );
      throw e;
    }
    Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(
      res.getBody()
    );
    String accessToken = (String) jsonMap.get('access_token');
    return accessToken;
  }

  public static String getSurveyResponse(
    String authToken,
    String surveyId,
    String responseId
  ) {
    Http h = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(
      'https://sjc1.qualtrics.com/API/v3/surveys/' +
      surveyId +
      '/responses/' +
      responseId
    );
    req.setMethod('GET');
    req.setHeader('Accept', 'application/json');
    req.setHeader('Authorization', 'Bearer ' + authToken);
    HttpResponse res = h.send(req);
    if (res.getStatusCode() != 200) {
      CalloutException e = new CalloutException();
      e.setMessage(
        'Error getting qualtrics survey response: ' +
        res.getStatusCode() +
        ' ' +
        res.getStatus()
      );
      throw e;
    }
    return res.getBody();
  }
}