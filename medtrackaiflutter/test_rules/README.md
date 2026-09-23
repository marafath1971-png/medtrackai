# Firestore rules tests

Runs the real rules engine in the Firestore emulator — not a source-level
approximation. `firestore.rules` is the only thing under test.

```bash
firebase emulators:exec --only firestore --project medai-rules-test \
  "cd test_rules && npm test"
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

Dependent profiles (`dependents.test.js`). The app manages family members under
`users/{uid}/dependents/{profileId}/...`, but the rules had no match block for
that path. Rules do not cascade into subcollections, so the catch-all deny at
the bottom of the file blocked every dependent read and write — the whole
caregiver dataset — while the owner's identically-shaped collections worked.

Deleting the `match /dependents/{profileId}` block turns 7 of those tests red
(the owner and caregiver access cases); the deny cases stay green, because the
catch-all denies them for the wrong reason.
