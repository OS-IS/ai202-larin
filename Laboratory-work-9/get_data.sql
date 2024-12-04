CREATE OR REPLACE FUNCTION get_data(
    pupil_name text,
    v_user_name VARCHAR,
    v_token VARCHAR)
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
    CALL sso_control(v_user_name,v_token);
    str := 'SELECT s_id, pupil_name, class FROM pupil WHERE pupil_name =  $1';
    RETURN QUERY EXECUTE str USING pupil_name;
END;
$$ LANGUAGE plpgsql;