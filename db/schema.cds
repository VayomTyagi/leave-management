namespace leavemanagement.db;

using { cuid, managed } from '@sap/cds/common';

type LeaveRequestStatus : String(10) enum {
    PENDING;
    APPROVED;
    REJECTED;
}


@assert.unique: { code: [code] }
entity Departments : cuid, managed {
    code        : String(20)  not null;
    name        : String(100) not null;

    employees   : Association to many Employees on employees.department = $self;
}

@assert.unique: {
    employeeNumber : [employeeNumber],
    email          : [email]
}

entity Employees : cuid, managed {
    employeeNumber : String(20)  not null;
    firstName      : String(50)  not null;
    lastName       : String(50)  not null;
    fullName       : String      = firstName || ' ' || lastName;
    email          : String(100) not null;

    department     : Association to Departments not null;
    manager        : Association to Employees;

    active         : Boolean default true;

    leaveBalances  : Association to many LeaveBalances on leaveBalances.employee = $self;
    leaveRequests  : Association to many LeaveRequests on leaveRequests.employee = $self;
}

@assert.unique: { code: [code] }
entity LeaveTypes : cuid {
    code               : String(20) not null;
    name               : String(50) not null;

    defaultEntitlement : Integer not null;

    requiresBalance    : Boolean default true;
}

@assert.unique: { perEmployeeTypeYear: [employee, leaveType, year] }
entity LeaveBalances : cuid, managed {
    employee      : Association to Employees  not null;
    leaveType     : Association to LeaveTypes not null;

    year          : Integer not null;
    entitlement   : Integer not null;
    daysTaken     : Integer default 0;
    daysRemaining : Integer = (entitlement - daysTaken);
}

entity LeaveRequests : cuid, managed {

    employee        : Association to Employees  not null;
    leaveType       : Association to LeaveTypes not null;

    startDate       : Date not null;
    endDate         : Date not null;

    leaveDays       : Integer;
    comment         : String(500);
    status          : LeaveRequestStatus default #PENDING;
    submittedAt     : Timestamp;

    decidedAt       : Timestamp;
    decidedBy       : Association to Employees;
    
    rejectionReason : String(500);
}