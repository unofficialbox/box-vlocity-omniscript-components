/**
 * BoxToolkitCallable
 * Callable facade over Box Toolkit operations.
 */
@JsonAccess(serializable='always')
global with sharing class BoxToolkitCallable implements System.Callable {

    private static final String KEY_INPUT   = 'input';
    private static final String KEY_OUTPUT  = 'output';
    private static final String KEY_OPTIONS = 'options';

    // =========================
    // Dependencies
    // =========================
    private final box.Toolkit toolkit;
    private final box.BoxAIToolkit aiToolkit;
    private final box.BoxSignRequest signRequest;

    /**
     * Default constructor - initializes Toolkit dependencies.
     */
    global BoxToolkitCallable() {
        this.toolkit = new box.Toolkit();
        this.aiToolkit = new box.BoxAIToolkit();
        this.signRequest = new box.BoxSignRequest();
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
        this.signRequest = new box.BoxSignRequest();
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
    private Object createFolderForRecordId(Map<String, Object> input, Map<String, Object> output) {
        Id recordId = (Id) input.get('recordId');
        if (recordId == null) {
            throw new BoxToolkitCallableException('recordId is required');
        }
        String folderNameOverride = (String) input.get('folderNameOverride');
        Boolean optCreateRootFolder = (Boolean) input.get('optCreateRootFolder');

        String folderId = toolkit.createFolderForRecordId(recordId, folderNameOverride, optCreateRootFolder);
        Map<String, Object> result = new Map<String, Object>{ 'folderId' => folderId };
        output.put('result', result);
        return output;
    }

    // ========================================
    // Box AI Operations
    // ========================================
    private Object askBoxAI(Map<String, Object> input, Map<String, Object> output) {
        List<box.AIItem> items = (List<box.AIItem>) input.get('items');
        if (items == null || items.isEmpty()) {
            throw new BoxToolkitCallableException('items are required for askBoxAI');
        }
        String prompt = (String) input.get('prompt');
        if (String.isBlank(prompt)) {
            throw new BoxToolkitCallableException('prompt is required for askBoxAI');
        }

        Object answer = aiToolkit.askBoxAI(items, prompt);
        output.put('answer', answer);
        return output;
    }

    private Object extract(Map<String, Object> input, Map<String, Object> output) {
        String templateKey = (String) input.get('templateKey');
        if (String.isBlank(templateKey)) {
            throw new BoxToolkitCallableException('templateKey is required for extract');
        }

        String fileId = (String) input.get('fileId');
        if (String.isBlank(fileId)) {
            throw new BoxToolkitCallableException('fileId is required for extract');
        }

        List<box.AIItem> items = new List<box.AIItem>();
        box.AIItem fileItem = new box.AIItem();
        fileItem.type = 'file';
        fileItem.id = fileId;
        items.add(fileItem);

        Boolean includeConfidenceScores = (Boolean) input.get('includeConfidenceScores');
        if (includeConfidenceScores == null) {
            includeConfidenceScores = false;
        }

        box.BoxAIExtract extractReq = new box.BoxAIExtract();
        box.MetadataTemplate metadataTemplate = new box.MetadataTemplate();
        metadataTemplate.scope = 'enterprise';
        metadataTemplate.type = 'metadata_template';
        metadataTemplate.templateKey = templateKey;
        extractReq.metadata_template = metadataTemplate;
        extractReq.items = items;
        extractReq.include_confidence_score = includeConfidenceScores;

        box.BoxAIResponse resp = aiToolkit.extract(extractReq);
        output.put('answer', resp.answer);
        output.put('confidence_scores', resp.confidence_score);
        output.put('answer_map', resp.answerMap);
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
