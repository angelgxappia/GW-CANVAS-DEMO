public class CrmOpportunityPrefillController {
    @AuraEnabled
    public static Map<String, Object> findAccount(String oppId) {
        Map<String, Object> result = new Map<String, Object>();
        Opportunity[] opportunities = [
                SELECT AccountId
                FROM Opportunity
                WHERE Id = :oppId
                LIMIT 1
        ];
        if (opportunities.size() == 0) {
            return result;
        }
        Account[] accounts = [
                SELECT Name, BillingAddress
                FROM Account
                WHERE Id = :opportunities[0].AccountId
                LIMIT 1
        ];

        if (accounts.size() == 0) {
            return result;
        } else {
            result.put('Name', accounts[0].Name);
            result.put('BillingAddress', accounts[0].BillingAddress);
        }

        return result;
    }
}