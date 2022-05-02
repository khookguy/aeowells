/*
 * NOTE: FOR THESE TESTS TO PASS THE SANDBOX MUST HAVE EMAIL > DELIVERABILITY > ACCESS TO SEND EMAIL
 * SET TO 'ALL EMAIL'
 */

@isTest 
public with sharing class Notification_Test {
  private static final String ENTREPRENEUR_FIRST_NAME = 'Sam';
  private static final String ENTREPRENEUR_LAST_NAME = 'Waterstone';
  private static final String ENTREPRENEUR_EMAIL = 'sam.waterstone@privateidaho.com';
  private static final String ENTREPRENEUR_BIZ_NAME = 'Private Idaho';
  private static final String PROGRAM_NAME = 'Spudzone';
  private static final String COHORT_NAME = 'Fry Distribution';
  private static final String COHORT_MEMBER1_EMAIL = 'cohort1@frydistribution.com';
  private static final String COHORT_MEMBER2_EMAIL = 'cohort2@frydistribution.com';

  /**
   * @description Create a Program, Cohort, Entrepreneur (and their Business), Cohort Member,
   * Program Partner Membership, and Program Membership
   */
  @testSetup static void setup() {
    Program__c program = new Program__c(Name=PROGRAM_NAME, Description__c='A very good program');
    insert program;
    Account cohort = new Account(Name = COHORT_NAME);
    Account business = new Account(Name = ENTREPRENEUR_BIZ_NAME);
    insert cohort;
    insert business;
    Id programId = [
      SELECT Id
      FROM Program__c
      WHERE Name = :PROGRAM_NAME
      LIMIT 1
    ]
    .Id;
    Id cohortId = [SELECT Id FROM Account WHERE Name = :COHORT_NAME LIMIT 1].Id;
    Id businessId = [
      SELECT Id
      FROM Account
      WHERE Name = :ENTREPRENEUR_BIZ_NAME
      LIMIT 1
    ]
    .Id;
    Program_Partner_Membership__c programPartnerMember = new Program_Partner_Membership__c(
      Program__c = programId,
      Cohort__c = cohortId
    );
    insert programPartnerMember;
    Contact cohortMember1 = new Contact(
      FirstName = 'Cohort',
      LastName = 'Member1',
      Email = COHORT_MEMBER1_EMAIL
    );
    Contact cohortMember2 = new Contact(
      FirstName = 'Cohort',
      LastName = 'Member2',
      Email = COHORT_MEMBER2_EMAIL
    );
    cohortMember1.AccountId = cohortId;
    cohortMember2.AccountId = cohortId;
    insert cohortMember1;
    insert cohortMember2;
    Contact entrepreneur = new Contact(
      FirstName = ENTREPRENEUR_FIRST_NAME,
      LastName = ENTREPRENEUR_LAST_NAME,
      Email = ENTREPRENEUR_EMAIL
    );
    entrepreneur.AccountId = businessId;
    insert entrepreneur;
    Id entrepreneurId = [
      SELECT Id
      FROM Contact
      WHERE Email = :ENTREPRENEUR_EMAIL
      LIMIT 1
    ]
    .Id;
    Program_Membership__c programMembership = new Program_Membership__c(
      Individual__c = entrepreneurId,
      Program__c = programId,
      Cohort__c = cohortId
    );
    insert programMembership;
  }

  @isTest
  static void testSendEmail_happy_path() {
    // get the objects created during setup
    Contact entrepreneur = [
      SELECT Id, Email
      FROM Contact
      WHERE Email = :ENTREPRENEUR_EMAIL
      LIMIT 1
    ];
    Contact cohortMember1 = [
      SELECT Id, Email
      FROM CONTACT
      WHERE EMAIL = :COHORT_MEMBER1_EMAIL
      LIMIT 1
    ];
    Contact cohortMember2 = [
      SELECT Id, Email
      FROM CONTACT
      WHERE EMAIL = :COHORT_MEMBER2_EMAIL
      LIMIT 1
    ];
    Program__c program = [
      SELECT Id
      FROM Program__c
      WHERE Name = :PROGRAM_NAME
      LIMIT 1
    ];
    Account cohort = [SELECT Id FROM Account WHERE Name = :COHORT_NAME];
    Program_Membership__c programMembership = [
      SELECT Id, Program__c, Cohort__c, Individual__c, Member_Status__c
      FROM Program_Membership__c
      WHERE
        Individual__c = :entrepreneur.Id
        AND Program__c = :program.Id
        AND Cohort__c = :cohort.Id
    ];
    List<EmailTemplate> entrepreneur_emailTemplateList = [
      SELECT Id, Subject, HtmlValue
      FROM EmailTemplate
      WHERE
        Name = :Notification.entrepreneurNotificationEmailTemplateName_bha_complete
      LIMIT 1
    ];
    List<EmailTemplate> cohort_emailTemplateList = [
      SELECT Id, Subject, HtmlValue
      FROM EmailTemplate
      WHERE
        Name = :Notification.cohortNotificationEmailTemplateName_bha_complete
      LIMIT 1
    ];

    Test.startTest();
    System.assertEquals(
      0,
      Limits.getEmailInvocations(),
      'No emails should have been sent.'
    );
    Notification.sendEmail(
      new List<Id>{ entrepreneur.Id },
      Notification.FROM_EMAIL_ID,
      entrepreneur_emailTemplateList[0].Id,
      entrepreneur.Id,
      programMembership.Id,
      true
    );
    Integer newEmailInvocations = Limits.getEmailInvocations();
    System.assert(newEmailInvocations > 0, 'Emails should have been sent');
    Notification.sendEmail(
      new List<Id>{ cohortMember1.Id, cohortMember2.Id },
      Notification.FROM_EMAIL_ID,
      cohort_emailTemplateList[0].Id,
      cohortMember1.Id,
      programMembership.Id,
      false
    );
    Integer oldEmailInvocation = newEmailInvocations;
    newEmailInvocations = Limits.getEmailInvocations();
    System.assert(
      newEmailInvocations > oldEmailInvocation,
      'Emails should have been sent'
    );
    Notification.sendEmail(
      new List<String>{ entrepreneur.Email },
      Notification.FROM_EMAIL_ID,
      entrepreneur_emailTemplateList[0].Id,
      entrepreneur.Id,
      programMembership.Id,
      true
    );
    oldEmailInvocation = newEmailInvocations;
    newEmailInvocations = Limits.getEmailInvocations();
    System.assert(
      newEmailInvocations > oldEmailInvocation,
      'Emails should have been sent'
    );
    Notification.sendEmail(
      new List<String>{ cohortMember1.Email, cohortMember2.Email },
      Notification.FROM_EMAIL_ID,
      cohort_emailTemplateList[0].Id,
      cohortMember1.Id,
      programMembership.Id,
      false
    );
    oldEmailInvocation = newEmailInvocations;
    newEmailInvocations = Limits.getEmailInvocations();
    System.assert(
      newEmailInvocations > oldEmailInvocation,
      'Emails should have been sent'
    );
    Test.stopTest();
  }

  @isTest
  static void testNotifyEntrepreneur_happy_path() {
    System.assertEquals(
      0,
      Limits.getEmailInvocations(),
      'No emails should have been sent.'
    );
    // get the objects created during setup
    Contact entrepreneur = [
      SELECT Id
      FROM Contact
      WHERE Email = :ENTREPRENEUR_EMAIL
      LIMIT 1
    ];
    Program__c program = [
      SELECT Id
      FROM Program__c
      WHERE Name = :PROGRAM_NAME
      LIMIT 1
    ];
    Account cohort = [SELECT Id FROM Account WHERE Name = :COHORT_NAME];
    Program_Membership__c pm = [
      SELECT Id, Program__c, Cohort__c, Individual__c, Member_Status__c
      FROM Program_Membership__c
      WHERE
        Individual__c = :entrepreneur.Id
        AND Program__c = :program.Id
        AND Cohort__c = :cohort.Id
    ];

    Test.startTest();
    EmailException emailException = null;
    try {
      pm.Member_Status__c = Notification.BHA_COMPLETED;
      update pm;
      Notification.notifyCohortMembers(pm);
      Integer newEmailInvocations = Limits.getEmailInvocations();
      System.assert(
        newEmailInvocations > 0,
        'Emails should have been sent for BHA_COMPLETED'
      );
    } catch (EmailException e) {
      emailException = e;
      System.debug('Error notifying Entrepreneur: ' + e.getMessage());
    }
    System.assertEquals(
      null,
      emailException,
      'An exception was thrown during entrepreneur notification for status: ' +
      pm.Member_Status__c
    );
    System.debug(
      'Number of emails sent during entrepreneur notification tests: ' +
      Limits.getEmailInvocations()
    );
    Test.stopTest();
  }

  @isTest
  static void testNotifyCohortMembers_happy_path() {
    System.assertEquals(
      0,
      Limits.getEmailInvocations(),
      'No emails should have been sent.'
    );
    // get the objects created during setup
    Contact entrepreneur = [
      SELECT Id
      FROM Contact
      WHERE Email = :ENTREPRENEUR_EMAIL
      LIMIT 1
    ];
    Program__c program = [
      SELECT Id
      FROM Program__c
      WHERE Name = :PROGRAM_NAME
      LIMIT 1
    ];
    Account cohort = [SELECT Id FROM Account WHERE Name = :COHORT_NAME];
    Program_Membership__c pm = [
      SELECT Id, Program__c, Cohort__c, Individual__c, Member_Status__c
      FROM Program_Membership__c
      WHERE
        Individual__c = :entrepreneur.Id
        AND Program__c = :program.Id
        AND Cohort__c = :cohort.Id
    ];

    Test.startTest();
    EmailException emailException = null;
    try {
      pm.Member_Status__c = Notification.NEW_RESILI_ACCOUNT_CREATED;
      update pm;
      Notification.notifyCohortMembers(pm);
      Integer newEmailInvocations = Limits.getEmailInvocations();
      System.assert(
        newEmailInvocations > 0,
        'Emails should have been sent for NEW_RESILI_ACCOUNT_CREATED'
      );
      Integer oldnewEmailInvocations = newEmailInvocations;
      pm.Member_Status__c = Notification.BHA_COMPLETED;
      update pm;
      Notification.notifyCohortMembers(pm);
      newEmailInvocations = Limits.getEmailInvocations();
      System.assert(
        newEmailInvocations > oldnewEmailInvocations,
        'Emails should have been sent for BHA_COMPLETED'
      );
      oldnewEmailInvocations = newEmailInvocations;
      pm.Member_Status__c = Notification.POST_COACHING_COMPLETED;
      update pm;
      Notification.notifyCohortMembers(pm);
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
      'An exception was thrown during notification of cohort members for status: ' +
      pm.Member_Status__c
    );
    System.debug(
      'Number of emails sent during cohort notification tests: ' +
      Limits.getEmailInvocations()
    );
    Test.stopTest();
  }
}