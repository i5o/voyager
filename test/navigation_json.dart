const String navigation_json = '''
{
   "/home": {
      "type": "home",
      "widget": "HomeWidget",
      "title": "This is Home",
      "fab": "/other/thing"
   },
   "/other/:title": {
      "type": "other",
      "widget": "OtherWidget",
      "title": "This is %{title}"
   }
}
''';
