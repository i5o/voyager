const String navigation_json = '''
{
   "/home": {
      "type": "home",
      "screen": "HomeWidget",
      "title": "This is Home",
      "fab": "/other/thing"
   },
   "/other/:title": {
      "type": "other",
      "screen": "OtherWidget",
      "title": "This is %{title}"
   }
}
''';
