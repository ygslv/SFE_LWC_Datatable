import {LightningElement, api} from 'lwc';

export default class SfeRequiredLabel extends LightningElement {

    @api required;
    @api fieldLabel;
}