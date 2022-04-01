@isTest
public with sharing class QualtricsMock {
  public class GetSurveyResponseMockPass implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      String responseJson;
      String endpoint = req.getEndpoint();
      if (endpoint.contains('callout:Qualtrics_Auth_Token')) {
        responseJson = '{"access_token":"cf92f4be-755f-4239-b034-d0faceb64877","token_type":"Bearer","expires_in":3599,"scope":"read:survey_responses"}';
      } else if (
        endpoint.contains('surveys') && endpoint.contains('responses')
      ) {
        responseJson = '{"result":{"responseId":"R_264EqlGMmYU3s6R","values":{"startDate":"2022-03-22T17:16:05Z","endDate":"2022-03-22T17:16:29Z","status":0,"ipAddress":"72.69.36.227","progress":100,"duration":23,"finished":1,"recordedDate":"2022-03-22T17:16:29.752Z","locationLatitude":"40.9942932129","locationLongitude":"-73.7974014282","distributionChannel":"anonymous","userLanguage":"EN","QID2_TEXT":"Yolanda Hair Styling","QID3":2,"QID3_DO":["1","2","3","4"],"QID1":1,"QID1_DO":["1","2","3"],"course_plan":"marketing201","aeo_user_id":"ao9jurit8","aeo_cohort_id":"ko878ad"},"labels":{"status":"IP Address","finished":"True","QID3":"$10,001 - $250,000","QID3_DO":["Less than $10,000","$10,001 - $250,000","$250,001 - $1 million","More than $1 million"],"QID1":"Vanilla","QID1_DO":["Vanilla","Chocolate","Other"]},"displayedFields":["QID1","QID3","QID2_TEXT"],"displayedValues":{"QID1":[1,2,3],"QID3":[1,2,3,4]}},"meta":{"requestId":"9e49b542-f8d4-42b9-97c9-87f3cb69859d","httpStatus":"200 - OK"}}';
      } else if (endpoint.contains('resili') && endpoint.contains('activate')) {
        responseJson = '';
      } else {
        CalloutException e = new CalloutException();
        e.setMessage('Cannot process endpoint: ' + endpoint);
        throw e;
      }
      HTTPResponse res = new HTTPResponse();
      res.setHeader('Content-Type', 'text/json');
      res.setBody(responseJson);
      res.setStatusCode(200);
      return res;
    }
  }

  public class GetSurveyResponseMockFail implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      String responseJson;
      String endpoint = req.getEndpoint();
      HTTPResponse res = new HTTPResponse();
      res.setHeader('Content-Type', 'text/json');
      if (endpoint.contains('callout:Qualtrics_Auth_Token')) {
        responseJson = '{"access_token":"cf92f4be-755f-4239-b034-d0faceb64877","token_type":"Bearer","expires_in":3599,"scope":"read:survey_responses"}';
        res.setBody(responseJson);
        res.setStatusCode(200);
      } else if (
        endpoint.contains('surveys') && endpoint.contains('responses')
      ) {
        res.setBody('{}');
        res.setStatusCode(500);
      } else {
        CalloutException e = new CalloutException();
        e.setMessage('Cannot process endpoint: ' + endpoint);
        throw e;
      }
      return res;
    }
  }
}