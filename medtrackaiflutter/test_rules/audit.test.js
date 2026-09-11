import { readFileSync } from 'fs';
import assert from 'assert';
import {
  initializeTestEnvironment, assertFails, assertSucceeds,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'medai-rules-test',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8'),
                 host: '127.0.0.1', port: 8080 },
  });
});
after(async () => { if (env) await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });

const PATIENT = 'patient_uid';
const CAREGIVER = 'caregiver_uid';
const STRANGER = 'stranger_uid';
const CG_ID = '1712345678';

const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));

describe('FINDING 1: invite payload exposure — FIXED', () => {
  it('an identifying field cannot be written into an invite', async () => {
    // The document is readable by anyone holding the code, so the shape is
    // pinned rather than left to convention.
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertFails(setDoc(doc(db, 'caregiverInvites/SHAPE'), {
      patientUid: PATIENT, cgId: 1, relation: 'Spouse',
      patientName: 'Jane Doe', createdAt: serverTimestamp(),
    }));
  });

  it('the legitimate PHI-free payload is still accepted', async () => {
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertSucceeds(setDoc(doc(db, 'caregiverInvites/OK'), {
      patientUid: PATIENT, cgId: 1, relation: 'Spouse',
      createdAt: serverTimestamp(),
    }));
  });

  it('a stranger who reads an invite learns nothing identifying', async () => {
    await seed((db) => setDoc(doc(db, 'caregiverInvites/LIVE2'), {
      patientUid: PATIENT, cgId: 1, relation: 'Spouse', createdAt: new Date(),
    }));
    const db = env.authenticatedContext(STRANGER).firestore();
    const snap = await getDoc(doc(db, 'caregiverInvites/LIVE2'));
    const fields = Object.keys(snap.data() || {});
    assert.deepStrictEqual(fields.sort(),
      ['cgId', 'createdAt', 'patientUid', 'relation']);
  });

  it('createdAt is pinned to request.time — the window cannot be backdated', async () => {
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertFails(setDoc(doc(db, 'caregiverInvites/FUTURE'), {
      patientUid: PATIENT, cgId: 1, relation: 'Spouse',
      createdAt: new Date(Date.now() + 365 * 24 * 3600 * 1000),
    }));
  });
});

describe('FINDING 2: delete clause — FIXED', () => {
  it('a stranger can no longer delete a live invite', async () => {
    await seed((db) => setDoc(doc(db, 'caregiverInvites/VICTIM'), {
      patientUid: PATIENT, createdAt: new Date(),
    }));
    const db = env.authenticatedContext(STRANGER).firestore();
    await assertFails(deleteDoc(doc(db, 'caregiverInvites/VICTIM')));
  });

  it('the patient can still revoke their own invite', async () => {
    await seed((db) => setDoc(doc(db, 'caregiverInvites/MINE2'), {
      patientUid: PATIENT, createdAt: new Date(),
    }));
    const db = env.authenticatedContext(PATIENT).firestore();
    await assertSucceeds(deleteDoc(doc(db, 'caregiverInvites/MINE2')));
  });

  it('a caregiver can consume the invite once their grant exists', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, 'caregiverInvites/CONSUME'), {
        patientUid: PATIENT, createdAt: new Date(),
      });
      await setDoc(doc(db, `users/${PATIENT}/caregiverAccess/${CAREGIVER}`), {
        status: 'active',
      });
    });
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertSucceeds(deleteDoc(doc(db, 'caregiverInvites/CONSUME')));
  });

  it('invites are already immutable — no update clause exists', async () => {
    // Correcting my own first pass: I expected the patient to be able to
    // overwrite an invite. The block has create/read/delete and NO update, so
    // an overwrite is denied for everyone, patient included. That is the
    // immutability b383def asked for, and main already has it.
    await seed((db) => setDoc(doc(db, 'caregiverInvites/MUT'), {
      patientUid: PATIENT, createdAt: new Date(),
    }));
    const pdb = env.authenticatedContext(PATIENT).firestore();
    await assertFails(setDoc(doc(pdb, 'caregiverInvites/MUT'), {
      patientUid: PATIENT, createdAt: new Date(), relation: 'changed',
    }));
    const sdb = env.authenticatedContext(STRANGER).firestore();
    await assertFails(setDoc(doc(sdb, 'caregiverInvites/MUT'), {
      patientUid: PATIENT, createdAt: new Date(), relation: 'hijacked',
    }));
  });
});

describe('FINDING 3: isActiveCaregiver keying — FIXED', () => {
  it('an activated caregiver can read the patient data they monitor', async () => {
    // Exactly what activatePatientCaregiver() now writes: the cgId-keyed
    // roster entry AND the uid-keyed grant the rule can actually address.
    await seed(async (db) => {
      await setDoc(doc(db, `users/${PATIENT}/caregivers/${CG_ID}`), {
        status: 'active', joinedCaregiverUid: CAREGIVER,
      });
      await setDoc(doc(db, `users/${PATIENT}/caregiverAccess/${CAREGIVER}`), {
        status: 'active', cgId: 1712345678,
      });
      await setDoc(doc(db, `users/${PATIENT}`), { name: 'Jane' });
      await setDoc(doc(db, `users/${PATIENT}/medicines/m1`), { name: 'Aspirin' });
      await setDoc(doc(db, `users/${PATIENT}/history/2026-09-11`), { entries: [] });
      await setDoc(doc(db, `users/${PATIENT}/symptoms/s1`), { note: 'x' });
    });
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertSucceeds(getDoc(doc(db, `users/${PATIENT}`)));
    await assertSucceeds(getDoc(doc(db, `users/${PATIENT}/medicines/m1`)));
    await assertSucceeds(getDoc(doc(db, `users/${PATIENT}/history/2026-09-11`)));
    await assertSucceeds(getDoc(doc(db, `users/${PATIENT}/symptoms/s1`)));
  });

  it('a stranger with no grant still cannot read patient data', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, `users/${PATIENT}`), { name: 'Jane' });
      await setDoc(doc(db, `users/${PATIENT}/medicines/m1`), { name: 'Aspirin' });
    });
    const db = env.authenticatedContext(STRANGER).firestore();
    await assertFails(getDoc(doc(db, `users/${PATIENT}`)));
    await assertFails(getDoc(doc(db, `users/${PATIENT}/medicines/m1`)));
  });

  it('a revoked grant stops access', async () => {
    await seed(async (db) => {
      await setDoc(doc(db, `users/${PATIENT}/caregiverAccess/${CAREGIVER}`), {
        status: 'revoked',
      });
      await setDoc(doc(db, `users/${PATIENT}`), { name: 'Jane' });
    });
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertFails(getDoc(doc(db, `users/${PATIENT}`)));
  });

  it('a caregiver may create their own grant when redeeming', async () => {
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertSucceeds(setDoc(
      doc(db, `users/${PATIENT}/caregiverAccess/${CAREGIVER}`),
      { status: 'active', cgId: 1 }));
  });

  it('a caregiver cannot grant access to somebody else', async () => {
    const db = env.authenticatedContext(CAREGIVER).firestore();
    await assertFails(setDoc(
      doc(db, `users/${PATIENT}/caregiverAccess/${STRANGER}`),
      { status: 'active' }));
  });
});
