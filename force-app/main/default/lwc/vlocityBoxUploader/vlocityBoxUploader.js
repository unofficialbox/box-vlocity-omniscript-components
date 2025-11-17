import { LightningElement, api, wire} from "lwc";
import { OmniscriptBaseMixin } from "vlocity_ins/omniscriptBaseMixin";
import { getRecord } from "lightning/uiRecordApi";



export default class VlocityBoxUploader extends OmniscriptBaseMixin(LightningElement) {
    @api flexCardData;
    @api accessToken;
    @api folderId;
    @api vfOrigin;
    @api buieURL;
    @api uploadedFiles;
    @api recordId;


    @api stepName;
    data = {};
    error;

    async connectedCallback() {  
        window.addEventListener('message' , this.handleVFResponse);
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

        const data = event.data;
        console.log('LWC Received From VF - data: ', data);
        if(data.operation == 'upload_complete') {
            this.uploadedFiles = data.files;
            console.log('LWC Received From VF - Found uploaded files: ', this.uploadedFiles);
            this.omniApplyCallResp(this.uploadedFiles);
            // this.omniUpdateDataJson({"uploadFiles": this.uploadedFiles});        
        }
    }
}