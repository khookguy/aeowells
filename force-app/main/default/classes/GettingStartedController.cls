public class GettingStartedController {


  @AuraEnabled
  /**
   * @Return the Cohort ID (Account ID) and User ID of the running user who is logged in
   * to the portal for the given program.
   * 
   * @param  programName the name of the program for the portal (e.g., Wells Fargo)
   * @return             A json string like {"cohortId": "xxxxx", "userId":"yyyyyy"}
   */
  public static String serverGetUserAndCohort(String programName) {
    String userId;
    String cohortId;

    List<User> UserRec = [
      SELECT contact.account.name, contact.accountId
      FROM user
      WHERE contact.accountId != NULL AND id = :UserInfo.getUserId()
    ];
    cohortId = UserRec[0].contact.accountId;
    userId = UserInfo.getUserId();
    Map<String, String> returnMap = new Map<String, String>();
    returnMap.put('cohortId', cohortId);
    returnMap.put('userId', userId);
    return JSON.serialize(returnMap);

  }
  
}