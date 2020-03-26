@IsTest
public class CrmCanvasPrefillTest {
    @IsTest static void testGetMethodReturns200() {

        Account account1 = new Account(
                FirstName = 'John',
                LastName = 'Kowalsky',
                RecordTypeId = Schema.SObjectType.Account
                        .getRecordTypeInfosByDeveloperName()
                        .get('PersonAccount')
                        .getRecordTypeId(),
                FinServ__SourceSystemId__c = 'extId:1'
        );
        insert account1;

        Opportunity personalOpportunity;
        personalOpportunity = new Opportunity(
                Name = 'Test Op',
                RecordTypeId = Schema.SObjectType.Opportunity
                        .getRecordTypeInfosByDeveloperName()
                        .get('Insurance_P_C')
                        .getRecordTypeId(),
                CloseDate = Date.today().addDays(10),
                StageName = 'Needs Analysis',
                AccountId = account1.Id,
                gw_crm__PC_Job_Id__c = 'JobNumber',
                gw_crm__PC_Id__c = 'pc:101'
        );
        insert personalOpportunity;

        Test.startTest();
        initRestContext(personalOpportunity.Id);
        CrmCanvasPrefillResource.retrievePrefillData();

        System.assertEquals(200, RestContext.response.statusCode);

        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(
                RestContext.response.responseBody.toString());

        String foundName = (String) responseBody.get('Name');

        System.assertEquals('John Kowalsky', foundName);
        Test.stopTest();
    }

    @IsTest static void testGetMethodReturns400() {

        Test.startTest();
        initRestContext(null);
        CrmCanvasPrefillResource.retrievePrefillData();
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(
                RestContext.response.responseBody.toString());
        Object httpStatus = responseBody.get('httpStatus');
        System.assertEquals(400, httpStatus);
        Test.stopTest();
    }

    @IsTest static void testGetMethodReturns404() {

        Test.startTest();
        initRestContext('empty_id');
        CrmCanvasPrefillResource.retrievePrefillData();
        System.assertEquals(404, RestContext.response.statusCode);
        Test.stopTest();
    }

    private static void initRestContext(String oppId) {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/v1/sync/prefill/';
        if(!String.isBlank(oppId)){
            req.requestURI = req.requestURI + '?oppId=' + oppId;
            req.params.put('oppId', oppId);
        }
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
    }
}