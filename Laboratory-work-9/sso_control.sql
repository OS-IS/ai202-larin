CREATE OR REPLACE PROCEDURE sso_control(
    v_user_name VARCHAR,
    v_token VARCHAR
)
AS $$
BEGIN
    IF NOT EXISTS ( SELECT FROM users u, sso_tokens t
                    WHERE lower(u.user_name) = v_user_name
                      AND u.user_id = t.user_id
                      AND t.token = v_token
    ) THEN
        RAISE EXCEPTION 'Auth Error';
    END IF;
END;
$$ LANGUAGE plpgsql;