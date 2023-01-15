set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.fnc__edit_product(p_product_id bigint, p_name text, p_description text, p_category_id bigint, p_sub_category_ids bigint[], p_sub_brand_id bigint DEFAULT NULL::bigint)
 RETURNS SETOF products
 LANGUAGE plpgsql
AS $function$
declare
  v_product_edit_suggestion_id bigint;
  v_changed_name               text;
  v_changed_description        text;
  v_changed_category_id        bigint;
  v_changed_sub_brand_id       bigint;
  v_updated_product            products%ROWTYPE;
begin
  if fnc__has_permission(auth.uid(), 'can_edit_products') is false then
    raise exception 'user has no access to this feature';
  end if;

  update products
  set name         = p_name,
      description  = p_description,
      category_id  = p_category_id,
      sub_brand_id = p_sub_brand_id
  where id = p_product_id
  returning * into v_updated_product;

  insert into product_edit_suggestions (product_id, name, description, category_id, sub_brand_id, created_by)
  values (p_product_id, v_changed_name, v_changed_description, v_changed_category_id, v_changed_sub_brand_id,
          auth.uid())
  returning id into v_product_edit_suggestion_id;

  with current_subcategories as (select subcategory_id from products_subcategories where product_id = p_product_id)
  delete
  from products_subcategories ps
  where ps.product_id = p_product_id
    and ps.subcategory_id != any (p_sub_category_ids);

  with subcategories_for_product as (select p_product_id               product_id,
                                            unnest(p_sub_category_ids) subcategory_id)
  insert
  into products_subcategories (product_id, subcategory_id)
  select product_id, subcategory_id
  from subcategories_for_product
  on conflict do nothing;

  return query (select * from v_updated_product);
end
$function$
;

