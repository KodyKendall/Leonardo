# Sprint 1, Week 1b: Authentication & Core Models (Dec 1-5)

**Duration:** 1 week
**Focus:** User authentication, roles, core Tender/Client/LineItem models
**Deliverable:** Users can log in, tenders can be created/edited with proper permissions

---

## Week Overview

Week 1b established the user authentication system and core tender management models. Users can now log in with email/password, and role-based access control restricts functionality appropriately.

**Status:** COMPLETED

---

## Scope: Authentication & Authorization

### User Authentication (Devise)
**Status:** COMPLETED

- Email/password authentication via Devise
- Session management and remember me functionality
- Password reset capability
- Login/logout workflows

### Role-Based Access Control
**Status:** COMPLETED

**User Roles Implemented:**
| Role | Access Level | Users |
|------|-------------|-------|
| Admin | Full system access | Richard, Ruan |
| QS (Quantity Surveyor) | Create/edit tenders, view rates | Demi |
| Office Staff | Create tenders, data entry, limited editing | Elmarie |
| Buyer | Update material rates only | Maria (planned) |

**Seeded Test Users:**
- Richard Spencer (richard@rsb.co.za) - Admin
- Demi Swanepoel (demi@rsb.co.za) - QS
- Elmarie (elmarie@rsb.co.za) - Office Staff

---

## Scope: Core Models

### Client Model
**Status:** COMPLETED

Fields: name, contact_person, email, phone, address, is_active

### Tender Model
**Status:** COMPLETED

- Tender number generation (E + sequential ID)
- Project type enum (commercial, mining)
- Status workflow (draft, in_progress, ready_for_review, etc.)
- Associations to User (created_by) and Client

### Tender Views
**Status:** COMPLETED

- Tenders index with status badges
- New tender form with client selection
- Tender show page with navigation tabs
- Edit tender functionality

---

## Scope: BOQ Foundation

### BOQ Upload
**Status:** COMPLETED

- CSV file upload capability
- File preview with row display
- Header row selection (to skip metadata rows)
- Original file stored for reference

### BOQ Model
**Status:** COMPLETED

- BOQ record linked to Tender
- Status tracking (uploaded, parsing, parsed, failed)
- File metadata storage

---

## Implementation Details

### Controllers Created
- `SessionsController` - Devise authentication
- `UsersController` - User management (admin only)
- `TendersController` - Full CRUD operations
- `BoqsController` - BOQ upload handling

### Key Views
- `app/views/devise/sessions/new.html.erb` - Login page
- `app/views/tenders/index.html.erb` - Tender list with filters
- `app/views/tenders/new.html.erb` - New tender form
- `app/views/tenders/show.html.erb` - Tender detail view
- `app/views/tenders/boq_upload.html.erb` - BOQ upload interface

### Permissions Matrix

| Action | Admin | QS | Office Staff | Buyer |
|--------|-------|----|--------------| ------|
| View tenders | Yes | Yes | Yes | No |
| Create tender | Yes | Yes | Yes | No |
| Edit tender | Yes | Yes | Limited | No |
| Delete tender | Yes | No | No | No |
| View rates | Yes | Yes | Yes | Yes |
| Edit rates | Yes | No | No | Yes (materials only) |

---

## Deliverables Achieved

- Users can log in with email/password
- Role-based permissions enforced on all tender operations
- Tender CRUD operations working
- Basic tender workflow established
- BOQ upload functional
- Foundation ready for AI parsing in Week 1c

---

## Rollover to Week 1c

- AI-powered BOQ parsing
- Line item review and finalization
- Mobile crane breakdown calculations
- Rate build-up foundation

---

**Week 1b Status:** COMPLETED
**Last Updated:** December 8, 2025
