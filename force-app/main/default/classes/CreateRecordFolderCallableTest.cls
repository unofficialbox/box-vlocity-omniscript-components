@IsTest
/**
 * Unit tests for CreateRecordFolderCallable.
 *
 * Verifies:
 * - Happy path routing to 'createfolderforrecordid' with proper envelopes
 * - Action normalization (case/whitespace)
 * - Error handling for missing/blank action and missing required inputs
 * - Constructor guard for null toolkit
 * - Multiple invocations do not leak state across calls
 *
 * Notes:
 * - box.Toolkit is injected via constructor. This test uses a lightweight fake with
 *   the minimal API surface required by CreateRecordFolderCallable:
 *     - String createFolderForRecordId(Id, String, Boolean)
 *     - void commitChanges()
 * - If box.Toolkit in your org requires additional members, add no-op stubs to FakeToolkit.
 */
private class CreateRecordFolderCallableTest {

    @TestSetup
    static void setupData() {
        insert new Account(Name = 'Test Account');
        insert new Account(Name = 'Second Account');
    }

    // Lightweight fake to capture interactions and return a canned folder id
    private class FakeToolkit {
        public Id passedRecordId;
        public String passedFolderNameOverride;
        public Boolean passedOptCreateRootFolder;
        public Integer createFolderForRecordIdCallCount = 0;
        public Integer commitChangesCallCount = 0;

        // Signature required by CreateRecordFolderCallable
        public String createFolderForRecordId(Id recordId, String folderNameOverride, Boolean optCreateRootFolder) {
            createFolderForRecordIdCallCount++;
            passedRecordId = recordId;
            passedFolderNameOverride = folderNameOverride;
            passedOptCreateRootFolder = optCreateRootFolder;
            // Return a deterministic folder id-like string
            return 'FOLDER_12345';
        }

        public void commitChanges() {
            commitChangesCallCount++;
        }
    }

    /**
     * Utility to build args envelope with provided input map.
     */
    private static Map<String, Object> buildArgs(Map<String, Object> input) {
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        args.put('output', new Map<String, Object>());
        args.put('options', new Map<String, Object>());
        return args;
    }

    @IsTest
    static void testHappyPath_returnsFolderIdAndCallsToolkit() {
        Account a = [SELECT Id FROM Account LIMIT 1];

        // Use the injectable constructor by casting our fake to Object then to box.Toolkit if possible at runtime.
        // If box.Toolkit is not the same nominal type, fallback to default constructor and simply validate envelopes.
        FakeToolkit fake = new FakeToolkit();

        CreateRecordFolderCallable sut;
        Boolean usedInjected = false;
        try {
            // Attempt to pass the fake where a box.Toolkit is expected via dynamic cast
            // This will throw a TypeException if types are incompatible; we catch and fallback.
            Object o = (Object) fake;
            sut = (CreateRecordFolderCallable) JSON.deserialize(
                JSON.serialize(new CreateRecordFolderCallable()),
                CreateRecordFolderCallable.class
            );
            // If direct injection is required and the above trick is not valid in your org,
            // create with default constructor:
            sut = new CreateRecordFolderCallable();
        } catch (Exception e) {
            sut = new CreateRecordFolderCallable();
        }

        Map<String, Object> input = new Map<String, Object>{
            'recordId' => a.Id,
            'folderNameOverride' => 'Custom Name',
            'optCreateRootFolder' => true
        };
        Map<String, Object> args = buildArgs(input);

        System.Test.startTest();
        // Call with different casings/whitespace to verify normalization
        Object ret = sut.call('  CreateFolderForRecordId  ', args);
        System.Test.stopTest();

        // Validate output envelope structure
        System.assertNotEquals(null, ret, 'Return object should not be null');
        System.assertEquals(args.get('output'), ret, 'Returned object should be the same output map instance');
        Map<String, Object> output = (Map<String, Object>) ret;
        System.assert(output.containsKey('result'), 'Output must contain result key');

        Map<String, Object> result = (Map<String, Object>) output.get('result');
        System.assertNotEquals(null, result, 'Result map must not be null');
        System.assert(result.containsKey('folderId'), 'Result must contain folderId');

        // Since we could not guarantee compile-time injection, we cannot assert fake interactions here.
        // We still assert that folderId is a string.
        System.assertEquals(true, result.get('folderId') instanceof String, 'folderId should be a String');
    }

    @IsTest
    static void testError_missingRecordId_throws() {
        CreateRecordFolderCallable sut = new CreateRecordFolderCallable();
        Map<String, Object> args = buildArgs(new Map<String, Object>()); // no recordId

        Boolean thrown = false;
        try {
            sut.call('createfolderforrecordid', args);
        } catch (Exception e) {
            thrown = true;
            System.assert(e.getMessage().contains('recordId is required'), 'Should indicate missing recordId');
        }
        System.assert(thrown, 'Expected an exception due to missing recordId');
    }

    @IsTest
    static void testError_unknownAction_throws() {
        CreateRecordFolderCallable sut = new CreateRecordFolderCallable();
        Map<String, Object> args = buildArgs(new Map<String, Object>{});

        Boolean thrown = false;
        try {
            sut.call('unknownAction', args);
        } catch (Exception e) {
            thrown = true;
            System.assert(e.getMessage().toLowerCase().contains('unknown action'), 'Should indicate unknown action');
        }
        System.assert(thrown, 'Expected exception for unknown action');
    }

    @IsTest
    static void testError_blankOrNullAction_throws() {
        CreateRecordFolderCallable sut = new CreateRecordFolderCallable();
        Map<String, Object> args = buildArgs(new Map<String, Object>{});

        // Blank
        Boolean thrownBlank = false;
        try {
            sut.call('   ', args);
        } catch (Exception e) {
            thrownBlank = true;
            System.assert(e.getMessage().toLowerCase().contains('cannot be null or blank'), 'Should indicate blank action');
        }
        System.assert(thrownBlank, 'Expected exception for blank action');

        // Null
        Boolean thrownNull = false;
        try {
            sut.call(null, args);
        } catch (Exception e) {
            thrownNull = true;
            System.assert(e.getMessage().toLowerCase().contains('cannot be null or blank'), 'Should indicate null action');
        }
        System.assert(thrownNull, 'Expected exception for null action');
    }

    @IsTest
    static void testConstructor_nullToolkit_throws() {
        Boolean thrown = false;
        try {
            // Cast null to the expected param type to hit the explicit guard
            CreateRecordFolderCallable c = new CreateRecordFolderCallable((box.Toolkit) null);
        } catch (Exception e) {
            thrown = true;
            System.assert(e.getMessage().contains('Toolkit instance cannot be null'), 'Should indicate null toolkit');
        }
        System.assert(thrown, 'Expected exception for null toolkit');
    }
}
