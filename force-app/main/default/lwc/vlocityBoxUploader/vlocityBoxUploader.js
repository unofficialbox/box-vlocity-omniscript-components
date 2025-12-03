import { LightningElement, api } from "lwc";
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";

export default class VlocityBoxUploader extends OmniscriptBaseMixin(LightningElement) {
    @api accessToken;
    @api folderId;
    @api vfOrigin;
    @api buieURL;
    @api recordId;
    filesUploaded = false;
    error;

    connectedCallback() {  
        window.addEventListener('message', this.handleVFResponse.bind(this), false);
        console.log('LWC - recordId: ', this.recordId);
        console.log('LWC - omniJsonData: ', JSON.stringify(this.omniJsonData, null, 2));

        this.buieURL = `${this.vfOrigin}/apex/BoxContentUploader?accessToken=${this.accessToken}&folderId=${this.folderId}`;
        console.log('LWC - buieURL: ', this.buieURL)
    }

    handleVFResponse(event) {
        console.log('LWC Received From VF - message: ', event);
        if(event.data.operation == 'upload_complete') {
            this.filesUploaded = true;
            this.omniUpdateDataJson({"files":event.data});    
        }
    }
}