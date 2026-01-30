@JsonAccess(serializable='always')
global with sharing class CreateRecordFolderCallable implements Callable{
    private static final String KEY_INPUT   = 'input';
    private static final String KEY_OUTPUT  = 'output';
    private static final String KEY_OPTIONS = 'options';

    // =========================
    // Define toolkit variables
    // =========================
    private box.Toolkit toolkit;

    /**
     * Default constructor - initializes Toolkit dependencies.
     */
    global CreateRecordFolderCallable() {
        this.toolkit = new box.Toolkit();
    }

    /**
     * Constructor allowing Toolkit injection (useful for testing).
     * @param toolkit Existing Toolkit instance to use
     */
    global CreateRecordFolderCallable(box.Toolkit toolkit) {
        if (toolkit == null) {
            throw new CreateRecordFolderCallableException('Toolkit instance cannot be null');
        }
        this.toolkit = toolkit;
    }

    /**
     * Main entry point for the Callable interface. Routes the action to the appropriate Toolkit method.
     * @param action The name of the Toolkit method to invoke
     * @param args Map containing envelopes: input, output, options
     * @return The result envelope (output map)
     */
    global Object call(String action, Map<String, Object> args) {
        if (String.isBlank(action)) {
            throw new CreateRecordFolderCallableException('Action parameter cannot be null or blank');
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
            throw new CreateRecordFolderCallableException(String.format('Unknown action: {0}', new List<String>{ (String) action }));
        }
        if (String.isBlank(normalized)) {
            throw new CreateRecordFolderCallableException('Action parameter cannot be null or blank');
        }

        // Route to the appropriate method based on action
        switch on normalized {
            when 'createfolderforrecordid' {
                return createFolderForRecordId(input, output);
            }
            when else {  
                throw new CreateRecordFolderCallableException(String.format('Unknown action: {0}', new List<String>{ normalized }));
            }
        }
    }

    // ========================================
    // Folder Operations
    // ========================================
    private Object createFolderForRecordId(Map<String, Object> input, Map<String, Object> output) {
        Id recordId = (Id) input.get('recordId');
        if (recordId == null) {
            throw new CreateRecordFolderCallableException('recordId is required');
        }
        String folderNameOverride = (String) input.get('folderNameOverride');
        if (String.isBlank(folderNameOverride)) {
            folderNameOverride = null;
        }
        Boolean optCreateRootFolder = (Boolean) input.get('optCreateRootFolder');
        if (optCreateRootFolder == null) {
            optCreateRootFolder = false;
        }

        String folderId = toolkit.createFolderForRecordId(recordId, folderNameOverride, optCreateRootFolder);
        toolkit.commitChanges();

        if(folderId == null) {
            throw new CreateRecordFolderCallableException('Failed to create folder for recordId: ' + recordId);
        }
        Map<String, Object> result = new Map<String, Object>{ 'folderId' => folderId };
        output.put('result', result);
        return output;
    }

    /**
     * Domain-specific exception.
     */
    public class CreateRecordFolderCallableException extends Exception {}
}
