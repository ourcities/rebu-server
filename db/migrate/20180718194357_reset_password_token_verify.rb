class ResetPasswordTokenVerify < ActiveRecord::Migration
  def up
    execute <<-SQL
      CREATE OR REPLACE FUNCTION postgraphql.reset_password_token_verify(token text)
      returns json
      language plpgsql
      AS $function$
          declare
              _jwt json;
              _user public.users;
          begin

              if (select valid from pgjwt.verify(token, public.configuration('jwt_secret'), 'HS512')) is false then
                  raise 'invalid_token';
              end if;

              select payload
                  from pgjwt.verify(token, public.configuration('jwt_secret'), 'HS512')
              into _jwt;

              if to_date(_jwt->>'expirated_at', 'YYYY MM DD') <= now()::date then
                  raise 'invalid_token';
              end if;

              select * from public.users u where u.id = (_jwt->>'id')::int and u.reset_password_token = token into _user;
              if _user is null then
                  raise 'invalid_token';
              end if;

              return _jwt;
          end;
      $function$;
      grant execute on function postgraphql.reset_password_token_verify(token text) to anonymous;
    SQL
  end

  def down
    execute <<-SQL
      DROP FUNCTION POSTGRAPHQL.RESET_PASSWORD_TOKEN(token text);
    SQL
  end
end
