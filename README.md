# koha-plugin-format-facet

Koha plugin for combining serveral marc fields and subfields into one single
facet. It is tailored according to the requirements of the
Gothenburg University Library. Use it at your own risk.

## Fields that are analyzed
- leader position 6, __type of record__
- leader postition 7 __bibliographic level__
- 008 position 23 __form of item__
- 042#9 - if it contains the string DBAS it is considered a database.

The combination of the four makes out a footprint that would imply a certain
format, that is then put into a marc field of choice through configuration.

| #   | Format (GUB-Chamo) | Format (field value) | Format (Swedish description) | 000/06 Type of record | 000/07 Bibliographic level | 008/23 Form of item | 042#9 prod |
| --- | --- |  ------------------ | ----------- | ------------| --- | --- | --- |
| 1   | book | book               | Bok         | a   | acdm | NOT so | |
| 2   | book.ebook | ebook              | E-bok | a | acdm | so | |
| 3   | serial | journal            | Tidskrift | a | s | NOT so | |
| 4   | serial.ejournal | ejournal           | E-tidskrift | a | s | so | |
| 5   | movies | movie              | Film/video | g | | | |
| 6   | sound_recording | musicrecording     | Musikinspelning | j | | | |
| 7   | sound_recording | otherrecording     | Inspelning övrig | i | | | |
| 8   | notated_music | notatedmusic       | Musiktryck (noter) | cd | m | | |
| 9   | database | database           | Databas | ak | i | | DBAS |
| 10  | computer_games | eresource       | Elektronisk resurs | m | | | |
| 11  |  | other              | Övrigt | | | | |


The generated marc fields are put into the incomming records and returned to
the indexer but nothing is persisted. The idea is that library staff should able
to explicitly modifying the configured marc field, putting a format value
explicitly. Then this plugin will trust the judgement of the librarian that set
the value and leave the field as it is.

This plugin have no side effects. The modification it makes is returned with
the parameters sent into it.
