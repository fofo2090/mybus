// Firebase Configuration Check
let db;
try {
    if (typeof firebase !== 'undefined' && firebase.apps.length > 0) {
        db = firebase.firestore();
        console.log('✅ Firebase connected successfully');
    } else {
        console.log('⚠️ Firebase not available, using mock data');
    }
} catch (error) {
    console.log('⚠️ Firebase error, using mock data:', error);
}

// Parent Students Management
class ParentStudentsManager {
    constructor() {
        this.students = [];
        this.filteredStudents = [];
        this.buses = [];
        this.currentStudentId = null;
        
        this.init();
    }

    async init() {
        console.log('🚀 Initializing Parent Students Manager...');

        try {
            // Show loading state
            this.showLoadingState();

            // Load data
            await this.loadStudents();
            await this.loadBuses();

            // Setup event listeners
            this.setupEventListeners();

            // Update statistics
            this.updateStatistics();

            // Hide loading state
            this.hideLoadingState();

            console.log('✅ Parent Students Manager initialized successfully');
        } catch (error) {
            console.error('❌ Error initializing Parent Students Manager:', error);
            this.hideLoadingState();
            this.showError('فشل في تحميل البيانات');
        }
    }

    showLoadingState() {
        const loadingState = document.getElementById('loadingState');
        const emptyState = document.getElementById('emptyState');
        const tableBody = document.getElementById('parentStudentsTableBody');

        if (loadingState) loadingState.style.display = 'block';
        if (emptyState) emptyState.style.display = 'none';
        if (tableBody) tableBody.innerHTML = '';
    }

    hideLoadingState() {
        const loadingState = document.getElementById('loadingState');
        if (loadingState) loadingState.style.display = 'none';
    }

    async loadStudents() {
        console.log('📚 Loading students from Firebase...');

        try {
            // Check if Firebase is available
            if (typeof firebase === 'undefined' || typeof db === 'undefined') {
                console.error('❌ Firebase not available');
                this.loadMockData();
                return;
            }

            // Try to load from Firebase
            const snapshot = await db.collection('students')
                .where('isActive', '==', true)
                .get();

            this.students = snapshot.docs.map(doc => {
                const data = doc.data();
                return {
                    id: doc.id,
                    ...data,
                    createdAt: data.createdAt?.toDate() || new Date(),
                    updatedAt: data.updatedAt?.toDate() || new Date(),
                    // Add approval status (default to pending for parent-added students)
                    approvalStatus: data.approvalStatus || 'pending',
                    // Ensure required fields exist
                    name: data.name || 'غير محدد',
                    parentName: data.parentName || 'غير محدد',
                    parentPhone: data.parentPhone || 'غير محدد',
                    grade: data.grade || 'غير محدد',
                    schoolName: data.schoolName || 'غير محدد',
                    busRoute: data.busRoute || 'غير محدد',
                    qrCode: data.qrCode || data.id,
                    parentId: data.parentId || 'unknown'
                };
            });

            console.log(`✅ Loaded ${this.students.length} students from Firebase`);

            // If no data from Firebase, load mock data
            if (this.students.length === 0) {
                console.log('📝 No students found in Firebase, loading mock data...');
                this.loadMockData();
            }

            // Filter and display
            this.applyFilters();

        } catch (error) {
            console.error('❌ Error loading students from Firebase:', error);
            console.log('📝 Loading mock data as fallback...');
            this.loadMockData();
        }
    }

    loadMockData() {
        console.log('📝 Loading mock student data...');

        this.students = [
            {
                id: 'student_1',
                name: 'أحمد محمد علي',
                parentName: 'محمد علي أحمد',
                parentPhone: '0501234567',
                parentId: 'parent_1',
                grade: 'الثالث الابتدائي',
                schoolName: 'مدرسة النور الابتدائية',
                busRoute: 'الرياض - حي النرجس',
                qrCode: 'STU001',
                approvalStatus: 'pending',
                photoUrl: null,
                createdAt: new Date(2024, 11, 1),
                updatedAt: new Date(2024, 11, 1),
                isActive: true
            },
            {
                id: 'student_2',
                name: 'فاطمة عبدالله',
                parentName: 'عبدالله محمد',
                parentPhone: '0507654321',
                parentId: 'parent_2',
                grade: 'الخامس الابتدائي',
                schoolName: 'مدرسة الأمل الابتدائية',
                busRoute: 'الرياض - حي الملقا',
                qrCode: 'STU002',
                approvalStatus: 'approved',
                photoUrl: null,
                createdAt: new Date(2024, 10, 28),
                updatedAt: new Date(2024, 11, 2),
                isActive: true
            },
            {
                id: 'student_3',
                name: 'خالد سعد',
                parentName: 'سعد خالد',
                parentPhone: '0551234567',
                parentId: 'parent_3',
                grade: 'الأول الابتدائي',
                schoolName: 'مدرسة المستقبل الابتدائية',
                busRoute: 'الرياض - حي العليا',
                qrCode: 'STU003',
                approvalStatus: 'pending',
                photoUrl: null,
                createdAt: new Date(2024, 11, 3),
                updatedAt: new Date(2024, 11, 3),
                isActive: true
            },
            {
                id: 'student_4',
                name: 'نورا أحمد',
                parentName: 'أحمد عبدالرحمن',
                parentPhone: '0509876543',
                parentId: 'parent_4',
                grade: 'الرابع الابتدائي',
                schoolName: 'مدرسة الفجر الابتدائية',
                busRoute: 'الرياض - حي الورود',
                qrCode: 'STU004',
                approvalStatus: 'approved',
                photoUrl: null,
                createdAt: new Date(2024, 10, 25),
                updatedAt: new Date(2024, 11, 1),
                isActive: true
            },
            {
                id: 'student_5',
                name: 'عبدالرحمن يوسف',
                parentName: 'يوسف عبدالرحمن',
                parentPhone: '0556789012',
                parentId: 'parent_5',
                grade: 'الثاني الابتدائي',
                schoolName: 'مدرسة الرسالة الابتدائية',
                busRoute: 'الرياض - حي الصحافة',
                qrCode: 'STU005',
                approvalStatus: 'rejected',
                photoUrl: null,
                createdAt: new Date(2024, 10, 30),
                updatedAt: new Date(2024, 11, 4),
                isActive: true
            },
            {
                id: 'student_6',
                name: 'مريم سالم',
                parentName: 'سالم مريم',
                parentPhone: '0503456789',
                parentId: 'parent_6',
                grade: 'السادس الابتدائي',
                schoolName: 'مدرسة الهدى الابتدائية',
                busRoute: 'الرياض - حي الياسمين',
                qrCode: 'STU006',
                approvalStatus: 'pending',
                photoUrl: null,
                createdAt: new Date(2024, 11, 5),
                updatedAt: new Date(2024, 11, 5),
                isActive: true
            }
        ];

        console.log(`✅ Loaded ${this.students.length} mock students`);
        this.applyFilters();
    }

    async loadBuses() {
        console.log('🚌 Loading buses from Firebase...');

        try {
            // Check if Firebase is available
            if (typeof firebase === 'undefined' || typeof db === 'undefined') {
                console.error('❌ Firebase not available');
                this.loadMockBuses();
                return;
            }

            const snapshot = await db.collection('buses')
                .where('isActive', '==', true)
                .get();

            this.buses = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));

            console.log(`✅ Loaded ${this.buses.length} buses from Firebase`);

            // If no buses from Firebase, load mock data
            if (this.buses.length === 0) {
                console.log('📝 No buses found in Firebase, loading mock data...');
                this.loadMockBuses();
            }

            // Populate bus selects
            this.populateBusSelects();
            this.populateRouteFilter();

        } catch (error) {
            console.error('❌ Error loading buses from Firebase:', error);
            console.log('📝 Loading mock buses as fallback...');
            this.loadMockBuses();
        }
    }

    loadMockBuses() {
        console.log('📝 Loading mock bus data...');

        this.buses = [
            {
                id: 'bus_1',
                plateNumber: 'أ ب ج 123',
                route: 'الرياض - حي النرجس',
                driverName: 'أحمد محمد',
                driverPhone: '0501234567',
                capacity: 30,
                isActive: true
            },
            {
                id: 'bus_2',
                plateNumber: 'د هـ و 456',
                route: 'الرياض - حي الملقا',
                driverName: 'محمد علي',
                driverPhone: '0507654321',
                capacity: 25,
                isActive: true
            },
            {
                id: 'bus_3',
                plateNumber: 'ز ح ط 789',
                route: 'الرياض - حي العليا',
                driverName: 'سعد أحمد',
                driverPhone: '0551234567',
                capacity: 35,
                isActive: true
            },
            {
                id: 'bus_4',
                plateNumber: 'ي ك ل 012',
                route: 'الرياض - حي الورود',
                driverName: 'عبدالله سالم',
                driverPhone: '0509876543',
                capacity: 28,
                isActive: true
            },
            {
                id: 'bus_5',
                plateNumber: 'م ن س 345',
                route: 'الرياض - حي الصحافة',
                driverName: 'خالد يوسف',
                driverPhone: '0556789012',
                capacity: 32,
                isActive: true
            },
            {
                id: 'bus_6',
                plateNumber: 'ع ف ص 678',
                route: 'الرياض - حي الياسمين',
                driverName: 'فهد عبدالرحمن',
                driverPhone: '0503456789',
                capacity: 30,
                isActive: true
            }
        ];

        console.log(`✅ Loaded ${this.buses.length} mock buses`);

        // Populate bus selects
        this.populateBusSelects();
        this.populateRouteFilter();
    }

    populateBusSelects() {
        const assignBusSelect = document.getElementById('assignBusSelect');
        if (assignBusSelect) {
            assignBusSelect.innerHTML = '<option value="">اختر سيارة...</option>';
            
            this.buses.forEach(bus => {
                const option = document.createElement('option');
                option.value = bus.id;
                option.textContent = `${bus.plateNumber} - ${bus.route}`;
                assignBusSelect.appendChild(option);
            });
        }
    }

    populateRouteFilter() {
        const routeFilter = document.getElementById('routeFilter');
        if (routeFilter) {
            const routes = [...new Set(this.buses.map(bus => bus.route))].sort();
            
            routes.forEach(route => {
                const option = document.createElement('option');
                option.value = route;
                option.textContent = route;
                routeFilter.appendChild(option);
            });
        }
    }

    setupEventListeners() {
        // Search input
        const searchInput = document.getElementById('searchInput');
        if (searchInput) {
            searchInput.addEventListener('input', () => this.applyFilters());
        }

        // Filter selects
        ['gradeFilter', 'statusFilter', 'routeFilter'].forEach(filterId => {
            const filter = document.getElementById(filterId);
            if (filter) {
                filter.addEventListener('change', () => this.applyFilters());
            }
        });

        // Modal buttons
        const approveBtn = document.getElementById('approveStudentBtn');
        if (approveBtn) {
            approveBtn.addEventListener('click', () => this.showApproveModal());
        }

        const rejectBtn = document.getElementById('rejectStudentBtn');
        if (rejectBtn) {
            rejectBtn.addEventListener('click', () => this.rejectStudent());
        }

        const confirmApproveBtn = document.getElementById('confirmApproveBtn');
        if (confirmApproveBtn) {
            confirmApproveBtn.addEventListener('click', () => this.confirmApproveStudent());
        }

        // Excel import buttons
        const importBtn = document.getElementById('importExcelBtn');
        const fileInput = document.getElementById('excelFile');

        if (importBtn) {
            importBtn.addEventListener('click', () => fileInput.click());
        }

        if (fileInput) {
            fileInput.addEventListener('change', (event) => this.handleExcelImport(event));
        }
    }

    applyFilters() {
        const searchTerm = document.getElementById('searchInput')?.value.toLowerCase() || '';
        const gradeFilter = document.getElementById('gradeFilter')?.value || '';
        const statusFilter = document.getElementById('statusFilter')?.value || '';
        const routeFilter = document.getElementById('routeFilter')?.value || '';

        this.filteredStudents = this.students.filter(student => {
            const matchesSearch = !searchTerm || 
                student.name.toLowerCase().includes(searchTerm) ||
                student.parentName.toLowerCase().includes(searchTerm);
            
            const matchesGrade = !gradeFilter || student.grade === gradeFilter;
            const matchesStatus = !statusFilter || student.approvalStatus === statusFilter;
            const matchesRoute = !routeFilter || student.busRoute === routeFilter;

            return matchesSearch && matchesGrade && matchesStatus && matchesRoute;
        });

        this.renderStudentsTable();
        this.updateStatistics();
    }

    renderStudentsTable() {
        const tbody = document.getElementById('parentStudentsTableBody');
        const loadingState = document.getElementById('loadingState');
        const emptyState = document.getElementById('emptyState');

        if (!tbody) return;

        // Hide loading state
        if (loadingState) loadingState.style.display = 'none';

        if (this.filteredStudents.length === 0) {
            tbody.innerHTML = '';
            if (emptyState) emptyState.style.display = 'block';
            return;
        }

        if (emptyState) emptyState.style.display = 'none';

        tbody.innerHTML = this.filteredStudents.map(student => `
            <tr>
                <td>
                    ${student.photoUrl ? 
                        `<img src="${student.photoUrl}" alt="${student.name}" class="rounded-circle" width="40" height="40" style="object-fit: cover;">` :
                        `<div class="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center" style="width: 40px; height: 40px; font-weight: bold;">
                            ${student.name.charAt(0)}
                        </div>`
                    }
                </td>
                <td>
                    <strong>${student.name}</strong><br>
                    <small class="text-muted">QR: ${student.qrCode}</small>
                </td>
                <td>
                    <strong>${student.parentName}</strong><br>
                    <small class="text-muted">${student.parentPhone}</small>
                </td>
                <td>${student.grade}</td>
                <td>${student.schoolName}</td>
                <td>${student.busRoute}</td>
                <td>${this.formatDate(student.createdAt)}</td>
                <td>${this.getStatusBadge(student.approvalStatus)}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary me-1" onclick="parentStudentsManager.viewStudentDetails('${student.id}')">
                        <i class="fas fa-eye"></i>
                    </button>
                    ${student.approvalStatus === 'pending' ? `
                        <button class="btn btn-sm btn-outline-success me-1" onclick="parentStudentsManager.quickApprove('${student.id}')">
                            <i class="fas fa-check"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-danger" onclick="parentStudentsManager.quickReject('${student.id}')">
                            <i class="fas fa-times"></i>
                        </button>
                    ` : ''}
                </td>
            </tr>
        `).join('');
    }

    getStatusBadge(status) {
        const badges = {
            'approved': '<span class="badge bg-success">معتمد</span>',
            'pending': '<span class="badge bg-warning">في انتظار المراجعة</span>',
            'rejected': '<span class="badge bg-danger">مرفوض</span>'
        };
        return badges[status] || '<span class="badge bg-secondary">غير محدد</span>';
    }

    formatDate(date) {
        if (!date) return 'غير محدد';
        return new Intl.DateTimeFormat('ar-SA', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        }).format(date);
    }

    updateStatistics() {
        const total = this.students.length;
        const approved = this.students.filter(s => s.approvalStatus === 'approved').length;
        const pending = this.students.filter(s => s.approvalStatus === 'pending').length;
        const activeParents = new Set(this.students.map(s => s.parentId)).size;

        document.getElementById('totalParentStudents').textContent = total;
        document.getElementById('approvedStudents').textContent = approved;
        document.getElementById('pendingStudents').textContent = pending;
        document.getElementById('activeParents').textContent = activeParents;
    }

    viewStudentDetails(studentId) {
        const student = this.students.find(s => s.id === studentId);
        if (!student) return;

        this.currentStudentId = studentId;

        const content = document.getElementById('studentDetailsContent');
        if (content) {
            content.innerHTML = `
                <div class="row">
                    <div class="col-md-4 text-center">
                        ${student.photoUrl ? 
                            `<img src="${student.photoUrl}" alt="${student.name}" class="img-fluid rounded-circle mb-3" style="max-width: 150px;">` :
                            `<div class="bg-primary text-white rounded-circle d-flex align-items-center justify-content-center mx-auto mb-3" style="width: 150px; height: 150px; font-size: 3rem; font-weight: bold;">
                                ${student.name.charAt(0)}
                            </div>`
                        }
                        <h5>${student.name}</h5>
                        ${this.getStatusBadge(student.approvalStatus)}
                    </div>
                    <div class="col-md-8">
                        <table class="table table-borderless">
                            <tr><th>الصف:</th><td>${student.grade}</td></tr>
                            <tr><th>المدرسة:</th><td>${student.schoolName}</td></tr>
                            <tr><th>خط السير:</th><td>${student.busRoute}</td></tr>
                            <tr><th>ولي الأمر:</th><td>${student.parentName}</td></tr>
                            <tr><th>هاتف ولي الأمر:</th><td>${student.parentPhone}</td></tr>
                            <tr><th>رمز QR:</th><td><code>${student.qrCode}</code></td></tr>
                            <tr><th>تاريخ الإضافة:</th><td>${this.formatDate(student.createdAt)}</td></tr>
                            <tr><th>آخر تحديث:</th><td>${this.formatDate(student.updatedAt)}</td></tr>
                        </table>
                    </div>
                </div>
            `;
        }

        const modal = new bootstrap.Modal(document.getElementById('studentDetailsModal'));
        modal.show();
    }

    showApproveModal() {
        const modal = new bootstrap.Modal(document.getElementById('approveStudentModal'));
        modal.show();
    }

    async quickApprove(studentId) {
        this.currentStudentId = studentId;
        await this.approveStudent();
    }

    async quickReject(studentId) {
        this.currentStudentId = studentId;
        await this.rejectStudent();
    }

    async approveStudent() {
        if (!this.currentStudentId) return;

        try {
            // Check if Firebase is available
            if (typeof firebase !== 'undefined' && typeof db !== 'undefined') {
                await db.collection('students').doc(this.currentStudentId).update({
                    approvalStatus: 'approved',
                    approvedAt: firebase.firestore.FieldValue.serverTimestamp(),
                    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                });
            } else {
                // Update mock data
                const student = this.students.find(s => s.id === this.currentStudentId);
                if (student) {
                    student.approvalStatus = 'approved';
                    student.approvedAt = new Date();
                    student.updatedAt = new Date();
                }
            }

            this.showSuccess('تم اعتماد الطالب بنجاح');
            await this.loadStudents();

            // Close modal if open
            const modal = bootstrap.Modal.getInstance(document.getElementById('studentDetailsModal'));
            if (modal) modal.hide();

        } catch (error) {
            console.error('❌ Error approving student:', error);
            this.showError('فشل في اعتماد الطالب');
        }
    }

    async confirmApproveStudent() {
        if (!this.currentStudentId) return;

        try {
            const busId = document.getElementById('assignBusSelect')?.value;

            // Check if Firebase is available
            if (typeof firebase !== 'undefined' && typeof db !== 'undefined') {
                const updateData = {
                    approvalStatus: 'approved',
                    approvedAt: firebase.firestore.FieldValue.serverTimestamp(),
                    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                };

                if (busId) {
                    updateData.busId = busId;
                }

                await db.collection('students').doc(this.currentStudentId).update(updateData);
            } else {
                // Update mock data
                const student = this.students.find(s => s.id === this.currentStudentId);
                if (student) {
                    student.approvalStatus = 'approved';
                    student.approvedAt = new Date();
                    student.updatedAt = new Date();
                    if (busId) {
                        student.busId = busId;
                    }
                }
            }

            this.showSuccess('تم اعتماد الطالب بنجاح' + (busId ? ' وتعيين السيارة' : ''));
            await this.loadStudents();

            // Close modals
            const approveModal = bootstrap.Modal.getInstance(document.getElementById('approveStudentModal'));
            if (approveModal) approveModal.hide();

            const detailsModal = bootstrap.Modal.getInstance(document.getElementById('studentDetailsModal'));
            if (detailsModal) detailsModal.hide();

        } catch (error) {
            console.error('❌ Error approving student:', error);
            this.showError('فشل في اعتماد الطالب');
        }
    }

    async rejectStudent() {
        if (!this.currentStudentId) return;

        if (!confirm('هل أنت متأكد من رفض هذا الطالب؟')) {
            return;
        }

        try {
            // Check if Firebase is available
            if (typeof firebase !== 'undefined' && typeof db !== 'undefined') {
                await db.collection('students').doc(this.currentStudentId).update({
                    approvalStatus: 'rejected',
                    rejectedAt: firebase.firestore.FieldValue.serverTimestamp(),
                    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                });
            } else {
                // Update mock data
                const student = this.students.find(s => s.id === this.currentStudentId);
                if (student) {
                    student.approvalStatus = 'rejected';
                    student.rejectedAt = new Date();
                    student.updatedAt = new Date();
                }
            }

            this.showSuccess('تم رفض الطالب');
            await this.loadStudents();

            // Close modal if open
            const modal = bootstrap.Modal.getInstance(document.getElementById('studentDetailsModal'));
            if (modal) modal.hide();

        } catch (error) {
            console.error('❌ Error rejecting student:', error);
            this.showError('فشل في رفض الطالب');
        }
    }

    showError(message) {
        // Create toast notification
        const toast = document.createElement('div');
        toast.className = 'toast align-items-center text-white bg-danger border-0 position-fixed';
        toast.style.cssText = 'top: 20px; right: 20px; z-index: 9999;';
        toast.innerHTML = `
            <div class="d-flex">
                <div class="toast-body">${message}</div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        `;
        document.body.appendChild(toast);

        const bsToast = new bootstrap.Toast(toast);
        bsToast.show();

        toast.addEventListener('hidden.bs.toast', () => {
            document.body.removeChild(toast);
        });
    }

    showSuccess(message) {
        // Create toast notification
        const toast = document.createElement('div');
        toast.className = 'toast align-items-center text-white bg-success border-0 position-fixed';
        toast.style.cssText = 'top: 20px; right: 20px; z-index: 9999;';
        toast.innerHTML = `
            <div class="d-flex">
                <div class="toast-body">${message}</div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        `;
        document.body.appendChild(toast);

        const bsToast = new bootstrap.Toast(toast);
        bsToast.show();

        toast.addEventListener('hidden.bs.toast', () => {
            document.body.removeChild(toast);
        });
    }
}

// Global functions
function refreshParentStudents() {
    if (window.parentStudentsManager) {
        window.parentStudentsManager.loadStudents();
    }
}

    async handleExcelImport(event) {
        const file = event.target.files[0];
        if (!file) {
            return;
        }

        this.showLoadingState();

        const reader = new FileReader();
        reader.onload = async (e) => {
            try {
                const data = new Uint8Array(e.target.result);
                const workbook = XLSX.read(data, { type: 'array' });
                const firstSheetName = workbook.SheetNames[0];
                const worksheet = workbook.Sheets[firstSheetName];
                const json = XLSX.utils.sheet_to_json(worksheet);

                if (json.length === 0) {
                    this.showError('ملف Excel فارغ أو غير صحيح');
                    this.hideLoadingState();
                    return;
                }

                await this.importStudentsToFirestore(json);

            } catch (error) {
                console.error('❌ Error processing Excel file:', error);
                this.showError('فشل في معالجة ملف Excel');
                this.hideLoadingState();
            } finally {
                // Reset file input
                event.target.value = '';
            }
        };
        reader.readAsArrayBuffer(file);
    }

    async importStudentsToFirestore(studentsData) {
        if (typeof db === 'undefined') {
            this.showError('Firebase غير متصل. لا يمكن الاستيراد.');
            this.hideLoadingState();
            return;
        }

        const batch = db.batch();
        let importedCount = 0;
        let skippedCount = 0;

        for (const student of studentsData) {
            // Basic validation
            if (!student.name || !student.parentPhone) {
                skippedCount++;
                continue;
            }

            const newStudentRef = db.collection('students').doc();
            const qrCode = `STU-${newStudentRef.id.substring(0, 6).toUpperCase()}`;

            batch.set(newStudentRef, {
                name: student.name || '',
                parentName: student.parentName || '',
                parentPhone: String(student.parentPhone) || '',
                parentEmail: student.parentEmail || '',
                grade: student.grade || 'غير محدد',
                schoolName: student.schoolName || 'مدرسة افتراضية',
                busRoute: student.busRoute || 'غير محدد',
                qrCode: student.qrCode || qrCode,
                address: student.address || '',
                notes: student.notes || '',
                photoUrl: null,
                parentId: '', // Should be linked later
                busId: '',
                currentStatus: 'home',
                approvalStatus: 'approved', // Automatically approved
                isActive: true,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
            });
            importedCount++;
        }

        try {
            await batch.commit();
            this.showSuccess(`تم استيراد ${importedCount} طالب بنجاح. تم تخطي ${skippedCount} طالب.`);
            await this.loadStudents(); // Refresh the list
        } catch (error) {
            console.error('❌ Error importing students to Firestore:', error);
            this.showError('فشل في حفظ الطلاب في قاعدة البيانات');
        } finally {
            this.hideLoadingState();
        }
    }
}

// Global functions
function refreshParentStudents() {
    if (window.parentStudentsManager) {
        window.parentStudentsManager.loadStudents();
    }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    window.parentStudentsManager = new ParentStudentsManager();
});
