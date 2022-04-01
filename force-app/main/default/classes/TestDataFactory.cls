@isTest
public class TestDataFactory {

    public static String createUniqueName(String namePrefix) {
        return namePrefix + '_' + Datetime.now().millisecondGmt();
    }

    public static List<Contact> createdListOfTwoDuplicateContacts(String firstName, String lastName, String email) {
        List<Contact> dupeList = new List<Contact>();
        Contact con1 = new Contact(FirstName=firstName, LastName=lastName, Email=email);
        Contact con2 = new Contact(FirstName=firstName, LastName=lastName, Email=email);
        insert con1;
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true; 
        Database.SaveResult sr = Database.insert(con2, dml); 
        dupeList.add(con1);
        dupeList.add(con2);
        return dupeList;
    }

    public static Program__c createProgram(String programName, String description) {
        List<Program__c> progList = [SELECT Id FROM Program__c WHERE Name =: programName];
        if (!progList.isEmpty()) {
            return null;
        }
        Account accRec = new Account(Name='TestAcc');
        insert accRec;
        Program__c prog = new Program__c();
        prog.Name = programName;
        prog.Description__c = description;
        prog.Organization__c = accRec.Id;
        insert prog;
        return prog;
    }

}