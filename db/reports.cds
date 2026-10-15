// ---- Native HANA calculation views (deployed from db/src/*.hdbcalculationview) ----
// @cds.persistence.exists: CAP must not create a table/view for these, they already exist in HANA.
// The entity names are the exact names of the calculation views and sit outside the namespace on purpose,
// so that CAP reads from CV_... and not from leavemanagement_db_...

@cds.persistence.exists
@cds.persistence.calcview
entity CV_USAGE_DEPT_TYPE {
  key DEPARTMENT_NAME : String(100);
  key LEAVETYPE_NAME  : String(50);
  key LEAVEYEAR       : Integer;
      DAYS_TAKEN      : Integer;
      REQUEST_COUNT   : Integer;
}

@cds.persistence.exists
@cds.persistence.calcview
entity CV_LEAVE_BALANCE {
  key EMPLOYEENUMBER  : String(20);
  key LEAVETYPE_NAME  : String(50);
  key LEAVEYEAR       : Integer;
      EMPLOYEE_NAME   : String(101);
      DEPARTEMENT_NAME : String(100);
      ENTITLEMENT     : Integer;
      DAYS_TAKEN      : Integer;
      DAYS_REMAINING  : Integer;
}

@cds.persistence.exists
@cds.persistence.calcview
entity CV_DEPT_UTILIZATION {
  key DEPARTEMENT_NAME : String(100);
  key LEAVETYPE_NAME  : String(50);
  key LEAVEYEAR       : Integer;
      ENTITLEMENT     : Integer;
      DAYS_TAKEN      : Integer;
      DAYS_REMAINING  : Integer;
      PCT_USED        : Decimal(9,2);
}
