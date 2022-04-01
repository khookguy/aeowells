@isTest
private class Resili_Test {
  @isTest
  static void activate_pass_test() {
    Test.setMock(HttpCalloutMock.class, new ResiliMock.ActivateMockPass());
    Test.startTest();
    String email = 'test' + Datetime.now().millisecondGmt() + 'testy.com';
    String bhaJson = '{"business_health_assessment":{"completion_date":"20220331","survey_id":"survey_id","response_id":"response_id"}, "course_groups":["group1","group2"]}';
    IllegalArgumentException illegalArgumentException = null;
    try {
      Resili.activate(null, bhaJson);
    } catch (IllegalArgumentException e) {
      illegalArgumentException = e;
    }
    CalloutException calloutException = null;
    try {
      Resili.activate(email, bhaJson);
    } catch (CalloutException e) {
      calloutException = e;
    }
    Test.stopTest();
    System.assertNotEquals(
      null,
      illegalArgumentException,
      'An illegal argument exception should have been thrown on a null email.'
    );
    System.assertEquals(
      null,
      calloutException,
      'No exception should have been thrown.'
    );
  }

  @isTest
  static void activate_fail_test() {
    Test.setMock(HttpCalloutMock.class, new ResiliMock.ActivateMockFail());
    Test.startTest();
    String email = 'test' + Datetime.now().millisecondGmt() + 'testy.com';
    String bhaJson = '{"business_health_assessment":{"completion_date":"20220331","survey_id":"survey_id","response_id":"response_id"}, "course_groups":["group1","group2"]}';
    CalloutException calloutException = null;
    try {
      Resili.activate(email, bhaJson);
    } catch (CalloutException e) {
      calloutException = e;
    }
    Test.stopTest();
    System.assertNotEquals(
      null,
      calloutException,
      'A callout exception should have been thrown.'
    );
  }
}