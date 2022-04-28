import {LightningElement, api} from 'lwc';

export default class SfeDynamicModal extends LightningElement {

    @api modalHeader;
    @api showModal = false;
    @api show() {this.showModal = true}
    @api hide() {this.showModal = false}

    handleDialogClose() {
        const closedialog = new CustomEvent('closedialog');
        this.dispatchEvent(closedialog);
        this.hide();
    }
}