-- List authentication policies
SHOW AUTHENTICATION POLICIES;

-- Create authentication policies
CREATE AUTHENTICATION POLICY allow_pats_policy AUTHENTICATION_METHODS = ('PROGRAMMATIC_ACCESS_TOKEN');

-- Delete authentication policies
DROP AUTHENTICATION POLICY allow_pats_policy;


-- List network policies
SHOW NETWORK RULES;
SHOW NETWORK RULES LIKE 'PYPI_RULE';

-- Get information about network rules
DESC NETWORK RULE 'PYPI_RULE';
DESCRIBE NETWORK RULE 'CLOUD_NETWORK';

-- Create network rules
CREATE NETWORK RULE cloud_network TYPE=IPV4 MODE=INGRESS VALUE_LIST=('47.88.25.32/27');

-- Delete network policies
DROP NETWORK RULE PYPI_RULE;
DROP NETWORK RULE IF EXISTS cloud_network;

-- List network policies
SHOW NETWORK POLICIES;

-- Create network policies
CREATE NETWORK POLICY allow_all_net_policy ALLOWED_IP_LIST = ('0.0.0.0/0');
CREATE NETWORK POLICY IF NOT EXISTS allow_aws_vpceid_block_public_policy
  ALLOWED_NETWORK_RULE_LIST = ('allow_aws_vpceid_access')
  BLOCKED_NETWORK_RULE_LIST = ('block_public_access_rule');

-- Set network policies at the account level
ALTER ACCOUNT SET NETWORK_POLICY = allow_aws_net_policy;

-- Delete network policies
DROP NETWORK POLICY allow_all_net_policy;


-- List warehouses
SHOW WAREHOUSES;

-- Show the warehouse in use
SELECT CURRENT_WAREHOUSE();

-- Use warehouses
USE WAREHOUSE dev_public_wh;

-- Show permissions objects have on warehouses
SHOW GRANTS ON WAREHOUSE dev_analytics_wh;

-- Delete warehouses
DROP WAREHOUSE IF EXISTS tuts_wh;


-- List databases
SHOW DATABASES;

-- Show the database in use
SELECT CURRENT_DATABASE();

-- Delete databases
DROP DATABASE IF EXISTS sf_tuts;


-- Show current role
SELECT CURRENT_ROLE();

-- Show roles available to the user
SELECT CURRENT_AVAILABLE_ROLES();

-- List roles
SHOW ROLES;
SHOW ROLES LIKE 'REDASH_SERVICE_ROLE';
SHOW ROLES LIKE '%DATA%';

-- Get information about users
DESC ROLE some_service_role;

-- Assume roles
-- the object assuming the role must have that role granted to it
USE ROLE USERADMIN;      -- create users and roles, manage the ones it owns
USE ROLE SYSADMIN;       -- create objects in an account
USE ROLE SECURITYADMIN;  -- manage objects' grants globally + create, monitor, and manage users and roles
USE ROLE ACCOUNTADMIN;   -- manage *all* resources in an account

-- Create roles
CREATE ROLE IF NOT EXISTS some_service_role;

-- Show permissions roles have
SHOW GRANTS TO ROLE SYSADMIN;
-- Show permissions the current role has on other objects
SHOW GRANTS ON ROLE SYSADMIN;

-- Grant permissions to roles
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE SYSADMIN;
GRANT USAGE ON DATABASE dev_dwh TO ROLE some_service_role;
GRANT USAGE ON SCHEMA dev_dwh.public TO ROLE some_service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA dev_dwh.public TO ROLE some_service_role;


-- Show current user
SELECT CURRENT_USER();

-- List users
SHOW USERS;
SHOW USERS LIKE 'BILLY';
SHOW USERS LIKE '%john%';
-- List service users
-- requires running in a warehouse
SELECT LOGIN_NAME FROM snowflake.account_usage.users WHERE TYPE='SERVICE';

-- Get information about users
DESC USER zoe;
DESCRIBE USER william;

-- Create users
CREATE USER alice;
CREATE USER IF NOT EXISTS bob;
CREATE OR REPLACE USER claude
  LOGIN_NAME='CLAUDE@EXAMPLE.ORG' DISPLAY_NAME='Claude' EMAIL='claude@example.org'
  PASSWORD='somePassword' MUST_CHANGE_PASSWORD=TRUE;
-- Create service users by specifying TYPE = SERVICE
-- Default resources do *not* need to exist beforehand, but *will* be used on login
CREATE USER IF NOT EXISTS some_service TYPE = SERVICE
  DEFAULT_ROLE = some_service_role DEFAULT_WAREHOUSE = dev_wh DEFAULT_NAMESPACE = dev_db.dev_schema;

-- Change user attributes
ALTER USER bob SET DEFAULT_WAREHOUSE = NULL;
ALTER USER my_service_user SET TYPE = SERVICE;
ALTER USER my_service_user UNSET PASSWORD;

-- Show permissions users have
SHOW GRANTS TO USER CLAUDE;
-- Show permissions the current user has on other users
SHOW GRANTS ON USER CLAUDE;

-- Grant permissions to users
GRANT ROLE some_service_role TO USER some_service_user;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO USER mike;

-- Assign policies to users
ALTER USER some_service_user SET AUTHENTICATION POLICY allow_pats_policy;
ALTER USER some_service_user SET NETWORK_POLICY = allow_all_net_policy;

-- List PATs for users
SHOW USER PROGRAMMATIC ACCESS TOKENS FOR USER some_service_user;

-- Generate PATs for users
-- 'ROLE_RESTRICTION' required for SERVICE users. Sets the role for the token. Must be uppercase.
-- 'DAYS_TO_EXPIRY' must be between 1 and 365. Cannot be modified later.
-- 'MINS_TO_BYPASS_NETWORK_POLICY_REQUIREMENT' and 'COMMENT' are optional.
ALTER USER nora ADD PROGRAMMATIC ACCESS TOKEN act_as_nora DAYS_TO_EXPIRY=15;
ALTER USER some_service_user ADD PROGRAMMATIC ACCESS TOKEN some_service_pat
  ROLE_RESTRICTION='SOME_SERVICE_ROLE'
  DAYS_TO_EXPIRY=365
  MINS_TO_BYPASS_NETWORK_POLICY_REQUIREMENT=3
  COMMENT='Some optional comment';

-- Rotate PATs for users
ALTER USER some_service_user ROTATE PROGRAMMATIC ACCESS TOKEN some_service_pat;

-- Rename PATs for users
ALTER USER some_service_user MODIFY PROGRAMMATIC ACCESS TOKEN some_service_pat
  RENAME TO some_service_pat_new COMMENT = 'new name';

-- Disable PATs for users
ALTER USER some_service_user MODIFY PROGRAMMATIC ACCESS TOKEN some_service_pat SET DISABLED = TRUE;

-- Delete PATs for users
ALTER USER some_service_user REMOVE PROGRAMMATIC ACCESS TOKEN some_service_pat;

-- Reset passwords
ALTER USER IF EXISTS elijah RESET PASSWORD;

-- Disable MFA
ALTER USER fred SET DISABLE_MFA=TRUE;

-- Unlock users
ALTER USER greg SET MINS_TO_UNLOCK=0;

-- Disable users
ALTER USER heather SET DISABLED=TRUE;

-- Delete users
DROP USER snowman;

-- Ensure multi-factor authentication (MFA) is turned on for all human users with password-based authentication
CREATE AUTHENTICATION POLICY enforce_password_mfa
  MFA_AUTHENTICATION_METHODS = ('PASSWORD')  -- enforce MFA when logging in with username and password
  MFA_ENROLLMENT = REQUIRED;                 -- require MFA enrollment when logging in with username and password
ALTER ACCOUNT SET AUTHENTICATION POLICY enforce_password_mfa;


-- Show current IP address
SELECT CURRENT_IP_ADDRESS();

-- Get the IDs of the AWS Virtual Network hosting the current Snowflake account
SELECT SYSTEM$GET_SNOWFLAKE_PLATFORM_INFO();

-- Get hostnames and port numbers to open to access Snowflake from behind firewalls
-- The output of this function can then be passed to SnowCD
SELECT SYSTEM$ALLOWLIST();

-- Get the Snowflake account's information necessary to facilitate the self-service configuration of private
-- connectivity to the Snowflake service or Snowflake internal stages.
SELECT SYSTEM$GET_PRIVATELINK_CONFIG();


-- Show the warehouse, database, and schema in use
SELECT CURRENT_WAREHOUSE(), CURRENT_DATABASE(), CURRENT_SCHEMA();

-- -----------------
-- programmatic access token setup
-- -----------------

-- 1. create policies
USE ROLE ACCOUNTADMIN;
CREATE AUTHENTICATION POLICY allow_pats_auth_policy AUTHENTICATION_METHODS=('PROGRAMMATIC_ACCESS_TOKEN');
CREATE NETWORK POLICY IF NOT EXISTS allow_all_net_policy ALLOWED_IP_LIST=('0.0.0.0/0');

-- 2. create service user and role
USE ROLE USERADMIN;
CREATE USER IF NOT EXISTS data_service_user TYPE=SERVICE DEFAULT_ROLE=data_service_role;
CREATE ROLE IF NOT EXISTS data_service_role;
GRANT USAGE ON DATABASE data_db TO ROLE data_service_role;
GRANT USAGE ON SCHEMA data_db.data_schema TO ROLE data_service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA data_db.data_schema TO ROLE data_service_role;
GRANT ROLE data_service_role TO USER data_service_user;

-- 3. grant policies
ALTER USER data_service_user SET AUTHENTICATION POLICY allow_pats_auth_policy;
ALTER USER data_service_user SET NETWORK_POLICY=allow_all_net_policy;

-- 4. create pat
ALTER USER data_service_user ADD PROGRAMMATIC ACCESS TOKEN data_service_pat
  ROLE_RESTRICTION='DATA_SERVICE_ROLE' DAYS_TO_EXPIRY=90 COMMENT='Test PAT';


-- -----------------
-- change users to service users
-- -----------------

ALTER USER my_service_user SET TYPE = SERVICE;
ALTER USER my_service_user UNSET PASSWORD;
ALTER USER my_service_user UNSET FIRST_NAME;
ALTER USER my_service_user UNSET MIDDLE_NAME;
ALTER USER my_service_user UNSET LAST_NAME;
ALTER USER my_service_user SET DISABLE_MFA = TRUE;
