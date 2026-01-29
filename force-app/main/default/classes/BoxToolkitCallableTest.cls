/**
 * @description Unit tests for BoxToolkitCallable
 * Covers happy paths using a mock Toolkit and error paths for null/blank inputs.
 * Follows: Return Early, no DML/SOQL, no SeeAllData, meaningful assertions.
 */
@IsTest
private class BoxToolkitCallableTest {

    // Simple stub types to satisfy type references in BoxToolkitCallable
    private class AIItem {}

    /**
     * Mock implementations of the external box.* classes used by BoxToolkitCallable.
     * These are inner classes to avoid namespace coupling in tests.
     */
    private class MockToolkit extends box.Toolkit {
        public Id lastRecordId;
        public String lastFolderNameOverride;
        public Boolean lastOptCreateRootFolder;

        public Id lastContentVersionId;
        public String lastBoxFolderId;

        public Id lastUserId;
        public Id lastRecordIdForCollab;
        public String lastCollaboratorType;
        public Boolean lastOptCreateFolder;

        public String lastBoxFileId;
        public String lastScope;
        public String lastTemplateKey;
        public List<box.KeyValuePair> lastKeyValuePairs;

        public Object lastHttpRequest;

        public override Object createFolderForRecordId(Id recordId, String folderNameOverride, Boolean optCreateRootFolder) {
            this.lastRecordId = recordId;
            this.lastFolderNameOverride = folderNameOverride;
            this.lastOptCreateRootFolder = optCreateRootFolder;
            return 'created';
        }

        public override Object pushFileToBox(Id contentVersionId, String boxFolderId) {
            this.lastContentVersionId = contentVersionId;
            this.lastBoxFolderId = boxFolderId;
            return 'pushed';
        }

        public override Object createCollaborationOnRecord(Id userId, Id recordId, String collaboratorType, Boolean optCreateFolder) {
            this.lastUserId = userId;
            this.lastRecordIdForCollab = recordId;
            this.lastCollaboratorType = collaboratorType;
            this.lastOptCreateFolder = optCreateFolder;
            return 'collab';
        }

        public override Object createBoxMetadataByFileId(String boxFileId, String scope, String templateKey, List<box.KeyValuePair> keyValuePairs) {
            this.lastBoxFileId = boxFileId;
            this.lastScope = scope;
            this.lastTemplateKey = templateKey;
            this.lastKeyValuePairs = keyValuePairs;
            return 'metadata';
        }

        public override Object sendRequest(HttpRequest req) {
            this.lastHttpRequest = req;
            return 'sent';
        }
    }

    private class MockBoxAIToolkit extends box.BoxAIToolkit {
        public List<AIItem> lastItems;
        public String lastPrompt;
        public String lastTemplateKey;
        public Boolean lastIncludeConfidence;

        public override Object askBoxAI(List<AIItem> items, String prompt) {
            this.lastItems = items;
            this.lastPrompt = prompt;
            return 'aiAnswer';
        }

        public override Object extract(List<AIItem> items, String templateKey, Object unused, Boolean includeConfidenceScores, Object unused2) {
            this.lastItems = items;
            this.lastTemplateKey = templateKey;
            this.lastIncludeConfidence = includeConfidenceScores;
            return 'extracted';
        }
    }

    /**
     * Helper to build a callable with injected mocks.
     * We cannot directly inject aiToolkit/signRequest due to visibility; tests will rely on returned values.
     */
    private static BoxToolkitCallable newCallableWith(MockToolkit tk) {
        return new BoxToolkitCallable(tk);
    }

    @IsTest
    static void call_requires_action_nonblank() {
        BoxToolkitCallable c = new BoxToolkitCallable();
        Test.startTest();
        try {
            c.call(null, new Map<String, Object>());
            System.assert(false, 'Expected exception for null action');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('Action parameter cannot be null or blank'));
        }
        try {
            c.call('  ', new Map<String, Object>());
            System.assert(false, 'Expected exception for blank action');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('Action parameter cannot be null or blank'));
        }
        try {
            c.call('UNKNOWN_ACTION', new Map<String, Object>());
            System.assert(false, 'Expected exception for unknown action');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('Unknown action'));
        }
        Test.stopTest();
    }

    @IsTest
    static void constructor_throws_on_null_toolkit() {
        try {
            new BoxToolkitCallable((box.Toolkit) null);
            System.assert(false, 'Expected exception for null toolkit');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('Toolkit instance cannot be null'));
        }
    }

    @IsTest
    static void createFolderForRecordId_happy_and_guards() {
        MockToolkit tk = new MockToolkit();
        BoxToolkitCallable c = newCallableWith(tk);

        // Guard: missing recordId
        try {
            c.call('createFolderForRecordId', new Map<String, Object>());
            System.assert(false, 'Expected exception for missing recordId');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('recordId is required'));
        }

        // Happy path
        Map<String, Object> args = new Map<String, Object>{
            'recordId' => (Id) '001000000000001',
            'folderNameOverride' => 'Folder',
            'optCreateRootFolder' => true
        };
        Object res = c.call('createFolderForRecordId', args);
        System.assertEquals('created', res);
        System.assertEquals('001000000000001', String.valueOf(tk.lastRecordId));
        System.assertEquals('Folder', tk.lastFolderNameOverride);
        System.assertEquals(true, tk.lastOptCreateRootFolder);
    }

    @IsTest
    static void pushFileToBox_happy_and_guards() {
        MockToolkit tk = new MockToolkit();
        BoxToolkitCallable c = newCallableWith(tk);

        // Guards
        try {
            c.call('pushFileToBox', new Map<String, Object>());
            System.assert(false, 'Expected exception for missing contentVersionId');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('contentVersionId is required'));
        }
        try {
            Map<String, Object> argsMissingFolder = new Map<String, Object>{
                'contentVersionId' => (Id) '068000000000001'
            };
            c.call('pushFileToBox', argsMissingFolder);
            System.assert(false, 'Expected exception for missing boxFolderId');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('boxFolderId is required'));
        }

        // Happy path
        Map<String, Object> args = new Map<String, Object>{
            'contentVersionId' => (Id) '068000000000001',
            'boxFolderId' => '12345'
        };
        Object res = c.call('pushFileToBox', args);
        System.assertEquals('pushed', res);
        System.assertEquals('068000000000001', String.valueOf(tk.lastContentVersionId));
        System.assertEquals('12345', tk.lastBoxFolderId);
    }

    @IsTest
    static void createCollaborationOnRecord_happy_and_guards() {
        MockToolkit tk = new MockToolkit();
        BoxToolkitCallable c = newCallableWith(tk);

        // Guards
        try {
            c.call('createCollaborationOnRecord', new Map<String, Object>());
            System.assert(false, 'Expected exception for missing userId');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('userId is required'));
        }
        try {
            Map<String, Object> argsMissingRecord = new Map<String, Object>{
                'userId' => (Id) '005000000000001'
            };
            c.call('createCollaborationOnRecord', argsMissingRecord);
            System.assert(false, 'Expected exception for missing recordId');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('recordId is required'));
        }
        try {
            Map<String, Object> argsMissingType = new Map<String, Object>{
                'userId' => (Id) '005000000000001',
                'recordId' => (Id) '001000000000001'
            };
            c.call('createCollaborationOnRecord', argsMissingType);
            System.assert(false, 'Expected exception for missing collaboratorType');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('collaboratorType is required'));
        }

        // Happy path
        Map<String, Object> args = new Map<String, Object>{
            'userId' => (Id) '005000000000001',
            'recordId' => (Id) '001000000000001',
            'collaboratorType' => 'EDITOR',
            'optCreateFolder' => false
        };
        Object res = c.call('createCollaborationOnRecord', args);
        System.assertEquals('collab', res);
        System.assertEquals('005000000000001', String.valueOf(tk.lastUserId));
        System.assertEquals('001000000000001', String.valueOf(tk.lastRecordIdForCollab));
        System.assertEquals('EDITOR', tk.lastCollaboratorType);
        System.assertEquals(false, tk.lastOptCreateFolder);
    }

    @IsTest
    static void createBoxMetadataByFileId_happy_and_guards() {
        MockToolkit tk = new MockToolkit();
        BoxToolkitCallable c = newCallableWith(tk);

        // Guards
        try {
            c.call('createBoxMetadataByFileId', new Map<String, Object>());
            System.assert(false, 'Expected exception for missing boxFileId');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('boxFileId is required'));
        }
        try {
            Map<String, Object> argsMissingScope = new Map<String, Object>{
                'boxFileId' => 'bf_1'
            };
            c.call('createBoxMetadataByFileId', argsMissingScope);
            System.assert(false, 'Expected exception for missing scope');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('scope is required'));
        }
        try {
            Map<String, Object> argsMissingTemplate = new Map<String, Object>{
                'boxFileId' => 'bf_1',
                'scope' => 'enterprise'
            };
            c.call('createBoxMetadataByFileId', argsMissingTemplate);
            System.assert(false, 'Expected exception for missing templateKey');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('templateKey is required'));
        }

        // Happy path with null keyValuePairs defaulted to empty list
        Map<String, Object> args = new Map<String, Object>{
            'boxFileId' => 'bf_1',
            'scope' => 'enterprise',
            'templateKey' => 'invoice',
            'keyValuePairs' => null
        };
        Object res = c.call('createBoxMetadataByFileId', args);
        System.assertEquals('metadata', res);
        System.assertEquals('bf_1', tk.lastBoxFileId);
        System.assertEquals('enterprise', tk.lastScope);
        System.assertEquals('invoice', tk.lastTemplateKey);
        System.assertNotEquals(null, tk.lastKeyValuePairs, 'keyValuePairs should be defaulted to empty list when null');
        System.assertEquals(true, tk.lastKeyValuePairs.isEmpty(), 'Defaulted list should be empty');
    }

    @IsTest
    static void sendRequest_happy_and_guards() {
        MockToolkit tk = new MockToolkit();
        BoxToolkitCallable c = newCallableWith(tk);

        // Guard: blank request string
        try {
            c.call('sendRequest', new Map<String, Object>{ 'httpRequestString' => '' });
            System.assert(false, 'Expected exception for blank httpRequestString');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('httpRequestString is required'));
        }

        // Guard: malformed JSON
        try {
            c.call('sendRequest', new Map<String, Object>{ 'httpRequestString' => '{bad-json' });
            System.assert(false, 'Expected exception for bad JSON');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('Failed to deserialize httpRequestString'));
        }

        // Happy path: minimal HttpRequest JSON
        String valid = JSON.serialize(new HttpRequest());
        Object res = c.call('sendRequest', new Map<String, Object>{ 'httpRequestString' => valid });
        System.assertEquals('sent', res);
        System.assertNotEquals(null, tk.lastHttpRequest);
    }

    @IsTest
    static void askBoxAI_and_extract_guards_and_happy() {
        // We cannot inject aiToolkit directly; rely on returned values and exception behavior.
        BoxToolkitCallable c = new BoxToolkitCallable();

        // askBoxAI guards
        try {
            c.call('askBoxAI', new Map<String, Object>());
            System.assert(false, 'Expected exception for missing items');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('items are required for askBoxAI'));
        }
        try {
            c.call('askBoxAI', new Map<String, Object>{ 'items' => new List<AIItem>(), 'prompt' => 'x' });
            System.assert(false, 'Expected exception for empty items');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('items are required for askBoxAI'));
        }
        try {
            c.call('askBoxAI', new Map<String, Object>{ 'items' => new List<AIItem>{ new AIItem() }, 'prompt' => '' });
            System.assert(false, 'Expected exception for blank prompt');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('prompt is required for askBoxAI'));
        }

        // Happy
        Object askRes = c.call('askBoxAI', new Map<String, Object>{ 'items' => new List<AIItem>{ new AIItem() }, 'prompt' => 'Hello' });
        System.assertNotEquals(null, askRes, 'Should return a non-null response');

        // extract guards
        try {
            c.call('extract', new Map<String, Object>());
            System.assert(false, 'Expected exception for missing items on extract');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('items are required for extract'));
        }
        try {
            c.call('extract', new Map<String, Object>{ 'items' => new List<AIItem>(), 'templateKey' => 't' });
            System.assert(false, 'Expected exception for empty items on extract');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('items are required for extract'));
        }
        try {
            c.call('extract', new Map<String, Object>{ 'items' => new List<AIItem>{ new AIItem() }, 'templateKey' => '' });
            System.assert(false, 'Expected exception for blank templateKey');
        } catch (BoxToolkitCallable.BoxToolkitCallableException e) {
            System.assert(e.getMessage().contains('templateKey is required for extract'));
        }

        // Happy
        Object extractRes = c.call('extract', new Map<String, Object>{ 'items' => new List<AIItem>{ new AIItem() }, 'templateKey' => 't', 'includeConfidenceScores' => true });
        System.assertNotEquals(null, extractRes, 'Should return a non-null response');
    }
}
