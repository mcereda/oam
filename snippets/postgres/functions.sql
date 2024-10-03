/**
 * Shuffle values in a column
 * Returns the number of affected rows
 *
 * Only works on that column, with no regards for data connections.
 * Requires a way to identify the row in the source table during the update.
 * └── Using 'ctid' over a table's primary key to avoid the need of specifying another column.
 * ctids shall stay the same, but values shall be numbered randomly (hence the shuffling part).
 *
 * Credits to <https://stackoverflow.com/questions/33555524/postgresql-shuffle-column-values#33555639>.
 *
 * SELECT user_id, name FROM band_members WHERE name IN ('mark', 'tom', 'travis') ORDER BY name;
 * SELECT shuffle_column('band_members','name');
 * SELECT user_id, name FROM band_members WHERE name IN ('mark', 'tom', 'travis') ORDER BY name;
 **/

CREATE OR REPLACE FUNCTION shuffle_column(
  table_name TEXT,
  column_name TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
  DECLARE affected_rows INTEGER;
  BEGIN
    EXECUTE format('
      WITH
        ctids AS (
          SELECT
            ROW_NUMBER() OVER (),
            ctid
          FROM %I
        ),
        shuffled_values AS (
          SELECT
            ROW_NUMBER() OVER (ORDER BY RANDOM()),
            %I AS new_value
          FROM %I
        )
      UPDATE %I
        SET %I = shuffled_values.new_value
        FROM shuffled_values JOIN ctids ON shuffled_values.row_number = ctids.row_number
        WHERE %I.ctid = ctids.ctid
    ', table_name, column_name, table_name, table_name, column_name, table_name);
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows;
  END;
$$;


/**
 * Replace UUID in a column
 * Returns the number of affected rows
 **/
