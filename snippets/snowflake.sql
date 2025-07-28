-- List authentication policies
SHOW AUTHENTICATION POLICIES;

-- Create authentication policies
CREATE AUTHENTICATION POLICY allow_pats_policy AUTHENTICATION_METHODS = ('PROGRAMMATIC_ACCESS_TOKEN');

-- Delete authentication policies
DROP AUTHENTICATION POLICY allow_pats_policy;


-- List network policies
SHOW NETWORK POLICIES;

-- Create network policies
CREATE NETWORK POLICY IF NOT EXISTS allow_all_net_policy ALLOWED_IP_LIST = ('0.0.0.0/0');

-- Delete network policies
DROP NETWORK POLICY allow_all_net_policy;


-- List warehouses
SHOW WAREHOUSES;

-- Use warehouses
USE WAREHOUSE dev_public_wh;

-- Delete warehouses
DROP WAREHOUSE IF EXISTS tuts_wh;


-- List databases
SHOW DATABASES;

-- Delete databases
DROP DATABASE IF EXISTS sf_tuts;


-- List roles
SHOW ROLES;
SHOW ROLES LIKE '%DATA%';

-- Get information about users
DESC ROLE some_service_role;

-- Create roles
CREATE ROLE IF NOT EXISTS some_service_role;

-- Grant permissions to roles
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE SYSADMIN;
GRANT USAGE ON DATABASE dev_dwh TO ROLE some_service_role;
GRANT USAGE ON SCHEMA dev_dwh.public TO ROLE some_service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA dev_dwh.public TO ROLE some_service_role;

-- Assume roles
USE ROLE ACCOUNTADMIN;
USE ROLE USERADMIN;


-- List users
SHOW USERS;
SHOW USERS LIKE 'BILLY';
SHOW USERS LIKE '%john%';
-- List service users
-- requires running in a warehouse
SELECT LOGIN_NAME FROM snowflake.account_usage.users WHERE TYPE = 'SERVICE';

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
ALTER USER my_service_user SET TYPE = SERVICE; ALTER USER my_service_user UNSET PASSWORD;

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
ALTER USER some_service_user ADD PROGRAMMATIC ACCESS TOKEN some_service_pat
  ROLE_RESTRICTION='SOME_SERVICE_ROLE'  -- Uppercase. Required for SERVICE users. Sets the role for the token.
  DAYS_TO_EXPIRY=365                    -- 1 <= X <= 365. Cannot be modified later.
  MINS_TO_BYPASS_NETWORK_POLICY_REQUIREMENT=3  -- Optional
  COMMENT='Some comment';

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

-- Delete users
DROP USER snowman;


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
