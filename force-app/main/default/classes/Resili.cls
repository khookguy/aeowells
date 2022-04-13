public with sharing class Resili {
  private static String RESILI_ACCESS_TOKEN = 'WcgqsbWHYxzIieMhxtoULRsJmaqhQplh';
  private static String RESILI_ACTIVATION_ENDPOINT = 'https://resilistaging.aeoworks.org/wp-json/aeo/v1/users/activate';

  public static void activate(String email, String bhaPayload) {
    System.debug('Entered: activate');
    if (email == null) {
      throw new IllegalArgumentException('Email cannot be null');
    }
    String urlEncodedEmail = EncodingUtil.urlEncode(email, 'UTF-8');
    System.debug('Calling Resisli activation for email (urlencoded): ' + urlEncodedEmail);
    System.debug('with payload: ' + bhaPayload);
    Http h = new Http();
    HttpRequest req = new HttpRequest();
    req.setEndpoint(RESILI_ACTIVATION_ENDPOINT + '?email=' + urlEncodedEmail);
    req.setMethod('PUT');
    req.setHeader('Content-Type', 'application/json');
    req.setHeader('Authorization', 'Bearer ' + RESILI_ACCESS_TOKEN);
    req.setBody(bhaPayload);
    HttpResponse res = h.send(req);
    if (res.getStatusCode() != 200) {
      CalloutException e = new CalloutException();
      e.setMessage(
        'Error activating Resili account for email ' +
        email +
        ': ' +
        res.getStatusCode() +
        ' ' +
        res.getStatus()
      );
      throw e;
    }
    System.debug('Resili account for email ' + email + ' has been activated.');
  }
}