CREATE OR REPLACE FUNCTION get_data_secure(pupil_name text)
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
    str := 'SELECT s_id, pupil_name, class FROM pupil WHERE pupil_name =  $1';
    RETURN QUERY EXECUTE str USING pupil_name;
END;
$$ LANGUAGE plpgsql;