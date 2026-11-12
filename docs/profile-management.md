# Profile management (M02)

`features/profiles/domain` defines UserProfile, ProfileRepository, ProfileSnapshot and validation. `data/local_profile_repository.dart` implements local SQLite operations; presentation contains ProfilesViewModel and reusable widgets. No backend profile endpoints, HTTP calls, login, or local number formulas are used.

## Lifecycle

- createProfile validates a trimmed 1–200 UTF-16-code-unit name with Latin/diacritic letter content and a real Gregorian YYYY-MM-DD date. It preserves Vietnamese text, creates a cryptographically random UUID, records UTC created/updated timestamps, and creates a random cache revision in one transaction. Future birth dates are permitted, consistent with the backend contract. Diacritic folding is for a presence-of-letters validation check only; stored names are not transliterated, and no numerology mapping is implemented. M03 still treats backend validation as authoritative for unusual non-Vietnamese names.
- getProfileById returns null when missing. getAllProfiles returns immutable profiles ordered by created_at then UUID for deterministic ties.
- updateProfile preserves ID/created_at. Changed name/date advances updated_at (at least one microsecond beyond the old timestamp if the device clock regresses), rotates the private revision and deletes private cache/context entries in the same transaction. A trimmed no-op update preserves timestamps/cache. Missing IDs return a safe notFound failure.
- deleteProfile is idempotent. Foreign keys delete calculation/revision/context records and clear selection in the same transaction. Shared interpretations remain available.
- selectProfile validates the ID and persists it in the SQLite singleton; null explicitly clears it. Invalid selection leaves existing state unchanged.
- getSnapshot reads list and selection in one transaction, repairing stale external references to null.

The first profile is automatically selected. Adding further profiles retains selection. Deleting a selected profile clears selection; it does not silently switch to another profile. Empty lists have null selection. Reopening the same database restores both records and selected ID. selected profile is never duplicated in shared_preferences.

## Riverpod

profileRepositoryProvider supplies the real local implementation. profilesViewModelProvider exposes AsyncValue<ProfileSnapshot>; selectedProfileProvider derives AsyncValue<UserProfile?> from the same snapshot. View-model writes serialize, hold the provider alive until completion, wait for initial state if needed, then refresh from a consistent repository snapshot. Failed writes propagate safe errors and retain the last visible data. refresh explicitly retries storage access. Consumers should await commands and display safe errors through localDataErrorMessage.

## Reusable UI only

- ProfileInputForm: create/edit prefill, Vietnamese full-name helper, three-part Gregorian date entry, save/loading/error state, local-storage note, onSaved callback. It does not choose a post-save route or trigger a calculation.
- ProfileSelectionTile: name/date, selection state, edit and delete actions, no fabricated numerical badges.
- ProfileList: async loading/error/empty/list states, persisted selection and confirmed local deletion; parents supply onEdit/onAdd navigation callbacks.
- confirmProfileDeletion: destructive confirmation, cancel by default; confirmation never logs the name.

Components use the M01 Design System's exact Stitch purple/gold/lavender palette, Inter/Playfair styles, 12-radius cards, documented spacing, production Material icons and safe busy controls. They are not mounted into or substituted for the eight route placeholders. Full screen layouts/navigation are M04 work. Salutation is present in Stitch but not in M02's requested five-field profile schema, so it is not persisted or sent to the backend.

All CRUD/selection commands are local and work without an API/Firebase connection. Full offline font fidelity still requires bundling fonts before release; font asset work is separate from profile data persistence.


## M04 screen wiring

V02 mounts ProfileInputForm with selectOnSave; its view-model saveAndSelect command uses existing CRUD then persists the chosen profile. V08 mounts reusable profile selection/edit/delete/add controls and actual selected-result metrics. V01 uses ProfileList in a local drawer. deleteAllProfiles is an additional transactional repository command invoked only by V10 after explicit confirmation; foreign keys clear selection/private cache while public articles remain. No database file or preferences are deleted. UserProfile has value equality to prevent unchanged selected records from triggering new calculations. Runtime checks remain blocked.
