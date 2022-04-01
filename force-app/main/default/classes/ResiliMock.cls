@isTest
public with sharing class ResiliMock {
  public class ActivateMockPass implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HTTPResponse res = new HTTPResponse();
      res.setStatusCode(200);
      return res;
    }
  }

  public class ActivateMockFail implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      HTTPResponse res = new HTTPResponse();
      res.setStatusCode(500);
      return res;
    }
  }
}