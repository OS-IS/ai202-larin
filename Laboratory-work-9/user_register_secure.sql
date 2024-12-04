CREATE OR REPLACE FUNCTION user_register_secure(
    v_user_name varchar,
    v_password varchar
)
    RETURNS INTEGER
AS $$
DECLARE
    num_digits INT;
    num_lowercase INT;
    num_uppercase INT;
    num_special INT;
BEGIN
    -- Перевірка, чи пароль у списку найгірших паролів
    IF NOT EXISTS (
        SELECT FROM worst_passwords
        WHERE passname = v_password
    ) THEN
        -- Розрахунок кількості символів різних типів
        num_digits := LENGTH(REGEXP_REPLACE(v_password, '[^0-9]', '', 'g'));
        num_lowercase := LENGTH(REGEXP_REPLACE(v_password, '[^a-z]', '', 'g'));
        num_uppercase := LENGTH(REGEXP_REPLACE(v_password, '[^A-Z]', '', 'g'));
        num_special := LENGTH(REGEXP_REPLACE(v_password, '[^!@#$%^&*]', '', 'g'));

        -- Перевірки надійності пароля
        IF LENGTH(v_password) >= 12 AND
           num_digits >= 3 AND
           num_lowercase >= 2 AND
           num_uppercase >= 4 AND
           num_special >= 4 THEN
            -- Якщо пароль відповідає вимогам, додаємо користувача
            INSERT INTO users (user_name, password_hash)
            VALUES (
                       v_user_name,
                       md5(v_password) -- внесення хеш-значення пароля
                   );
            RETURN 1;
        ELSE
            -- Виведення повідомлення про причину помилки
            RAISE NOTICE 'Password does not meet security requirements. Details: Length = %, Digits = %, Lowercase = %, Uppercase = %, Special = %',
                LENGTH(v_password), num_digits, num_lowercase, num_uppercase, num_special;
            RETURN -1;
        END IF;
    ELSE
        -- Пароль у списку найгірших паролів
        RAISE NOTICE 'Password = % is a bad password', v_password;
        RETURN -1;
    END IF;
END;
$$ LANGUAGE plpgsql;
