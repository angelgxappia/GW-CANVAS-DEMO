({
    doInit : function(cmp, event) {
        var recordId = cmp.get("v.recordId");
        var output = '{"opportunity":' + '{"id":"' + recordId + '"}}';
        cmp.set("v.info", output);
    }
});
