using LeaveService as service from '../../srv/leave-service';

/* =========================================================
   MANAGER APP: leave requests of my team
   Approve / Reject are the only things a manager can do.
   ========================================================= */
annotate service.TeamRequests with @(
  Capabilities.InsertRestrictions : { Insertable : false },
  Capabilities.UpdateRestrictions : { Updatable : false },
  Capabilities.DeleteRestrictions : { Deletable : false },

  UI.HeaderInfo : {
    TypeName       : 'Leave request',
    TypeNamePlural : 'Team leave requests',
    Title          : { Value : employee.fullName },
    Description    : { Value : leaveType.name }
  },

  UI.SelectionFields : [ status, startDate ],

  // Oldest submitted first, so nothing is forgotten
  UI.PresentationVariant : {
    SortOrder      : [{ Property : submittedAt, Descending : false }],
    Visualizations : [ '@UI.LineItem' ]
  },

  UI.LineItem : [
    { $Type : 'UI.DataFieldForAction', Action : 'LeaveService.approveRequest', Label : 'Approve', Criticality : #Positive },
    { $Type : 'UI.DataFieldForAction', Action : 'LeaveService.rejectRequest',  Label : 'Reject',  Criticality : #Negative },
    { $Type : 'UI.DataField', Value : employee.fullName, Label : 'Employee' },
    { $Type : 'UI.DataField', Value : leaveType.name,    Label : 'Leave type' },
    { $Type : 'UI.DataField', Value : startDate },
    { $Type : 'UI.DataField', Value : endDate },
    { $Type : 'UI.DataField', Value : leaveDays },
    { $Type : 'UI.DataField', Value : comment },
    { $Type : 'UI.DataField', Value : status, Criticality : statusCriticality, CriticalityRepresentation : #WithIcon },
    { $Type : 'UI.DataField', Value : rejectionReason }
  ],

  UI.Facets : [
    { $Type : 'UI.ReferenceFacet', ID : 'RequestFacet',  Label : 'Request',  Target : '@UI.FieldGroup#Request'  },
    { $Type : 'UI.ReferenceFacet', ID : 'DecisionFacet', Label : 'Decision', Target : '@UI.FieldGroup#Decision' }
  ],

  UI.FieldGroup #Request : {
    $Type : 'UI.FieldGroupType',
    Data  : [
      { $Type : 'UI.DataField', Value : employee.fullName, Label : 'Employee' },
      { $Type : 'UI.DataField', Value : leaveType.name,    Label : 'Leave type' },
      { $Type : 'UI.DataField', Value : startDate },
      { $Type : 'UI.DataField', Value : endDate },
      { $Type : 'UI.DataField', Value : leaveDays },
      { $Type : 'UI.DataField', Value : comment }
    ]
  },

  UI.FieldGroup #Decision : {
    $Type : 'UI.FieldGroupType',
    Data  : [
      { $Type : 'UI.DataField', Value : status, Criticality : statusCriticality },
      { $Type : 'UI.DataField', Value : submittedAt },
      { $Type : 'UI.DataField', Value : decidedAt },
      { $Type : 'UI.DataField', Value : rejectionReason }
    ]
  },

  // Buttons on the detail page
  UI.Identification : [
    { $Type : 'UI.DataFieldForAction', Action : 'LeaveService.approveRequest', Label : 'Approve' },
    { $Type : 'UI.DataFieldForAction', Action : 'LeaveService.rejectRequest',  Label : 'Reject'  }
  ]
);

annotate service.TeamRequests with {
  // The filter bar starts on the requests that still need a decision
  status          @title : 'Status'  /*@Common.FilterDefaultValue : 'PENDING'*/;
  startDate       @title : 'Start date';
  endDate         @title : 'End date';
  leaveDays       @title : 'Working days';
  comment         @title : 'Comment';
  submittedAt     @title : 'Submitted';
  decidedAt       @title : 'Decided';
  rejectionReason @title : 'Rejection reason';
};

// The reject dialog asks for the reason, and it is mandatory
annotate service.TeamRequests actions {
  rejectRequest(reason @title : 'Reason for rejection' @mandatory);
};
