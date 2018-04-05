# koha-plugin-format-facet

Koha plugin for combining serveral marc fields and subfields into one single
facet. The rules of this module are specific an tailored
according to the requirements of the
Gothenburg University Library. Use it at your own risk and make sure to modify
it according to the needs of Your own Library or organization.

## Dependencies
The plugin is only useful in __Koha__ in combination with the __ElasticSearch__
search engine. It also depends on the __gub-plugin-extender__
code of Gothenburg University library. Furthermore it will need a hook called
__update_index_before__ in order to run automatically before the indexer runs.

## Notes about the fields that are analyzed
- leader position 06 (seventh), __type of record__
- leader postition 07 (eighth) __bibliographic level__
- 008 position 23 (twenty-fourth) __form of item__
- 042#9 - if it contains the string DBAS it is considered a database.
- ANY matches any character including whitespace
- the __other__ facet will only be set if none of the ten formats apply.
  Any bibliographic record having the format of __other__ found after indexing
  should be regarded as a failure in deciding the correct format.
  It might be an indication of incomplete rules,
  a possible misstake made during cataloging or a bug in this module.


The combination of the four makes out a footprint that would imply a certain
format, that is then put into a marc field of choice through configuration.

| #   | Format (GUB-Chamo) | Format (field value) | Format (Swedish description) | 000/06 Type of record | 000/07 Bibliographic level | 008/23 Form of item | 042#9 prod |
| --- | --- |  ------------------ | ----------- | ------------| --- | --- | --- |
| 1   | book | book               | Bok         | a   | acdm | NOT so | |
| 2   | book.ebook | ebook              | E-bok | a | acdm | so | |
| 3   | serial | journal            | Tidskrift | a | s | NOT so | |
| 4   | serial.ejournal | ejournal           | E-tidskrift | a | s | so | |
| 5   | movies | movie              | Film/video | g | ANY | ANY | |
| 6   | sound_recording | musicrecording     | Musikinspelning | j | ANY | | |
| 7   | sound_recording | otherrecording     | Inspelning övrig | i | ANY | | |
| 8   | notated_music | notatedmusic       | Musiktryck (noter) | cd | m | ANY | |
| 9   | database | database           | Databas | ak | i | ANY | DBAS |
| 10  | computer_games | eresource       | Elektronisk resurs | m | ANY | ANY | |
| 11  |  | other              | Övrigt | | | | |


The generated marc fields are put into the incomming records and returned to
the indexer but nothing is persisted. The idea is that library staff should able
to explicitly modifying the configured marc field, putting a format value
explicitly. Then this plugin will trust the judgement of the librarian that set
the value and leave the field as it is.

This plugin have no side effects. The modification it makes is returned with
the parameters sent into it.
