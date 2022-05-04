import {LightningElement, api, track} from 'lwc';

export default class SfeReportFilter extends LightningElement {

    @api objectApiName;
    @api section;
    @api reportFilterData;
    @track reportFilterSectionData = {};

    connectedCallback() {
        this.generateReportFilterSectionData();
    }

    handleFilterChange(event) {

        Object.keys(this.reportFilterSectionData).some(prop => {
            const fieldName = event.target.name ? event.target.name : event.target.fieldName;
            const targetElement = this.reportFilterSectionData[prop].find(elem => elem.fieldName === fieldName);
            if (targetElement) {
                targetElement.value = event.detail.value;
                return true;
            }
        });

        this.dispatchEvent(new CustomEvent("filtervaluechange", {detail: this.reportFilterSectionData}));
    }

    generateReportFilterSectionData() {
        debugger;
        Object.keys(this.reportFilterData).forEach(type => {
            this.reportFilterData[type].forEach(field => {
                if (field.section === this.section) {
                    Object.keys(this.reportFilterSectionData).includes(type) ?
                        this.reportFilterSectionData[type].push(field) :
                        this.reportFilterSectionData[type] = [field]
                }
            })
        })
    }
}