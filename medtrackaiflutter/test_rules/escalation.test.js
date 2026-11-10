import { readFileSync } from 'fs';
import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} from '@firebase/rules-unit-testing';
import {
  doc, getDoc, setDoc, updateDoc, collection, query, where, getDocs,
} from 'firebase/firestore';

/**
 * missedDoseAlerts — the escalation record behind the caregiver chain.
 *
 * Each document names a patient's medicine and when they missed it, so only
 * the patient and the caregivers it was sent to may read it, and nobody may
 * write it from a client: acknowledging goes through the
 * acknowledgeMissedDose function, which checks the caller was alerted.
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
const MOM = 'mom_uid';
const BACKUP = 'backup_uid';
const STRANGER = 'stranger_uid';
const ALERT = `missedDoseAlerts/${PATIENT}_self_1_08:00_2026-09-29`;

const seedAlert = () => seed(async (db) => {
  await setDoc(doc(db, ALERT), {
    patientUid: PATIENT,
    medName: 'Warfarin',
    alertedUids: [MOM],
    dayKey: '2026-09-29',
  });
});

describe('missedDoseAlerts', () => {
  it('the alerted caregiver can read it', async () => {
    await seedAlert();
    await assertSucceeds(getDoc(doc(env.authenticatedContext(MOM).firestore(), ALERT)));
  });

  it('the alerted caregiver can list their alerts', async () => {
    await seedAlert();
    const db = env.authenticatedContext(MOM).firestore();
    await assertSucceeds(getDocs(query(
      collection(db, 'missedDoseAlerts'),
      where('alertedUids', 'array-contains', MOM),
    )));
  });

  it('the patient can read their own', async () => {
    await seedAlert();
    await assertSucceeds(getDoc(doc(env.authenticatedContext(PATIENT).firestore(), ALERT)));
  });

  it('a caregiver later in the chain cannot read it before being alerted', async () => {
    await seedAlert();
    await assertFails(getDoc(doc(env.authenticatedContext(BACKUP).firestore(), ALERT)));
  });

  it('a stranger cannot read or list it', async () => {
    await seedAlert();
    const db = env.authenticatedContext(STRANGER).firestore();
    await assertFails(getDoc(doc(db, ALERT)));
    await assertFails(getDocs(collection(db, 'missedDoseAlerts')));
  });

  it('nobody can forge an acknowledgment from the client', async () => {
    await seedAlert();
    await assertFails(updateDoc(doc(env.authenticatedContext(MOM).firestore(), ALERT), {
      acknowledgedBy: MOM,
    }));
    await assertFails(setDoc(doc(env.authenticatedContext(PATIENT).firestore(), ALERT), {
      patientUid: PATIENT, alertedUids: [STRANGER],
    }));
  });
});
