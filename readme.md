# Employee Leave Management

A leave application built with **SAP CAP (Node.js)** and **SAP HANA Cloud**. Employees request leave, managers approve or reject it, and HR sees leave usage across the company. The management reports are **HANA calculation views**, exposed through the application.

- Repository: `https://github.com/VayomTyagi/leave-management`
- Deployed app (BTP trial): `8fc1608dtrial-trial-y4cuizm0-dev-leave-management.cfapps.ap21.hana.ondemand.com`

## What it does

| Who | What they can do |
| --- | --- |
| Employee | Request leave (Annual, Sick, Unpaid, Parental), see their own requests with status, see their balance |
| Manager | See pending requests of their direct reports, approve, or reject with a mandatory reason |
| HR | See balances for all employees, usage by department and leave type, and the percentage of entitlement used per department, for a selected year |

## Architecture

```
db/schema.cds            data model (5 entities)
db/data/*.csv            sample data
db/src/*.hdbcalculationview   3 HANA calculation views (+ .hdiconfig)
db/reports.cds           proxy entities that map the calculation views into CAP
srv/leave-service.*      employee + manager scenarios: validation and approve/reject logic
srv/report-service.cds   HR reports (read-only, HR role)
test/*.http              request collections used to test and demo every rule
```

**Design in short**

- **Two services.** `LeaveService` (`/leave`) handles the day-to-day process and `ReportService` (`/report`) is read-only and restricted to HR.
- **Business rules live in the service layer** (`srv/leave-service.js`), so they apply to every client, not only a UI.
- **Reports are computed inside HANA.** Each report is a calculation view that CAP reads like a table, so they stay fast as data grows. The service never loops over rows to build a report.
- **Identity = e-mail.** The logged-in user id is matched to `Employees.email`. Roles (`Employee`, `Manager`, `HR`) come from XSUAA on BTP and from mocked users locally.

### Data model

`Departments`, `Employees` (with a self-reference to the manager), `LeaveTypes`, `LeaveBalances` (one row per employee, leave type and year) and `LeaveRequests`. Request status is an enum: `PENDING`, `APPROVED`, `REJECTED`.
`daysRemaining` is a calculated field (entitlement minus days taken), not stored, so it cannot go out of sync.

### Business rules (enforced in `leave-service.js`)

- End date cannot be before the start date.
- Leave days are calculated automatically; Saturdays and Sundays are not counted. A request containing only weekend days is refused.
- A request cannot be submitted without enough leave: entitlement minus approved and pending days must cover it.
- A request cannot overlap the employee's own pending or approved requests.
- A manager sees and decides only requests of their direct reports. A rejection requires a reason.
- Once approved or rejected, a request cannot be changed again (the second attempt returns 409).
- Approval adds the days to the balance's `daysTaken`.

### Calculation views

| View | Grain | Content |
| --- | --- | --- |
| `CV_LEAVE_BALANCE` | employee, leave type, year | entitlement, days taken (approved requests only), days remaining |
| `CV_USAGE_DEPT_TYPE` | department, leave type, year | approved days and number of requests |
| `CV_DEPT_UTILIZATION` | department, leave type, year | entitlement, days taken, days remaining, **% used** |

The percentage is a calculated measure computed **after** aggregation (total taken / total entitlement), so it stays correct however the rows are rolled up. The year is an ordinary column the client filters on.

HR endpoints: `/report/LeaveBalances`, `/report/UsageByDeptAndType`, `/report/DepartmentUtilization` (department level) and `/report/DepartmentUtilizationByType`, each filterable with `?$filter=year eq 2026`.

## Sample data

16 employees in 5 departments (with a manager hierarchy), 4 leave types, 65 balance rows (2025 and 2026), and 46 leave requests: 34 approved, 8 pending, 4 rejected. Usage differs by department on purpose (for example Sales about 37 % of entitlement used in 2026 and Finance about 8 %), so the HR reports show something to discuss.

## Setup

### Prerequisites

- SAP BTP trial account with a Cloud Foundry space, SAP HANA Cloud instance (running), Business Application Studio or a local Node.js 20+ with `@sap/cds-dk`.

### Run locally

```bash
npm install
cds watch
```

This uses SQLite and mocked users. The employee and manager scenarios work completely. **The HR reports need HANA** (calculation views do not exist in SQLite), so they return an error in this mode.

### Run locally against HANA (reports included)

```bash
cf login
cds deploy --to hana          # creates the HDI container, tables, data and calculation views
cds watch --profile hybrid
```

Mocked users (password `pass`):

| User | Roles |
| --- | --- |
| `priya.nair@company.com` | Employee |
| `arjun.rao@company.com` | Employee, Manager |
| `vikram.singh@company.com` | Employee, Manager |
| `pooja.shah@company.com` | Employee, HR |
| `meera.iyer@company.com` | Employee, Manager, HR |

Then run the requests in `test/leave.http` and `test/report.http`.

### Deploy to BTP

```bash
mbt build -t gen --mtar mta.tar
cf deploy gen/mta.tar
```

Afterwards, in the BTP cockpit create a role collection with the roles `Employee`, `Manager` and `HR`, assign it to your user and log in again. On BTP the demo user is `<your BTP login e-mail>`, which is set as the e-mail of employee `<Arjun Rao / EMP003>` in `db/data/leavemanagement.db-Employees.csv`, so one login can show the employee, manager and HR views.

## Assumptions

- Only Saturdays and Sundays are excluded; **public holidays are not modelled**.
- Leave is counted in whole days (no half days).
- A request must lie within one calendar year (a request across New Year is submitted as two).
- **Pending requests reserve balance**: available days = entitlement − approved − pending. Rejected requests release the days.
- **Unpaid leave has no cap**, so it skips the balance check and has no balance rows.
- **Parental leave** has a balance only for employees who were given one (one employee in the sample data), so others cannot request it.
- The percentage of entitlement used covers all leave types that have an entitlement (Annual, Sick and Parental); Unpaid is excluded.
- Each employee has one direct manager, who is the only person who can decide their requests. The HR director has no manager, so she approves the department heads' requests and cannot submit her own.
- Cancelling or editing a submitted request is out of scope.

## Trial limits and workarounds

| Limit | What I did |
| --- | --- |
| HANA Cloud free tier stops every night | Restart the instance before working or demoing |
| HANA Cloud accepts connections only from allowed IP addresses, which blocked deployment from Business Application Studio | Set the instance to allow all IP addresses (acceptable on a trial) |
| The instance must be mapped to the Cloud Foundry space | Done in HANA Cloud Central, instance mapping |
| Cloud Foundry memory quota of the trial exceeded on deployment (`quota_exceeded`) | Lowered the memory of the apps in `mta.yaml` (`<values you used>`) |
| Calculation views cannot run on SQLite | Reports are tested with `cds watch --profile hybrid` against HANA; the rest runs on SQLite locally |
| Only one HANA instance and one HDI container are practical | One container holds tables, data and calculation views |