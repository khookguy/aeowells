@isTest 
public class GettingStartedController_Test {
    
    static testMethod void serverGetUserAndCohort_Test() {

        String programName = 'TestProgram';
        Account cohortAcct = new Account (Name='TestCohort');
        insert cohortAcct;
        Account cohort = [SELECT Id FROM Account WHERE Name = 'TestCohort' LIMIT 1];
        Program__c programForCohort = new Program__c(Name=programName, Organization__c=cohort.Id);
        insert programForCohort;
        Program__c program = [SELECT Id, Name, Organization__c from Program__c WHERE Name = :programName LIMIT 1];
        Program_Partner_Membership__c ppm = new Program_Partner_Membership__c(Program__c=program.Id,Cohort__c=cohort.Id);
        ppm.Bitly_Link_To_Resili__c = 'https://bit.ly/3uSwAcG';
        ppm.Bitly_Link_to_Post_Coaching_Survey__c = 'https://bit.ly/3vC2bjn';
        insert ppm;

        // create the sys admin user inside test because it needs to be a future
        Test.startTest();
        String sysAdminUsername = System.now().millisecond() + 'sysadmin@test.com';
        GettingStartedController_Test.createSystemAdminUser(sysAdminUsername);
        Test.stopTest();

        User sysAdminUser = [SELECT Id, Username FROM User WHERE Username = :sysAdminUsername LIMIT 1];
        // Create a Cohort contact as portal user
        System.runAs ( sysAdminUser ) {
            //Create contact
            Contact contact1 = new Contact(
                FirstName = 'Test',
                Lastname = 'McTesty',
                AccountId = cohort.Id,
                Email = System.now().millisecond() + 'test@test.com'
            );
            Database.insert(contact1);
            
            //Create user
            Profile portalProfile = [SELECT Id FROM Profile where name like '%Cohort Community User%' Limit 1];
            User portalUser = new User(
                Username = System.now().millisecond() + 'test12345@test.com',
                ContactId = contact1.Id,
                ProfileId = portalProfile.Id,
                Alias = 'test123',
                Email = 'test12345@test.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'McTesty',
                CommunityNickname = 'test12345',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_US',
                LanguageLocaleKey = 'en_US'
            );
            Database.insert(portalUser);
        }
        
        /**
         * When running as the portal user, the method serverGetUserAndCohort should return the 
         * contact and account of that portal user.
         */
        User portalUser = [Select Id, ContactId, AccountId from user where Alias = 'test123' limit 1 ];
        String userCohortJson;
        System.runAs ( portalUser ) {
            userCohortJson = GettingStartedController.serverGetUserCohortAndLinks(programName);
        }

        Map<String,String> userCohort = (Map<String,String>) JSON.deserialize(userCohortJson, Map<String,String>.class);
        String userId = userCohort.get('userId');
        String cohortId = userCohort.get('cohortId');
        String bitlyResili = userCohort.get('bitlyResili');
        String bitlyPostCoach = userCohort.get('bitlyPostCoach');
        System.assertEquals(portalUser.Id, userId);
        System.assertEquals(cohort.Id, cohortId);
        System.assertEquals(ppm.Bitly_Link_To_Resili__c, bitlyResili);
        System.assertEquals(ppm.Bitly_Link_to_Post_Coaching_Survey__c, bitlyPostCoach);
    }

    @future
    public static void createSystemAdminUser(String username) {
        UserRole sysAdminRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
        system.debug('portalRole is ' + sysAdminRole);
        Profile sysAdminProfile = [Select Id from Profile where name = 'System Administrator'];
        User sysAdminUser = new User(
            UserRoleId = sysAdminRole.Id,
            ProfileId = sysAdminProfile.Id,
            Username = username,
            Alias = 'batman',
            Email='bruce.wayne@wayneenterprises.com',
            EmailEncodingKey='UTF-8',
            Firstname='Bruce',
            Lastname='Wayne',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            TimeZoneSidKey='America/Chicago'
        );
        Database.insert(sysAdminUser);
    }
}