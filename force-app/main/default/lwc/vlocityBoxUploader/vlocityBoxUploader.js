import { LightningElement, api, wire} from "lwc";
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";
// import pubsub from "vlocity_ins/pubsub";
import { getRecord } from "lightning/uiRecordApi";



export default class VlocityBoxUploader extends OmniscriptBaseMixin(LightningElement) {
    @api flexCardData;
    @api accessToken;
    @api folderId;
    @api vfOrigin;
    @api buieURL;
    @api uploadedFiles;
    @api recordId;
    filesUploaded = false;


    @api stepName;
    data = {};
    error;

    connectedCallback() {  
        window.addEventListener('message' , this.handleVFResponse);
        // pubsub.register('upload_complete', {
        //     data: this.handleVFResponse.bind(this)
        // })
        console.log('LWC - flex card data: ', JSON.stringify(this.flexCardData, null, 2));
        console.log('LWC - recordId: ', this.recordId);
     

        let folderId;
        let accessToken;
        let vfOrigin;

        if(this.flexCardData) {
            folderId = this.flexCardData.FolderId;
            accessToken = this.flexCardData.DownscopedToken;
            vfOrigin = this.flexCardData.VFOrigin;
        }
        else {
            folderId = this.folderId;
            accessToken = this.accessToken;
            vfOrigin = this.vfOrigin;
        }
        console.log('LWC - Found folderId: ', folderId);
        console.log('LWC - Found accessToken: ', accessToken);
        console.log('LWC - Found vfOrigin: ', vfOrigin);

        this.buieURL = `${vfOrigin}/apex/BoxContentUploader?accessToken=${accessToken}&folderId=${folderId}`;
        console.log('LWC - buieURL: ', this.buieURL)

    }

    handleVFResponse(event) {
        console.log('LWC Received From VF - message: ', event);

        let eventData = event.data;
        console.log('LWC Received From VF - data: ', eventData);
        if(eventData.operation == 'upload_complete') {
            this.filesUploaded = true;
            this.uploadedFiles = eventData.files;

            let data = {
                files: JSON.parse(JSON.stringify(eventData.files))
            };
            console.log('LWC Received From VF - Found uploaded files: ', this.uploadedFiles);
            console.log('Omni Json Data: ', this.omniJsonData);

            // const eventName = 'omniaggregate';
            // const myEvent = new CustomEvent(eventName, {
            //     bubbles: true,
            //     cancelable: true,
            //     composed: true,
            //     detail: data,
            // });
            // this.dispatchEvent(myEvent); 

            // this.omniUpdateDataJson(this.uploadedFiles)
            this.omniApplyCallResp(eventData);
            // this.omniUpdateDataJson(eventData);
            // this.omniSaveState(eventData, 'files', false);
            // this.omniUpdateDataJson({"uploadFiles": this.uploadedFiles});        
            // this.renderedCallback()
        }
    }
}