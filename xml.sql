-- command to export doctor table to xml format
COPY (
  SELECT *
  FROM query_to_xml('SELECT * FROM person;', TRUE, FALSE, ''))
To '/Users/biruzka/Documents/person.xml'
WITH CSV;