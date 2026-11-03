sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"employeeapp/test/integration/pages/MyRequestsList.gen",
	"employeeapp/test/integration/pages/MyRequestsObjectPage.gen"
], function (JourneyRunner, MyRequestsListGenerated, MyRequestsObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('employeeapp') + '/test/flp.html#app-preview',
        pages: {
			onTheMyRequestsListGenerated: MyRequestsListGenerated,
			onTheMyRequestsObjectPageGenerated: MyRequestsObjectPageGenerated
        },
        async: true
    });

    return runner;
});

