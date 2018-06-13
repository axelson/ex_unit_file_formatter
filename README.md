# ExUnitFileFormatter

Outputs the list of files that have failed tests and sorts them by number of
failures.

Example usage:

    mix test --formatter ExUnitFileFormatter

Example output (in an Umbrella application):

```
==> my_app

Failed Files:
1: /Users/jason/dev/my_app/apps/web_interface/test/controllers/internal_api/v1/page_controller_test.exs
==> parser

Failed Files:
9: /Users/jason/dev/my_app/apps/parser/test/parser_test.exs
5: /Users/jason/dev/my_app/apps/parser/test/parser_info_test.exs
1: /Users/jason/dev/my_app/apps/parser/test/file_parser_test.exs
==> ftp_handler
```
