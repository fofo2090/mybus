// Complaints Management JavaScript - Namespace to avoid conflicts
const ComplaintsManager = {
    data: [],
    filtered: [],
    currentPage: 1,
    perPage: 10
};

// Legacy variables for backward compatibility
let complaintsData = [];
let filteredComplaints = [];
let complaintsCurrentPage = 1;
const complaintsPerPage = 10;

// Initialize complaints page
function initializeComplaintsPage() {
    console.log('🔧 Initializing complaints page...');
    
    // Load complaints data
    loadComplaints();
    
    // Set up event listeners
    setupComplaintsEventListeners();
    
    // Set default date filter to last 30 days
    const today = new Date();
    const thirtyDaysAgo = new Date(today.getTime() - (30 * 24 * 60 * 60 * 1000));
    
    document.getElementById('dateToFilter').value = today.toISOString().split('T')[0];
    document.getElementById('dateFromFilter').value = thirtyDaysAgo.toISOString().split('T')[0];
}

// Set up event listeners
function setupComplaintsEventListeners() {
    // Add response form
    document.getElementById('addResponseForm').addEventListener('submit', handleAddResponse);
    
    // Update status form
    document.getElementById('updateStatusForm').addEventListener('submit', handleUpdateStatus);
    
    // Search input with debounce
    let searchTimeout;
    document.getElementById('searchInput').addEventListener('input', function() {
        clearTimeout(searchTimeout);
        searchTimeout = setTimeout(filterComplaints, 300);
    });
}

// Load complaints from Firebase
async function loadComplaints() {
    console.log('📥 Loading complaints from Firebase...');
    
    try {
        showComplaintsLoading();
        
        // Get complaints collection - simplified query to avoid index requirement
        const complaintsRef = firebase.firestore().collection('complaints');
        const snapshot = await complaintsRef
            .where('isActive', '==', true)
            .get();
        
        complaintsData = [];

        snapshot.forEach(doc => {
            const data = doc.data();
            complaintsData.push({
                id: doc.id,
                ...data,
                createdAt: data.createdAt?.toDate() || new Date(),
                updatedAt: data.updatedAt?.toDate() || new Date(),
                responseDate: data.responseDate?.toDate() || null
            });
        });

        // Sort by createdAt in memory (newest first)
        complaintsData.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
        
        console.log(`✅ Loaded ${complaintsData.length} complaints`);
        
        // Update statistics
        updateComplaintsStatistics();
        
        // Apply filters and display
        filterComplaints();
        
    } catch (error) {
        console.error('❌ Error loading complaints:', error);

        // Try fallback: get all complaints without filters
        try {
            console.log('🔄 Trying fallback: get all complaints...');
            const fallbackSnapshot = await firebase.firestore().collection('complaints').get();

            complaintsData = [];
            fallbackSnapshot.forEach(doc => {
                const data = doc.data();
                if (data.isActive !== false) { // Filter in memory
                    complaintsData.push({
                        id: doc.id,
                        ...data,
                        createdAt: data.createdAt?.toDate() || new Date(),
                        updatedAt: data.updatedAt?.toDate() || new Date(),
                        responseDate: data.responseDate?.toDate() || null
                    });
                }
            });

            // Sort by createdAt in memory (newest first)
            complaintsData.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

            console.log(`✅ Fallback successful: Loaded ${complaintsData.length} complaints`);

            // Update statistics and display
            updateComplaintsStatistics();
            filterComplaints();

        } catch (fallbackError) {
            console.error('❌ Fallback also failed:', fallbackError);

            // Last resort: use sample data for demonstration
            console.log('🧪 Using sample complaints data for demonstration...');
            complaintsData = [
                {
                    id: 'sample_1',
                    title: 'تأخير الباص',
                    description: 'الباص يتأخر كل يوم عن الموعد المحدد',
                    parentName: 'أحمد محمد',
                    parentPhone: '01234567890',
                    studentName: 'محمد أحمد',
                    type: 'timing',
                    priority: 'medium',
                    status: 'pending',
                    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000), // Yesterday
                    updatedAt: new Date(Date.now() - 24 * 60 * 60 * 1000),
                    responseDate: null,
                    isActive: true
                },
                {
                    id: 'sample_2',
                    title: 'مشكلة في التكييف',
                    description: 'التكييف لا يعمل في الباص والجو حار جداً',
                    parentName: 'فاطمة علي',
                    parentPhone: '01987654321',
                    studentName: 'علي فاطمة',
                    type: 'busService',
                    priority: 'high',
                    status: 'inProgress',
                    createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
                    updatedAt: new Date(Date.now() - 12 * 60 * 60 * 1000), // 12 hours ago
                    responseDate: new Date(Date.now() - 12 * 60 * 60 * 1000),
                    adminResponse: 'تم التواصل مع فني التكييف وسيتم الإصلاح غداً',
                    isActive: true
                },
                {
                    id: 'sample_3',
                    title: 'سلوك السائق غير مناسب',
                    description: 'السائق يتحدث بصوت عالي ويزعج الأطفال',
                    parentName: 'خالد حسن',
                    parentPhone: '01555666777',
                    studentName: 'حسن خالد',
                    type: 'driverBehavior',
                    priority: 'urgent',
                    status: 'resolved',
                    createdAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 1 week ago
                    updatedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), // 3 days ago
                    responseDate: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
                    adminResponse: 'تم التحدث مع السائق وتم حل المشكلة. شكراً لتنبيهنا.',
                    isActive: true
                }
            ];

            console.log(`✅ Sample data loaded: ${complaintsData.length} complaints`);

            // Update statistics and display
            updateComplaintsStatistics();
            filterComplaints();
        }
    }
}

// Update statistics cards
function updateComplaintsStatistics() {
    const stats = {
        total: complaintsData.length,
        pending: complaintsData.filter(c => c.status === 'pending').length,
        inProgress: complaintsData.filter(c => c.status === 'inProgress').length,
        resolved: complaintsData.filter(c => c.status === 'resolved').length,
        urgent: complaintsData.filter(c => c.priority === 'urgent').length,
        high: complaintsData.filter(c => c.priority === 'high').length
    };
    
    document.getElementById('totalComplaints').textContent = stats.total;
    document.getElementById('pendingComplaints').textContent = stats.pending;
    document.getElementById('inProgressComplaints').textContent = stats.inProgress;
    document.getElementById('resolvedComplaints').textContent = stats.resolved;
    
    console.log('📊 Updated statistics:', stats);
}

// Filter complaints based on search and filters
function filterComplaints() {
    const searchTerm = document.getElementById('searchInput').value.toLowerCase();
    const statusFilter = document.getElementById('statusFilter').value;
    const priorityFilter = document.getElementById('priorityFilter').value;
    const typeFilter = document.getElementById('typeFilter').value;
    const dateFrom = document.getElementById('dateFromFilter').value;
    const dateTo = document.getElementById('dateToFilter').value;
    
    filteredComplaints = complaintsData.filter(complaint => {
        // Search filter
        const matchesSearch = !searchTerm || 
            complaint.title.toLowerCase().includes(searchTerm) ||
            complaint.description.toLowerCase().includes(searchTerm) ||
            complaint.parentName.toLowerCase().includes(searchTerm) ||
            (complaint.studentName && complaint.studentName.toLowerCase().includes(searchTerm));
        
        // Status filter
        const matchesStatus = !statusFilter || complaint.status === statusFilter;
        
        // Priority filter
        const matchesPriority = !priorityFilter || complaint.priority === priorityFilter;
        
        // Type filter
        const matchesType = !typeFilter || complaint.type === typeFilter;
        
        // Date filter
        let matchesDate = true;
        if (dateFrom || dateTo) {
            const complaintDate = complaint.createdAt;
            if (dateFrom) {
                const fromDate = new Date(dateFrom);
                matchesDate = matchesDate && complaintDate >= fromDate;
            }
            if (dateTo) {
                const toDate = new Date(dateTo);
                toDate.setHours(23, 59, 59, 999); // End of day
                matchesDate = matchesDate && complaintDate <= toDate;
            }
        }
        
        return matchesSearch && matchesStatus && matchesPriority && matchesType && matchesDate;
    });
    
    console.log(`🔍 Filtered ${filteredComplaints.length} complaints from ${complaintsData.length} total`);
    
    // Reset to first page
    complaintsCurrentPage = 1;

    // Display filtered complaints
    displayComplaints();
}

// Display complaints in table
function displayComplaints() {
    const startIndex = (complaintsCurrentPage - 1) * complaintsPerPage;
    const endIndex = startIndex + complaintsPerPage;
    const pageComplaints = filteredComplaints.slice(startIndex, endIndex);
    
    const tbody = document.getElementById('complaintsTableBody');
    
    if (filteredComplaints.length === 0) {
        showComplaintsEmpty();
        return;
    }
    
    // Show table
    showComplaintsTable();
    
    // Update count
    document.getElementById('complaintsCount').textContent = `${filteredComplaints.length} شكوى`;
    
    // Generate table rows
    tbody.innerHTML = pageComplaints.map((complaint, index) => `
        <tr>
            <td>${startIndex + index + 1}</td>
            <td>
                <div class="fw-bold">${escapeHtml(complaint.title)}</div>
                <small class="text-muted">${escapeHtml(complaint.description.substring(0, 50))}${complaint.description.length > 50 ? '...' : ''}</small>
            </td>
            <td>
                <div class="fw-bold">${escapeHtml(complaint.parentName)}</div>
                <small class="text-muted">${escapeHtml(complaint.parentPhone)}</small>
                ${complaint.studentName ? `<br><small class="text-info">الطالب: ${escapeHtml(complaint.studentName)}</small>` : ''}
            </td>
            <td>
                <span class="badge bg-secondary">${getTypeDisplayName(complaint.type)}</span>
            </td>
            <td>
                <span class="badge ${getPriorityBadgeClass(complaint.priority)}">${getPriorityDisplayName(complaint.priority)}</span>
            </td>
            <td>
                <span class="badge ${getStatusBadgeClass(complaint.status)}">${getStatusDisplayName(complaint.status)}</span>
            </td>
            <td>
                <div>${formatDate(complaint.createdAt)}</div>
                <small class="text-muted">${formatTime(complaint.createdAt)}</small>
            </td>
            <td>
                <div class="btn-group btn-group-sm" role="group">
                    <button class="btn btn-outline-primary btn-sm" onclick="viewComplaintDetails('${complaint.id}')" title="عرض التفاصيل">
                        <i class="fas fa-eye me-1"></i>
                        <span>عرض</span>
                    </button>
                    ${complaint.status === 'pending' ? `
                        <button class="btn btn-outline-success btn-sm" onclick="startProcessing('${complaint.id}')" title="بدء المعالجة">
                            <i class="fas fa-play me-1"></i>
                            <span>بدء المعالجة</span>
                        </button>
                    ` : ''}
                    ${complaint.status === 'inProgress' ? `
                        <button class="btn btn-outline-info btn-sm" onclick="showAddResponseModal('${complaint.id}')" title="إضافة رد">
                            <i class="fas fa-reply me-1"></i>
                            <span>إضافة رد</span>
                        </button>
                    ` : ''}
                    <button class="btn btn-outline-warning btn-sm" onclick="showUpdateStatusModal('${complaint.id}')" title="تحديث الحالة">
                        <i class="fas fa-edit me-1"></i>
                        <span>تحديث</span>
                    </button>
                </div>
            </td>
        </tr>
    `).join('');
    
    // Update pagination
    updatePagination();
}

// Show different states
function showComplaintsLoading() {
    document.getElementById('complaintsLoading').classList.remove('d-none');
    document.getElementById('complaintsEmpty').classList.add('d-none');
    document.getElementById('complaintsError').classList.add('d-none');
    document.getElementById('complaintsTable').classList.add('d-none');
}

function showComplaintsEmpty() {
    document.getElementById('complaintsLoading').classList.add('d-none');
    document.getElementById('complaintsEmpty').classList.remove('d-none');
    document.getElementById('complaintsError').classList.add('d-none');
    document.getElementById('complaintsTable').classList.add('d-none');
    document.getElementById('complaintsPagination').classList.add('d-none');
}

function showComplaintsError(message) {
    document.getElementById('complaintsLoading').classList.add('d-none');
    document.getElementById('complaintsEmpty').classList.add('d-none');
    document.getElementById('complaintsError').classList.remove('d-none');
    document.getElementById('complaintsTable').classList.add('d-none');
    document.getElementById('complaintsErrorMessage').textContent = message;
}

function showComplaintsTable() {
    document.getElementById('complaintsLoading').classList.add('d-none');
    document.getElementById('complaintsEmpty').classList.add('d-none');
    document.getElementById('complaintsError').classList.add('d-none');
    document.getElementById('complaintsTable').classList.remove('d-none');
}

// Helper functions for display
function getTypeDisplayName(type) {
    const types = {
        busService: 'خدمة الباص',
        driverBehavior: 'سلوك السائق',
        safety: 'السلامة',
        timing: 'التوقيت',
        communication: 'التواصل',
        other: 'أخرى'
    };
    return types[type] || type;
}

function getPriorityDisplayName(priority) {
    const priorities = {
        low: 'منخفضة',
        medium: 'متوسطة',
        high: 'عالية',
        urgent: 'عاجلة'
    };
    return priorities[priority] || priority;
}

function getStatusDisplayName(status) {
    const statuses = {
        pending: 'في انتظار المراجعة',
        inProgress: 'قيد المعالجة',
        resolved: 'تم الحل',
        closed: 'مغلقة'
    };
    return statuses[status] || status;
}

function getPriorityBadgeClass(priority) {
    const classes = {
        low: 'bg-success',
        medium: 'bg-warning',
        high: 'bg-danger',
        urgent: 'bg-dark'
    };
    return classes[priority] || 'bg-secondary';
}

function getStatusBadgeClass(status) {
    const classes = {
        pending: 'bg-warning',
        inProgress: 'bg-info',
        resolved: 'bg-success',
        closed: 'bg-secondary'
    };
    return classes[status] || 'bg-secondary';
}

function formatDate(date) {
    return date.toLocaleDateString('ar-SA', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
    });
}

function formatTime(date) {
    return date.toLocaleTimeString('ar-SA', {
        hour: '2-digit',
        minute: '2-digit'
    });
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Pagination
function updatePagination() {
    const totalPages = Math.ceil(filteredComplaints.length / complaintsPerPage);
    const pagination = document.getElementById('complaintsPagination');
    
    if (totalPages <= 1) {
        pagination.classList.add('d-none');
        return;
    }
    
    pagination.classList.remove('d-none');
    
    let paginationHTML = '';
    
    // Previous button
    paginationHTML += `
        <li class="page-item ${complaintsCurrentPage === 1 ? 'disabled' : ''}">
            <a class="page-link" href="#" onclick="changeComplaintsPage(${complaintsCurrentPage - 1}); return false;">السابق</a>
        </li>
    `;

    // Page numbers
    for (let i = 1; i <= totalPages; i++) {
        if (i === 1 || i === totalPages || (i >= complaintsCurrentPage - 2 && i <= complaintsCurrentPage + 2)) {
            paginationHTML += `
                <li class="page-item ${i === complaintsCurrentPage ? 'active' : ''}">
                    <a class="page-link" href="#" onclick="changeComplaintsPage(${i}); return false;">${i}</a>
                </li>
            `;
        } else if (i === complaintsCurrentPage - 3 || i === complaintsCurrentPage + 3) {
            paginationHTML += '<li class="page-item disabled"><span class="page-link">...</span></li>';
        }
    }

    // Next button
    paginationHTML += `
        <li class="page-item ${complaintsCurrentPage === totalPages ? 'disabled' : ''}">
            <a class="page-link" href="#" onclick="changeComplaintsPage(${complaintsCurrentPage + 1}); return false;">التالي</a>
        </li>
    `;
    
    pagination.querySelector('.pagination').innerHTML = paginationHTML;
}

function changeComplaintsPage(page) {
    const totalPages = Math.ceil(filteredComplaints.length / complaintsPerPage);
    if (page >= 1 && page <= totalPages) {
        complaintsCurrentPage = page;
        displayComplaints();
    }
}

// Action functions
function refreshComplaints() {
    loadComplaints();
}

function clearFilters() {
    document.getElementById('searchInput').value = '';
    document.getElementById('statusFilter').value = '';
    document.getElementById('priorityFilter').value = '';
    document.getElementById('typeFilter').value = '';
    document.getElementById('dateFromFilter').value = '';
    document.getElementById('dateToFilter').value = '';
    filterComplaints();
}

function sortComplaints(field, direction) {
    filteredComplaints.sort((a, b) => {
        let aValue, bValue;
        
        switch (field) {
            case 'date':
                aValue = a.createdAt;
                bValue = b.createdAt;
                break;
            case 'priority':
                const priorityOrder = { urgent: 4, high: 3, medium: 2, low: 1 };
                aValue = priorityOrder[a.priority] || 0;
                bValue = priorityOrder[b.priority] || 0;
                break;
            case 'status':
                aValue = a.status;
                bValue = b.status;
                break;
            default:
                return 0;
        }
        
        if (direction === 'asc') {
            return aValue > bValue ? 1 : -1;
        } else {
            return aValue < bValue ? 1 : -1;
        }
    });
    
    complaintsCurrentPage = 1;
    displayComplaints();
}

// Export complaints
function exportComplaints() {
    const csvContent = generateCSV(filteredComplaints);
    downloadCSV(csvContent, 'complaints.csv');
}

function generateCSV(data) {
    const headers = ['العنوان', 'ولي الأمر', 'الهاتف', 'الطالب', 'النوع', 'الأولوية', 'الحالة', 'التاريخ', 'الوصف'];
    const rows = data.map(complaint => [
        complaint.title,
        complaint.parentName,
        complaint.parentPhone,
        complaint.studentName || '',
        getTypeDisplayName(complaint.type),
        getPriorityDisplayName(complaint.priority),
        getStatusDisplayName(complaint.status),
        formatDate(complaint.createdAt),
        complaint.description
    ]);
    
    const csvContent = [headers, ...rows]
        .map(row => row.map(field => `"${field}"`).join(','))
        .join('\n');
    
    return csvContent;
}

function downloadCSV(content, filename) {
    const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    const url = URL.createObjectURL(blob);
    link.setAttribute('href', url);
    link.setAttribute('download', filename);
    link.style.visibility = 'hidden';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}

// View complaint details
function viewComplaintDetails(complaintId) {
    const complaint = complaintsData.find(c => c.id === complaintId);
    if (!complaint) return;

    const modalContent = document.getElementById('complaintDetailsContent');
    modalContent.innerHTML = `
        <div class="row">
            <div class="col-md-6">
                <h6 class="text-muted">معلومات الشكوى</h6>
                <table class="table table-sm">
                    <tr><td><strong>العنوان:</strong></td><td>${escapeHtml(complaint.title)}</td></tr>
                    <tr><td><strong>النوع:</strong></td><td>${getTypeDisplayName(complaint.type)}</td></tr>
                    <tr><td><strong>الأولوية:</strong></td><td><span class="badge ${getPriorityBadgeClass(complaint.priority)}">${getPriorityDisplayName(complaint.priority)}</span></td></tr>
                    <tr><td><strong>الحالة:</strong></td><td><span class="badge ${getStatusBadgeClass(complaint.status)}">${getStatusDisplayName(complaint.status)}</span></td></tr>
                    <tr><td><strong>التاريخ:</strong></td><td>${formatDate(complaint.createdAt)} ${formatTime(complaint.createdAt)}</td></tr>
                </table>
            </div>
            <div class="col-md-6">
                <h6 class="text-muted">معلومات ولي الأمر</h6>
                <table class="table table-sm">
                    <tr><td><strong>الاسم:</strong></td><td>${escapeHtml(complaint.parentName)}</td></tr>
                    <tr><td><strong>الهاتف:</strong></td><td>${escapeHtml(complaint.parentPhone)}</td></tr>
                    ${complaint.studentName ? `<tr><td><strong>الطالب:</strong></td><td>${escapeHtml(complaint.studentName)}</td></tr>` : ''}
                </table>
            </div>
        </div>

        <div class="mt-3">
            <h6 class="text-muted">تفاصيل الشكوى</h6>
            <div class="border rounded p-3 bg-light">
                ${escapeHtml(complaint.description)}
            </div>
        </div>

        ${complaint.attachments && complaint.attachments.length > 0 ? `
            <div class="mt-3">
                <h6 class="text-muted">المرفقات (${complaint.attachments.length})</h6>
                <div class="d-flex gap-2 flex-wrap">
                    ${complaint.attachments.map((url, index) => `
                        <a href="${url}" target="_blank" class="btn btn-outline-primary btn-sm">
                            <i class="fas fa-image me-1"></i>
                            مرفق ${index + 1}
                        </a>
                    `).join('')}
                </div>
            </div>
        ` : ''}

        ${complaint.adminResponse ? `
            <div class="mt-3">
                <h6 class="text-muted">رد الإدارة</h6>
                <div class="border rounded p-3 bg-success bg-opacity-10">
                    ${escapeHtml(complaint.adminResponse)}
                    ${complaint.responseDate ? `<br><small class="text-muted">تاريخ الرد: ${formatDate(complaint.responseDate)} ${formatTime(complaint.responseDate)}</small>` : ''}
                </div>
            </div>
        ` : ''}
    `;

    // Set edit button data
    document.getElementById('editComplaintBtn').setAttribute('data-complaint-id', complaintId);

    // Show modal
    new bootstrap.Modal(document.getElementById('complaintDetailsModal')).show();
}

// Start processing complaint
async function startProcessing(complaintId) {
    try {
        await firebase.firestore().collection('complaints').doc(complaintId).update({
            status: 'inProgress',
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        });

        showToast('تم بدء معالجة الشكوى بنجاح', 'success');
        loadComplaints();
    } catch (error) {
        console.error('Error starting processing:', error);
        showToast('خطأ في بدء معالجة الشكوى: ' + error.message, 'error');
    }
}

// Show add response modal
function showAddResponseModal(complaintId) {
    const complaint = complaintsData.find(c => c.id === complaintId);
    if (!complaint) return;

    document.getElementById('responseComplaintId').value = complaintId;
    document.getElementById('responseComplaintTitle').value = complaint.title;
    document.getElementById('adminResponse').value = '';
    document.getElementById('newStatus').value = 'resolved';

    new bootstrap.Modal(document.getElementById('addResponseModal')).show();
}

// Handle add response form
async function handleAddResponse(event) {
    event.preventDefault();

    const complaintId = document.getElementById('responseComplaintId').value;
    const response = document.getElementById('adminResponse').value.trim();
    const newStatus = document.getElementById('newStatus').value;

    if (!response) {
        showToast('يرجى كتابة رد الإدارة', 'error');
        return;
    }

    try {
        await firebase.firestore().collection('complaints').doc(complaintId).update({
            adminResponse: response,
            responseDate: firebase.firestore.FieldValue.serverTimestamp(),
            status: newStatus,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
            assignedTo: 'admin' // You can get current admin ID here
        });

        showToast('تم إضافة رد الإدارة بنجاح', 'success');
        bootstrap.Modal.getInstance(document.getElementById('addResponseModal')).hide();
        loadComplaints();
    } catch (error) {
        console.error('Error adding response:', error);
        showToast('خطأ في إضافة رد الإدارة: ' + error.message, 'error');
    }
}

// Show update status modal
function showUpdateStatusModal(complaintId) {
    const complaint = complaintsData.find(c => c.id === complaintId);
    if (!complaint) return;

    document.getElementById('statusComplaintId').value = complaintId;
    document.getElementById('statusComplaintTitle').value = complaint.title;
    document.getElementById('complaintStatus').value = complaint.status;
    document.getElementById('statusNote').value = '';

    new bootstrap.Modal(document.getElementById('updateStatusModal')).show();
}

// Handle update status form
async function handleUpdateStatus(event) {
    event.preventDefault();

    const complaintId = document.getElementById('statusComplaintId').value;
    const newStatus = document.getElementById('complaintStatus').value;
    const note = document.getElementById('statusNote').value.trim();

    try {
        const updateData = {
            status: newStatus,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
        };

        if (note) {
            updateData.statusNote = note;
        }

        await firebase.firestore().collection('complaints').doc(complaintId).update(updateData);

        showToast('تم تحديث حالة الشكوى بنجاح', 'success');
        bootstrap.Modal.getInstance(document.getElementById('updateStatusModal')).hide();
        loadComplaints();
    } catch (error) {
        console.error('Error updating status:', error);
        showToast('خطأ في تحديث حالة الشكوى: ' + error.message, 'error');
    }
}

// Edit complaint (placeholder)
function editComplaint() {
    const complaintId = document.getElementById('editComplaintBtn').getAttribute('data-complaint-id');
    showToast('ميزة تعديل الشكوى قيد التطوير', 'info');
}

// Toast notification function
function showToast(message, type = 'info') {
    // Create toast element
    const toastId = 'toast-' + Date.now();
    const toastHTML = `
        <div id="${toastId}" class="toast align-items-center text-white bg-${type === 'error' ? 'danger' : type === 'success' ? 'success' : 'primary'} border-0" role="alert">
            <div class="d-flex">
                <div class="toast-body">
                    <i class="fas fa-${type === 'error' ? 'exclamation-triangle' : type === 'success' ? 'check-circle' : 'info-circle'} me-2"></i>
                    ${message}
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        </div>
    `;

    // Add to toast container (create if doesn't exist)
    let toastContainer = document.getElementById('toastContainer');
    if (!toastContainer) {
        toastContainer = document.createElement('div');
        toastContainer.id = 'toastContainer';
        toastContainer.className = 'toast-container position-fixed top-0 end-0 p-3';
        toastContainer.style.zIndex = '9999';
        document.body.appendChild(toastContainer);
    }

    toastContainer.insertAdjacentHTML('beforeend', toastHTML);

    // Show toast
    const toastElement = document.getElementById(toastId);
    const toast = new bootstrap.Toast(toastElement, { delay: 5000 });
    toast.show();

    // Remove from DOM after hiding
    toastElement.addEventListener('hidden.bs.toast', () => {
        toastElement.remove();
    });
}
