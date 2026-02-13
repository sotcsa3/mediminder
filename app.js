/* ============================================
   MediMinder – Application Logic
   ============================================ */

const APP_VERSION = '1.3.0';

// NOTE: DB object is now defined in firebase-db.js

// ============================================
// UTILITY HELPERS
// ============================================
function generateId() {
    return Date.now().toString(36) + Math.random().toString(36).substr(2, 6);
}

function todayStr() {
    return new Date().toISOString().split('T')[0];
}

function formatDate(dateStr) {
    const d = new Date(dateStr + 'T00:00:00');
    const months = ['jan.', 'feb.', 'márc.', 'ápr.', 'máj.', 'jún.',
        'júl.', 'aug.', 'szept.', 'okt.', 'nov.', 'dec.'];
    return `${months[d.getMonth()]} ${d.getDate()}.`;
}

function formatDateLong(dateStr) {
    const d = new Date(dateStr + 'T00:00:00');
    const months = ['január', 'február', 'március', 'április', 'május', 'június',
        'július', 'augusztus', 'szeptember', 'október', 'november', 'december'];
    const days = ['vasárnap', 'hétfő', 'kedd', 'szerda', 'csütörtök', 'péntek', 'szombat'];
    return `${d.getFullYear()}. ${months[d.getMonth()]} ${d.getDate()}. – ${days[d.getDay()]}`;
}

function formatDateTime(dateStr, timeStr) {
    return `${formatDate(dateStr)}, ${timeStr}`;
}

function isToday(dateStr) {
    return dateStr === todayStr();
}

function isFuture(dateStr) {
    return dateStr >= todayStr();
}

function isPast(dateStr) {
    return dateStr < todayStr();
}

function getFrequencyLabel(freq) {
    const labels = {
        daily1: 'Naponta 1x',
        daily2: 'Naponta 2x',
        daily3: 'Naponta 3x',
        weekly: 'Hetente',
        asneeded: 'Szükség szerint'
    };
    return labels[freq] || freq;
}

function getGreeting() {
    const hour = new Date().getHours();
    if (hour < 10) return '🌅 Jó reggelt';
    if (hour < 18) return '☀️ Jó napot';
    return '🌙 Jó estét';
}

function getWeekDates() {
    const today = new Date();
    const dates = [];
    for (let i = 0; i < 7; i++) {
        const d = new Date(today);
        d.setDate(today.getDate() + i);
        dates.push(d.toISOString().split('T')[0]);
    }
    return dates;
}

// ============================================
// TIME SELECTOR HELPERS (24h)
// ============================================
function generateTimeSelectHtml(timeStr) {
    let [h, m] = (timeStr || '08:00').split(':');

    let hours = '';
    for (let i = 0; i < 24; i++) {
        const val = String(i).padStart(2, '0');
        hours += `<option value="${val}" ${val === h ? 'selected' : ''}>${val}</option>`;
    }

    let minutes = '';
    for (let i = 0; i < 60; i += 5) {
        const val = String(i).padStart(2, '0');
        minutes += `<option value="${val}" ${val === m ? 'selected' : ''}>${val}</option>`;
    }

    return `<div class="time-select-wrapper">
        <select class="time-select hour">${hours}</select>
        <span class="time-separator">:</span>
        <select class="time-select minute">${minutes}</select>
    </div>`;
}

function getTimeSelectValue(wrapper) {
    const h = wrapper.querySelector('.hour').value;
    const m = wrapper.querySelector('.minute').value;
    return `${h}:${m}`;
}

// ============================================
// SAMPLE DATA
// ============================================
function seedSampleData() {
    if (DB.getMedications().length === 0 && DB.getAppointments().length === 0) {
        const today = todayStr();
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 3);
        const tomorrowStr = tomorrow.toISOString().split('T')[0];

        const pastDate = new Date();
        pastDate.setDate(pastDate.getDate() - 5);
        const pastStr = pastDate.toISOString().split('T')[0];

        DB.saveMedications([
            {
                id: generateId(),
                name: 'Metformin',
                dosage: '500mg',
                frequency: 'daily2',
                times: ['08:00', '20:00'],
                notes: 'Étkezés után'
            },
            {
                id: generateId(),
                name: 'Aspirin',
                dosage: '100mg',
                frequency: 'daily1',
                times: ['12:00'],
                notes: ''
            },
            {
                id: generateId(),
                name: 'Atorvastatin',
                dosage: '20mg',
                frequency: 'daily1',
                times: ['20:00'],
                notes: 'Lefekvés előtt'
            }
        ]);

        DB.saveAppointments([
            {
                id: generateId(),
                doctorName: 'Dr. Kovács Péter',
                specialty: 'Belgyógyászat',
                date: tomorrowStr,
                time: '10:00',
                location: 'Klinika, 3. emelet',
                notes: 'Vérvétel eredményét vinni',
                status: 'pending'
            },
            {
                id: generateId(),
                doctorName: 'Dr. Nagy Éva',
                specialty: 'Szemészet',
                date: pastStr,
                time: '14:00',
                location: 'Szemklinika, földszint',
                notes: '',
                status: 'done'
            }
        ]);

        DB.saveUser({ name: 'Anna' });
    }
}

// ============================================
// MEDICATION LOG HELPERS
// ============================================
function getMedLogKey(medId, date, time) {
    return `${medId}_${date}_${time}`;
}

function isMedTaken(medId, date, time) {
    const logs = DB.getMedLogs();
    return logs.some(l => l.medId === medId && l.date === date && l.time === time && l.taken);
}

function toggleMedTaken(medId, date, time) {
    const logs = DB.getMedLogs();
    const idx = logs.findIndex(l => l.medId === medId && l.date === date && l.time === time);

    if (idx >= 0) {
        logs[idx].taken = !logs[idx].taken;
        logs[idx].takenAt = logs[idx].taken ? new Date().toISOString() : null;
    } else {
        logs.push({
            id: generateId(),
            medId,
            date,
            time,
            taken: true,
            takenAt: new Date().toISOString()
        });
    }

    DB.saveMedLogs(logs);
}

function markAllTimesToday(medId) {
    const med = DB.getMedications().find(m => m.id === medId);
    if (!med) return;
    const today = todayStr();
    med.times.forEach(time => {
        if (!isMedTaken(medId, today, time)) {
            toggleMedTaken(medId, today, time);
        }
    });
}

function areMedAllTimesTakenToday(medId) {
    const med = DB.getMedications().find(m => m.id === medId);
    if (!med) return false;
    const today = todayStr();
    return med.times.every(time => isMedTaken(medId, today, time));
}

// ============================================
// TOAST
// ============================================
let toastTimer = null;
function showToast(message) {
    const el = document.getElementById('toast');
    const msg = document.getElementById('toast-message');
    msg.textContent = message;
    el.classList.remove('hidden');

    requestAnimationFrame(() => {
        el.classList.add('show');
    });

    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => {
        el.classList.remove('show');
        setTimeout(() => el.classList.add('hidden'), 400);
    }, 2500);
}

// ============================================
// CONFIRM DIALOG
// ============================================
let confirmResolve = null;

function showConfirm(title, message, icon = '⚠️') {
    return new Promise(resolve => {
        confirmResolve = resolve;
        document.getElementById('confirm-icon').textContent = icon;
        document.getElementById('confirm-title').textContent = title;
        document.getElementById('confirm-message').textContent = message;
        document.getElementById('modal-confirm').classList.remove('hidden');
    });
}

function setupConfirmDialog() {
    document.getElementById('btn-confirm-yes').addEventListener('click', () => {
        document.getElementById('modal-confirm').classList.add('hidden');
        if (confirmResolve) confirmResolve(true);
    });
    document.getElementById('btn-confirm-no').addEventListener('click', () => {
        document.getElementById('modal-confirm').classList.add('hidden');
        if (confirmResolve) confirmResolve(false);
    });
}

// ============================================
// NAVIGATION
// ============================================
let currentPage = 'dashboard';

function navigateTo(pageName) {
    currentPage = pageName;

    // Update pages
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.getElementById(`page-${pageName}`).classList.add('active');

    // Update nav
    document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
    document.querySelector(`.nav-item[data-page="${pageName}"]`).classList.add('active');

    // Refresh content
    if (pageName === 'dashboard') renderDashboard();
    if (pageName === 'medications') renderMedications();
    if (pageName === 'appointments') renderAppointments();
}

function setupNavigation() {
    document.querySelectorAll('.nav-item').forEach(btn => {
        btn.addEventListener('click', () => navigateTo(btn.dataset.page));
    });
}

// ============================================
// HEADER
// ============================================
function updateHeader() {
    const user = DB.getUser();
    document.getElementById('header-greeting').textContent = `${getGreeting()}, ${user.name}!`;
    document.getElementById('header-date').textContent = formatDateLong(todayStr());

    // Update account button
    const accountIcon = document.getElementById('account-icon');
    if (DB.isLoggedIn()) {
        accountIcon.textContent = '✅';
        accountIcon.title = 'Bejelentkezve';
    } else {
        accountIcon.textContent = '👤';
        accountIcon.title = 'Bejelentkezés';
    }
}

// ============================================
// RENDER: DASHBOARD
// ============================================
function renderDashboard() {
    renderDashboardMeds();
    renderDashboardAppointment();
    renderDashboardStats();
}

function renderDashboardMeds() {
    const meds = DB.getMedications();
    const container = document.getElementById('dashboard-meds');
    const emptyEl = document.getElementById('dashboard-meds-empty');
    const today = todayStr();

    if (meds.length === 0) {
        container.innerHTML = '';
        emptyEl.classList.remove('hidden');
        return;
    }

    emptyEl.classList.add('hidden');

    // Build flat list of all time slots for today
    const slots = [];
    meds.forEach(med => {
        med.times.forEach(time => {
            slots.push({
                med,
                time,
                taken: isMedTaken(med.id, today, time)
            });
        });
    });

    // Sort: untaken first, then by time
    slots.sort((a, b) => {
        if (a.taken !== b.taken) return a.taken ? 1 : -1;
        return a.time.localeCompare(b.time);
    });

    container.innerHTML = slots.map(slot => `
        <div class="dashboard-med-item ${slot.taken ? 'taken' : ''}" 
             data-med-id="${slot.med.id}" data-time="${slot.time}">
            <div class="med-item-left">
                <button class="med-checkbox ${slot.taken ? 'checked' : ''}" 
                        aria-label="${slot.taken ? 'Visszavonás' : 'Bevettem'}">
                    ${slot.taken ? '✓' : ''}
                </button>
                <div class="med-item-info">
                    <div class="med-item-name">${slot.med.name} ${slot.med.dosage}</div>
                    <div class="med-item-dosage">${getFrequencyLabel(slot.med.frequency)}</div>
                </div>
            </div>
            <span class="med-item-time">${slot.time}</span>
        </div>
    `).join('');

    // Click handlers
    container.querySelectorAll('.dashboard-med-item').forEach(item => {
        item.addEventListener('click', () => {
            const medId = item.dataset.medId;
            const time = item.dataset.time;
            toggleMedTaken(medId, today, time);
            renderDashboard();
            showToast(isMedTaken(medId, today, time) ? '✅ Bevettem!' : '↩️ Visszavonva');
        });
    });
}

function renderDashboardAppointment() {
    const appts = DB.getAppointments()
        .filter(a => isFuture(a.date) && a.status === 'pending')
        .sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time));

    const container = document.getElementById('dashboard-appointment');
    const emptyEl = document.getElementById('dashboard-appointment-empty');

    if (appts.length === 0) {
        container.innerHTML = '';
        emptyEl.classList.remove('hidden');
        return;
    }

    emptyEl.classList.add('hidden');
    const next = appts[0];

    container.innerHTML = `
        <div class="dashboard-appt-card">
            <div class="dashboard-appt-doctor">${next.doctorName}</div>
            ${next.specialty ? `<div class="dashboard-appt-specialty">${next.specialty}</div>` : ''}
            <div class="dashboard-appt-detail">
                <span class="dashboard-appt-detail-icon">📅</span>
                ${formatDateTime(next.date, next.time)}
            </div>
            ${next.location ? `
                <div class="dashboard-appt-detail">
                    <span class="dashboard-appt-detail-icon">📍</span>
                    ${next.location}
                </div>
            ` : ''}
            ${next.notes ? `
                <div class="dashboard-appt-detail" style="margin-top:6px; font-style:italic; color:#9E9E9E;">
                    <span class="dashboard-appt-detail-icon">📝</span>
                    ${next.notes}
                </div>
            ` : ''}
        </div>
    `;
}

function renderDashboardStats() {
    const meds = DB.getMedications();
    const today = todayStr();

    let taken = 0, total = 0;
    meds.forEach(med => {
        med.times.forEach(time => {
            total++;
            if (isMedTaken(med.id, today, time)) taken++;
        });
    });

    document.getElementById('stat-taken').textContent = taken;
    document.getElementById('stat-remaining').textContent = total - taken;

    // Appointments this week
    const weekDates = getWeekDates();
    const weekAppts = DB.getAppointments()
        .filter(a => weekDates.includes(a.date) && a.status === 'pending').length;
    document.getElementById('stat-appointments').textContent = weekAppts;
}

// ============================================
// RENDER: MEDICATIONS
// ============================================
let medViewMode = 'today';

function renderMedications() {
    const meds = DB.getMedications();
    const container = document.getElementById('medications-list');
    const emptyEl = document.getElementById('medications-empty');
    const today = todayStr();

    if (meds.length === 0) {
        container.innerHTML = '';
        emptyEl.classList.remove('hidden');
        return;
    }

    emptyEl.classList.add('hidden');

    container.innerHTML = meds.map(med => {
        const allTaken = areMedAllTimesTakenToday(med.id);

        return `
            <div class="med-card ${allTaken ? 'is-taken' : ''}" data-med-id="${med.id}">
                <div class="med-card-header">
                    <div>
                        <div class="med-card-name">${med.name}</div>
                        <div class="med-card-dosage">${med.dosage}</div>
                    </div>
                    <div class="med-card-actions">
                        <button class="med-card-action edit" data-med-id="${med.id}" aria-label="Szerkesztés">✏️</button>
                        <button class="med-card-action delete" data-med-id="${med.id}" aria-label="Törlés">🗑️</button>
                    </div>
                </div>
                <div class="med-card-schedule">
                    🔄 ${getFrequencyLabel(med.frequency)}
                </div>
                ${med.notes ? `<div class="med-card-notes">💬 ${med.notes}</div>` : ''}
                <div class="med-card-times">
                    ${med.times.map(time => {
            const taken = isMedTaken(med.id, today, time);
            return `
                            <span class="med-time-chip ${taken ? 'done' : 'pending'}" 
                                  data-med-id="${med.id}" data-time="${time}">
                                ${taken ? '✅' : '⏰'} ${time}
                            </span>
                        `;
        }).join('')}
                </div>
                ${allTaken
                ? `<div class="btn-take-med done">✅ Már mind bevettem</div>`
                : `<button class="btn-take-med take" data-med-id="${med.id}">
                         💊 Bevettem – mind
                       </button>`
            }
            </div>
        `;
    }).join('');

    // Time chip click
    container.querySelectorAll('.med-time-chip').forEach(chip => {
        chip.addEventListener('click', (e) => {
            e.stopPropagation();
            const medId = chip.dataset.medId;
            const time = chip.dataset.time;
            toggleMedTaken(medId, today, time);
            renderMedications();
            showToast(isMedTaken(medId, today, time) ? `✅ ${time} – Bevettem!` : `↩️ ${time} – Visszavonva`);
        });
    });

    // Take all button
    container.querySelectorAll('.btn-take-med.take').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            markAllTimesToday(btn.dataset.medId);
            renderMedications();
            showToast('✅ Minden bevéve!');
        });
    });

    // Edit buttons
    container.querySelectorAll('.med-card-action.edit').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            openMedModal(btn.dataset.medId);
        });
    });

    // Delete buttons
    container.querySelectorAll('.med-card-action.delete').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            e.stopPropagation();
            const confirmed = await showConfirm(
                'Gyógyszer törlése',
                'Biztosan törli ezt a gyógyszert? Ez a művelet nem vonható vissza.',
                '💊'
            );
            if (confirmed) {
                const meds = DB.getMedications().filter(m => m.id !== btn.dataset.medId);
                DB.saveMedications(meds);
                renderMedications();
                showToast('🗑️ Gyógyszer törölve');
            }
        });
    });
}

function setupMedDaySelector() {
    document.querySelectorAll('.day-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            document.querySelectorAll('.day-btn').forEach(b => b.classList.remove('active'));
            btn.classList.add('active');
            medViewMode = btn.dataset.day;
            renderMedications();
        });
    });
}

// ============================================
// RENDER: APPOINTMENTS
// ============================================
function renderAppointments() {
    const appts = DB.getAppointments();
    const upcoming = appts.filter(a => isFuture(a.date) || (isToday(a.date) && a.status === 'pending'))
        .sort((a, b) => (a.date + a.time).localeCompare(b.date + b.time));
    const past = appts.filter(a => isPast(a.date) || a.status !== 'pending')
        .sort((a, b) => (b.date + b.time).localeCompare(a.date + a.time));

    renderUpcomingAppointments(upcoming);
    renderPastAppointments(past);
}

function renderUpcomingAppointments(appts) {
    const container = document.getElementById('appointments-upcoming');
    const emptyEl = document.getElementById('appointments-upcoming-empty');

    if (appts.length === 0) {
        container.innerHTML = '';
        emptyEl.classList.remove('hidden');
        return;
    }

    emptyEl.classList.add('hidden');

    container.innerHTML = appts.map(appt => `
        <div class="appt-card" data-appt-id="${appt.id}">
            <div class="appt-card-header">
                <div>
                    <div class="appt-doctor">${appt.doctorName}</div>
                    ${appt.specialty ? `<span class="appt-specialty">${appt.specialty}</span>` : ''}
                </div>
                <div class="appt-card-actions">
                    <button class="med-card-action edit" data-appt-id="${appt.id}" aria-label="Szerkesztés">✏️</button>
                    <button class="med-card-action delete" data-appt-id="${appt.id}" aria-label="Törlés">🗑️</button>
                </div>
            </div>
            <div class="appt-detail">
                <span class="appt-detail-icon">📅</span>
                ${formatDateTime(appt.date, appt.time)}
            </div>
            ${appt.location ? `
                <div class="appt-detail">
                    <span class="appt-detail-icon">📍</span>
                    ${appt.location}
                </div>
            ` : ''}
            ${appt.notes ? `<div class="appt-notes">📝 ${appt.notes}</div>` : ''}
            <div class="appt-status-row">
                <button class="appt-status-btn btn-done" data-appt-id="${appt.id}" data-status="done">
                    ✅ Megtörtént
                </button>
                <button class="appt-status-btn btn-missed" data-appt-id="${appt.id}" data-status="missed">
                    ❌ Elmaradt
                </button>
            </div>
        </div>
    `).join('');

    // Status buttons
    container.querySelectorAll('.appt-status-btn').forEach(btn => {
        btn.addEventListener('click', () => {
            const appts = DB.getAppointments();
            const idx = appts.findIndex(a => a.id === btn.dataset.apptId);
            if (idx >= 0) {
                appts[idx].status = btn.dataset.status;
                DB.saveAppointments(appts);
                renderAppointments();
                showToast(btn.dataset.status === 'done' ? '✅ Vizit megtörtént' : '❌ Vizit elmaradt');
            }
        });
    });

    // Edit buttons
    container.querySelectorAll('.med-card-action.edit').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            openApptModal(btn.dataset.apptId);
        });
    });

    // Delete buttons
    container.querySelectorAll('.med-card-action.delete').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            e.stopPropagation();
            const confirmed = await showConfirm(
                'Találkozó törlése',
                'Biztosan törli ezt a találkozót?',
                '🩺'
            );
            if (confirmed) {
                const appts = DB.getAppointments().filter(a => a.id !== btn.dataset.apptId);
                DB.saveAppointments(appts);
                renderAppointments();
                showToast('🗑️ Találkozó törölve');
            }
        });
    });
}

function renderPastAppointments(appts) {
    const container = document.getElementById('appointments-past');
    const emptyEl = document.getElementById('appointments-past-empty');

    if (appts.length === 0) {
        container.innerHTML = '';
        emptyEl.classList.remove('hidden');
        return;
    }

    emptyEl.classList.add('hidden');

    container.innerHTML = appts.map(appt => `
        <div class="appt-card past-card status-${appt.status}" data-appt-id="${appt.id}">
            <div class="appt-card-header">
                <div>
                    <div class="appt-doctor">${appt.doctorName}</div>
                    ${appt.specialty ? `<span class="appt-specialty">${appt.specialty}</span>` : ''}
                </div>
                <div class="appt-card-actions">
                    <button class="med-card-action delete" data-appt-id="${appt.id}" aria-label="Törlés">🗑️</button>
                </div>
            </div>
            <div class="appt-detail">
                <span class="appt-detail-icon">📅</span>
                ${formatDateTime(appt.date, appt.time)}
            </div>
            <span class="appt-status-badge ${appt.status}">
                ${appt.status === 'done' ? '✅ Megtörtént' : appt.status === 'missed' ? '❌ Elmaradt' : '⏳ Folyamatban'}
            </span>
        </div>
    `).join('');

    // Delete buttons for past appointments
    container.querySelectorAll('.med-card-action.delete').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            e.stopPropagation();
            const confirmed = await showConfirm(
                'Találkozó törlése',
                'Biztosan törli ezt a korábbi találkozót?',
                '🩺'
            );
            if (confirmed) {
                const appts = DB.getAppointments().filter(a => a.id !== btn.dataset.apptId);
                DB.saveAppointments(appts);
                renderAppointments();
                showToast('🗑️ Találkozó törölve');
            }
        });
    });
}

// ============================================
// MEDICATION MODAL
// ============================================
function openMedModal(medId = null) {
    const modal = document.getElementById('modal-medication');
    const form = document.getElementById('form-medication');
    const title = document.getElementById('modal-med-title');
    const timeInputs = document.getElementById('time-inputs');

    form.reset();
    document.getElementById('med-id').value = '';

    if (medId) {
        const med = DB.getMedications().find(m => m.id === medId);
        if (!med) return;

        title.textContent = 'Gyógyszer szerkesztése';
        document.getElementById('med-id').value = med.id;
        document.getElementById('med-name').value = med.name;
        document.getElementById('med-dosage').value = med.dosage;
        document.getElementById('med-frequency').value = med.frequency;
        document.getElementById('med-notes').value = med.notes || '';

        timeInputs.innerHTML = med.times.map(t => `
            <div class="time-input-row">
                ${generateTimeSelectHtml(t)}
                ${med.times.length > 1 ? '<button type="button" class="btn-remove-time" aria-label="Törlés">&times;</button>' : ''}
            </div>
        `).join('');

        // Add delete handlers
        timeInputs.querySelectorAll('.btn-remove-time').forEach(btn => {
            btn.addEventListener('click', (e) => e.target.closest('.time-input-row').remove());
        });
    } else {
        title.textContent = 'Új gyógyszer';
        timeInputs.innerHTML = `
            <div class="time-input-row">
                ${generateTimeSelectHtml('08:00')}
            </div>
        `;
    }

    modal.classList.remove('hidden');
}

function closeMedModal() {
    document.getElementById('modal-medication').classList.add('hidden');
}

function setupMedModal() {
    document.getElementById('btn-add-med').addEventListener('click', () => openMedModal());
    document.getElementById('modal-med-close').addEventListener('click', closeMedModal);
    document.getElementById('btn-med-cancel').addEventListener('click', closeMedModal);

    // Add time input
    document.getElementById('btn-add-time').addEventListener('click', () => {
        const container = document.getElementById('time-inputs');
        const rows = container.querySelectorAll('.time-input-row');
        if (rows.length >= 5) {
            showToast('Maximum 5 időpont adható meg');
            return;
        }

        const div = document.createElement('div');
        div.className = 'time-input-row';
        div.innerHTML = `
            ${generateTimeSelectHtml('12:00')}
            <button type="button" class="btn-remove-time" aria-label="Törlés">&times;</button>
        `;

        div.querySelector('.btn-remove-time').addEventListener('click', () => div.remove());
        container.appendChild(div);
    });

    // Form submit
    document.getElementById('form-medication').addEventListener('submit', (e) => {
        e.preventDefault();

        const id = document.getElementById('med-id').value;
        const name = document.getElementById('med-name').value.trim();
        const dosage = document.getElementById('med-dosage').value.trim();
        const frequency = document.getElementById('med-frequency').value;
        const notes = document.getElementById('med-notes').value.trim();

        const times = Array.from(document.querySelectorAll('#time-inputs .time-select-wrapper'))
            .map(wrapper => getTimeSelectValue(wrapper))
            .sort();

        if (!name || !dosage) {
            showToast('❌ Kérem töltse ki a kötelező mezőket');
            return;
        }

        if (times.length === 0) {
            showToast('❌ Legalább egy időpont szükséges');
            return;
        }

        const meds = DB.getMedications();

        if (id) {
            const idx = meds.findIndex(m => m.id === id);
            if (idx >= 0) {
                meds[idx] = { ...meds[idx], name, dosage, frequency, times, notes };
            }
        } else {
            meds.push({ id: generateId(), name, dosage, frequency, times, notes });
        }

        DB.saveMedications(meds);
        closeMedModal();
        renderMedications();
        renderDashboard();
        showToast(id ? '✏️ Gyógyszer frissítve' : '✅ Gyógyszer hozzáadva');
    });

    // Close on overlay click
    document.getElementById('modal-medication').addEventListener('click', (e) => {
        if (e.target === e.currentTarget) closeMedModal();
    });
}

// ============================================
// APPOINTMENT MODAL
// ============================================
function openApptModal(apptId = null) {
    const modal = document.getElementById('modal-appointment');
    const form = document.getElementById('form-appointment');
    const title = document.getElementById('modal-appt-title');

    form.reset();
    document.getElementById('appt-id').value = '';

    if (apptId) {
        const appt = DB.getAppointments().find(a => a.id === apptId);
        if (!appt) return;

        title.textContent = 'Találkozó szerkesztése';
        document.getElementById('appt-id').value = appt.id;
        document.getElementById('appt-doctor').value = appt.doctorName;
        document.getElementById('appt-specialty').value = appt.specialty || '';
        document.getElementById('appt-date').value = appt.date;
        document.getElementById('appt-location').value = appt.location || '';
        document.getElementById('appt-notes').value = appt.notes || '';

        // Time select
        document.getElementById('appt-time-container').innerHTML = generateTimeSelectHtml(appt.time);
    } else {
        title.textContent = 'Új találkozó';
        // Set default date to tomorrow
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        document.getElementById('appt-date').value = tomorrow.toISOString().split('T')[0];

        // Default time
        document.getElementById('appt-time-container').innerHTML = generateTimeSelectHtml('10:00');
    }

    modal.classList.remove('hidden');
}

function closeApptModal() {
    document.getElementById('modal-appointment').classList.add('hidden');
}

function setupApptModal() {
    document.getElementById('btn-add-appointment').addEventListener('click', () => openApptModal());
    document.getElementById('modal-appt-close').addEventListener('click', closeApptModal);
    document.getElementById('btn-appt-cancel').addEventListener('click', closeApptModal);

    // Form submit
    document.getElementById('form-appointment').addEventListener('submit', (e) => {
        e.preventDefault();

        const id = document.getElementById('appt-id').value;
        const doctorName = document.getElementById('appt-doctor').value.trim();
        const specialty = document.getElementById('appt-specialty').value;
        const date = document.getElementById('appt-date').value;
        const location = document.getElementById('appt-location').value.trim();
        const notes = document.getElementById('appt-notes').value.trim();

        // Get time from custom selector
        const timeWrapper = document.querySelector('#appt-time-container .time-select-wrapper');
        const time = getTimeSelectValue(timeWrapper);

        if (!doctorName || !date) {
            showToast('❌ Kérem töltse ki a kötelező mezőket');
            return;
        }

        const appts = DB.getAppointments();

        if (id) {
            const idx = appts.findIndex(a => a.id === id);
            if (idx >= 0) {
                appts[idx] = { ...appts[idx], doctorName, specialty, date, time, location, notes };
            }
        } else {
            appts.push({
                id: generateId(),
                doctorName, specialty, date, time, location, notes,
                status: 'pending'
            });
        }

        DB.saveAppointments(appts);
        closeApptModal();
        renderAppointments();
        renderDashboard();
        showToast(id ? '✏️ Találkozó frissítve' : '✅ Találkozó hozzáadva');
    });

    // Close on overlay click
    document.getElementById('modal-appointment').addEventListener('click', (e) => {
        if (e.target === e.currentTarget) closeApptModal();
    });
}

// ============================================
// SPLASH SCREEN
// ============================================
function handleSplash() {
    const splash = document.getElementById('splash-screen');
    const app = document.getElementById('app');

    setTimeout(() => {
        splash.classList.add('fade-out');
        setTimeout(() => {
            splash.style.display = 'none';
            app.classList.remove('hidden');
            // Initial render
            updateHeader();
            renderDashboard();
        }, 600);
    }, 2000);
}

// ============================================
// AUTH UI
// ============================================
let authMode = 'login'; // 'login' or 'register'

function openAuthModal() {
    if (DB.isLoggedIn()) {
        // Show account info modal
        const user = auth.currentUser;
        document.getElementById('account-user-name').textContent = DB.getUser().name || 'Felhasználó';
        document.getElementById('account-user-email').textContent = user?.email || '';
        document.getElementById('modal-account').classList.remove('hidden');
    } else {
        // Show login modal
        authMode = 'login';
        updateAuthUI();
        document.getElementById('form-auth').reset();
        document.getElementById('auth-error').classList.add('hidden');
        document.getElementById('modal-auth').classList.remove('hidden');
    }
}

function closeAuthModal() {
    document.getElementById('modal-auth').classList.add('hidden');
}

function closeAccountModal() {
    document.getElementById('modal-account').classList.add('hidden');
}

function updateAuthUI() {
    const title = document.getElementById('modal-auth-title');
    const submitBtn = document.getElementById('btn-auth-submit');
    const switchText = document.getElementById('auth-switch-text');
    const switchBtn = document.getElementById('btn-auth-switch');

    if (authMode === 'login') {
        title.textContent = 'Bejelentkezés';
        submitBtn.textContent = 'Bejelentkezés';
        switchText.textContent = 'Még nincs fiókja?';
        switchBtn.textContent = 'Regisztráció';
    } else {
        title.textContent = 'Regisztráció';
        submitBtn.textContent = 'Regisztráció';
        switchText.textContent = 'Már van fiókja?';
        switchBtn.textContent = 'Bejelentkezés';
    }
}

function showAuthError(message) {
    const el = document.getElementById('auth-error');
    el.textContent = message;
    el.classList.remove('hidden');
}

function getAuthErrorMessage(code) {
    const messages = {
        'auth/user-not-found': 'Nem található fiók ezzel az email címmel.',
        'auth/wrong-password': 'Helytelen jelszó.',
        'auth/invalid-credential': 'Helytelen email vagy jelszó.',
        'auth/email-already-in-use': 'Ez az email cím már foglalt.',
        'auth/weak-password': 'A jelszó túl gyenge. Minimum 6 karakter.',
        'auth/invalid-email': 'Érvénytelen email cím.',
        'auth/too-many-requests': 'Túl sok próbálkozás. Kérjük várjon.',
        'auth/network-request-failed': 'Hálózati hiba. Ellenőrizze az internetkapcsolatot.'
    };
    return messages[code] || 'Ismeretlen hiba történt. Próbálja újra.';
}

function setupAuth() {
    // Account button
    document.getElementById('btn-account').addEventListener('click', openAuthModal);

    // Auth modal close
    document.getElementById('modal-auth-close').addEventListener('click', closeAuthModal);
    document.getElementById('modal-auth').addEventListener('click', (e) => {
        if (e.target === e.currentTarget) closeAuthModal();
    });

    // Account modal close
    document.getElementById('btn-account-close').addEventListener('click', closeAccountModal);
    document.getElementById('modal-account').addEventListener('click', (e) => {
        if (e.target === e.currentTarget) closeAccountModal();
    });

    // Toggle login/register
    document.getElementById('btn-auth-switch').addEventListener('click', () => {
        authMode = authMode === 'login' ? 'register' : 'login';
        updateAuthUI();
        document.getElementById('auth-error').classList.add('hidden');
    });

    // Form submit
    document.getElementById('form-auth').addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('auth-email').value.trim();
        const password = document.getElementById('auth-password').value;
        const submitBtn = document.getElementById('btn-auth-submit');

        submitBtn.disabled = true;
        submitBtn.textContent = 'Kérem várjon...';
        document.getElementById('auth-error').classList.add('hidden');

        try {
            if (authMode === 'register') {
                const cred = await auth.createUserWithEmailAndPassword(email, password);
                // Set user name from email
                const name = email.split('@')[0];
                DB.saveUser({ name, email });
                showToast('✅ Sikeres regisztráció!');
            } else {
                await auth.signInWithEmailAndPassword(email, password);
                showToast('✅ Sikeres bejelentkezés!');
            }
            closeAuthModal();
        } catch (error) {
            console.error('[Auth] Error:', error.code, error.message);
            showAuthError(getAuthErrorMessage(error.code));
        } finally {
            submitBtn.disabled = false;
            submitBtn.textContent = authMode === 'login' ? 'Bejelentkezés' : 'Regisztráció';
        }
    });

    // Google Sign-In
    document.getElementById('btn-google-signin').addEventListener('click', async () => {
        const btn = document.getElementById('btn-google-signin');
        btn.disabled = true;
        document.getElementById('auth-error').classList.add('hidden');

        try {
            const provider = new firebase.auth.GoogleAuthProvider();
            const result = await auth.signInWithPopup(provider);
            const user = result.user;
            DB.saveUser({
                name: user.displayName || user.email.split('@')[0],
                email: user.email
            });
            closeAuthModal();
            showToast('✅ Sikeres bejelentkezés!');
        } catch (error) {
            console.error('[Auth] Google error:', error.code, error.message);
            if (error.code !== 'auth/popup-closed-by-user') {
                showAuthError(getAuthErrorMessage(error.code));
            }
        } finally {
            btn.disabled = false;
        }
    });

    // Logout
    document.getElementById('btn-logout').addEventListener('click', async () => {
        await auth.signOut();
        closeAccountModal();
        showToast('👋 Kijelentkezve');
    });

    // Firebase auth state listener
    auth.onAuthStateChanged(async (user) => {
        if (user) {
            console.log('[Auth] Logged in:', user.email);
            await DB.onLogin(user.uid);
        } else {
            console.log('[Auth] Logged out');
            DB.onLogout();
        }
        updateHeader();
        renderDashboard();
        if (currentPage === 'medications') renderMedications();
        if (currentPage === 'appointments') renderAppointments();
    });

    // Listen for real-time data changes from other devices
    DB.onDataChange((type) => {
        console.log('[DB] Data changed:', type);
        if (currentPage === 'dashboard') renderDashboard();
        if (currentPage === 'medications' && (type === 'medications' || type === 'medLogs')) renderMedications();
        if (currentPage === 'appointments' && type === 'appointments') renderAppointments();
    });
}

// ============================================
// NOTIFICATIONS
// ============================================
const NOTIF_KEY = 'mediminder_notif_enabled';
const NOTIF_SENT_KEY = 'mediminder_notif_sent';

function isNotifEnabled() {
    return localStorage.getItem(NOTIF_KEY) === 'true' && Notification.permission === 'granted';
}

function getNotifSentToday() {
    try {
        const data = JSON.parse(localStorage.getItem(NOTIF_SENT_KEY) || '{}');
        if (data.date !== todayStr()) return {};
        return data.sent || {};
    } catch { return {}; }
}

function markNotifSent(medId, time) {
    const data = { date: todayStr(), sent: getNotifSentToday() };
    data.sent[`${medId}_${time}`] = true;
    localStorage.setItem(NOTIF_SENT_KEY, JSON.stringify(data));
}

function updateBellIcon() {
    const bell = document.getElementById('bell-icon');
    const btn = document.getElementById('btn-notifications');
    if (!('Notification' in window)) {
        bell.textContent = '🔕';
        btn.title = 'Értesítések nem támogatottak';
        return;
    }
    if (isNotifEnabled()) {
        bell.textContent = '🔔';
        btn.title = 'Értesítések bekapcsolva';
        btn.classList.add('active');
    } else {
        bell.textContent = '🔕';
        btn.title = 'Értesítések kikapcsolva';
        btn.classList.remove('active');
    }
}

function sendMedNotification(medName, dosage, time) {
    if (!isNotifEnabled()) return;
    try {
        new Notification('💊 MediMinder – Gyógyszer emlékeztető', {
            body: `${medName} ${dosage} – ${time}\nIdeje bevenni a gyógyszerét!`,
            icon: './icons/icon-192.png',
            badge: './icons/icon-192.png',
            tag: `med-${time}`,
            requireInteraction: true
        });
    } catch (e) {
        console.error('[Notif] Error sending:', e);
    }
}

function checkMedicationTimes() {
    if (!isNotifEnabled()) return;

    const now = new Date();
    const currentHH = String(now.getHours()).padStart(2, '0');
    const currentMM = String(now.getMinutes()).padStart(2, '0');
    const currentTime = `${currentHH}:${currentMM}`;

    const meds = DB.getMedications();
    const logs = DB.getMedLogs();
    const today = todayStr();
    const sent = getNotifSentToday();

    meds.forEach(med => {
        (med.times || []).forEach(time => {
            // Skip if already sent today
            if (sent[`${med.id}_${time}`]) return;

            // Skip if already taken
            const taken = logs.some(l =>
                l.medId === med.id && l.date === today && l.time === time && l.taken
            );
            if (taken) return;

            // Check if it's time (within 1-minute window)
            if (currentTime === time) {
                sendMedNotification(med.name, med.dosage, time);
                markNotifSent(med.id, time);
            }

            // Also send a reminder 5 minutes before
            const [h, m] = time.split(':').map(Number);
            const reminderDate = new Date(now);
            reminderDate.setHours(h, m - 5, 0);
            const remHH = String(reminderDate.getHours()).padStart(2, '0');
            const remMM = String(reminderDate.getMinutes()).padStart(2, '0');
            const reminderTime = `${remHH}:${remMM}`;

            if (currentTime === reminderTime) {
                try {
                    new Notification('⏰ MediMinder – Hamarosan!', {
                        body: `${med.name} ${med.dosage} – 5 perc múlva (${time})`,
                        icon: './icons/icon-192.png',
                        tag: `med-remind-${time}`
                    });
                } catch (e) { /* ignore */ }
                markNotifSent(med.id, time);
            }
        });
    });
}

let notifInterval = null;

function startNotifChecker() {
    if (notifInterval) clearInterval(notifInterval);
    if (isNotifEnabled()) {
        checkMedicationTimes();
        notifInterval = setInterval(checkMedicationTimes, 30000); // every 30 sec
        console.log('[Notif] Checker started');
    }
}

function stopNotifChecker() {
    if (notifInterval) {
        clearInterval(notifInterval);
        notifInterval = null;
        console.log('[Notif] Checker stopped');
    }
}

async function toggleNotifications() {
    if (!('Notification' in window)) {
        showToast('❌ A böngésző nem támogatja az értesítéseket');
        return;
    }

    if (isNotifEnabled()) {
        // Turn off
        localStorage.setItem(NOTIF_KEY, 'false');
        stopNotifChecker();
        updateBellIcon();
        showToast('🔕 Értesítések kikapcsolva');
        return;
    }

    // Request permission
    const permission = await Notification.requestPermission();
    if (permission === 'granted') {
        localStorage.setItem(NOTIF_KEY, 'true');
        startNotifChecker();
        updateBellIcon();
        showToast('🔔 Értesítések bekapcsolva!');
        // Send a test notification
        new Notification('✅ MediMinder értesítések aktívak!', {
            body: 'Emlékeztetni fogunk a gyógyszerbevételi időpontokra.',
            icon: './icons/icon-192.png'
        });
    } else {
        showToast('❌ Értesítés engedély megtagadva');
    }
}

function setupNotifications() {
    document.getElementById('btn-notifications').addEventListener('click', toggleNotifications);
    updateBellIcon();
    startNotifChecker();
}

// ============================================
// INIT
// ============================================
document.addEventListener('DOMContentLoaded', () => {
    // Show version
    document.getElementById('splash-version').textContent = `v${APP_VERSION}`;
    document.getElementById('app-version').textContent = `v${APP_VERSION}`;

    seedSampleData();
    setupNavigation();
    setupMedModal();
    setupApptModal();
    setupConfirmDialog();
    setupMedDaySelector();
    setupAuth();
    setupNotifications();
    handleSplash();
});
