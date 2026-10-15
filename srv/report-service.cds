using { CV_USAGE_DEPT_TYPE, CV_LEAVE_BALANCE, CV_DEPT_UTILIZATION } from '../db/reports';

@path: '/report'
@requires: 'HR'
service ReportService {

  // Approved leave days by department, leave type and year
  @readonly entity UsageByDeptAndType as projection on CV_USAGE_DEPT_TYPE {
    key DEPARTMENT_NAME as department,
    key LEAVETYPE_NAME  as leaveType,
    key LEAVEYEAR       as year,
        DAYS_TAKEN      as daysTaken,
        REQUEST_COUNT   as requestCount
  };

  // Entitlement, days taken and days remaining per employee, leave type and year
  @readonly entity LeaveBalances as projection on CV_LEAVE_BALANCE {
    key EMPLOYEENUMBER  as employeeNumber,
    key LEAVETYPE_NAME  as leaveType,
    key LEAVEYEAR       as year,
        EMPLOYEE_NAME   as employeeName,
        DEPARTEMENT_NAME as department,
        ENTITLEMENT     as entitlement,
        DAYS_TAKEN      as daysTaken,
        DAYS_REMAINING  as daysRemaining
  };

  // Department level: leave types are left out on purpose, so HANA rolls them up
  // and calculates the percentage from the totals
  @readonly entity DepartmentUtilization as projection on CV_DEPT_UTILIZATION {
    key DEPARTEMENT_NAME as department,
    key LEAVEYEAR       as year,
        ENTITLEMENT     as entitlement,
        DAYS_TAKEN      as daysTaken,
        DAYS_REMAINING  as daysRemaining,
        PCT_USED        as percentUsed
  };

  // Same view, with the leave type breakdown
  @readonly entity DepartmentUtilizationByType as projection on CV_DEPT_UTILIZATION {
    key DEPARTEMENT_NAME as department,
    key LEAVETYPE_NAME  as leaveType,
    key LEAVEYEAR       as year,
        ENTITLEMENT     as entitlement,
        DAYS_TAKEN      as daysTaken,
        DAYS_REMAINING  as daysRemaining,
        PCT_USED        as percentUsed
  };
}
