@RestResource(urlMapping='/CreateMember')
global class CreateMemberInbound {
  private static Id individualContactRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
    .get('Individual')
    .getRecordTypeId();
  private static Id smallBusinessRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
    .get('General_Organization')
    .getRecordTypeId();

  global class ResponseWrapper {
    global String status { get; set; }
    global String memberId { get; set; }
  }

  global class RequestWrapper {
    global String firstName { get; set; }
    global String lastName { get; set; }
    global String businessName { get; set; }
    global String email { get; set; }
    global String cohortId { get; set; }
    global String programId { get; set; }
  }

  @HTTPPOST
  global static ResponseWrapper doPost() {
    RestRequest req = RestContext.request;
    ResponseWrapper response = new ResponseWrapper();
    system.debug('==> entered doPost');
    try {
      system.debug('==> req ' + req);
      if (req != null) {
        system.debug('==> req.requestBody ' + req.requestBody);
        String jsonString = req.requestBody.toString();
        system.debug('==> jsonString ' + jsonString);
        if (String.isNotBlank(jsonString)) {
          RequestWrapper reqBody = (RequestWrapper) JSON.deserialize(
            jsonString,
            RequestWrapper.class
          );
          system.debug('==> reqBody ' + reqBody);
          String firstName = reqBody.firstName;
          String lastName = reqBody.lastName;
          String email = reqBody.email;
          String businessName = reqBody.businessName;
          String programId = reqBody.programId;
          String cohortId = reqBody.cohortId;
          Program_Membership__c member = findOrCreateMemberAndNotifyCohort(
            firstName,
            lastName,
            email,
            businessName,
            programId,
            cohortId
          );
          if (member != null) {
            response.memberId = member.Id;
            response.status = 'Success';
          }
        }
      }
    } catch (Exception ex) {
      response.memberId = '';
      response.status = 'Error: ' + ex.getMessage();
    }
    return response;
  }

  /**
   * Get an account matching the business name and attach it to the contact. Make the contact
   * an Individual (record type) and insert the contact. Returns null if the contact cannot be inserted.
   * @param  con          a contact that has not been inserted
   * @param  businessName the name of the contact's business
   * @return              the contact's Id afer insertion or null if it failed to insert
   *
   */
  public static Id insertContact(Contact con, String businessName) {
    system.debug('==> shoot insertContact ');
    String contactId = '';
    String accountId = getOrCreateAccount(businessName);
    system.debug('==> accountId ' + accountId);
    con.AccountId = accountId;
    con.RecordTypeId = individualContactRecTypeId;
    system.debug('==> con.RecordTypeId ' + con.RecordTypeId);
    try {
      insert con;
    } catch (Exception e) {
      return null;
    }

    if (String.isNotBlank(con.Id)) {
      contactId = con.Id;
    }
    system.debug('==> contactId ' + contactId);
    return contactId;
  }

  /**
   * @description Given a list of contacts, search for duplicates and return the first one found.
   * @param  conList the list of contacts to search for duplicates
   * @return  the first contact found that is a duplicate otherwise null
   */
  public static Contact findDuplicateContact(List<Contact> conList) {
    Contact con = null;
    List<sObject> recordMatches = new List<sObject>();
    system.debug('==> SHOOT findDuplicateContact');
    system.debug('==> conList ' + conList);
    if (conList != null) {
      for (
        Datacloud.FindDuplicatesResult findDupeResult : Datacloud.FindDuplicates.findDuplicates(
          conList
        )
      ) {
        for (
          Datacloud.DuplicateResult dupResult : findDupeResult.getDuplicateResults()
        ) {
          for (
            Datacloud.MatchResult matchResult : dupResult.getMatchResults()
          ) {
            for (
              Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()
            ) {
              recordMatches.add(matchRecord.getRecord());
            }
          }
        }
      }
    }
    system.debug('==> recordMatches ' + recordMatches);
    if (recordMatches.size() >= 1) {
      con = new Contact();
      con.Id = recordMatches[0].Id;
    }
    system.debug('==> con ' + con);
    return con;
  }

  /**
   * Return an account with the specified businessName and if one does not exist, create it.
   * @param  businessName businessName description
   * @return the Account Id
   */
  public static Id getOrCreateAccount(String businessName) {
    system.debug('==> shoot getAccount ');
    String response = null;
    system.debug('==> businessName ' + businessName);
    if (String.isNotBlank(businessName)) {
      List<Account> acct = [
        SELECT Id
        FROM Account
        WHERE Name = :businessName AND RecordTypeId = :smallBusinessRecTypeId
        LIMIT 1
      ];
      system.debug('==> acct ' + acct);
      if (!acct.isEmpty()) {
        system.debug('==> shoot account dupl ');
        response = acct[0].Id;
      } else {
        system.debug('==> shoot create account ');
        Account newAccount = new Account();
        newAccount.Name = businessName;
        newAccount.RecordTypeId = smallBusinessRecTypeId;
        insert newAccount;
        response = newAccount.Id;
      }
    }
    system.debug('==>  getAccount response ' + response);
    return response;
  }

  /**
   * Create a program log entry. Returns null if the programId does
   * not exist or if the status is not valid.
   * @param  description The program log description
   * @param  status      The progam log status. Must be a valid value as specified by
   *                     the Program_Log__c.Status__c picklist.
   * @param  programId   The Id of an existing program
   * @return             the log entry or null if program Id does not exists or status is invalid
   */
  public static Program_Log__c createProgLog(
    String description,
    String status,
    String programId
  ) {
    system.debug('==> entered createProgLog');
    List<Program__c> programList = [
      SELECT Id
      FROM Program__c
      WHERE Id = :programId
    ];
    if (programList.isEmpty()) {
      system.debug('==> not a valid program Id: ' + programId);
      return null;
    }
    Schema.DescribeFieldResult statusFieldResult = Program_Log__c.Status__c.getDescribe();
    List<Schema.PicklistEntry> ple = statusFieldResult.getPicklistValues();
    boolean found = false;
    for (Schema.PicklistEntry t : ple) {
      if (t.getValue().equals(status)) {
        found = true;
      }
    }
    if (!found) {
      system.debug('==> not a valid program status: ' + status);
      return null;
    }
    Program_Log__c progLog = new Program_Log__c();
    progLog.Description__c = description;
    progLog.Status__c = status;
    progLog.Program__c = programId;
    insert progLog;
    system.debug('==> progLog =  ' + progLog);
    return progLog;
  }

  /**
   * Find a program member with matching contact Id, program Id, and cohort Id
   * @param  contactId The contact Id of the program member (Individual__c)
   * @param  programId The program Id of the program member (Program __c)
   * @param  cohortId The cohort Id of the program member (Cohort__c)
   * @return           The program member object or null if no match is found
   */
  public static Program_Membership__c findMatchingProgramMember(
    String contactId,
    String programId,
    String cohortId
  ) {
    Program_Membership__c progMember = null;
    if (
      String.isNotBlank(programId) &&
      String.isNotBlank(contactId) &&
      String.isNotBlank(cohortId)
    ) {
      List<Program_Membership__c> progMemberList = [
        SELECT Id, Individual__c, Program__c, Member_Status__c, Cohort__c
        FROM Program_Membership__c
        WHERE
          Individual__c = :contactId
          AND Program__c = :programId
          AND Cohort__c = :cohortId
      ];
      if (!progMemberList.isEmpty()) {
        progMember = progMemberList[0];
      }
    }
    return progMember;
  }

  /**
   * @description If a program member exists that matches the parameters, return it.  Otherwise return null
   * @param  firstName    contact first name
   * @param  lastName     contact last name
   * @param  email        contact email
   * @param  programId    the program id
   * @param  cohortId     the cohort id
   * @return              the proram member or null if none exists
   */
  public static Program_Membership__c findMatchingProgramMember(
    String firstName,
    String lastName,
    String email,
    String programId,
    String cohortId
  ) {
    Contact con = new Contact();
    con.FirstName = firstName;
    con.LastName = lastName;
    con.Email = email;
    Contact duplicateContact = findDuplicateContact(new List<Contact>{ con });
    if (duplicateContact == null) {
      return null;
    }
    return findMatchingProgramMember(duplicateContact.id, programId, cohortId);
  }

  /**
   * Look for program membership record using the contact Id, program Id, and cohort Id provided. If one
   * exists, then return it. If none exists, then create one with the status "RESILI Account Created".  
   * If no such contact or program can be found (from the Ids), return null
   * @param  contactId the contact Id
   * @param  programId the program Id
   * @param  cohortId The cohort Id of the program member (Cohort__c)
   * @return           the program membership or null
   */
  public static Program_Membership__c getOrCreateProgramMemberForNewResiliAccount(
    String contactId,
    String programId,
    String cohortId
  ) {
    system.debug('==> entered getOrCreateProgramMember');
    system.debug('==> contactId = ' + contactId);
    system.debug('==> programId = ' + programId);
    system.debug('==> cohortId = ' + cohortId);

    Program_Membership__c programMembershipResponse = null;
    String progDescriptionForLog = '';
    String progStatusForLog = '';
    List<Contact> existing_contactList = [
      SELECT Id
      FROM Contact
      WHERE Id = :contactId
      LIMIT 1
    ];
    List<Program__c> existing_programList = [
      SELECT Id
      FROM Program__c
      WHERE Id = :programId
      LIMIT 1
    ];
    List<Account> existing_cohortList = [
      SELECT Id
      FROM Account
      WHERE Id = :cohortId
      LIMIT 1
    ];

    system.debug('==> existing_contactList = ' + existing_contactList);
    system.debug('==> existing_programList = ' + existing_programList);
    system.debug('==> existing_cohortList = ' + existing_cohortList);

    if (
      existing_cohortList.isEmpty() ||
      existing_programList.isEmpty() ||
      existing_contactList.isEmpty()
    ) {
      // One of the necessary objects is missing. We cannot create a membership object instance.
      return null;
    }
    Contact existing_contact = existing_contactList[0];
    system.debug('==> existing_contact ' + existing_contact);
    Program__c existing_program = existing_programList[0];
    system.debug('==> existing_program ' + existing_program);
    Account existing_cohort = existing_cohortList[0];
    system.debug('==> existing_cohort ' + existing_cohort);
    if (
      existing_contact != null &&
      existing_program != null &&
      existing_cohort != null
    ) {
      //check for duplicate program membership
      Program_Membership__c progMembership = findMatchingProgramMember(
        contactId,
        programId,
        cohortId
      );
      system.debug('==> progMembership ' + progMembership);
      if (progMembership != null) {
        //found existing program membership
        programMembershipResponse = progMembership;
        progDescriptionForLog = 'Program Member Already Exists';
        progStatusForLog = 'Duplicate';
      } else {
        //create new program membership record
        programMembershipResponse = new Program_Membership__c();
        programMembershipResponse.Individual__c = contactId;
        programMembershipResponse.Program__c = programId;
        programMembershipResponse.Cohort__c = cohortId;
        programMembershipResponse.Program_Members__c = cohortId;
        programMembershipResponse.Member_Status__c = 'RESILI Account Created';
        insert programMembershipResponse;
        progDescriptionForLog = 'Program Member Created Successfully';
        progStatusForLog = 'Success';
      }
      //create prog log record
      createProgLog(progDescriptionForLog, progStatusForLog, programId);
    }
    system.debug('==> getProgramMember response ' + programMembershipResponse);
    return programMembershipResponse;
  }

  /**
   * Look for program partner membership record using the cohort Id and program Id provided. If one
   * exists, then return it. If none exists, then create one.  If no such cohort or program
   * can be found (from the Ids), return null
   * @param  programId the program Id
   * @param  cohortId  the cohort Id
   * @return           the program partner membership record (found or created), otherwise null
   */
  public static Program_Partner_Membership__c getOrCreateProgramPartnerMember(
    String programId,
    String cohortId
  ) {
    List<Program__c> progRecord = [
      SELECT Id
      FROM Program__c
      WHERE Id = :programId
      LIMIT 1
    ];
    List<Account> acctRecord = [
      SELECT Id
      FROM Account
      WHERE Id = :cohortId
      LIMIT 1
    ];
    system.debug('==> createProgPartnerMember progRecord' + progRecord);
    system.debug('==> createProgPartnerMember  acctRecord' + acctRecord);
    if (!progRecord.isEmpty() && !acctRecord.isEmpty()) {
      system.debug('==> createProgPartnerMember shoot IF ');
      String acctId = acctRecord[0].Id;
      String progId = progRecord[0].Id;
      //check duplicate program partner membership record
      List<Program_Partner_Membership__c> progPartnerMemberList = [
        SELECT Id, Cohort__c, Program__c
        FROM Program_Partner_Membership__c
        WHERE Cohort__c = :acctId AND Program__c = :progId
        LIMIT 1
      ];
      system.debug('==> progPartnerMemberList  ' + progPartnerMemberList);
      if (progPartnerMemberList.isEmpty()) {
        //no duplicate record
        //create new program partner membership
        Program_Partner_Membership__c ppm = new Program_Partner_Membership__c();
        ppm.Cohort__c = acctId;
        ppm.Program__c = progId;
        insert ppm;
        return ppm;
      } else {
        return progPartnerMemberList[0];
      }
    }
    return null;
  }

  /**
   * @description findOrCreateMemberAndNotifyCohort description
   * @param  firstName    firstName description
   * @param  lastName     lastName description
   * @param  email        email description
   * @param  businessName businessName description
   * @param  programId    programId description
   * @param  cohortId     cohortId description
   * @return              return description
   */
  public static Program_Membership__c findOrCreateMemberAndNotifyCohort(
    String firstName,
    String lastName,
    String email,
    String businessName,
    String programId,
    String cohortId
  ) {
    Program_Membership__c programMembership = null;
    if (
      String.isNotBlank(firstName) &&
      String.isNotBlank(lastName) &&
      String.isNotBlank(email)
    ) {
      Program_Membership__c existingProgramMembership = findMatchingProgramMember(
        firstName,
        lastName,
        email,
        programId,
        cohortId
      );
      if (existingProgramMembership == null) {
        Contact con = new Contact();
        con.FirstName = firstName;
        con.LastName = lastName;
        con.Email = email;
        Contact duplicateContact = findDuplicateContact(
          new List<Contact>{ con }
        );
        system.debug('==> duplicateContact ' + duplicateContact);
        if (duplicateContact != null) {
          //found existing contact
          programMembership = getOrCreateProgramMemberForNewResiliAccount(
            duplicateContact.Id,
            programId,
            cohortId
          );
        } else {
          //no existing contact
          //create new contact record
          String contactId = insertContact(con, businessName);
          system.debug('==> created new contact ');
          system.debug('==> contactId ' + contactId);
          if (contactId != null && programId != null && cohortId != null) {
            programMembership = getOrCreateProgramMemberForNewResiliAccount(
              contactId,
              programId,
              cohortId
            );
            // since the membership is newly created, notify the cohort
            Notification.notifyCohortMembers(
              programMembership, Notification.NEW_RESILI_ACCOUNT_CREATED
            );
          }
        }
      } else {
        programMembership = existingProgramMembership;
      }
    }
    system.debug('==> programMembership ' + programMembership);
    if (programMembership != null) {
      // in case it doesn't exist, create the program partner member
      getOrCreateProgramPartnerMember(programId, cohortId);
    }
    return programMembership;
  }

}