public with sharing class Notification {
  /*
   * Picklist values for Program Membership object's Member Status field. The status
   * determines which email template to use for notification.
   */
  public static String NEW_RESILI_ACCOUNT_CREATED = 'RESILI Account Created';
  public static String BHA_COMPLETED = 'BHA Completed';
  public static String POST_COACHING_COMPLETED = 'Post-Coaching Survey Completed';
  public static String ONE_YEAR_SURVEY_COMPLETED = '1-Year Survey Completed';
  public static String TWO_YEAR_SURVEY_COMPLETED = '2-Year Survey Completed';

  /*
   * The email address that sends notifications. It must be defined in Salesforce as an Organization-Wide Address.
   */
  // public static String FROM_EMAIL_ADDRESS = 'aeoinnovates@aeoworks.org';
  public static String FROM_EMAIL_ADDRESS = 'info@aeoworks.org';
  public static final Id FROM_EMAIL_ID;
  static {
    List<OrgWideEmailAddress> orgEmail = [
      SELECT Id
      FROM OrgWideEmailAddress
      WHERE Address = :FROM_EMAIL_ADDRESS
    ];
    Id fromEmail = null;
    if (orgEmail.size() > 0)
      fromEmail = orgEmail[0].Id;
    FROM_EMAIL_ID = fromEmail;
  }

  public static String cohortNotificationEmailTemplateName_new_account = 'Cohort Notification - NEW ACCOUNT';
  public static String cohortNotificationEmailTemplateName_bha_complete = 'Cohort Notification - RESILI ACTIVATION';
  public static String entrepreneurNotificationEmailTemplateName_bha_complete = 'Entrepreneur Notification - RESILI ACTIVATION';
  public static String cohortNotificationEmailTemplateName_post_coaching_complete = 'Cohort Notification - POST COACHING';

  /**
   * @description Utility function that sends emails using a template.
   *
   * @param  toAddressList                List of email addresses or Ids (Lead or Contact) to send the email to.
   * @param  orgWideFromEmailId           Id of an org wide email address.  Used as the from address.
   * @param  emailTemplateId              Id of the email template
   * @param  targetObjectId               Id of the target object. Typically one of the email recipients.
   * @param  whatId                       Id of the object used by the template for property merge. Typically a Program Membership object.
   * @param  treatTargetObjectAsRecipient Set to true if the targetObjectId is also the receipient. This is the case for entrepreneur emails, but not cohort emails.
   */
  public static void sendEmail(
    List<String> toAddressList,
    Id orgWideFromEmailId,
    Id emailTemplateId,
    Id targetObjectId,
    Id whatId,
    Boolean treatTargetObjectAsRecipient
  ) {
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    mail.setToAddresses(toAddressList);
    mail.setOrgWideEmailAddressId(orgWideFromEmailId);
    mail.setTemplateId(emailTemplateId);
    mail.setTargetObjectId(targetObjectId);
    mail.setWhatId(whatId);
    mail.setTreatTargetObjectAsRecipient(treatTargetObjectAsRecipient);
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

  /**
   * @description Send an email notification to the entrepreneur notifying them of their status. Only supported for
   * BHA_COMPLETED status at this time. Any other status will not send a notification.
   *
   * @param  programMembership programMembership object that contains entrepreneur and status
   */
  public static void notifyEntrepreneur(
    Program_Membership__c programMembership
  ) {
    List<EmailTemplate> emailTemplateList = null;
    if (programMembership.Member_Status__c == BHA_COMPLETED) {
      emailTemplateList = [
        SELECT Id, Subject, HtmlValue
        FROM EmailTemplate
        WHERE Name = :entrepreneurNotificationEmailTemplateName_bha_complete
        LIMIT 1
      ];
    }
    if (emailTemplateList != null & emailTemplateList.size() > 0) {
      sendEmail(
        new List<Id>{ programMembership.Individual__c },
        FROM_EMAIL_ID,
        emailTemplateList[0].Id,
        programMembership.Individual__c,
        programMembership.Id,
        true
      );
    }
  }

  /**
   * Send an email to notify cohort members of a status change for a member of their cohort. Supports these statuses:
   * - NEW_RESILI_ACCOUNT_CREATED
   * - BHA_COMPLETED
   * - POST_COACHING_COMPLETED
   *
   * @param  programMembership the program membership object for the cohort member
   */
  public static void notifyCohortMembers(
    Program_Membership__c programMembership
  ) {
    Id programId = programMembership.Program__c;
    Id cohortId = programMembership.Cohort__c;
    Id contactId = programMembership.Individual__c;
    String memberStatus = programMembership.Member_Status__c;

    String programName = [
      SELECT Name
      FROM Program__c
      WHERE Id = :programId
      LIMIT 1
    ]
    .Name;
    String cohortName = [SELECT Name FROM Account WHERE Id = :cohortId LIMIT 1]
    .Name;

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

    List<EmailTemplate> emailTemplateList = null;
    if (memberStatus == NEW_RESILI_ACCOUNT_CREATED) {
      emailTemplateList = [
        SELECT Id, Subject, HtmlValue
        FROM EmailTemplate
        WHERE Name = :cohortNotificationEmailTemplateName_new_account
      ];
    } else if (memberStatus == BHA_COMPLETED) {
      emailTemplateList = [
        SELECT Id, Subject, HtmlValue
        FROM EmailTemplate
        WHERE Name = :cohortNotificationEmailTemplateName_bha_complete
      ];
    } else if (memberStatus == POST_COACHING_COMPLETED) {
      emailTemplateList = [
        SELECT Id, Subject, HtmlValue
        FROM EmailTemplate
        WHERE Name = :cohortNotificationEmailTemplateName_post_coaching_complete
      ];
    }
    if (emailTemplateList != null & emailTemplateList.size() > 0) {
      sendEmail(
        emailList,
        FROM_EMAIL_ID,
        emailTemplateList[0].Id,
        firstCohortMemberId,
        programMembership.Id,
        false
      );
    }
  }
}