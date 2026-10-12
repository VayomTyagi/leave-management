using leavemanagement.db as db from '../db/schema';

service LeaveService @(path: '/leave') @(requires: 'authenticated-user') {

  @readonly entity LeaveTypes  as projection on db.LeaveTypes;
  @readonly entity Departments as projection on db.Departments excluding { employees };

  @readonly
  @restrict: [{ grant: 'READ', to: ['Manager', 'HR'] }]
  entity Employees as projection on db.Employees excluding { leaveBalances, leaveRequests };

  @restrict: [
    { grant: 'READ',   to: 'Employee', where: 'employee.email = $user' },
    { grant: 'CREATE', to: 'Employee' }
  ]
  entity MyRequests as projection on db.LeaveRequests;

  @readonly
  @restrict: [
    { grant: 'READ', to: 'Employee', where: 'employee.email = $user' },
    { grant: 'READ', to: 'HR' }
  ]
  entity Balances as projection on db.LeaveBalances;

  @restrict: [
    { grant: 'READ', to: 'Manager', where: 'employee.manager.email = $user' },
    { grant: ['approveRequest', 'rejectRequest'], to: 'Manager', where: 'employee.manager.email = $user' }
  ]
  entity TeamRequests as projection on db.LeaveRequests actions {
    action approveRequest() returns TeamRequests;
    action rejectRequest(reason : String) returns TeamRequests;
  };

  type CurrentUser {
    ID         : UUID;
    fullName   : String;
    email      : String;
    department : String;
    isManager  : Boolean;
    isHR       : Boolean;
  }
  function me() returns CurrentUser;
}

annotate LeaveService.MyRequests with {
  employee        @readonly;
  leaveDays       @readonly;
  status          @readonly;
  submittedAt     @readonly;
  decidedAt       @readonly;
  decidedBy       @readonly;
  rejectionReason @readonly;
};

extend LeaveService.MyRequests   with columns { virtual null as statusCriticality : Integer };
extend LeaveService.TeamRequests with columns { virtual null as statusCriticality : Integer };