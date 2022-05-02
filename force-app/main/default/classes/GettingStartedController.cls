public class GettingStartedController {


  @AuraEnabled
  /**
   * @description Return the following fields for the running user who is logged in to the portal for the 
   * given program.
   * - cohortId - the Cohort ID (Account ID)
   * - userId - the User ID
   * - bitlyResili - the Bitly Link to RESILI 
   * - bitlyPostCoach - the Bitly Link to Post-Coaching Survey
   * 
   * @param  programName the name of the program for the portal (e.g., Wells Fargo)
   * @return             A json string like {"cohortId": "xxxxx", "userId":"yyyyyy", ...}
   */
  public static String serverGetUserCohortAndLinks(String programName) {
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
    List<Program__c> programList = [
      SELECT Id FROM Program__c WHERE Name = :programName
    ];
    Id programId = null;
    if (programList.size() > 0) {
      programId = programList[0].Id;
    }
    List<Program_Partner_Membership__c> cohortProgramList = [
      SELECT Bitly_Link_to_Post_Coaching_Survey__c, Bitly_Link_To_Resili__c
      FROM Program_Partner_Membership__c
      WHERE Program__c = :programId AND Cohort__c = :cohortId
    ];
    if (cohortProgramList.size() > 0) {
      Program_Partner_Membership__c cohortProgram = cohortProgramList[0];
      returnMap.put('bitlyResili', cohortProgram.Bitly_Link_To_Resili__c);
      returnMap.put('bitlyPostCoach', cohortProgram.Bitly_Link_to_Post_Coaching_Survey__c);
    }
    return JSON.serialize(returnMap);

  }
  
}