@IsTest
private class CreateMemberInboundTest {

    // default account record type for small business
    static Id smallBusinessAccountRecTypeId = 
        Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('General_Organization').getRecordTypeId();
    // default contact record type for small business
    private static Id individualContactRecTypeId = 
        Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Individual').getRecordTypeId();

    @IsTest
    static void testGetAccount_createNewOne() {
        String newAcctName = TestDataFactory.createUniqueName('TestAccount');
        List<Account> acctList = [SELECT Id FROM Account WHERE Name =: newAcctName AND RecordTypeId =: smallBusinessAccountRecTypeId LIMIT 1];
        System.assert(acctList.size() == 0, 'An account with name '+newAcctName+' should not exist.');
        String newlyCreated = CreateMemberInbound.getAccount(newAcctName);
        acctList = [SELECT Id, Name FROM Account WHERE Id =: newlyCreated AND RecordTypeId =: smallBusinessAccountRecTypeId LIMIT 1];
        System.assert(acctList.size() == 1, 'An account with name '+newAcctName+' should have been created.');
        System.assert(acctList[0].Name == newAcctName, 'The name of the new account should be '+newAcctName+' and not '+acctList[0].Name+'.');
    }

    @IsTest
    static void testGetAccount_findExistingOne() {
        String newAcctName = TestDataFactory.createUniqueName('TestAccount');
        List<Account> acctList = [SELECT Id FROM Account WHERE Name =: newAcctName AND RecordTypeId =: smallBusinessAccountRecTypeId LIMIT 1];
        System.assert(acctList.size() == 0, 'An account with name '+newAcctName+' should not exist.');
        Account newAcct = new Account();
        newAcct.Name = newAcctName;
        newAcct.RecordTypeId = smallBusinessAccountRecTypeId;
        insert newAcct;
        acctList = [SELECT Id FROM Account WHERE Name =: newAcctName AND RecordTypeId =: smallBusinessAccountRecTypeId LIMIT 1];
        System.assert(acctList.size() == 1, 'Exactly one account with name '+newAcctName+' should exist.');
        Id existingAcctId = acctList[0].Id;

        // check that getAccount does not create a new one, but finds the existing one
        String existingAcct = CreateMemberInbound.getAccount(newAcctName);
        acctList = [SELECT Id, Name FROM Account WHERE Id =: existingAcct AND RecordTypeId =: smallBusinessAccountRecTypeId LIMIT 1];
        System.assert(acctList.size() == 1, 'getAccount should have returned exactly one account with name '+newAcctName+'.');
        System.assertEquals(newAcctName, acctList[0].Name, 'The name of the account returned by getAccount should be '+newAcctName+' and not '+acctList[0].Name+'.');
        System.assertEquals(existingAcctId, acctList[0].Id, 'The Id of the account returned by getAccount should be '+existingAcctId+' and not '+acctList[0].Id+'.');
    }

    @IsTest
    static void testInsertContact_createNewOne() {
        String newAcctName = TestDataFactory.createUniqueName('TestAccount');
        String newContactLastName = TestDataFactory.createUniqueName('TestContact');
        List<Account> acctList = [SELECT Id FROM Account WHERE Name =: newAcctName AND RecordTypeId =: smallBusinessAccountRecTypeId LIMIT 1];
        System.assert(acctList.size() == 0, 'An account with name '+newAcctName+' should not exist.');
        List<Contact> contList = [SELECT Id FROM Contact WHERE LastName =: newContactLastName AND RecordTypeId =:individualContactRecTypeId LIMIT 1];
        System.assert(contList.size() == 0, 'A contact with name '+newContactLastName+' should not exist.');
        Contact con =  new Contact(LastName=newContactLastName);
        CreateMemberInbound.insertContact(con, newAcctName);
        acctList = [SELECT Id FROM Account WHERE Name =: newAcctName AND RecordTypeId =: smallBusinessAccountRecTypeId LIMIT 1];
        System.assert(acctList.size() == 1, 'An account with name '+newAcctName+' should have been created.');
        contList = [SELECT Id, AccountId FROM Contact WHERE LastName =: newContactLastName AND RecordTypeId =:individualContactRecTypeId LIMIT 1];
        System.assert(contList.size() == 1, 'A contact with last name '+newContactLastName+' should have been created.');      
        System.assertEquals(acctList[0].Id, contList[0].AccountId, 'The newly created contact should be associated with the newly created account.');
    }

    @IsTest
    static void testInsertContact_existingContact() {
        String newAcctName = TestDataFactory.createUniqueName('TestAccount');
        String newContactLastName = TestDataFactory.createUniqueName('TestContact');
        List<Account> acctList = [SELECT Id FROM Account WHERE Name =: newAcctName AND RecordTypeId =: smallBusinessAccountRecTypeId LIMIT 1];
        System.assert(acctList.size() == 0, 'An account with name '+newAcctName+' should not exist.');
        List<Contact> contList = [SELECT Id FROM Contact WHERE LastName =: newContactLastName AND RecordTypeId =:individualContactRecTypeId LIMIT 1];
        System.assert(contList.size() == 0, 'A contact with name '+newContactLastName+' should not exist.');
        Contact con =  new Contact(LastName=newContactLastName);
        insert con;
        Id insertAgainContactId = CreateMemberInbound.insertContact(con, newAcctName);
        System.assertEquals(null, insertAgainContactId, 'Null should be returned when inserting an exsting contact.');
    }

    @IsTest
    static void testFindDuplicateContact() {
        String lastName = TestDataFactory.createUniqueName('Last');
        List<Contact> dupeList = TestDataFactory.createdListOfTwoDuplicateContacts('Joe', lastName, 'joe.'+lastName+'@test.com');
        Contact con1 = dupeList[0];
        Contact con2 = dupeList[1];
        List<Contact> listOfOne = new Contact[]{ con1 };
        Contact dupe = CreateMemberInbound.findDuplicateContact(listOfOne);
        System.assertNotEquals(null, dupe, 'Should have found a duplicate.');
        System.assertEquals(dupe.Id, con2.Id, 'The duplicate should be the second one.');
    }

    @IsTest
    static void testCreateProgLog_happy_path() {
        Program__c prog = TestDataFactory.createProgram('My Program', 'A very good program');
        Program_Log__c pl = CreateMemberInbound.createProgLog('This is a test', 'Success', prog.Id);
        System.assertNotEquals(null, pl, 'Should have created a program log.');
        System.assertEquals(pl.Program__c, prog.Id, 'The progam log has the wrong program Id.');  
    }

    @IsTest
    static void testCreateProgLog_bad_id() {
        Program_Log__c pl = CreateMemberInbound.createProgLog('This is a test', 'Success', 'bad_id');
        System.assertEquals(null, pl, 'Bad program Id should return null.');
    }

    @IsTest
    static void testCreateProgLog_bad_status() {
        Program__c prog = TestDataFactory.createProgram('My Program', 'A very good program');
        Program_Log__c progLog = CreateMemberInbound.createProgLog('This is a test', 'Bad status', prog.Id);
        System.assertEquals(null, progLog, 'Bad status should return null.');
    }

    @IsTest
    static void testFindMatchingProgramMember_happy_path() {
        // happy path
        String cohortName = TestDataFactory.createUniqueName('Cohort');
        Account cohort = new Account(Name=cohortName);
        insert cohort;
        System.assertNotEquals(null, cohort.Id);
        String lastName = TestDataFactory.createUniqueName('Last');
        Contact entrepreneur = new Contact();
        entrepreneur.LastName = lastName;
        entrepreneur.Firstname = 'Sam';
        entrepreneur.Email = 'sam.'+lastName+'@test.com';
        insert entrepreneur;
        System.assertNotEquals(null, entrepreneur.Id);
        String programName = TestDataFactory.createUniqueName('Program');
        Program__c program = TestDataFactory.createProgram(programName, 'A very good program');
        Program_Membership__c pm = new Program_Membership__c();
        pm.Program__c = program.Id;
        pm.Cohort__c = cohort.Id;
        pm.Individual__c = entrepreneur.Id;
        pm.Program_Members__c = cohort.Id;
        insert pm;
        Program_Membership__c matchingPm = CreateMemberInbound.findMatchingProgramMember(entrepreneur.Id, program.Id, cohort.Id);
        System.assertNotEquals(null, matchingPm, 'Should find a match.');
        System.assertEquals(entrepreneur.Id, matchingPm.Individual__c, 'The match should have our test entrepreneur');
        System.assertEquals(cohort.Id, matchingPm.Cohort__c, 'The match should have our test cohort.');
        System.assertEquals(program.Id, matchingPm.Program__c, 'The match should have our program.');
    }

    @IsTest
    static void testFindMatchingProgramMember_no_matching_contact() {
        String cohortName = TestDataFactory.createUniqueName('Cohort');
        Account cohort = new Account(Name=cohortName);
        insert cohort;
        System.assertNotEquals(null, cohort.Id);
        String lastName = TestDataFactory.createUniqueName('Last');
        Contact entrepreneur1 = new Contact();
        entrepreneur1.LastName = lastName;
        entrepreneur1.Firstname = 'Sam';
        entrepreneur1.Email = 'sam.'+lastName+'@test.com';
        insert entrepreneur1;
        System.assertNotEquals(null, entrepreneur1.Id);
        lastName = TestDataFactory.createUniqueName('Last');
        Contact entrepreneur2 = new Contact();
        entrepreneur2.LastName = lastName;
        entrepreneur2.Firstname = 'Sam';
        entrepreneur2.Email = 'sam.'+lastName+'@test.com';
        insert entrepreneur2;
        System.assertNotEquals(null, entrepreneur2.Id);
        String programName = TestDataFactory.createUniqueName('Program');
        Program__c program = TestDataFactory.createProgram(programName, 'A very good program');
        Program_Membership__c pm = new Program_Membership__c();
        pm.Program__c = program.Id;
        pm.Cohort__c = cohort.Id;
        pm.Program_Members__c = cohort.Id;
        pm.Individual__c = entrepreneur1.Id;
        insert pm;
        // pm was created with entrepreneur1, but we search for entrepreneur2
        Program_Membership__c dupePm = CreateMemberInbound.findMatchingProgramMember(entrepreneur2.Id, program.Id, cohort.Id);
        System.assertEquals(null, dupePm, 'Should not find a match.');
    }

    @IsTest
    static void testFindMatchingProgramMember_bad_arguments() {
        Program_Membership__c matchingPm = CreateMemberInbound.findMatchingProgramMember(null, null, null);
        System.assertEquals(null, matchingPm, 'Should not find a match.');
        matchingPm = CreateMemberInbound.findMatchingProgramMember('bad string', 'very bad', 'ohhh');
        System.assertEquals(null, matchingPm, 'Should not find a match.');
    }

    @IsTest
    static void testGetOrCreateProgramMember_find_existing() {
        // happy path
        String cohortName = TestDataFactory.createUniqueName('Cohort');
        Account cohort = new Account(Name=cohortName);
        insert cohort;
        System.assertNotEquals(null, cohort.Id);
        String lastName = TestDataFactory.createUniqueName('Last');
        Contact entrepreneur = new Contact();
        entrepreneur.LastName = lastName;
        entrepreneur.Firstname = 'Sam';
        entrepreneur.Email = 'sam.'+lastName+'@test.com';
        insert entrepreneur;
        System.assertNotEquals(null, entrepreneur.Id);
        String programName = TestDataFactory.createUniqueName('Program');
        Program__c program = TestDataFactory.createProgram(programName, 'A very good program');
        Program_Membership__c pm = new Program_Membership__c();
        pm.Program__c = program.Id;
        pm.Cohort__c = cohort.Id;
        pm.Individual__c = entrepreneur.Id;
        pm.Program_Members__c = cohort.Id;
        insert pm;
        Program_Membership__c getPm = CreateMemberInbound.getOrCreateProgramMember(entrepreneur.Id, program.Id, cohort.Id);
        System.assertNotEquals(null, getPm, 'Should find one.');
        System.assertEquals(entrepreneur.Id, getPm.Individual__c, 'The program member should have our test entrepreneur');
        System.assertEquals(cohort.Id, getPm.Cohort__c, 'The program member should have our test cohort.');
        System.assertEquals(program.Id, getPm.Program__c, 'The program member should have our program.');
    }

    @IsTest
    static void testGetOrCreateProgramMember_create_new() {
        // happy path
        String cohortName = TestDataFactory.createUniqueName('Cohort');
        Account cohort = new Account(Name=cohortName);
        insert cohort;
        System.assertNotEquals(null, cohort.Id);
        String lastName = TestDataFactory.createUniqueName('Last');
        Contact entrepreneur = new Contact();
        entrepreneur.LastName = lastName;
        entrepreneur.Firstname = 'Sam';
        entrepreneur.Email = 'sam.'+lastName+'@test.com';
        insert entrepreneur;
        System.assertNotEquals(null, entrepreneur.Id);
        String programName = TestDataFactory.createUniqueName('Program');
        Program__c program = TestDataFactory.createProgram(programName, 'A very good program');
        Program_Membership__c createPm = CreateMemberInbound.getOrCreateProgramMember(entrepreneur.Id, program.Id, cohort.Id);
        System.assertNotEquals(null, createPm, 'Should have created one.');
        System.assertEquals(entrepreneur.Id, createPm.Individual__c, 'The program member should have our test entrepreneur');
        System.assertEquals(cohort.Id, createPm.Cohort__c, 'The program member should have our test cohort.');
        System.assertEquals(program.Id, createPm.Program__c, 'The program member should have our program.');
    }

    @IsTest
    static void testGetOrCreateProgramMember_null_arguments() {
        Program_Membership__c pm = CreateMemberInbound.getOrCreateProgramMember(null, null, null);
        System.assertEquals(null, pm, 'Should return null.');
        pm = CreateMemberInbound.getOrCreateProgramMember('bad string', 'badder', 'worst');
        System.assertEquals(null, pm, 'Should return null.');
    }

   @IsTest
    static void testGetOrCreateProgramPartnerMember_find_existing() {
        // happy path
        String cohortName = TestDataFactory.createUniqueName('Cohort');
        Account cohort = new Account(Name=cohortName);
        insert cohort;
        System.assertNotEquals(null, cohort.Id);
        String programName = TestDataFactory.createUniqueName('Program');
        Program__c program = TestDataFactory.createProgram(programName, 'A very good program');
        Program_Partner_Membership__c ppm = new Program_Partner_Membership__c();
        ppm.Program__c = program.Id;
        ppm.Cohort__c = cohort.Id;
        insert ppm;
        Program_Partner_Membership__c getPpm = CreateMemberInbound.getOrCreateProgramPartnerMember(program.Id, cohort.Id);
        System.assertNotEquals(null, getPpm, 'Should find one.');
        System.assertEquals(cohort.Id, getPpm.Cohort__c, 'The program partner member should have our test cohort.');
        System.assertEquals(program.Id, getPpm.Program__c, 'The program partner member should have our program.');
    }

    @IsTest
    static void testGetOrCreateProgramPartnerMember_create_new() {
        // happy path
        String cohortName = TestDataFactory.createUniqueName('Cohort');
        Account cohort = new Account(Name=cohortName);
        insert cohort;
        System.assertNotEquals(null, cohort.Id);
        String programName = TestDataFactory.createUniqueName('Program');
        Program__c program = TestDataFactory.createProgram(programName, 'A very good program');
        Program_Partner_Membership__c createPpm = CreateMemberInbound.getOrCreateProgramPartnerMember(program.Id, cohort.Id);
        System.assertNotEquals(null, createPpm, 'Should have created one.');
        System.assertEquals(cohort.Id, createPpm.Cohort__c, 'The program partner member should have our test cohort.');
        System.assertEquals(program.Id, createPpm.Program__c, 'The program partner member should have our program.');
    }

    @IsTest
    static void testGetOrCreateProgramParnerMember_bad_arguments() {
        Program_Partner_Membership__c ppm = CreateMemberInbound.getOrCreateProgramPartnerMember(null, null);
        System.assertEquals(null, ppm, 'Should return null.');
        ppm = CreateMemberInbound.getOrCreateProgramPartnerMember('bad string', 'badder');
        System.assertEquals(null, ppm, 'Should return null.');
    }

    @IsTest 
    static void testCreateMember_happy_path_contact_does_not_exist_yet() {
        String firstName = 'Sam';
        String lastName = TestDataFactory.createUniqueName('Last');
        String email = firstName+'.'+lastName+'@test.com';
        String businessName = TestDataFactory.createUniqueName('Business');
        String programName = TestDataFactory.createUniqueName('Program');
        Program__c program = TestDataFactory.createProgram(programName, 'A very good program');
        String cohortName = TestDataFactory.createUniqueName('Cohort');
        Account cohort = new Account(Name=cohortName);
        insert cohort;

        Program_Membership__c pm = CreateMemberInbound.createMember(
            firstName, 
            lastName, 
            email, 
            businessName, 
            program.Id, 
            cohort.Id);
        
        system.assertNotEquals(null, pm);
        List<Contact> memberList = [SELECT Id, FirstName, LastName, Email, AccountId FROM Contact WHERE Id =: pm.Individual__c LIMIT 1];
        system.assertEquals(1,memberList.size(),'Exactly one program member should have been created.');
        Contact member = memberList[0];
        system.assertEquals(firstName, member.FirstName);
        system.assertEquals(lastName, member.LastName);
        system.assertEquals(email.toLowerCase(), member.Email);
        Account memberCohort = [SELECT Id, Name FROM Account WHERE Id =: pm.Cohort__c LIMIT 1];
        system.assertNotEquals(null, memberCohort);
        system.assertEquals(cohort.Id, pm.Cohort__c);
        system.assertEquals(cohortName, memberCohort.Name);
        system.assertEquals(program.Id, pm.Program__c);

    }

    @IsTest 
    static void testCreateMember_happy_path_contact_exists() {
        String firstName = 'Sam';
        String lastName = TestDataFactory.createUniqueName('Last');
        String email = firstName+'.'+lastName+'@test.com';
        String businessName = TestDataFactory.createUniqueName('Business');
        String programName = TestDataFactory.createUniqueName('Program');
        Program__c program = TestDataFactory.createProgram(programName, 'A very good program');
        String cohortName = TestDataFactory.createUniqueName('Cohort');
        Account cohort = new Account(Name=cohortName);
        insert cohort;
        Account memberBusiness = new Account();
        memberBusiness.Name = businessName;
        insert memberBusiness;
        Contact member = new Contact();
        member.FirstName = firstName;
        member.LastName = lastName;
        member.Email = email;
        member.AccountId = memberBusiness.Id;
        insert member;

        Program_Membership__c pm = CreateMemberInbound.createMember(
            firstName, 
            lastName, 
            email, 
            businessName, 
            program.Id, 
            cohort.Id);
        
        Contact pmMember = [SELECT Id, FirstName, LastName, Email, AccountId FROM Contact WHERE Id =: pm.Individual__c LIMIT 1];
        system.assertNotEquals(null, pmMember);
        system.assertEquals(member.Id, pmMember.id);
        Account pmMemberAccount = [SELECT Id, Name FROM Account WHERE Id =: pmMember.AccountId];
        system.assertNotEquals(null, pmMemberAccount);
        system.assertEquals(member.AccountId, pmMemberAccount.Id);
        system.assertEquals(pmMemberAccount.Name, businessName);
        system.assertEquals(cohort.Id, pm.Cohort__c);
        system.assertEquals(program.Id, pm.Program__c);

    }

    @IsTest
    static void testCreateMember_bad_arguments() {
        Program_Membership__c member = CreateMemberInbound.createMember(null, null, null, null, null, null);
        System.assertEquals(null, member, 'Should return null.');
        member = CreateMemberInbound.createMember('bad string', 'badder', 'worst', 'some', 'more', 'text');
        System.assertEquals(null, member, 'Should return null.');
    }

    @IsTest
    static void testCreateMember_invalid_ids() {
        Program_Membership__c member = CreateMemberInbound.createMember(null, null, null, null, null, null);
        System.assertEquals(null, member, 'Should return null.');
        member = CreateMemberInbound.createMember('bad string', 'badder', 'worst', 'some', 'more', 'text');
        System.assertEquals(null, member, 'Should return null.');
    }

    @IsTest
    static void testTempWithData() {
        Program_Membership__c pmem = CreateMemberInbound.createMember(
            'Lene',
            'Tsegaye',
            'emnet98@verizon.net',
            'Ouley Hair Gallery LLC,',
            'a0R75000000AOrLEAW',
            '00175000007cOaxAAE'
        );
        //system.assertNotEquals(null, pmem, 'Should not be null');
    }

}