public with sharing class Notification {
  public static String NEW_RESILI_ACCOUNT_CREATED = 'a new RESILI account has been created';
  public static String BHA_COMPLETED = 'the BHA survey has been completed';
  public static String POST_COACHING_COMPLETED = 'the Post Coaching Survey has been completed';
  private static List<String> CC_EMAILS = new List<String>{
    'rkon@abcdandcompany.com',
    'mhansen@abcdandcompany.com'
  };
  private static String cohortNotificationEmailTemplateName_new_account = 'Cohort Notification - NEW ACCOUNT';
  private static String cohortNotificationEmailTemplateName_bha_complete = 'Cohort Notification - RESILI ACTIVATION';
  private static String cohortNotificationEmailTemplateName_post_coaching_complete = 'Cohort Notification - POST COACHING';

  /**
   * Send an email to notify cohort members of a status change for a member of their cohort.
   *
   * @param  programMembership the program membership object for the cohort member
   */
  public static void notifyCohortMembers(
    Program_Membership__c programMembership,
    String newStatus
  ) {
    Id programId = programMembership.Program__c;
    Id cohortId = programMembership.Cohort__c;
    Id contactId = programMembership.Individual__c;

    String programName = [
      SELECT Name
      FROM Program__c
      WHERE Id = :programId
      LIMIT 1
    ]
    .Name;
    String cohortName = [SELECT Name FROM Account WHERE Id = :cohortId LIMIT 1]
    .Name;
    // get the organization wide email address
    List<OrgWideEmailAddress> orgEmail = [
      SELECT Id, Address, DisplayName, Purpose, IsAllowAllProfiles
      FROM OrgWideEmailAddress
      WHERE Address = 'info@aeoworks.org'
    ];
    String fromEmail = '';
    if (orgEmail.size() > 0)
      fromEmail = orgEmail[0].Id;
    // get the email addresses of all the cohort members
    List<Contact> cohortMembers = [
      SELECT Id, Email
      FROM Contact
      WHERE AccountId = :cohortId
    ];
    String[] emailList = new List<String>();
    Id firstCohortMemberId = null;
    for (Contact c : cohortMembers) {
      emailList.add(c.Email);
      if (firstCohortMemberId == null) {
        firstCohortMemberId = c.Id;
        System.debug(
          'firstCohortMemberId = ' +
          c.Id +
          ' with email: ' +
          c.Email
        );
      }
    }
    for (String email : CC_EMAILS) {
      emailList.add(email);
    }
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(emailList);
    mail.setOrgWideEmailAddressId(fromEmail);
    EmailTemplate emailTemplate = null;
    if (newStatus == NEW_RESILI_ACCOUNT_CREATED) {
      emailTemplate = [
        SELECT Id, Subject, HtmlValue
        FROM EmailTemplate
        WHERE Name = :cohortNotificationEmailTemplateName_new_account
        LIMIT 1
      ];
    } else if (newStatus == BHA_COMPLETED) {
      emailTemplate = [
        SELECT Id, Subject, HtmlValue
        FROM EmailTemplate
        WHERE Name = :cohortNotificationEmailTemplateName_bha_complete
        LIMIT 1
      ];
    } else if (newStatus == POST_COACHING_COMPLETED) {
      emailTemplate = [
        SELECT Id, Subject, HtmlValue
        FROM EmailTemplate
        WHERE Name = :cohortNotificationEmailTemplateName_post_coaching_complete
        LIMIT 1
      ];
    }
    System.debug('emailTemplateId = ' + emailTemplate.Id);
    mail.setTemplateId(emailTemplate.Id);
    mail.setTargetObjectId(firstCohortMemberId);
    mail.setWhatId(programMembership.Id);
    mail.setTreatTargetObjectAsRecipient(false);
    List<Messaging.SingleEmailMessage> mailAsList = new List<Messaging.SingleEmailMessage>{
      mail
    };
    Messaging.SendEmailResult[] sendEmailResult = Messaging.sendEmail(
      mailAsList
    );
    System.debug('sendEmailResult size = ' + sendEmailResult.size());
    System.debug(
      'sendEmailResult[0].isSuccess() = ' + sendEmailResult[0].isSuccess()
    );
    if (!sendEmailResult[0].isSuccess()) {
      Messaging.SendEmailError[] errors = sendEmailResult[0].getErrors();
      String errMsg = '';
      Boolean firstLoop = true;
      for (Messaging.SendEmailError me : errors) {
        if (firstLoop) {
          errMsg += me.getStatusCode() + ' ' + me.getMessage();
          firstLoop = false;
        } else {
          errMsg += ' | ' + me.getStatusCode() + ' ' + me.getMessage();
        }
      }
      throw new EmailException(errMsg);
    }
  }
}