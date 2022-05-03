import {LightningElement, api} from 'lwc';

export default class SfeReportFilter extends LightningElement {

    @api reportFilterData;

    handleFilterChange(event) {
        Object.keys(this.reportFilterData).forEach(prop => {

            const fieldName = event.target.name ? event.target.name : event.target.fieldName;
            const targetElement = this.reportFilterData[prop].find(elem => elem.fieldName === fieldName);
            if (targetElement) {
                targetElement.value = event.detail.value;
                return;
            }
        });
    }
}