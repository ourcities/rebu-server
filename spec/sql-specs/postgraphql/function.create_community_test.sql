begin;
  insert into public.users(id, email, provider, uid, encrypted_password, admin, locale) values
    (1, 'foo@foo.com', 'bonde', '1', crypt('123456', gen_salt('bf', 9)), false, 'pt-BR');

  select plan(7);

  select has_function('postgraphql', 'create_community', ARRAY['json']);
  select function_returns('postgraphql', 'create_community', ARRAY['json'], 'json');

  create or replace function test_create_community_not_authenticated()
  returns setof text language plpgsql as $$
  declare
  begin
    set local role anonymous;

    return next throws_matching(
    'select postgraphql.create_community(''{"name": "Nossa BH", "city": "Belo Horizonte"}''::json)',
      'permission_denied',
      'should be authenticated'
    );
  end;
  $$;
  select * from test_create_community_not_authenticated();

  create or replace function test_create_community_authenticated()
  returns setof text language plpgsql as $$
  declare
    /* _community public.communities; */
    _community json;
  begin
    set local role common_user;

    -- test missing requied attributes
    return next throws_matching(
      'select postgraphql.create_community(''{"name": "", "city": "Belo Horizonte"}''::json)',
      'missing_community_name',
      'should be raise when missing community name'
    );
    return next throws_matching(
      'select postgraphql.create_community(''{"name": "Nossa BH", "city": ""}''::json)',
      'missing_community_city',
      'should be raise when missing community city'
    );

    _community := postgraphql.create_community(
      json_build_object(
        'name', 'Nossa BH',
        'city', 'Belo Horizonte')
    );
    return next is(_community->>'name', 'Nossa BH', 'should community name equals Nossa BH');
    return next is(_community->>'city', 'Belo Horizonte', 'should community city equals Belo Horizonte');
  end;
  $$;
  select * from test_create_community_authenticated();
rollback;