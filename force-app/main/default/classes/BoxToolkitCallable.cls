/**
 * BoxToolkitCallable
 * Callable facade over Box Toolkit operations.
 */
@JsonAccess(serializable='always')
global with sharing class BoxToolkitCallable implements System.Callable {
    private static final String METHOD_POST = 'POST';
    private static final String CONTENT_TYPE_HEADER = 'Content-Type';
    private static final String APPLICATION_ENCODED_HEADER = 'application/x-www-form-urlencoded';
    private static final String APPLICATION_JSON_HEADER = 'application/json';
    private static final String TOKEN_URL_STRING = 'https://api.box.com/oauth2/token';
    private static final String EXTRACT_URL_STRING = 'https://api.box.com/2.0/ai/extract_structured';
    private static final String KEY_INPUT   = 'input';
    private static final String KEY_OUTPUT  = 'output';
    private static final String KEY_OPTIONS = 'options';

    // =========================
    // Define toolkit variables
    // =========================
    private final box.Toolkit toolkit;
    private final box.BoxAIToolkit aiToolkit;

    /**
     * Default constructor - initializes Toolkit dependencies.
     */
    global BoxToolkitCallable() {
        this.toolkit = new box.Toolkit();
        this.aiToolkit = new box.BoxAIToolkit();
    }

    /**
     * Constructor allowing Toolkit injection (useful for testing).
     * @param toolkit Existing Toolkit instance to use
     */
    global BoxToolkitCallable(box.Toolkit toolkit) {
        if (toolkit == null) {
            throw new BoxToolkitCallableException('Toolkit instance cannot be null');
        }
        this.toolkit = toolkit;
        this.aiToolkit = new box.BoxAIToolkit();
    }

    /**
     * Main entry point for the Callable interface. Routes the action to the appropriate Toolkit method.
     * @param action The name of the Toolkit method to invoke
     * @param args Map containing envelopes: input, output, options
     * @return The result envelope (output map)
     */
    global Object call(String action, Map<String, Object> args) {
        if (String.isBlank(action)) {
            throw new BoxToolkitCallableException('Action parameter cannot be null or blank');
        }
        if (args == null) {
            args = new Map<String, Object>();
        }

        // Extract envelopes, defaulting to empty maps
        Map<String, Object> input   = (Map<String, Object>) args.get(KEY_INPUT);
        Map<String, Object> output  = (Map<String, Object>) args.get(KEY_OUTPUT);
        Map<String, Object> options = (Map<String, Object>) args.get(KEY_OPTIONS);
        if (input == null)   input = new Map<String, Object>();
        if (output == null)  output = new Map<String, Object>();
        if (options == null) options = new Map<String, Object>();

        // Normalize action string
        String normalized;
        try {
            normalized = action == null ? null : String.valueOf(action).trim().toLowerCase();
        } catch (Exception e) {
            throw new BoxToolkitCallableException(String.format('Unknown action: {0}', new List<String>{ (String) action }));
        }
        if (String.isBlank(normalized)) {
            throw new BoxToolkitCallableException('Action parameter cannot be null or blank');
        }

        // Route to the appropriate method based on action
        switch on normalized {
            when 'downscopetoken' {
                return downscopeToken(input, output);
            }
            when 'createfolderforrecordid' {
                return createFolderForRecordId(input, output);
            }
            when 'pushfiletobox' {
                return pushFileToBox(input, output);
            }
            when 'createcollaborationonrecord' {
                return createCollaborationOnRecord(input, output);
            }
            when 'createboxmetadatabyfileid' {
                return createBoxMetadataByFileId(input, output);
            }
            when 'askboxai' {
                return askBoxAI(input, output);
            }
            when 'extract' {
                return extract(input, output);
            }
            when 'sendsignrequest' {
                return sendSignRequest(input, output);
            }
            when 'sendrequest' {
                return sendRequest(input, output);
            }
            when else {  
                throw new BoxToolkitCallableException(String.format('Unknown action: {0}', new List<String>{ normalized }));
            }
        }
    }

    // ========================================
    // Folder Operations
    // ========================================
    private Object downscopeToken(Map<String, Object> input, Map<String, Object> output) {
        System.debug('Starting downscopeToken operation with input: ' + input);
        String clientId = (String) input.get('clientId');
        if (clientId == null) {
            throw new BoxToolkitCallableException('clientId is required');
        }

        String clientSecret = (String) input.get('clientSecret');
        if (clientSecret == null) {
            throw new BoxToolkitCallableException('clientSecret is required');
        }

        String boxSubjectType = (String) input.get('boxSubjectType');
        if (boxSubjectType == null) {
            throw new BoxToolkitCallableException('boxSubjectType is required');
        }

        String boxSubjectId = (String) input.get('boxSubjectId');
        if (boxSubjectId == null) {
            throw new BoxToolkitCallableException('boxSubjectId is required');
        }

        String scopes = (String) input.get('scopes');
        if (scopes == null) {
            throw new BoxToolkitCallableException('scopes is required');
        }

        String resource = (String) input.get('resource');
        if (resource == null) {
            throw new BoxToolkitCallableException('resource is required');
        }

        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod(METHOD_POST);
        httpRequest.setEndpoint(TOKEN_URL_STRING);
        httpRequest.setTimeout(60000);
        httpRequest.setHeader(CONTENT_TYPE_HEADER, APPLICATION_ENCODED_HEADER);

        String urlParameters = String.format(
                'grant_type=client_credentials&client_id={0}&client_secret={1}&box_subject_type={2}&box_subject_id={3}',
                new List<String>{
                    clientId,
                    clientSecret,
                    boxSubjectType,
                    boxSubjectId
                });

        httpRequest.setBody(urlParameters);
        Http http = new Http();
        HttpResponse response = http.send(httpRequest);
        System.debug('Found accessToken: ' + response.getBody());
        Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());

        urlParameters = String.format(
        'grant_type={0}&subject_token={1}&subject_token_type={2}&scope={3}&resource={4}',
        new List<String>{
            'urn:ietf:params:oauth:grant-type:token-exchange',
            String.valueOf(responseMap.get('access_token')),
            'urn:ietf:params:oauth:token-type:access_token',
            scopes,
            resource
        });
        httpRequest.setBody(urlParameters);
        response = http.send(httpRequest);
        System.debug('Found downscoped token: ' + response.getBody());
        responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
        Map<String, Object> result = new Map<String, Object> { 'accessToken' => responseMap.get('access_token') };
     
        output.put('result', result);
        return output;
        }

    // ========================================
    // Folder Operations
    // ========================================
    private Object createFolderForRecordId(Map<String, Object> input, Map<String, Object> output) {
        Id recordId = (Id) input.get('recordId');
        if (recordId == null) {
            throw new BoxToolkitCallableException('recordId is required');
        }
        String folderNameOverride = (String) input.get('folderNameOverride');
        Boolean optCreateRootFolder = (Boolean) input.get('optCreateRootFolder');

        String folderId = toolkit.createFolderForRecordId(recordId, folderNameOverride, optCreateRootFolder);
        toolkit.commitChanges();
        Map<String, Object> result = new Map<String, Object>{ 'folderId' => folderId };
        output.put('result', result);
        return output;
    }

    // ========================================
    // Box AI Operations
    // ========================================
    private Object askBoxAI(Map<String, Object> input, Map<String, Object> output) {
        // Validate and normalize items
        String itemsObject = JSON.serialize(input.get('items'), true);
        System.debug('Received items object: ' + itemsObject);
        if (itemsObject == null) {
            throw new BoxToolkitCallableException('items are required for askBoxAI');
        }
        List<box.AIItem> items = (List<box.AIItem>) JSON.deserialize(itemsObject, List<box.AIItem>.class);

        if (items == null || items.isEmpty()) {
            throw new BoxToolkitCallableException('items are required for askBoxAI');
        }

        // Validate prompt
        String prompt = (String) input.get('prompt');
        if (String.isBlank(prompt)) {
            throw new BoxToolkitCallableException('prompt is required for askBoxAI');
        }

        // Execute and shape output
        Object answer = aiToolkit.askBoxAI(items, prompt);
        output.put('answer', answer);
        return output;
    }

    private Object extract(Map<String, Object> input, Map<String, Object> output) {
        // Validate required inputs
        String templateKey = (String) input.get('templateKey');
        if (String.isBlank(templateKey)) {
            throw new BoxToolkitCallableException('templateKey is required for extract');
        }
        String fileId = (String) input.get('fileId');
        if (String.isBlank(fileId)) {
            throw new BoxToolkitCallableException('fileId is required for extract');
        }

        // Build items payload
        List<Map<String, Object>> items = new List<Map<String, Object>>();
        Map<String, Object> fileItem = new Map<String, Object>{
            'type' => 'file',
            'id'   => fileId
        };
        items.add(fileItem);

        // Read optional flags with sane defaults
        Boolean includeConfidenceScores = (input.containsKey('includeConfidenceScores') 
            ? Boolean.valueOf(input.get('includeConfidenceScores')) 
            : true);
        if (includeConfidenceScores == null) {
            includeConfidenceScores = true;
        }

        // Build extract request payload
        Map<String, Object> metadataTemplateMap = new Map<String, Object>{
            'scope'        => 'enterprise',
            'type'         => 'metadata_template',
            'template_key' => templateKey
        };
        Map<String, Object> extractRequestMap = new Map<String, Object>{
            'include_confidence_score' => true,
            'metadata_template'        => metadataTemplateMap,
            'items'                    => items
        };

        // Invoke Box AI extract endpoint
        HttpRequest httpRequest = new HttpRequest();
        httpRequest.setMethod(METHOD_POST);
        httpRequest.setEndpoint(EXTRACT_URL_STRING);
        httpRequest.setTimeout(60000);
        httpRequest.setHeader(CONTENT_TYPE_HEADER, APPLICATION_JSON_HEADER);
        httpRequest.setBody(JSON.serialize(extractRequestMap, true));

        HttpResponse httpResp = toolkit.sendRequest(httpRequest);
        String body = httpResp != null ? httpResp.getBody() : null;
        if (String.isBlank(body)) {
            throw new BoxToolkitCallableException('Empty response from Box AI extract endpoint');
        }

        // Parse response and shape result
        Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(body);
        Map<String, Object> answerMap = (Map<String, Object>) respMap.get('answer');
        Map<String, Object> confidenceScoreMap = (Map<String, Object>) respMap.get('confidence_score');

        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        if (answerMap != null) {
            for (String key : answerMap.keySet()) {
                Map<String, Object> row = new Map<String, Object>{
                    'key'        => key,
                    'value'      => answerMap.get(key),
                    'confidence' => (confidenceScoreMap != null ? confidenceScoreMap.get(key) : null)
                };
                resultList.add(row);
            }
        }

        output.put('result', resultList);
        return output;
    }

    // ========================================
    // File Operations
    // ========================================
    private Object pushFileToBox(Map<String, Object> input, Map<String, Object> output) {
        Id contentVersionId = (Id) input.get('contentVersionId');
        if (contentVersionId == null) {
            throw new BoxToolkitCallableException('contentVersionId is required');
        }
        String folderId = (String) input.get('folderId');
        if (String.isBlank(folderId)) {
            throw new BoxToolkitCallableException('folderId is required');
        }

        Object result = toolkit.pushFileToBox(contentVersionId, folderId);
        output.put('result', result);
        return output;
    }

    private Object createBoxMetadataByFileId(Map<String, Object> input, Map<String, Object> output) {
        String boxFileId = (String) input.get('fileId');
        if (String.isBlank(boxFileId)) {
            throw new BoxToolkitCallableException('fileId is required');
        }
        String scope = (String) input.get('scope');
        if (String.isBlank(scope)) {
            scope = 'enterprise';
        }
        String templateKey = (String) input.get('templateKey');
        if (String.isBlank(templateKey)) {
            throw new BoxToolkitCallableException('templateKey is required');
        }
        List<box.KeyValuePair> keyValuePairs = (List<box.KeyValuePair>) input.get('keyValuePairs');
        if (keyValuePairs == null) {
            keyValuePairs = new List<box.KeyValuePair>();
        }

        Object result = toolkit.createBoxMetadataByFileId(boxFileId, scope, templateKey, keyValuePairs);
        output.put('result', result);
        return output;
    }

    // ========================================
    // Collaboration Operations
    // ========================================
    private Object createCollaborationOnRecord(Map<String, Object> input, Map<String, Object> output) {
        Id userId = (Id) input.get('userId');
        if (userId == null) {
            throw new BoxToolkitCallableException('userId is required');
        }
        Id recordId = (Id) input.get('recordId');
        if (recordId == null) {
            throw new BoxToolkitCallableException('recordId is required');
        }
        box.Toolkit.CollaborationType collabType = (box.Toolkit.CollaborationType) input.get('collabType');
        if (collabType == null) {
            throw new BoxToolkitCallableException('collaboratorType is required');
        }
        Boolean optCreateFolder = (Boolean) input.get('optCreateFolder');

        Object result = toolkit.createCollaborationOnRecord(userId, recordId, collabType, optCreateFolder);
        output.put('result', result);
        return output;
    }

    // ========================================
    // Box Sign Operations  
    // ========================================
    private Object sendSignRequest(Map<String, Object> input, Map<String, Object> output) {

        List<box.BoxSignRequest> signRequestList = (List<box.BoxSignRequest>) input.get('signRequests');
        
        if (signRequestList == null || signRequestList.isEmpty()) {
            throw new BoxToolkitCallableException('signRequests are required');
        }

        Object result = box.BoxSignService.sendSignRequests(signRequestList);
        output.put('result', result);
        return output;
    }

    // ========================================
    // Utility Methods
    // ========================================
    private Object sendRequest(Map<String, Object> input, Map<String, Object> output) {
        String httpRequestString = (String) input.get('httpRequestString');
        if (String.isBlank(httpRequestString)) {
            throw new BoxToolkitCallableException('httpRequestString is required');
        }
        HttpRequest httpRequest;
        try {
            httpRequest = (HttpRequest) JSON.deserialize(httpRequestString, HttpRequest.class);
        } catch (Exception e) {
            throw new BoxToolkitCallableException('Failed to deserialize httpRequestString: ' + e.getMessage());
        }
        if (httpRequest == null) {
            throw new BoxToolkitCallableException('Deserialized HttpRequest cannot be null');
        }

        Object result = toolkit.sendRequest(httpRequest);
        output.put('result', result);
        return output;
    }

    /**
     * Domain-specific exception.
     */
    public class BoxToolkitCallableException extends Exception {}
}
