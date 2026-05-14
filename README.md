# MLM

A comprehensive open-source Multi-Level Marketing (MLM) package offering registration, membership management, compensation structures, automated tasks, shopping capabilities, ticketing systems, and backend administration. The package includes four built-in bonus plans: Unilevel, Team, Pairing, and Affiliate. Developers can easily extend these to create custom bonus plans.

The software is built on [Genelet](https://github.com/genelet/perl), an open-source web development framework designed for creating secure, scalable, and high-performance websites.

> **Note:** The legacy codebase is preserved in the `master` branch.

## Mobile and API Development

This project provides a comprehensive JSON API for building mobile and external applications.

- **OpenAPI Specification**: Refer to [`openapi.yaml`](openapi.yaml) for the complete OpenAPI 3.0 specification documenting all available endpoints, authentication methods, and schemas.
- **Mobile App Guide**: See [`REACT_NATIVE.md`](REACT_NATIVE.md) for a detailed roadmap on building a native mobile application using React Native and the JSON API.

---

## Chapter 1. Installation

The software is developed in Perl and can operate as a standard CGI-BIN program or FastCGI (see Section 1.11). In addition to running CGI, you need MySQL database access and shell command execution to run the built-in unit and functional test suites. You should pass these tests to ensure successful installation and accurate compensation calculations.

### 1.1) Download the Genelet Framework

```bash
git clone https://github.com/genelet/perl.git
```

Assume your current directory is `SAMPLE_home`. After cloning, a new directory named `perl` will be created within `SAMPLE_home`.

> **Note:** In a real environment, replace all occurrences of `SAMPLE_home` in these instructions with your actual home directory path.

### 1.2) Download MLM

```bash
git clone https://github.com/genelet/mlm.git
```

After cloning, the `mlm` directory will be created with four subdirectories: `lib`, `conf`, `www`, and `views`. The file structure will look like this:

```
SAMPLE_home/
├── perl/
│   └── Genelet/
└── mlm/
    ├── lib/
    │   └── MLM/
    ├── conf/
    ├── www/
    └── views/
```

### 1.3) Install Perl Dependencies

For development and testing on Ubuntu or Debian, install the required Perl modules with the Makefile:

```bash
cd SAMPLE_home/mlm
make deps
```

The target installs the distribution packages for DBI, DBD::mysql, JSON, Template Toolkit, XML::LibXML, CGI, LWP, Digest::HMAC_SHA1, MIME::Lite, and Test::Class. The `cpanfile` is kept as a module manifest for non-Debian systems or custom dependency tooling.

For a deployed CGI/FastCGI server, add both `SAMPLE_home/perl` and `SAMPLE_home/mlm/lib` to the Perl path:

```bash
export PERL5LIB=/SAMPLE_home/perl:/SAMPLE_home/mlm/lib
```

### 1.4) Choose a Test Database

The test suite needs an empty MySQL database because it loads schema, seed data, products, members, compensation data, and ledger entries. You can use either Docker MySQL or your own MySQL instance.

#### 1.4.1) Option A: Docker MySQL

Use this if you do not already have a MySQL server. MLM includes a repo-owned MySQL 8 test service on host port `53307`. It does not depend on the Genelet framework's Docker Compose file.

```bash
cd SAMPLE_home/mlm
make mysql-up
make mysql-reset
```

`make mysql-reset` loads `conf/01_init.sql` and `conf/03_setup.sql` into the Docker database `mlm_test` with user/password `mlm`/`mlm`.

#### 1.4.2) Option B: Your Own MySQL

Use this if you already run MySQL locally or on another host. Create a dedicated empty database for tests; do not point the test suite at production data.

Example for a local MySQL server:

```bash
sudo apt-get install mysql-server default-mysql-client
sudo mysql
```

Then run these SQL statements in the MySQL prompt:

```sql
CREATE DATABASE mlm_test CHARACTER SET utf8;
CREATE USER 'mlm'@'localhost' IDENTIFIED BY 'mlm';
GRANT ALL PRIVILEGES ON mlm_test.* TO 'mlm'@'localhost';
FLUSH PRIVILEGES;
```

If your MySQL server has binary logging enabled and schema loading fails with error 1419, ask your DBA or run as a MySQL administrator:

```sql
SET GLOBAL log_bin_trust_function_creators = 1;
```

Load the schema and seed data through the external-MySQL target:

```bash
cd SAMPLE_home/mlm
make mysql-reset-external \
  MYSQL_HOST=127.0.0.1 \
  MYSQL_PORT=3306 \
  MYSQL_DATABASE=mlm_test \
  MYSQL_USER=mlm \
  MYSQL_PASSWORD=mlm
```

The same variables also tell the Perl functional tests where to connect. To run the full suite against your own MySQL:

```bash
make test-external \
  MYSQL_HOST=127.0.0.1 \
  MYSQL_PORT=3306 \
  MYSQL_DATABASE=mlm_test \
  MYSQL_USER=mlm \
  MYSQL_PASSWORD=mlm
```

For a remote MySQL server, replace `MYSQL_HOST`, `MYSQL_PORT`, `MYSQL_USER`, and `MYSQL_PASSWORD` with that server's values. Make sure the MySQL user is allowed to connect from your client host and has full privileges on the test database.

### 1.5) Create a Production MySQL Database

For production, create a MySQL database with appropriate credentials and load the schema with a MySQL client.

Example:

```bash
sudo mysql
```

```sql
CREATE DATABASE mlm_prod CHARACTER SET utf8;
CREATE USER 'mlm_prod_user'@'localhost' IDENTIFIED BY 'CHANGE_THIS_PASSWORD';
GRANT ALL PRIVILEGES ON mlm_prod.* TO 'mlm_prod_user'@'localhost';
FLUSH PRIVILEGES;
```

For a remote application server, replace `'localhost'` with the host or subnet that will connect to MySQL. After creating the database, set the `Db` block in `conf/config.json`:

```json
"Db": ["dbi:mysql:database=mlm_prod;host=127.0.0.1;port=3306", "mlm_prod_user", "CHANGE_THIS_PASSWORD"]
```

Use a strong password, keep production credentials out of test scripts, and do not reuse the sample `mlm`/`mlm` test account for production.

#### 1.5.1) Migrate the Database Schema

Load the database schema from `conf/01_init.sql` using a MySQL client tool.

#### 1.5.2) Migrate Initial Data

Load `conf/03_setup.sql` to create one compensation plan, one backend admin user, and one member for the initial website launch.

### 1.6) Configure config.json and component.json

Copy the sample configuration file:

```bash
cp conf/SAMPLE_config.json conf/config.json
```

Edit `config.json` and update the following:
- Replace `SAMPLE_home` with your actual directory path hosting `mlm` and `perl`
- Replace `SAMPLE_domain` with your real domain name (or subdomain)
- Generate random security codes (typically ~80 characters)
- Update the MySQL access parameters in the `Db` block

Set up your shell environment:

```bash
export PERL5LIB=/SAMPLE_home/perl:/SAMPLE_home/mlm/lib
# Replace SAMPLE_home with your actual path
```

The test harness can run against `conf/SAMPLE_config.json` directly. `MLM::Beacon` rewrites its sample paths to the current checkout and defaults the DB connection to the test database. You can override those values with `MLM_CONFIG`, `MLM_DB_DSN`, `MLM_DB_USER`, `MLM_DB_PASSWORD`, `MLM_LIB`, and `GENELET_LIB`.

#### 1.6.1) Domain Name in Cookies

The authentication cookies' `Domain` must exactly match the website domain in `config.json`; otherwise, login error code 1036 will occur.

| Site URL | Domain Setting |
|----------|----------------|
| `http://noniland.com` | `noniland.com` |
| `http://www.noniland.com` | `www.noniland.com` |

#### 1.6.2) File Uploads in component.json

By default, uploaded files are saved in `Uploaddir`. You can override this by specifying a folder in `component.json`. For example, product photos are uploaded to `Document_root/product` as shown in `lib/MLM/Gallery/component.json`:

```json
"insert": {
  "validate": ["categoryid"],
  "upload": {
    "logoupload": ["logo", "/product"],
    "fullupload": ["full", "/product"]
  }
}
```

#### 1.6.3) HTTP Method and CSRF Policy in component.json

For security, custom actions must explicitly declare allowed HTTP methods in `component.json`. Safe reads should use GET; mutating actions should use POST and include `"options": ["csrf"]` for authenticated roles.

Browser forms and JSON responses for authenticated roles use a CSRF token named `csrf`. JSON clients should read the latest token from `relationships.csrf` and send it back as the `csrf` form field on later mutating POST requests.

### 1.7) Run Tests

With Docker MySQL, run the full compile, JSON, unit, reset, and functional test sequence:

```bash
cd SAMPLE_home/mlm
make test
```

With your own MySQL, use:

```bash
cd SAMPLE_home/mlm
make test-external MYSQL_HOST=127.0.0.1 MYSQL_PORT=3306 MYSQL_DATABASE=mlm_test MYSQL_USER=mlm MYSQL_PASSWORD=mlm
```

The functional tests run in this order because each file builds on the state from the prior one:

- `conf/SAMPLE_bin/01_product.t`
- `conf/SAMPLE_bin/02_member.t`
- `conf/SAMPLE_bin/03_income.t`
- `conf/SAMPLE_bin/04_ledger.t`
- `conf/SAMPLE_bin/05_shopping.t`

### 1.8) Build Week Tables

Follow the instructions in `conf/07_read.me` to build the week tables (`cron_1week` and `cron_4week`) that determine when different compensation types are calculated:

```bash
perl conf/08_weekly.pl -h
```

Follow the on-screen instructions to proceed.

### 1.9) Set Up Cronjob

Configure `bin/run_daily.pl` to run as a daily cronjob (e.g., at 2 AM):

```bash
crontab -e
# Add the following line:
0 2 * * * /SAMPLE_home/mlm/bin/run_daily.pl
```

### 1.10) Launch the Website

Ensure the web server, configuration file, week tables, and cronjob are all properly configured. The entry point URLs are:

| Portal | URL |
|--------|-----|
| New Member Signup | `http://SAMPLE_domain/cgi-bin/goto/p/en/member?action=startnew` |
| Backend Admin | `http://SAMPLE_domain/cgi-bin/goto/a/en/member?action=topics` |
| Member Portal | `http://SAMPLE_domain/cgi-bin/goto/m/en/member?action=dashboard` |

### 1.11) Run as FastCGI

For most systems, running MLM as a CGI program is fast and secure. However, for large customer bases, limited system resources, or virtual host environments, you may want to use FastCGI for improved performance.

To configure FastCGI:

1. Copy `goto` to `/SAMPLE_home/mlm/www` and configure Apache to run it as an FCGID handler
2. Update `Script` in `config.json` from `/cgi-bin/goto` to `/goto`
3. Add `1` as the fourth argument in `Genelet::Dispatch::run`:

```perl
Genelet::Dispatch::run(
  "/SAMPLE_home/mlm/conf/config.json",
  "/SAMPLE_home/mlm/lib",
  ["Admin", "Affiliate", "Signup", "Member", "Sponsor", "Placement",
   "Category", "Gallery", "Package", "Packagedetail", "Packagetype",
   "Sale", "Basket", "Lineitem", "Income", "Incomeamount", "Ledger",
   "Tt", "Ttpost", "Week1", "Week4", "Affiliate"],
  1
);
```

---

## Chapter 2. Compensation Plans

Four compensation plans are built into the system. Parameters are defined in the `Custom` block of `config.json` and in three database tables: `def_type`, `def_direct`, and `def_match`. Use these as building blocks to create custom compensation plans.

### 2.1) Membership Types

Members are classified into different membership types, defined in `def_type`:

```sql
CREATE TABLE def_type (
  typeid TINYINT(3) UNSIGNED NOT NULL,
  short VARCHAR(255) NOT NULL,
  name VARCHAR(255) DEFAULT NULL,
  bv INT(10) UNSIGNED DEFAULT NULL,
  price INT(10) UNSIGNED DEFAULT NULL,
  yes21 ENUM('Yes','No') DEFAULT 'No',
  c_upper INT(10) UNSIGNED DEFAULT NULL,
  PRIMARY KEY (typeid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

| Column | Description |
|--------|-------------|
| `typeid` | Unique identifier |
| `name` | Membership name (e.g., "Gold Membership") |
| `short` | Abbreviation |
| `price` | Minimum price for initial signup package |
| `bv` | Bonus Value of the package |
| `yes21` | Whether 2:1 pairing is allowed (Pairing bonus only) |
| `c_upper` | Upper limit in dollars per pairing (Pairing bonus only) |

> **Note:** Retail shopping by existing members is assigned `typeid` value `SHOP_typeid` defined in `config.json`.

### 2.2) Unilevel Bonus (Direct Bonus)

When a member (sponsor) refers a new member (offspring), the sponsor receives a Unilevel Bonus. The bonus amount is defined in `def_direct`:

```sql
CREATE TABLE def_direct (
  directid TINYINT(3) UNSIGNED NOT NULL,
  typeid TINYINT(3) UNSIGNED NOT NULL,
  whoid TINYINT(3) UNSIGNED NOT NULL,
  bonus DOUBLE DEFAULT NULL,
  PRIMARY KEY (directid),
  KEY typeid (typeid),
  KEY whoid (whoid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

| Column | Description |
|--------|-------------|
| `directid` | Unique identifier |
| `typeid` | Sponsor's membership type |
| `whoid` | Offspring's membership type |
| `bonus` | Dollar amount rewarded to sponsor |

The Unilevel Bonus is calculated every 4 weeks (monthly) on days defined in `cron_4week`.

### 2.3) Team Bonus (Match Bonus)

In addition to the Unilevel Bonus, sponsors can earn Match-Up Bonuses from their referrals' activities. For example, if your direct referral sponsors a new member, you receive a 2nd-generation match-up bonus. This extends to multiple generations.

Simultaneously, when a sponsor earns a match-up bonus, their direct referrals share a percentage as a Match-Down Bonus. These are combined as the Team Bonus to encourage team building.

The match-up bonus is defined in `def_match`:

```sql
CREATE TABLE def_match (
  matchid TINYINT(3) UNSIGNED NOT NULL,
  typeid TINYINT(3) UNSIGNED NOT NULL,
  lev TINYINT(3) UNSIGNED NOT NULL,
  rate DOUBLE NOT NULL DEFAULT '0',
  PRIMARY KEY (matchid),
  KEY typeid (typeid)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

| Column | Description |
|--------|-------------|
| `matchid` | Unique identifier |
| `typeid` | Sponsor's membership type |
| `lev` | Generation level (2 or above) |
| `rate` | Percentage rate |

**Example:** If `lev=10` and `rate=0.01`, a new member with a $1,000 initial package triggers a $10 reward to their 10th-generation sponsor.

The match-down rate is defined in `RATE_matchdown` in `config.json`. If a sponsor with 5 direct offspring earns $10 in match-up bonus and the match-down rate is 0.25, each offspring receives $0.50.

The Team Bonus is calculated weekly on days defined in `cron_1week`. For large-scale deployments, the calculation engine is optimized for memory efficiency when processing multi-generation relationships.

### 2.4) Pairing Bonus (Binary Bonus)

Members can build a pyramid tree in addition to the sponsor tree. Each member has left and right legs, each accommodating one direct downline.

**Terminology:**
- **Sponsor tree:** sponsor and offspring
- **Pyramid tree:** upline and downline

Downlines in a member's pyramid tree are offspring of their direct sponsor and up-generation sponsors in the sponsor tree. Any up-generation sponsor can place a downline on a member's left or right leg.

**Example:** Mary refers Karl to the system. Since Mary's legs are full, she places Karl under John (Mary's multi-generation offspring). Therefore:
- Karl is Mary's direct offspring (sponsor tree)
- Karl is John's direct downline (pyramid tree)
- Karl is Mary's multi-generation downline (pyramid tree)
- John and Karl have no relationship in the sponsor tree

**Pairing Calculation:**

When a member accumulates sufficient points on both legs, a collision occurs, generating a pairing bonus. Parameters are defined in `Custom->{BIN}`:
- `unit`: Base unit in BV
- `rate`: Conversion rate from BV to dollars

**Example:** A member with 500 BV (left) and 400 BV (right), with `unit=200`:
- Collision: 2 units → $40 (at `rate=0.1`)
- Remaining: 100 BV (left), 0 BV (right)

If `c_upper=30` is defined, the actual payout is $30 instead of $40.

**2:1 Pairing:** For unbalanced legs, the system supports 2:1 pairing (if `yes21='Yes'` in `def_type`). With 1,000 BV (left) and 400 BV (right), pairing at 800:400 yields 2 units of 2:1, leaving 200:0. The rate for 2:1 pairing is `rate21`.

The Pairing Bonus is calculated weekly on days defined in `cron_1week`.

### 2.5) Auto Placement and Power Line

Members can configure Auto Placement on the member portal, specifying a default offspring and leg for new signups in the pyramid tree. If the assigned position is occupied, the system automatically uses the same leg of the new signup as the next default.

**Example:** Mary sets John's left leg as Auto Placement. When Henry joins and occupies John's left leg, Henry's left leg becomes Mary's new Auto Placement.

This feature helps build a power line automatically. Members typically leverage a strong upline's power line while building their other lines, adjusting Auto Placement to balance sales volumes.

### 2.6) Affiliate Bonus

This bonus applies to privileged members designated as affiliates in the admin portal's Membership/Affiliates section.

When activating a new signup, managers can attribute it to an affiliate. The affiliate receives a bonus defined by `RATE_affiliate` in `config.json`. For a $1,000 package with `rate=0.02`, the affiliate earns $20.

The Affiliate Bonus is calculated weekly on days defined in `cron_1week`.

### 2.7) Calculation Schedule

All bonus calculations are handled automatically by the daily cronjob `run_daily.pl` (see Section 1.9). The system includes a robust catch-up mechanism (`run_to_yesterday`) that ensures all pending compensation cycles are processed sequentially if the service is interrupted.

### 2.8) Data Integrity and Transactions

Critical financial operations, such as purchasing and ledger updates, are protected by database transactions to ensure data consistency. This prevents partial data writes in the event of system failures.

### 2.9) Error Handling

The system uses a centralized error constant module (`MLM::Constants`) to provide consistent error reporting across all modules.

### 2.10) Display Limits

For security, you can limit the display depth of pyramid downlines and sponsor offspring in `config.json`:

| Parameter | Description |
|-----------|-------------|
| `MAX_plevel` | Maximum downline display level (admin portal) |
| `MAX_mplevel` | Maximum downline display level (member portal) |
| `MAX_slevel` | Maximum offspring display level (admin portal) |
| `MAX_mslevel` | Maximum offspring display level (member portal) |

---

## Chapter 3. Management and Accounting

This chapter explains how to use the backend management system to build product packages, process orders, and maintain ledger books.

> **Important:** MLM does **not** handle credit/debit card charges or process online transactions. Your accounting department must insert markers into the relevant sales and ledger tables to proceed. You can either process payments offline or implement your own payment processing integration.

MLM is not a comprehensive eCommerce package—it implements limited product and shopping features sufficient for core MLM functions. You can integrate third-party eCommerce software by coordinating the database tables.

### 3.1) New Applicants

#### 3.1.1) Public Website

New candidates complete the application form at:

```
http://SAMPLE_domain/cgi-bin/goto/p/en/member?action=startnew
```

The applicant can specify their sponsor's username. Sponsors should provide candidates with a pre-filled URL:

**Method 1:** Add sponsor username as a query parameter:
```
http://SAMPLE_domain/cgi-bin/goto/p/en/member?action=startnew&sidlogin=MeMeMe
```

**Method 2:** Use subdomain or URL path with web server redirect:
```
http://MeMeMe.SAMPLE_domain/
http://SAMPLE_domain/MeMeMe
```
Both redirect to the signup page with the sponsor pre-filled.

Applicants can optionally specify their pyramid upline's member ID and leg, or rely on Auto Placement (see Section 2.5).

#### 3.1.2) Backend Processing

New applicants appear in Membership/New Signups. Managers can activate or delete applications. When activating, enter a transaction ID to track the payment source. The system records the timestamp and manager's name in `member_signup`.

After activation, the new member participates in all compensation plans.

### 3.2) Process Sales Orders

Upon signup activation, a Pending Order is generated in Sales. Update order status as processing progresses:

| Status | Description |
|--------|-------------|
| Pending | Payment received, awaiting packaging |
| Processing | Order packaged, in shipping department |
| Delivered | Product delivered (enter tracking ID) |

You may integrate your own logistics or ERP system for order tracking.

### 3.3) Online Shopping

MLM provides basic shopping functionality. You may enhance it or integrate third-party eCommerce software.

#### 3.3.1) Categories

Manage product categories in Product/Categories.

#### 3.3.2) Items

Manage individual product items in Product/Product Items, including price, BV, description, and images.

#### 3.3.3) Product Packages

Create product packages in Product/Packages by specifying name and membership type, then adding items. Package prices can differ from the sum of item prices (for discounts).

For signup packages, the system uses the intrinsic price from `def_type` for BV calculation. The BV remains fixed for a membership type regardless of package sales price.

#### 3.3.4) Retail Shopping

Members shop on the member portal:

```
http://SAMPLE_domain/cgi-bin/goto/m/en/member?action=dashboard
```

Members use their ledger balance to purchase products. If the balance is insufficient, they must deposit funds through offline methods.

### 3.4) Compensation and Ledger Books

Weekly, MLM generates reward bonuses. View detailed calculations in the backend's Compensations section.

For each compensation type:
- **Details:** Lists sales counts grouped by membership type within a week
- **Rewards:** Displays actual dollar amounts converted from sales

### 3.5) Ledger Book

Compensation amounts are deposited into `income_ledger`, split into two accounts:
- `balance`: For withdrawal
- `shop_balance`: For retail shopping

The split ratio is defined by `RATE_shop` in `config.json` (percentage for shopping; remainder for withdrawal).

| Ledger Status | Description |
|---------------|-------------|
| Weekly | Weekly compensation deposit |
| Monthly | Monthly compensation deposit |
| Shopping | Retail purchase deduction |
| Withdraw | Cash withdrawal |
| In | Offline deposit |

### 3.6) Cut-Off or Re-Join Pyramid

To disconnect a member from their upline's leg in the pyramid tree, or re-join a separated subtree to a different member, use Membership/Binary Tree in the backend.

> **Note:** Internally, cut pyramids are placed under a disabled system account (`TOP_memberid` in `config.json`).

### 3.7) Manage Administrators

Backend managers are classified into four groups:

| Group | Permissions |
|-------|-------------|
| ROOT | Full access, including manager management |
| ACCOUNTING | Selected accounting tasks |
| SUPPORT | Selected support tasks |
| MARKETING | Selected marketing tasks |

### 3.8) Compensation Tests

Compensation Test allows managers to preview bonus calculations without depositing funds.

ROOT users can access Execute and Write, which runs the actual bonus calculation process.

> **Warning:** Execute and Write operations are irreversible. Use only during early development for testing.

---

## Chapter 4. Additional Topics

### 4.1) Customization

To add a custom compensation plan (e.g., "Bonus X"):

1. Add column `statusX` to `cron_1week`
2. Add action `week1_x` to `lib/MLM/Income/component.json`
3. Add plan parameters to `Custom` block in `config.json`
4. Implement methods in `lib/MLM/Income/Model.pm`:
   - `is_week1_x`
   - `week1_x`
   - `done_week1_x`
   - `weekly_x`
5. Update `run_cron`, `run_daily`, and `run_all_tests` methods
6. Add to `bin/run_daily.pl`

### 4.2) Java and Go Development

Genelet supports Java and Go in addition to Perl. Contact [greetingland@gmail.com](mailto:greetingland@gmail.com) for details.

### 4.3) CSS Bootstrap Template

Dynamic HTML pages use Perl's Template Toolkit with [Bootstrap](https://getbootstrap.com/). To customize views:

1. Create a new view directory
2. Update `Template` in `config.json` to point to it
3. Copy the existing structure:
   ```bash
   (cd SAMPLE_home/views; tar cvf - *) | (cd NEW_view_directory; tar xvf -)
   ```
4. Modify templates as needed

### 4.4) JSON API

Change the URL tag from `en` to `json` to receive JSON responses instead of HTML:

```
http://SAMPLE_domain/cgi-bin/goto/m/json/member?action=dashboard
```

This enables API access for mobile apps and other integrations.

For app development or other extensions, refer to `openapi.yaml` for the complete OpenAPI 3.0 specification documenting all available endpoints, authentication methods, and request/response schemas.
