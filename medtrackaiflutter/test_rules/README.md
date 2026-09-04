# Firestore rules tests

Runs the real rules engine in the Firestore emulator — not a source-level
approximation. `firestore.rules` is the only thing under test.

```bash
firebase emulators:exec --only firestore --project medai-rules-test \
  "cd test_rules && npx mocha --timeout 20000 invites.test.js"
```

Needs **JDK 21+** (`firebase-tools` dropped 17). Point `JAVA_HOME` at a 21 JDK
for this command only — the Android build still wants 17, so do not change the
system default.

## What these cover

The invite probe. `SocialController.createInvite` generates a code and reads it
back up to five times to check for collisions, so the read happens when the
document does *not* exist. `resource` is null there, and the old rule
dereferenced `resource.data.createdAt` — which denies rather than returning
empty, so every invite creation failed in the uniqueness check.

Reverting that one line turns the two probe tests red, which is how the fix
was confirmed.
