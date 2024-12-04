CREATE OR REPLACE FUNCTION get_data(pupil_name text)
    RETURNS TABLE
            (
                s_id  integer,
                name  varchar,
                class varchar
            )
AS
$$
DECLARE
    str VARCHAR;
BEGIN
    str := 'SELECT s_id, pupil_name, class FROM pupil WHERE pupil_name = ''' ||
           pupil_name || '''';
    RAISE NOTICE 'Query=%',str;
    RETURN QUERY EXECUTE str;
END;
$$ LANGUAGE plpgsql;