import { readFileSync } from 'fs';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

/**
 * Dependent profiles — the children and elderly relatives the app manages
 * under users/{uid}/dependents/{profileId}.
 *
 * firestore.rules had no match block for that path. Rules do not cascade into
 * subcollections, so the catch-all `allow read, write: if false` at the bottom
 * of the file denied every dependent read and write: the entire dataset behind
 * the "Dedicated Caregiver" persona was unreachable in production, while the
 * owner's own identically-shaped collections worked fine.
 *
 * Deleting the `match /dependents/{profileId}` block turns every test in this
 * file red, which is how the fix was confirmed.
 */

let env;

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'medai-rules-test',
    firestore: {
      rules: readFileSync('../firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });

const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

const PATIENT = 'patient_uid';
const CAREGIVER = 'caregiver_uid';
const STRANGER = 'stranger_uid';
const DEP = 'dependent_1';

/** Grants CAREGIVER an active, uid-keyed access grant — what isActiveCaregiver reads. */
const grantCaregiverAccess = () => seed(async (db) => {
  await setDoc(doc(db, `users/${PATIENT}/caregiverAccess/${CAREGIVER}`), {
    status: 'active',
  });
});

const DEP_MED = `users/${PATIENT}/dependents/${DEP}/medicines/med1`;
const DEP_HISTORY = `users/${PATIENT}/dependents/${DEP}/history/2026-09-22`;
const DEP_SYMPTOM = `users/${PATIENT}/dependents/${DEP}/symptoms/sym1`;
const DEP_DOC = `users/${PATIENT}/dependents/${DEP}`;

describe('dependent profiles — the owner', () => {
  it('can write a dependent medicine', async () => {
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertSucceeds(setDoc(doc(db, DEP_MED), { id: 1, name: 'Warfarin' }));
  });

  it('can read a dependent medicine back', async () => {
    await seed((db) => setDoc(doc(db, DEP_MED), { id: 1, name: 'Warfarin' }));
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertSucceeds(getDoc(doc(db, DEP_MED)));
  });

  it('can write and read dependent history', async () => {
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertSucceeds(setDoc(doc(db, DEP_HISTORY), { entries: [] }));
    await assertSucceeds(getDoc(doc(db, DEP_HISTORY)));
  });

  it('can write and read dependent symptoms', async () => {
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertSucceeds(setDoc(doc(db, DEP_SYMPTOM), { name: 'Headache' }));
    await assertSucceeds(getDoc(doc(db, DEP_SYMPTOM)));
  });

  it('can write the dependent parent doc that holds takenToday', async () => {
    // saveTakenToday is what creates this doc at all — it does not exist until
    // a dose is logged for that dependent.
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertSucceeds(setDoc(doc(db, DEP_DOC), { takenToday: { '1-08:00': true } }));
  });
});

describe('dependent profiles — an active caregiver', () => {
  it('can read a dependent medicine', async () => {
    await seed((db) => setDoc(doc(db, DEP_MED), { id: 1, name: 'Warfarin' }));
    await grantCaregiverAccess();
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertSucceeds(getDoc(doc(db, DEP_MED)));
  });

  it('can read dependent history', async () => {
    await seed((db) => setDoc(doc(db, DEP_HISTORY), { entries: [] }));
    await grantCaregiverAccess();
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertSucceeds(getDoc(doc(db, DEP_HISTORY)));
  });

  it('cannot write a dependent medicine', async () => {
    // Read-only, exactly as for the owner's own medicines. A caregiver
    // editing a dependent's schedule would be an unreviewed change to what
    // someone actually takes.
    await grantCaregiverAccess();
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertFails(setDoc(doc(db, DEP_MED), { id: 1, name: 'Forged' }));
  });

  it('cannot write dependent history', async () => {
    await grantCaregiverAccess();
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertFails(setDoc(doc(db, DEP_HISTORY), { entries: [] }));
  });

  it('loses access once the grant is revoked', async () => {
    await seed((db) => setDoc(doc(db, DEP_MED), { id: 1, name: 'Warfarin' }));
    await seed((db) => setDoc(doc(db, `users/${PATIENT}/caregiverAccess/${CAREGIVER}`), {
      status: 'revoked',
    }));
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertFails(getDoc(doc(db, DEP_MED)));
  });
});

describe('dependent profiles — an unrelated user', () => {
  it('cannot read a dependent medicine', async () => {
    await seed((db) => setDoc(doc(db, DEP_MED), { id: 1, name: 'Warfarin' }));
    const db = env.authenticatedContext(STRANGER).firestore();
    await assertFails(getDoc(doc(db, DEP_MED)));
  });

  it('cannot write a dependent medicine', async () => {
    const db = env.authenticatedContext(STRANGER).firestore();
    await assertFails(setDoc(doc(db, DEP_MED), { id: 1, name: 'Forged' }));
  });

  it('cannot read dependent history or symptoms', async () => {
    await seed((db) => setDoc(doc(db, DEP_HISTORY), { entries: [] }));
    await seed((db) => setDoc(doc(db, DEP_SYMPTOM), { name: 'Headache' }));
    const db = env.authenticatedContext(STRANGER).firestore();
    await assertFails(getDoc(doc(db, DEP_HISTORY)));
    await assertFails(getDoc(doc(db, DEP_SYMPTOM)));
  });
});

describe('dependent profiles — an unauthenticated caller', () => {
  it('cannot read or write dependent data', async () => {
    await seed((db) => setDoc(doc(db, DEP_MED), { id: 1, name: 'Warfarin' }));
    const db = env.unauthenticatedContext().firestore();
    await assertFails(getDoc(doc(db, DEP_MED)));
    await assertFails(setDoc(doc(db, DEP_MED), { id: 1, name: 'Forged' }));
  });
});
