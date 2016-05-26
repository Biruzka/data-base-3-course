-- Equality select

SELECT *
FROM master_class
WHERE place = '{"street":"name of street", "house_num":2}';

-- Containment select

SELECT * FROM master_class WHERE place @> '{"house_num":2}';

-- Key exist select

SELECT * FROM master_class WHERE place ?| array['street', 'house_num'];

SELECT * FROM master_class WHERE place ?& array['street', 'house_num'];

-- use in table's selects
SELECT *
FROM master_class
WHERE place->>'street' = 'name of street'