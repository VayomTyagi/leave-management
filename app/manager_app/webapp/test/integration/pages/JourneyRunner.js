sap.ui.define([
    "sap/fe/test/JourneyRunner",
	"managerapp/test/integration/pages/TeamRequestsList.gen",
	"managerapp/test/integration/pages/TeamRequestsObjectPage.gen"
], function (JourneyRunner, TeamRequestsListGenerated, TeamRequestsObjectPageGenerated) {
    'use strict';

    const runner = new JourneyRunner({
        launchUrl: sap.ui.require.toUrl('managerapp') + '/test/flp.html#app-preview',
        pages: {
			onTheTeamRequestsListGenerated: TeamRequestsListGenerated,
			onTheTeamRequestsObjectPageGenerated: TeamRequestsObjectPageGenerated
        },
        async: true
    });

    return runner;
});

