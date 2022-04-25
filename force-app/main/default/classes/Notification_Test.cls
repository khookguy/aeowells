@IsTest
public with sharing class Notification_Test {
    @IsTest
    /**
     * @description Tests the notification of cohort members via Email.
     *
     * NOTE: FOR THIS TEST TO PASS THE SANDBOX MUST HAVE EMAIL > DELIVERABILITY > ACCESS TO SEND EMAIL SET TO 'ALL EMAIL'
     */
    static void testNotifyCohortMembers_happy_path() {
      String firstName = 'Sam';
      String lastName = TestDataFactory.createUniqueName('Last');
      String email = firstName + '.' + lastName + '@test.com';
      String businessName = TestDataFactory.createUniqueName('Business');
      String programName = TestDataFactory.createUniqueName('Program');
      Program__c program = TestDataFactory.createProgram(
        programName,
        'A very good program'
      );
      String cohortName = TestDataFactory.createUniqueName('Cohort');
      Account cohort = new Account(Name = cohortName);
      insert cohort;
      Id cohortId = [SELECT Id FROM Account WHERE Name = :cohortName LIMIT 1].Id;
      Contact cohortMember = new Contact(
        FirstName = 'Cohort',
        LastName = 'Member',
        Email = 'mhansen+cohort_member@abcdandcompany.com'
      );
      cohortMember.AccountId = cohortId;
      insert cohortMember;
  
      Test.startTest();
      System.assertEquals(
        0,
        Limits.getEmailInvocations(),
        'No emails should have been sent.'
      );
      EmailException emailException = null;
      try {
        Contact con = new Contact();
        con.FirstName = firstName;
        con.LastName = lastName;
        con.Email = email;
        String contactId = CreateMemberInbound.insertContact(con, businessName);
        Program_Membership__c pm = CreateMemberInbound.getOrCreateProgramMemberForNewResiliAccount(
          contactId,
          program.Id,
          cohortId
        );
        Notification.notifyCohortMembers(pm, Notification.NEW_RESILI_ACCOUNT_CREATED);
        Integer newEmailInvocations = Limits.getEmailInvocations();
        System.assert(
          newEmailInvocations > 0,
          'Emails should have been sent for NEW_RESILI_ACCOUNT_CREATED'
        );
        Integer oldnewEmailInvocations = newEmailInvocations;
        Notification.notifyCohortMembers(pm, Notification.BHA_COMPLETED);
        newEmailInvocations = Limits.getEmailInvocations();
        System.assert(
          newEmailInvocations > oldnewEmailInvocations,
          'Emails should have been sent for BHA_COMPLETED'
        );
        oldnewEmailInvocations = newEmailInvocations;
        Notification.notifyCohortMembers(pm, Notification.POST_COACHING_COMPLETED);
        newEmailInvocations = Limits.getEmailInvocations();
        System.assert(
          newEmailInvocations > oldnewEmailInvocations,
          'Emails should have been sent for POST_COACHING_COMPLETED'
        );
      } catch (EmailException e) {
        emailException = e;
        System.debug('Error notifying Cohort Members: ' + e.getMessage());
      }
      System.assertEquals(
        null,
        emailException,
        'An exception was thrown during notification of cohort members.'
      );
      System.debug('Number of emails sent: ' + Limits.getEmailInvocations());
      Test.stopTest();
    }

}