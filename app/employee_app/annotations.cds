using LeaveService as service from '../../srv/leave-service';

/* =========================================================
   EMPLOYEE APP: my leave requests (list + create + detail)
   ========================================================= */
annotate service.MyRequests with @(
  // Employees can create requests. Once saved a request cannot be edited or deleted (it is decided by the manager).
  Capabilities.UpdateRestrictions : { Updatable : false },
  Capabilities.DeleteRestrictions : { Deletable : false },

  UI.HeaderInfo : {
    TypeName       : 'Leave request',
    TypeNamePlural : 'My leave requests',
    Title          : { Value : leaveType.name },
    Description    : { Value : status }
  },

  UI.SelectionFields : [ status, leaveType_ID, startDate ],

  UI.PresentationVariant : {
    SortOrder      : [{ Property : startDate, Descending : true }],
    Visualizations : [ '@UI.LineItem' ]
  },

  UI.LineItem : [
    { $Type : 'UI.DataField', Value : leaveType_ID, Label : 'Leave type' },
    { $Type : 'UI.DataField', Value : startDate },
    { $Type : 'UI.DataField', Value : endDate },
    { $Type : 'UI.DataField', Value : leaveDays },
    { $Type : 'UI.DataField', Value : status, Criticality : statusCriticality, CriticalityRepresentation : #WithIcon },
    { $Type : 'UI.DataField', Value : submittedAt },
    { $Type : 'UI.DataField', Value : rejectionReason }
  ],

  UI.Facets : [
    { $Type : 'UI.ReferenceFacet', ID : 'RequestFacet',  Label : 'Request',  Target : '@UI.FieldGroup#Request'  },
    { $Type : 'UI.ReferenceFacet', ID : 'DecisionFacet', Label : 'Decision', Target : '@UI.FieldGroup#Decision' }
  ],

  // What the employee fills in
  UI.FieldGroup #Request : {
    $Type : 'UI.FieldGroupType',
    Data  : [
      { $Type : 'UI.DataField', Value : leaveType_ID, Label : 'Leave type' },
      { $Type : 'UI.DataField', Value : startDate },
      { $Type : 'UI.DataField', Value : endDate },
      { $Type : 'UI.DataField', Value : comment }
    ]
  },

  // Filled by the system / the manager
  UI.FieldGroup #Decision : {
    $Type : 'UI.FieldGroupType',
    Data  : [
      { $Type : 'UI.DataField', Value : status, Criticality : statusCriticality },
      { $Type : 'UI.DataField', Value : leaveDays },
      { $Type : 'UI.DataField', Value : submittedAt },
      { $Type : 'UI.DataField', Value : decidedAt },
      { $Type : 'UI.DataField', Value : rejectionReason }
    ]
  }
);

annotate service.MyRequests with {
  // Leave type dropdown showing the name instead of the technical id
  leaveType @(
    Common.Label                   : 'Leave type',
    Common.Text                    : leaveType.name,
    Common.TextArrangement         : #TextOnly,
    Common.ValueListWithFixedValues : true,
    Common.ValueList               : {
      $Type          : 'Common.ValueListType',
      CollectionPath : 'LeaveTypes',
      Parameters     : [
        { $Type : 'Common.ValueListParameterInOut',       LocalDataProperty : leaveType_ID, ValueListProperty : 'ID'   },
        { $Type : 'Common.ValueListParameterDisplayOnly', ValueListProperty : 'name' }
      ]
    }
  );
  startDate       @title : 'Start date';
  endDate         @title : 'End date';
  leaveDays       @title : 'Working days';
  comment         @title : 'Comment';
  status          @title : 'Status';
  submittedAt     @title : 'Submitted';
  decidedAt       @title : 'Decided';
  rejectionReason @title : 'Rejection reason';
};

/* =========================================================
   MY BALANCES (used by a small "My leave balance" app)
   ========================================================= */
annotate service.Balances with @(
  Capabilities.InsertRestrictions : { Insertable : false },
  Capabilities.UpdateRestrictions : { Updatable : false },
  Capabilities.DeleteRestrictions : { Deletable : false },

  UI.HeaderInfo : { TypeName : 'Leave balance', TypeNamePlural : 'My leave balance', Title : { Value : leaveType.name } },
  UI.SelectionFields : [ year ],
  UI.PresentationVariant : {
    SortOrder      : [{ Property : year, Descending : true }],
    Visualizations : [ '@UI.LineItem' ]
  },
  UI.LineItem : [
    { $Type : 'UI.DataField', Value : leaveType.name, Label : 'Leave type' },
    { $Type : 'UI.DataField', Value : year },
    { $Type : 'UI.DataField', Value : entitlement },
    { $Type : 'UI.DataField', Value : daysTaken },
    { $Type : 'UI.DataField', Value : daysRemaining }
  ]
);

annotate service.Balances with {
  year          @title : 'Year';
  entitlement   @title : 'Yearly entitlement';
  daysTaken     @title : 'Days taken';
  daysRemaining @title : 'Days remaining';
};
