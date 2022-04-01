@isTest
private class QualtricsSurvey_Test {
    
    private class GetAuthTokenMockPass implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String responseJson = '{"access_token":"cf92f4be-755f-4239-b034-d0faceb64877","token_type":"Bearer","expires_in":3599,"scope":"read:survey_responses"}';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(responseJson);
            res.setStatusCode(200);
            return res;
        }
    }

    private class GetAuthTokenMockFail implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String responseJson = '{}';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(responseJson);
            res.setStatusCode(500);
            return res;
        }
    }

    private class GetSurveyResponseMockPass implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String responseJson = '{"result":{"responseId":"R_264EqlGMmYU3s6R","values":{"startDate":"2022-03-22T17:16:05Z","endDate":"2022-03-22T17:16:29Z","status":0,"ipAddress":"72.69.36.227","progress":100,"duration":23,"finished":1,"recordedDate":"2022-03-22T17:16:29.752Z","locationLatitude":"40.9942932129","locationLongitude":"-73.7974014282","distributionChannel":"anonymous","userLanguage":"EN","QID2_TEXT":"Yolanda Hair Styling","QID3":2,"QID3_DO":["1","2","3","4"],"QID1":1,"QID1_DO":["1","2","3"],"course_plan":"marketing201","aeo_user_id":"ao9jurit8","aeo_cohort_id":"ko878ad"},"labels":{"status":"IP Address","finished":"True","QID3":"$10,001 - $250,000","QID3_DO":["Less than $10,000","$10,001 - $250,000","$250,001 - $1 million","More than $1 million"],"QID1":"Vanilla","QID1_DO":["Vanilla","Chocolate","Other"]},"displayedFields":["QID1","QID3","QID2_TEXT"],"displayedValues":{"QID1":[1,2,3],"QID3":[1,2,3,4]}},"meta":{"requestId":"9e49b542-f8d4-42b9-97c9-87f3cb69859d","httpStatus":"200 - OK"}}';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(responseJson);
            res.setStatusCode(200);
            return res;
        }
    }

    private class GetSurveyResponseMockFail implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String responseJson = '{}';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(responseJson);
            res.setStatusCode(500);
            return res;
        }
    }

    @isTest
    static void getAuthToken_pass_test() {
        Test.setMock(HttpCalloutMock.class, new GetAuthTokenMockPass());
        Test.startTest();
        String token = QualtricsSurvey.getAuthToken();
        Test.stopTest();
        System.assert(String.isNotBlank(token), 'Auth token should not be blank.');
    }

    @isTest
    static void getAuthToken_fail_test() {
        Test.setMock(HttpCalloutMock.class, new GetAuthTokenMockFail());
        Test.startTest();
        String token = null;
        CalloutException ce = null;
        try {
            token = QualtricsSurvey.getAuthToken();
        } catch (CalloutException e) {
            ce = e;
        }
        Test.stopTest();
        System.assertEquals(null, token, 'Should not have returned a token.');
        System.assertNotEquals(null, ce, 'Exception should have been thrown.');
    }


    @isTest
    static void getSurveyResponse_pass_test() {
        Test.setMock(HttpCalloutMock.class, new GetSurveyResponseMockPass());
        Test.startTest();
        String surveyResponseString = QualtricsSurvey.getSurveyResponse('auth-token', 'SV_80xQ0CkJkWw6zHw','R_264EqlGMmYU3s6R');
        Map<String, Object> surveyResponse = (Map<String, Object>) JSON.deserializeUntyped(surveyResponseString);
        Test.stopTest();
        System.assertNotEquals(null, surveyResponse, 'Survey response should not be null.');
        Map<String,Object> result = (Map<String,Object>) surveyResponse.get('result');
        System.assertNotEquals(null, result, 'Survey response result should not be null.');
        System.assertNotEquals(null, result.get('responseId'), 'Survey responseId should not be null.');
    }

    @isTest
    static void getSurveyResponse_fail_test() {
        Test.setMock(HttpCalloutMock.class, new GetSurveyResponseMockFail());
        Test.startTest();
        String surveyResponse = null;
        CalloutException ce = null;
        try {
            surveyResponse = QualtricsSurvey.getSurveyResponse('auth-token', 'SV_80xQ0CkJkWw6zHw','R_264EqlGMmYU3s6R');
        } catch (CalloutException e) {
            ce = e;
        }
        Test.stopTest();
        System.assertEquals(null, surveyResponse, 'Should not have returned a response.');
        System.assertNotEquals(null, ce, 'Exception should have been thrown.');
    }
}