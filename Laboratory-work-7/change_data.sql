CREATE OR REPLACE FUNCTION change_data(class text, name text)
RETURNS void AS
$$
DECLARE
str VARCHAR;
BEGIN
    str := 'UPDATE pupil SET class = ''' || class || ''' WHERE pupil_name = ''' || name || '''';
EXECUTE str;
END;
$$ LANGUAGE plpgsql;
