# Source Academy language directory

`directory.json` is a bundled fallback copy of:

`https://source-academy.github.io/language-directory/directory.json`

`Cadet.Chatbot.LanguageDirectory` loads this copy immediately and refreshes its
in-memory cache from the URL when the application starts. A failed refresh does
not prevent chat from working with the last bundled directory.
