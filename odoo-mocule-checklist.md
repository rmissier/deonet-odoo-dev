# ✅ Odoo Module Creation Checklist

## 1. **Setup**

- [ ] Create a new folder in your custom `addons/` directory.
- [ ] Add **`__manifest__.py`** with:
  - `name`, `summary`, `version`
  - `depends` (list required modules, e.g., `['base']`)
  - `data` (security, views, menus, reports)
  - `installable`, `application`
- [ ] Add **`__init__.py`** to load Python files.

---

## 2. **Model Definition**

- [ ] Create `models/` folder with `__init__.py`.
- [ ] Define models in `models/my_model.py`:
  - `class MyModel(models.Model):`
  - `_name` = `'your_module.model'`
  - `_description` = `'Human readable description'`
- [ ] Add required **fields**:
  - Basic: `Char`, `Boolean`, `Float`, `Date`, etc.
  - Relational: `Many2one`, `One2many`, `Many2many`
  - Computed: `@api.depends`
  - Constrained: `@api.constrains`
- [ ] Define **defaults** and **SQL constraints**.

---

## 3. **Security**

- [ ] Create `security/ir.model.access.csv`:
  - Define CRUD permissions for groups.
- [ ] (Optional) Add `security/security.xml`:
  - Record rules (e.g., users only see their own records).
  - Custom groups (`res.groups`).

---

## 4. **Views & Menus**

- [ ] Create `views/my_model_views.xml` with:
  - `form`, `tree`, and optionally `kanban`, `calendar`, `graph`.
- [ ] Define **menu items** (`menuitem`).
- [ ] Define **actions** (`act_window`).
- [ ] (Optional) Inherit and extend existing views with `xpath`.

---

## 5. **Data Initialization**

- [ ] Add XML/CSV files in `data/` for:
  - Default values (e.g., sequences, default config).
  - Demo records (if `demo=True`).
- [ ] Reference them in `__manifest__.py → data`.

---

## 6. **Reports (if needed)**

- [ ] Create `report/report_template.xml` with QWeb.
- [ ] Create `report/report_action.xml` to link to models.
- [ ] Add report to `__manifest__.py → data`.

---

## 7. **Business Logic**

- [ ] Add Python methods in your models:
  - `action_confirm`, `action_approve`, etc.
- [ ] Expose them to the UI with:
  - Buttons (`<button name="method_name" type="object"/>`).
  - Automated actions or scheduled jobs.

---

## 8. **Wizards (if needed)**

- [ ] Create `wizard/` folder with transient models.
- [ ] Use for multi-step user dialogs.
- [ ] Define temporary fields and `def action_apply()` methods.

---

## 9. **Web / API (optional, advanced)**

- [ ] Add `controllers/` for REST/JSON endpoints.
- [ ] Serve custom JS/CSS in `static/`.

---

## 10. **Testing**

- [ ] Add `tests/test_module.py`.
- [ ] Use Odoo test framework (`TransactionCase`, `SavepointCase`).
- [ ] Run with:

  ```bash
  ./odoo-bin -d db_name --test-enable --stop-after-init

---

## 11. **Polish & Best Practices**

- [ ] Check for naming conflicts (use your_module. prefix).
- [ ] Ensure translations (_() for strings, .po files in i18n/).
- [ ] Batch operations for performance (avoid per-record loops).
- [ ] Make sure ir.model.access.csv is complete — or module won’t install.
- [ ] Keep modules focused & modular (don’t bundle unrelated features).

---

## 12. **Install & Test**

- [ ] Restart Odoo service.
- [ ] Update app list (Apps → Update Apps List).
- [ ] Search and install your module.
- [ ] Verify menus, views, security, reports, and business logic.

---

## 🚀 Quick Example Workflow

1. When creating a new module called `school_management`:
2. Create folder `school_management`/.
3. Add `__manifest__.py` and `__init__.py`.
4. Create `models/student.py` with school.student model.
5. Create `views/student_views.xml` (form & tree).
6. Add security in `security/ir.model.access.csv`.
7. Add menu under `“School”`.
8. Restart → update apps list → install.
