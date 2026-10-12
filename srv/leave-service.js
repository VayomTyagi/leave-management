import cds from '@sap/cds';

export default class LeaveService extends cds.ApplicationService {

  async init() {
    const { LeaveRequests, LeaveBalances, LeaveTypes, Employees } = cds.entities('leavemanagement.db');
    const { MyRequests, TeamRequests } = this.entities;

    /* ---------------- date formating ---------------- */

    const toDate = s => new Date(`${s}T00:00:00Z`);

    const countWorkdays = (start, end) => {
      let n = 0;
      for (let d = toDate(start); d <= toDate(end); d.setUTCDate(d.getUTCDate() + 1)) {
        const day = d.getUTCDay();
        if (day !== 0 && day !== 6) n++;
      }
      return n;
    };

    const employeeByEmail = email =>
      SELECT.one.from(Employees).where({ email });

    this.after('READ', [MyRequests, TeamRequests], rows => {
      const colour = { APPROVED: 3, REJECTED: 1, PENDING: 2 };
      for (const r of Array.isArray(rows) ? rows : [rows]) if (r?.status) r.statusCriticality = colour[r.status];
    });


    this.on('me', async req => {
      const emp = await SELECT.one.from(Employees, e => { e('*'), e.department(d => d.name) })
        .where({ email: req.user.id });
      if (!emp) return req.reject(404, `No employee record for ${req.user.id}`);
      return {
        ID: emp.ID,
        fullName: `${emp.firstName} ${emp.lastName}`,
        email: emp.email,
        department: emp.department?.name,
        isManager: req.user.is('Manager'),
        isHR: req.user.is('HR')
      };
    });

    /* ---------------- Employee: submit a request ---------------- */

    this.before('CREATE', MyRequests, async req => {
      const { leaveType_ID, startDate, endDate } = req.data;

      if (!leaveType_ID || !startDate || !endDate)
        return req.reject(400, 'Leave type, start date and end date are required');

      const employee = await employeeByEmail(req.user.id);
      if (!employee || !employee.active)
        return req.reject(403, 'No active employee record for the logged-in user');
      if (!employee.manager_ID)
        return req.reject(400, 'No manager is assigned to you, please contact HR');

      // Date rules
      if (endDate < startDate)
        return req.reject(400, 'End date cannot be before the start date');
      if (startDate.slice(0, 4) !== endDate.slice(0, 4))
        return req.reject(400, 'A request cannot span two calendar years, please submit one request per year');

      const leaveDays = countWorkdays(startDate, endDate);
      if (leaveDays === 0)
        return req.reject(400, 'The selected period contains only weekend days');

      const leaveType = await SELECT.one.from(LeaveTypes).where({ ID: leaveType_ID });
      if (!leaveType) return req.reject(400, 'Unknown leave type');

      // No overlap
      const overlapping = await SELECT.one.from(LeaveRequests)
        .where({ employee_ID: employee.ID, status: { in: ['PENDING', 'APPROVED'] },
                 startDate: { '<=': endDate }, endDate: { '>=': startDate } });
      if (overlapping)
        return req.reject(409, `Overlaps with an existing ${overlapping.status.toLowerCase()} request (${overlapping.startDate} to ${overlapping.endDate})`);

      // Balance rule
      if (leaveType.requiresBalance) {
        const year = Number(startDate.slice(0, 4));
        const balance = await SELECT.one.from(LeaveBalances)
          .where({ employee_ID: employee.ID, leaveType_ID, year });
        if (!balance)
          return req.reject(400, `You have no ${leaveType.name} leave entitlement for ${year}`);

        const rows = await SELECT.from(LeaveRequests).columns('leaveDays')
          .where({ employee_ID: employee.ID, leaveType_ID, status: { in: ['PENDING', 'APPROVED'] },
                   startDate: { '>=': `${year}-01-01` }, endDate: { '<=': `${year}-12-31` } });
        const used = rows.reduce((sum, r) => sum + r.leaveDays, 0);
        const available = balance.entitlement - used;
        if (leaveDays > available)
          return req.reject(400, `Not enough ${leaveType.name} leave: you requested ${leaveDays} day(s) but only ${available} remain for ${year} (pending requests included)`);
      }

      // System-controlled fields
      req.data.employee_ID = employee.ID;
      req.data.leaveDays   = leaveDays;
      req.data.status      = 'PENDING';
      req.data.submittedAt = new Date().toISOString();
    });

    /* ---------------- approve / reject ---------------- */

    const decide = async (req, status) => {
      const ID = req.params[0]?.ID ?? req.params[0];
      const request = await SELECT.one.from(LeaveRequests).where({ ID });
      if (!request) return req.reject(404, 'Request not found');

      // Immutability
      if (request.status !== 'PENDING')
        return req.reject(409, `This request is already ${request.status} and can no longer be changed`);

      // Defence in depth
      const approver = await employeeByEmail(req.user.id);
      const requester = await SELECT.one.from(Employees).where({ ID: request.employee_ID });
      if (!approver || requester.manager_ID !== approver.ID)
        return req.reject(403, 'Only the direct manager of the employee can decide this request');

      let reason = null;
      if (status === 'REJECTED') {
        reason = req.data.reason?.trim();
        if (!reason) return req.reject(400, 'A reason is required to reject a request');
      }

      await UPDATE(LeaveRequests, ID).with({
        status,
        decidedAt: new Date().toISOString(),
        decidedBy_ID: approver.ID,
        rejectionReason: reason
      });

      // Approved days count
      if (status === 'APPROVED') {
        const year = Number(request.startDate.slice(0, 4));
        await UPDATE(LeaveBalances)
          .set({ daysTaken: { '+=': request.leaveDays } })
          .where({ employee_ID: request.employee_ID, leaveType_ID: request.leaveType_ID, year });
      }

      return SELECT.one.from(LeaveRequests).where({ ID });
    };

    this.on('approveRequest', TeamRequests, req => decide(req, 'APPROVED'));
    this.on('rejectRequest', TeamRequests, req => decide(req, 'REJECTED'));

    return super.init();
  }
}