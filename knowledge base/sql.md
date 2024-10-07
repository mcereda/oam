# Structured Query Language

Standard language for relational database management systems.

## TL;DR

`NULL` represents **unknown** or **missing** information.<br/>
It is **not** the same as an empty string or the number 0.

| Constraint | Description                                    |
| ---------- | ---------------------------------------------- |
| `NOT NULL` | The value cannot be `NULL`                     |
| `UNIQUE`   | The value must be unique in the table's column |

_Primary keys_ are one or more columns in a table used to uniquely identify a single row.<br/>
Tables can have **zero or one** primary keys. They **cannot** have more than one primary key.

Technically, primary key constraints are the combination of a `NOT NULL` constraint and a `UNIQUE` constraint.

_Foreign keys_ are one or more columns in a table that uniquely identify a row in **another** table.<br/>
They reference either the primary key or another `UNIQUE` constraint of the referenced table.

## Further readings

- [The SQL Standard - ISO/IEC 9075:2023 (ANSI X3.135)]
- [PostgreSQL]
- [MySQL]

<!--
  Reference
  ═╬═Time══
  -->

<!-- In-article sections -->
<!-- Knowledge base -->
[mysql]: mysql.md
[postgresql]: postgresql.md

<!-- Files -->
<!-- Upstream -->
[the sql standard - iso/iec 9075:2023 (ansi x3.135)]: https://blog.ansi.org/sql-standard-iso-iec-9075-2023-ansi-x3-135/

<!-- Others -->
