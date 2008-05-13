dojo.require('dijit.form.Form');
dojo.require('dijit.form.Button');
dojo.require('dijit.form.FilteringSelect');
dojo.require('dijit.form.NumberTextBox');
dojo.require('dojox.grid.Grid');
dojo.require('openils.acq.Provider');
dojo.require('fieldmapper.OrgUtils');

function getOrgInfo(rowIndex) {
    data = poGrid.model.getRow(rowIndex);
    if(!data) return;
    return fieldmapper.aou.findOrgUnit(data.owner).shortname();
}

function getProvider(rowIndex) {
    data = poGrid.model.getRow(rowIndex);
    if(!data) return;
    return openils.acq.Provider.retrieve(data.provider).name();
}

function getPOOwner(rowIndex) {
    data = poGrid.model.getRow(rowIndex);
    if(!data) return;
    return new openils.User({id:data.owner}).user.usrname();
}

function doSearch(fields) {
    var itemList = [];

    fieldmapper.standardRequest(
        ['open-ils.acq', 'open-ils.acq.purchase_order.search'],
        {
            async:1,
            params: [openils.User.authtoken, fields],
            onresponse : function(r) {
                var msg = r.recv();
                if(msg) itemList.push(msg.content());
            },
            oncomplete : function(r) {
                dojo.style('po-grid', 'visibility', 'visible');
                var store = new dojo.data.ItemFileReadStore({data:acqpo.toStoreData(itemList)});
                var model = new dojox.grid.data.DojoData(null, store,
                    {rowsPerPage: 20, clientSort: true, query:{id:'*'}});
                poGrid.setModel(model);
                poGrid.update();
            },
        }
    );
}

function loadForm() {

    /* load the providers */
    openils.acq.Provider.createStore(
        function(store) {
            providerSelector.store = 
                new dojo.data.ItemFileReadStore({data:store});
        },
        'MANAGE_PROVIDER'
    );
}

dojo.addOnLoad(loadForm);
