import {LightningElement, api, track} from 'lwc';

export default class SfeReportFilter extends LightningElement {

    @api reportFilterData;
    @track reportFilterDataChild;

    connectedCallback() {
        this.reportFilterDataChild = JSON.parse(JSON.stringify(this.reportFilterData));
    }

    handleFilterChange(event) {

        Object.keys(this.reportFilterDataChild).some(prop => {
            const fieldName = event.target.name ? event.target.name : event.target.fieldName;
            const targetElement = this.reportFilterDataChild[prop].find(elem => elem.fieldName === fieldName);
            if (targetElement) {
                targetElement.value = event.detail.value;
                return true;
            }
        });

        this.dispatchEvent(new CustomEvent("filtervaluechange", {detail: this.reportFilterDataChild}));
    }
}