class AdjustPayableFeeToUseLimit < ActiveRecord::Migration
  def up
    execute %Q{
CREATE OR REPLACE FUNCTION public.payable_fee(d donations)
 RETURNS numeric
 LANGUAGE sql
 IMMUTABLE
AS $function$
    select (
    case
    when d.payables is null or jsonb_array_length(d.payables) < 2 then
        (
            case 
            when extract(year from d.created_at) <= 2016 then
                (d.amount / 100.0) * 0.15
            else
                (d.amount / 100.0) * 0.13
            end
        )
    else
        (
            select 
                ((p ->> 'amount')::decimal / 100.0) -- ((p ->> 'fee')::decimal / 100.0)
            from jsonb_array_elements(d.payables) p
                where (p ->> 'fee')::decimal <> 0
                    limit 1
        )
    end)::decimal
$function$;
}
  end

  def down
    execute %Q{
    create or replace function public.payable_fee(d public.donations)
returns decimal language sql
immutable as $$
    select (
    case
    when jsonb_array_length(d.payables) < 2 then
        (
            case 
            when extract(year from d.created_at) <= 2016 then
                (d.amount / 100.0) * 0.15
            else
                (d.amount / 100.0) * 0.13
            end
        )
    else
        (
            select 
                ((p ->> 'amount')::decimal / 100.0) -- ((p ->> 'fee')::decimal / 100.0)
            from jsonb_array_elements(d.payables) p
                where (p ->> 'fee')::decimal <> 0
        )
    end)::decimal
$$;
}
  end
end
