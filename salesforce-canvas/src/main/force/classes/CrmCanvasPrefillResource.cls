@RestResource(urlMapping='/v1/sync/prefill/*')
global with sharing class CrmCanvasPrefillResource {
    private static final String OPP_ID_PROP = 'oppId';
    @TestVisible
    private static final String INTEGRATION_ERROR = 'System.IntegrationException ';
    @TestVisible
    private static final String INTEGRATION_ERROR_REASON = 'REASON: Request must contain url parameter: ' + OPP_ID_PROP;


    @HttpGet
    global static void retrievePrefillData() {
        try {
            validateSearchRequest(RestContext.request, RestContext.response);
            String oppId = RestContext.request.params.get(OPP_ID_PROP);
            if(oppId == null){
                return;
            }
            Map<String, Object> accountDetails = CrmOpportunityPrefillController.findAccount(oppId);
            if (accountDetails.isEmpty()) {
                RestContext.response.statusCode = 404;
            } else {
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(JSON.serialize(accountDetails));
                RestContext.response.statusCode = 200;
            }
        } catch (Exception e) {
            System.debug(e);
            Map<String, Object> responseBody = new Map<String, Object> ();

            responseBody.put('userMessage', 'ERROR TYPE: ' + e.getMessage());
            responseBody.put('errorCode', 'SF_5001');
            responseBody.put('httpStatus', 500);
            responseBody.put('severity', 'ERROR');
            responseBody.put('retryable', false);
            responseBody.put('success', false);

            RestContext.response.responseBody = Blob.valueOf(JSON.serialize(responseBody));
        }
    }

    private static void validateSearchRequest(RestRequest request, RestResponse resp) {
        String oppIdProp = request.params.get(OPP_ID_PROP);
        if (String.isBlank(oppIdProp)) {
            Map<String, Object> responseBody = new Map<String, Object> ();

            responseBody.put('userMessage', 'ERROR TYPE: ' + INTEGRATION_ERROR + INTEGRATION_ERROR_REASON);
            responseBody.put('errorCode', 'SF_4002');
            responseBody.put('httpStatus', 400);
            responseBody.put('severity', 'ERROR');
            responseBody.put('retryable', false);
            responseBody.put('success', false);

            resp.responseBody = Blob.valueOf(JSON.serialize(responseBody));
        }
    }

}