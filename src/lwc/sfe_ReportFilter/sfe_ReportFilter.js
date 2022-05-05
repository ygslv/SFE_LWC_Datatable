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
            const targetElement = this.reportFilterSectionData[prop].find(elem => elem.fieldName === event.target.fieldName);
            if (targetElement) {
                targetElement.value = event.detail.value;
                return true;
            }
        });

        this.dispatchEvent(new CustomEvent("filtervaluechange", {detail: this.reportFilterSectionData}));
    }

    generateReportFilterSectionData() {
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