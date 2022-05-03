import {LightningElement, api, track, wire} from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import getObjectLabel from '@salesforce/apex/SFE_LWCDatatableController.getObjectLabel';
import getColumns from '@salesforce/apex/SFE_LWCDatatableController.getColumns';
import handleDataLoad from '@salesforce/apex/SFE_LWCDatatableController.handleDataLoad';
import deleteRowRecord from '@salesforce/apex/SFE_LWCDatatableController.deleteRowRecord';

import getReportFilterData from '@salesforce/apex/SFE_ReportFilterController.getReportFilterData';

const actions = [
    { label: 'View Record', name: 'view_record' },
    { label: 'Edit', name: 'edit' },
    { label: 'Delete', name: 'delete' }
];

const rowActionColumn = {
    type: 'action',
    typeAttributes: { rowActions: actions }
};

export default class SfeLwcDatatable extends NavigationMixin(LightningElement) {

    label = {
        errorTitle : 'Error',
        successfulTitle : 'Success',
        recentlyViewed : 'Recently Viewed',
        searchThisList : 'Search this list...',
        newLabel : 'New',
        modalHeader : 'Filter',
        clearFilter: 'Clear Filters',
        cancel: 'Cancel',
        save: 'Save',
        export: 'Export',
    };

    @track isLoading = false;
    @track isFirstLoad = true;
    @track isSorted = false;
    @track isFiltered = false;

    @api objectApiName;
    @track recToReturn = 25;
    @track objectLabel;
    @track iconName = 'standard:';

    @track data;
    @track columns;

    @track fieldsToQuery;
    @track searchKey = '';

    @track totalNumOfRecords;
    @track currentNumOfRecords;
    @track lastModifiedDate;

    @track tableElement;

    @track lastTableRowId;

    @track sortedBy = 'Id';
    @track sortedDirection = 'asc';

    @track isFilterModalOpen = false;
    @track reportFilterData = {};
    @track reportFilterDataCopy = {};

    connectedCallback() {

        this.isLoading = true;
        this.iconName += this.objectApiName.toLowerCase();

        getObjectLabel({objectName: this.objectApiName})
            .then(data => this.objectLabel = data)
            .catch(error => this.showErrorToast(error.body.message))
    }

    @wire(getColumns, ({objectName:'$objectApiName'}))
    getColumnsCallback({error, data}){

        if(data) {

            const wrappedColumns = data;
            this.fieldsToQuery = wrappedColumns.map(({fieldName}) => fieldName);
            this.apexFieldTypes = wrappedColumns.map(({apexType}) => apexType);
            this.columns = [
                ...wrappedColumns.filter(col => !col.isId)
                    .map(({apexType, ...rest}) => rest),
                rowActionColumn
            ];

            this.handleDataLoad();
        } else if (error) {

            this.isLoading = false;
            this.showErrorToast(error.body.message);
        }
    }

    @wire(getReportFilterData, ({objectName:'$objectApiName'}))
    getReportFilterDataCallback({error, data}){

        if(data) {
            data.forEach(data => {
                console.log(data.options);
                Object.keys(this.reportFilterData).includes(data.fieldType.toLowerCase()) ?
                    this.reportFilterData[data.fieldType.toLowerCase()].push(data) :
                    this.reportFilterData[data.fieldType.toLowerCase()] = [data];
            });
            this.reportFilterDataCopy = JSON.parse(JSON.stringify(this.reportFilterData));
        } else if (error) {
            this.showErrorToast(error.body.message);
        }
    }

    handleDataLoad() {
        handleDataLoad({
            fieldsToQuery: this.fieldsToQuery,
            apexFieldTypes: this.apexFieldTypes,
            objectName: this.objectApiName,
            chunkSize: this.recToReturn,
            lastTableRowId: this.lastTableRowId,
            sortedBy: this.sortedBy,
            sortedDirection: this.sortedDirection,
            searchKey: this.searchKey,
            isSorted: this.isSorted,
            isFiltered: this.isFiltered,
        })
            .then(data => {
                const wrappedData = data;
                this.lastTableRowId = wrappedData.lastId;
                this.lastModifiedDate = wrappedData.lastModifiedDatetime;
                this.data = this.isFirstLoad ? wrappedData.data : this.data.concat(wrappedData.data);
                this.currentNumOfRecords = this.data.length;
                this.totalNumOfRecords = wrappedData.totalNumberOfRecords;
                this.isFirstLoad = false;
                this.tableElement.enableInfiniteLoading = wrappedData.data.length >= this.recToReturn;
                this.tableElement.isLoading = !this.tableElement;
                this.isLoading = false
            })
            .catch(error => {
                this.isLoading = false;
                this.showErrorToast(error.body.message);
            })
    }

    doLoadingData(event) {
        this.tableElement = event.target;
        this.tableElement.isLoading = this.tableElement;
        this.handleDataLoad();
    }

    doSearchingData() {
        this.data = [];
        this.isLoading = true;
        this.isFirstLoad = true;
        this.lastTableRowId = undefined;
        this.isFiltered = this.searchKey.length !== 0;
        this.handleDataLoad();
    }

    handleSearchKeyChange(event) {
        this.searchKey = event.target.value;
    }

    handleRefreshButtonClick() {
        this.searchKey = '';
        this.doSearchingData();
    }

    handleFilterButtonClick() {
        this.isFilterModalOpen = true;
    }

    handleEnter(event) {
        if(event.keyCode === 13){
            this.doSearchingData();
        }
    }

    doSortingData(event) {
        this.data = [];
        this.isLoading = true;
        this.isFirstLoad = true;
        this.lastTableRowId = undefined;
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.isSorted = true;
        this.handleDataLoad();
    }

    handleRowAction(event) {

        const action = event.detail.action;
        const Id = event.detail.row.Id;

        switch (action.name) {
            case 'view_record':
                this.viewRowRecord(Id);
                break;
            case 'delete':
                this.deleteRowRecord(Id);
                break;
            case 'edit':
                this.editRowRecord(Id);
                break;

        }
    }

    viewRowRecord(Id) {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: Id,
                objectApiName: this.objectApiName,
                actionName: 'view'
            },
        });
    }

    editRowRecord(Id) {

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: Id,
                objectApiName: this.objectApiName,
                actionName: 'edit'
            },
        });
    }

    deleteRowRecord(Id) {

        deleteRowRecord({
            recordId: Id
        })
            .then(() => {
                this.showSuccessToast('The record has been deleted successfully!');
                this.data = this.data.filter(row => row.Id !== Id);
                this.totalNumOfRecords--;
                this.currentNumOfRecords--;
            })
            .catch(error => {
                this.showToast('Error', 'There was an error deleting the record' + error.body.message , 'Error');
            })
    }

    createNewRecord(){

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectApiName,
                actionName: 'new'
            },
        })
            .then(() => {
                this.showSuccessToast('The record has been deleted successfully!');
            })
            .catch(error => {
                this.showErrorToast(error.body.message);
            });
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }

    showErrorToast(message) {
        this.showToast(this.label.errorTitle, message , 'Error');
    }

    showSuccessToast(message) {
        this.showToast(this.label.successfulTitle, message , 'Success');
    }

    handleFilterSave(event) {
        this.isFilterModalOpen = false;
    }

    handleFilterCancel(event) {
        this.isFilterModalOpen = false;
    }

    handleFilterClear(event) {
        this.isFilterModalOpen = false;
    }
}