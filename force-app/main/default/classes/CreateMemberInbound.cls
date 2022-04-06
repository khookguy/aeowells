@RestResource(urlMapping = '/CreateMember')
global class CreateMemberInbound {
    
    private static Id individualContactRecTypeId = 
        Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();
    private static Id smallBusinessRecTypeId = 
        Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('General_Organization').getRecordTypeId();

    global class ResponseWrapper{
        global String status{get; set;}
        global String memberId{get; set;}
    }
    
    global class RequestWrapper{
        global String firstName{get; set;}
        global String lastName{get; set;}
        global String businessName{get; set;}
        global String email{get; set;}
        global String cohortId{get; set;}
        global String programId{get; set;}
    }
    
    @HTTPPOST
    global static ResponseWrapper doPost(){
        RestRequest req = RestContext.request;
        ResponseWrapper response = new ResponseWrapper();
        system.debug('==> SHOOT HERE');
        try{
            system.debug('==> req ' + req);
            if(req != NULL){
                system.debug('==> req.requestBody ' + req.requestBody);
                String jsonString = req.requestBody.toString();
                system.debug('==> jsonString ' + jsonString);
                if(String.isNotBlank(jsonString)){
                    RequestWrapper reqBody = (RequestWrapper) JSON.deserialize(jsonString, RequestWrapper.class);
                    system.debug('==> reqBody ' + reqBody);
                    String firstName = reqBody.firstName;
                    String lastName = reqBody.lastName;
                    String email = reqBody.email;
                    String businessName = reqBody.businessName;
                    String programId = reqBody.programId;
                    String cohortId = reqBody.cohortId;
                    Program_Membership__c member = createMember(firstName, lastName, email, businessName, programId, cohortId);
                    if(member != null){
                        response.memberId = member.Id;
                        response.status = 'Success';
                        notifyCohortMembers(firstName, lastName, email, businessName, programId, cohortId);
                    }
                    
                }
            }
        }catch(Exception ex){
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
        
        if(String.isNotBlank(con.Id)){
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
    public static Contact findDuplicateContact(List<Contact> conList){
        Contact con = null;
        List<sObject> recordMatches = new List<sObject>();
        system.debug('==> SHOOT findDuplicateContact');
        system.debug('==> conList ' + conList);
        if(conList != NULL){
            for(Datacloud.FindDuplicatesResult findDupeResult: Datacloud.FindDuplicates.findDuplicates(conList)){
                for(Datacloud.DuplicateResult dupResult: findDupeResult.getDuplicateResults()){
                    for(Datacloud.MatchResult matchResult: dupResult.getMatchResults()){
                        for(Datacloud.MatchRecord matchRecord: matchResult.getMatchRecords()){
                            recordMatches.add(matchRecord.getRecord());
                        }
                    }
                    
                }
            }
        }  
        system.debug('==> recordMatches ' + recordMatches);
        if(recordMatches.size() >= 1){
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
    public static Id getOrCreateAccount(String businessName){
        system.debug('==> shoot getAccount ');
        String response = null;
        system.debug('==> businessName ' + businessName);
        if(String.isNotBlank(businessName)){
            List<Account> acct = [SELECT Id FROM Account WHERE Name =: businessName AND RecordTypeId =: smallBusinessRecTypeId LIMIT 1];
            system.debug('==> acct ' + acct);
            if(!acct.isEmpty()){
                system.debug('==> shoot account dupl ');
                response = acct[0].Id;
            }else{
                system.debug('==> shoot create account ');
                Account newAccount = new Account();
                newAccount.Name = businessName;
                newAccount.RecordTypeId = smallBusinessRecTypeId;
                Insert newAccount;
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
    public static Program_Log__c createProgLog(String description, String status, String programId){
        system.debug('==> entered createProgLog');
        List<Program__c> programList = [SELECT Id from Program__c WHERE Id =: programId];
        if (programList.isEmpty()) {
            system.debug('==> not a valid program Id: ' + programId);
            return null;
        }
        Schema.DescribeFieldResult statusFieldResult = Program_Log__c.Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = statusFieldResult.getPicklistValues();
        boolean found = false;
        for (Schema.PicklistEntry t: ple) {
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
    public static Program_Membership__c findMatchingProgramMember(String contactId, String programId, String cohortId){
        Program_Membership__c progMember = null;
        if(String.isNotBlank(programId) && String.isNotBlank(contactId) && String.isNotBlank(cohortId)){
            List<Program_Membership__c> progMemberList = [SELECT Id, Individual__c, Program__c, Member_Status__c, Cohort__c 
                                                          FROM Program_Membership__c 
                                                          WHERE Individual__c =: contactId AND Program__c =: programId AND Cohort__c =: cohortId];
            if(!progMemberList.isEmpty()){
                progMember = progMemberList[0];
            }
        }
        return progMember;
    }

    /**
     * Look for program membership record using the contact Id, program Id, and cohort Id provided. If one
     * exists, then return it. If none exists, then create one.  If no such contact or program
     * can be found (from the Ids), return null
     * @param  contactId the contact Id
     * @param  programId the program Id
     * @param  cohortId The cohort Id of the program member (Cohort__c)
     * @return           the program membership or null
     */
    public static Program_Membership__c getOrCreateProgramMember(String contactId, String programId, String cohortId){
        system.debug('==> entered getOrCreateProgramMember');
        system.debug('==> contactId = ' + contactId);
        system.debug('==> programId = ' + programId);
        system.debug('==> cohortId = ' + cohortId);
        
        Program_Membership__c response = null;
        String progDescriptionForLog = '';
        String progStatusForLog = '';
        List<Contact> existing_contactList = [SELECT Id FROM Contact WHERE Id =: contactId LIMIT 1];
        List<Program__c> existing_programList = [SELECT Id FROM Program__c WHERE Id =: programId LIMIT 1];
        List<Account> existing_cohortList = [SELECT Id FROM Account WHERE Id =: cohortId LIMIT 1];
        
        system.debug('==> existing_contactList = ' + existing_contactList);
        system.debug('==> existing_programList = ' + existing_programList);
        system.debug('==> existing_cohortList = ' + existing_cohortList);
        
        if (existing_cohortList.isEmpty() || existing_programList.isEmpty() || existing_contactList.isEmpty()) {
            return response;
        }
        Contact existing_contact = existing_contactList[0];
        system.debug('==> existing_contact ' + existing_contact);
        Program__c existing_program = existing_programList[0];
        system.debug('==> existing_program ' + existing_program);
        Account existing_cohort = existing_cohortList[0];
        system.debug('==> existing_cohort ' + existing_cohort);
        if(existing_contact != null && existing_program != null && existing_cohort != null){
            //check for duplicate program membership
            Program_Membership__c progMembership = findMatchingProgramMember(contactId, programId, cohortId);
            system.debug('==> progMembership ' + progMembership);
            if(progMembership != null){
                //found existing program membership
                response = progMembership;
                progDescriptionForLog = 'Program Member Already Exists';
                progStatusForLog = 'Duplicate';
            }else{
                //create new program membership record
                response = new Program_Membership__c();
                response.Individual__c = contactId;
                response.Program__c = programId;
                response.Cohort__c = cohortId;
                response.Program_Members__c = cohortId;
                response.Member_Status__c = 'Contact signed up';
                insert response;
                progDescriptionForLog = 'Program Member Created Successfully';
                progStatusForLog = 'Success';
            } 
            //create prog log record
        	createProgLog(progDescriptionForLog, progStatusForLog, programId);
        }
        system.debug('==> getProgramMember response ' + response);
        return response;
    }

    /**
     * Look for program partner membership record using the cohort Id and program Id provided. If one
     * exists, then return it. If none exists, then create one.  If no such cohort or program
     * can be found (from the Ids), return null
     * @param  programId the program Id
     * @param  cohortId  the cohort Id
     * @return           the program partner membership record (found or created), otherwise null
     */   
    public static Program_Partner_Membership__c getOrCreateProgramPartnerMember(String programId, String cohortId){
        List<Program__c> progRecord = [SELECT Id FROM Program__c WHERE Id =: programId LIMIT 1];
        List<Account> acctRecord = [SELECT Id FROM Account WHERE Id =: cohortId LIMIT 1];
        system.debug('==> createProgPartnerMember progRecord' + progRecord);
        system.debug('==> createProgPartnerMember  acctRecord' + acctRecord);
        if(!progRecord.isEmpty() && !acctRecord.isEmpty()){
            system.debug('==> createProgPartnerMember shoot IF ' );
            String acctId = acctRecord[0].Id;
            String progId = progRecord[0].Id;
            //check duplicate program partner membership record
            List<Program_Partner_Membership__c> progPartnerMemberList = [SELECT Id, Cohort__c, Program__c FROM Program_Partner_Membership__c
                                                                        WHERE Cohort__c =: acctId AND Program__c =: progId
                                                                 		LIMIT 1];
            system.debug('==> progPartnerMemberList  ' + progPartnerMemberList);
            if(progPartnerMemberList.isEmpty()){
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

    public static Program_Membership__c createMember(String firstName, String lastName, String email, 
        String businessName, String programId, String cohortId) {

        Program_Membership__c programMember = null;
        if(String.isNotBlank(firstName) && String.isNotBlank(lastName) && String.isNotBlank(email)){
            Contact con = new Contact();
            con.FirstName = firstName;
            con.LastName = lastName;
            con.Email = email;
            // find duplicate contact based on firstName, lastName and Email
            // TODO: should we also match on businessName?
            Contact duplicateContact = findDuplicateContact(new List<Contact>{con}); 
            system.debug('==> duplicateContact ' + duplicateContact);
            if(duplicateContact != null){
                //found existing contact
                programMember = getOrCreateProgramMember(duplicateContact.Id, programId, cohortId);
            }else{
                //no existing contact
                //create new contact record
                String contactId = insertContact(con, businessName); 
                system.debug('==> shoot without duplicateContact ');
                system.debug('==> contactId ' + contactId);
                //get program membership id
                programMember = getOrCreateProgramMember(contactId, programId, cohortId); 
            }
        }
        system.debug('==> programMember ' + programMember);
        if(programMember != null){
            // in case it doesn't exist, create the program partner member
            getOrCreateProgramPartnerMember(programId, cohortId);
        }
        return programMember;
    }

    /**
     * @description Send an email to notify cohort members of a newly activated RESILI account for a new member of
     * their cohort.
     * @param  firstName    Newly activate member's first name
     * @param  lastName     Newly activate member's last name
     * @param  email        Newly activate member's email
     * @param  businessName Newly activate member's business
     * @param  programId    The programId of the program they just joined
     * @param  cohortId     The cohortId within the program that they are part of.
     */
    public static void notifyCohortMembers(String firstName, String lastName, String email, String businessName, String programId, String cohortId) {

        String programName = [SELECT Name from Program__c where Id = :programId LIMIT 1].Name;
        String cohortName = [SELECT Name from Account where Id = :cohortId LIMIT 1].Name;
        // get the organization wide email address
        List<OrgWideEmailAddress> orgEmail = [SELECT Id, Address, DisplayName, Purpose, IsAllowAllProfiles FROM OrgWideEmailAddress WHERE Address = 'info@aeoworks.org'];
        String fromEmail = '';
        if(orgEmail.size() > 0)
            fromEmail = orgEmail[0].Id;
        // get the email addresses of all the cohort members
        List<Contact> cohortMembers = [SELECT Id, Email FROM Contact WHERE AccountId = :cohortId];
        String[] emailList = new List<String>();
        for (Contact c : cohortMembers) {
            emailList.add(c.Email);
        }
        emailList.add('rkon@abcdandcompany.com');
        emailList.add('mhansen@abcdandcompany.com');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        // mail.setTemplateId(??)
        mail.setToAddresses(emailList);
        mail.setOrgWideEmailAddressId(fromEmail);
        mail.setSubject( 'Resilli Activation Completed' );
        String template = 'Resilli Activation has been completed for: {0} {1} with email {2} and business named {3}. They are now members of the {4} program in cohort {5}.';
        List<String> params = new List<String>{firstName, LastName, email, businessName, programName, cohortName};
        String formattedBody = String.format(template, params);
        mail.setPlainTextBody(formattedBody);
        mail.setToAddresses(emailList);
        List<Messaging.SingleEmailMessage> mailAsList = new List<Messaging.SingleEmailMessage> {mail};
        Messaging.SendEmailResult [] r = Messaging.sendEmail(mailAsList);
        if (!r[0].isSuccess()) {
            Messaging.SendEmailError[] errors = r[0].getErrors();
            String errMsg = '';
            Boolean firstLoop = TRUE;
            for (Messaging.SendEmailError me: errors) {
                if (firstLoop) {
                    errMsg += me.getStatusCode() + ' ' + me.getMessage();
                    firstLoop = FALSE;
                } else {
                    errMsg += ' | ' + me.getStatusCode() + ' ' + me.getMessage();
                }
            }
            throw new EmailException(errMsg);
        }

    }
}