-- Get help
.help

-- View connections, tables & column information
.inspect


-- List AWS IAM users and their group
SELECT name FROM aws_iam_role
SELECT iam_user ->> 'UserName' AS User, name AS Group
  FROM aws_iam_group
  CROSS JOIN jsonb_array_elements(users) AS iam_user
