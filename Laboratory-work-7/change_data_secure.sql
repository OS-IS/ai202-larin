CREATE OR REPLACE FUNCTION change_data_secure(class text, name text)
RETURNS void AS
$$
DECLARE
str VARCHAR;
BEGIN
    str := 'UPDATE pupil SET class = $1 WHERE pupil_name = $2';
EXECUTE str USING class, name;
END;
$$ LANGUAGE plpgsql;
