# Controller Analysis: RESTful Design Review

Analysis of `sailings` controllers against RESTful resource-routing guidelines:
a controller should represent a **resource** (noun), and its actions should stay
within the seven REST verbs (`index, show, new, create, edit, update, destroy`).
Custom verb actions are a smell signalling a hidden resource that hasn't been named yet.

## Scorecard

| Controller | Actions | Non-REST | Verdict |
|---|---|---|---|
| `SessionsController` | 3 | 0 | ✅ Textbook singular resource |
| `PasswordsController` | 4 | 0 | ✅ Textbook |
| `MyRegistrationsController` | 1 (`show`) | 0 | ✅ Good "different audience" pattern |
| `MaintenanceTasksController` | 8 | 1 (`in_progress`) | 🟡 Minor |
| `UsersController` | 9 | 2 (`confirm_delete`, `disable`) | 🟡 One real smell |
| `SailingParticipantsController` | 8 | 2 (`bulk_update`, `sms_accepted`) | 🟠 One real smell + a god-method |
| `SailingsController` | **12** | **5** | 🔴 Doing far too much |

The app is quite RESTful overall — the auth controllers are textbook, and resource
nesting is used well. Issues are concentrated in a few fat controllers with custom-verb actions.

## 🔴 SailingsController — the main offender

12 actions, 5 custom (`calendar`, `financials`, `manifest`, `set_status`, `duplicate`).
Each custom action is a hidden resource:

- **`set_status`** → classic custom-verb smell. This *is* a resource:
  ```ruby
  resources :sailings do
    resource :status, only: :update   # Sailings::StatusesController#update
  end
  ```
- **`duplicate`** → creating a copy is a `create`:
  ```ruby
  resources :sailings do
    resources :duplicates, only: :create   # Sailings::DuplicatesController#create
  end
  ```
- **`manifest`** → a PDF document of a sailing is its own resource (`ManifestsController#show`),
  or simpler, a format on `show` (`show.pdf` via `respond_to`).
- **`calendar`** and **`financials`** → not actions on a sailing at all; they're **distinct
  read models** (one indexes by date range, the other is a paginated financial report filtered
  to charters). They deserve their own controllers: `CalendarController#index` and
  `FinancialsController#index` (or `FinancialReportsController`). Neither uses `set_sailing` —
  they're collection reads that happen to query `Sailing`.

Extracting those five takes Sailings back to a clean 7.

## 🟠 SailingParticipantsController

- **`sms_accepted`** → strong hidden-resource case. Queuing an SMS blast to accepted
  participants is **creating a notification**:
  ```ruby
  resources :sailings do
    resource :sms_blast, only: :create   # Sailings::SmsBlastsController#create
  end
  ```
- **`bulk_update`** → batch operations are a legitimate REST gray area, so the *routing* is
  defensible. The real problem is that it's a **god-method**: status updates + mailer dispatch +
  `days_sailed` accounting + training-date bookkeeping + sailing open/close, all inline. That
  logic belongs in the model or a service object regardless of controller. If you want it
  RESTful, model it as `resource :roster, only: :update`.

## 🟡 Minor

- **`Users#disable`** → a real (if mild) smell. It's a state change (soft-deactivation:
  `roles_mask: 0` + kill sessions). This is a hidden resource — `resource :activation,
  only: :destroy` (destroy = disable, create = re-enable). Worth doing if re-enabling is added.
- **`Users#confirm_delete`** → an interstitial confirmation page before `destroy`. Common and
  pragmatic; leave it. Low priority.
- **`MaintenanceTasks#in_progress`** → really just `index` with a filter (`date_fixed: nil`).
  Duplicates the pagination logic from `index`. Cleaner as `index` with a scope param
  (`?status=in_progress`), unless a distinct URL/nav entry is specifically wanted.

## Bottom line

Every custom-verb action in this app is a noun waiting to be named (`Status`, `Duplicate`,
`Manifest`, `SmsBlast`, `Activation`). The auth side already follows the guidelines perfectly;
applying the same discipline to `Sailings` is the highest-leverage cleanup. If tackling one
thing, split `calendar` and `financials` out first — they don't even operate on a single
sailing, so they're the least controversial extraction.
