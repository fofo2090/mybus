// Firebase Configuration - Same as Flutter app
const firebaseConfig = {
    apiKey: "AIzaSyCxUs93mPDENri0o6ARCDOm5p_m40D-y78",
    authDomain: "mybus-5a992.firebaseapp.com",
    projectId: "mybus-5a992",
    storageBucket: "mybus-5a992.firebasestorage.app",
    messagingSenderId: "804926032268",
    appId: "1:804926032268:web:6450c694a8bbc705982ea9"
};

// Initialize Firebase with error handling
try {
    firebase.initializeApp(firebaseConfig);
    console.log('✅ Firebase initialized successfully');
} catch (error) {
    console.error('❌ Firebase initialization error:', error);
}

// Initialize Firebase services with error handling
const auth = firebase.auth();
const db = firebase.firestore();

// Configure Firestore settings only once
if (!db._delegate._databaseId) {
    db.settings({
        cacheSizeBytes: firebase.firestore.CACHE_SIZE_UNLIMITED,
        merge: true
    });
}

// Enable offline persistence only if not already enabled
let persistenceEnabled = false;
if (!persistenceEnabled) {
    db.enablePersistence({ synchronizeTabs: true })
        .then(() => {
            console.log('✅ Firestore offline persistence enabled');
            persistenceEnabled = true;
        })
        .catch((err) => {
            if (err.code == 'failed-precondition') {
                console.warn('⚠️ Multiple tabs open, persistence can only be enabled in one tab at a time');
            } else if (err.code == 'unimplemented') {
                console.warn('⚠️ The current browser does not support persistence');
            } else {
                console.warn('⚠️ Persistence already enabled or failed:', err.message);
            }
        });
}

// Firebase helper functions
const FirebaseService = {
    // Authentication
    async signIn(email, password) {
        try {
            console.log('🔐 Attempting to sign in...');

            // Check network connectivity
            if (!navigator.onLine) {
                throw new Error('لا يوجد اتصال بالإنترنت');
            }

            const result = await auth.signInWithEmailAndPassword(email, password);
            console.log('✅ Sign in successful');
            return { success: true, user: result.user };
        } catch (error) {
            console.error('❌ Sign in error:', error);

            // Handle specific Firebase errors
            let errorMessage = error.message;
            if (error.code) {
                switch (error.code) {
                    case 'auth/network-request-failed':
                        errorMessage = 'خطأ في الاتصال بالشبكة. تحقق من اتصال الإنترنت.';
                        break;
                    case 'auth/too-many-requests':
                        errorMessage = 'تم تجاوز عدد المحاولات المسموح. حاول مرة أخرى لاحقاً.';
                        break;
                    case 'auth/user-not-found':
                        errorMessage = 'المستخدم غير موجود';
                        break;
                    case 'auth/wrong-password':
                        errorMessage = 'كلمة المرور غير صحيحة';
                        break;
                    case 'auth/invalid-email':
                        errorMessage = 'البريد الإلكتروني غير صحيح';
                        break;
                }
            }

            return { success: false, error: errorMessage };
        }
    },

    async signOut() {
        try {
            console.log('🚪 Signing out...');

            // Reset auth processing flags
            isProcessingAuth = false;
            lastAuthUser = null;

            await auth.signOut();
            console.log('✅ Sign out successful');
            return { success: true };
        } catch (error) {
            console.error('❌ Error signing out:', error);
            return { success: false, error: error.message };
        }
    },

    // Check if user is admin
    async isAdmin(uid) {
        try {
            // First check if it's the main admin email
            const user = auth.currentUser;
            if (user && user.email === 'admin@mybus.com') {
                console.log('✅ Main admin detected');
                return true;
            }

            // Then check in database with timeout
            const timeoutPromise = new Promise((_, reject) =>
                setTimeout(() => reject(new Error('Timeout')), 5000)
            );

            const docPromise = db.collection('users').doc(uid).get();

            const doc = await Promise.race([docPromise, timeoutPromise]);

            if (doc.exists) {
                const userData = doc.data();
                console.log('📋 User data:', userData);
                return userData.role === 'admin';
            }

            // If no user document exists but email is admin, still allow
            if (user && user.email === 'admin@mybus.com') {
                console.log('✅ Admin email detected, creating admin record');
                // Create admin record
                try {
                    await db.collection('users').doc(uid).set({
                        email: user.email,
                        role: 'admin',
                        name: 'مدير النظام',
                        createdAt: firebase.firestore.FieldValue.serverTimestamp()
                    });
                } catch (createError) {
                    console.log('⚠️ Could not create admin record, but allowing access');
                }
                return true;
            }

            return false;
        } catch (error) {
            console.error('Error checking admin status:', error);

            // Fallback: if it's admin email, allow access
            const user = auth.currentUser;
            if (user && user.email === 'admin@mybus.com') {
                console.log('⚠️ Fallback: Admin email detected despite error');
                return true;
            }

            return false;
        }
    },

    // Students
    async getStudents() {
        try {
            console.log('📚 Fetching students...');
            const snapshot = await db.collection('students')
                .where('isActive', '==', true)
                .orderBy('name')
                .get();

            const students = snapshot.docs.map(doc => {
                const data = doc.data();
                return {
                    id: doc.id,
                    name: data.name || 'غير محدد',
                    parentId: data.parentId || '',
                    parentName: data.parentName || 'غير محدد',
                    parentPhone: data.parentPhone || 'غير محدد',
                    schoolName: data.schoolName || 'غير محدد',
                    grade: data.grade || 'غير محدد',
                    busRoute: data.busRoute || 'غير محدد',
                    currentStatus: data.currentStatus || 'home',
                    qrCode: data.qrCode || '',
                    isActive: data.isActive !== false,
                    createdAt: data.createdAt,
                    updatedAt: data.updatedAt
                };
            });

            console.log('✅ Students fetched:', students.length);
            return students;
        } catch (error) {
            console.error('❌ Error getting students:', error);

            // Try without ordering if that fails
            try {
                console.log('🔄 Retrying without ordering...');
                const snapshot = await db.collection('students')
                    .where('isActive', '==', true)
                    .get();

                const students = snapshot.docs.map(doc => {
                    const data = doc.data();
                    return {
                        id: doc.id,
                        name: data.name || 'غير محدد',
                        parentName: data.parentName || 'غير محدد',
                        schoolName: data.schoolName || 'غير محدد',
                        grade: data.grade || 'غير محدد',
                        currentStatus: data.currentStatus || 'home',
                        isActive: data.isActive !== false
                    };
                });

                console.log('✅ Students fetched (no order):', students.length);
                return students;
            } catch (retryError) {
                console.error('❌ Retry failed:', retryError);
                return [];
            }
        }
    },

    async addStudent(studentData) {
        try {
            const docRef = await db.collection('students').add({
                ...studentData,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            return { success: true, id: docRef.id };
        } catch (error) {
            return { success: false, error: error.message };
        }
    },

    async updateStudent(id, studentData) {
        try {
            await db.collection('students').doc(id).update({
                ...studentData,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    },

    async deleteStudent(id) {
        try {
            await db.collection('students').doc(id).delete();
            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    },

    // Supervisors
    async getSupervisors() {
        try {
            console.log('👨‍💼 Fetching supervisors...');
            const snapshot = await db.collection('users')
                .where('userType', '==', 'supervisor')
                .where('isActive', '==', true)
                .get();

            const supervisors = snapshot.docs.map(doc => {
                const data = doc.data();
                return {
                    id: doc.id,
                    name: data.name || 'غير محدد',
                    email: data.email || 'غير محدد',
                    phone: data.phone || 'غير محدد',
                    userType: data.userType || 'supervisor',
                    isActive: data.isActive !== false,
                    createdAt: data.createdAt,
                    updatedAt: data.updatedAt
                };
            });

            console.log('✅ Supervisors fetched:', supervisors.length);
            return supervisors;
        } catch (error) {
            console.error('❌ Error getting supervisors:', error);
            return [];
        }
    },

    // Parents
    async getParents() {
        try {
            console.log('👨‍👩‍👧‍👦 Fetching parents...');
            const snapshot = await db.collection('users')
                .where('userType', '==', 'parent')
                .where('isActive', '==', true)
                .get();

            const parents = snapshot.docs.map(doc => {
                const data = doc.data();
                console.log(`📋 Parent ${doc.id} data:`, {
                    name: data.name,
                    address: data.address,
                    occupation: data.occupation,
                    emergencyPhone: data.emergencyPhone,
                    children: data.children
                });

                return {
                    id: doc.id,
                    name: data.name || 'غير محدد',
                    email: data.email || 'غير محدد',
                    phone: data.phone || 'غير محدد',
                    address: data.address || 'غير محدد',
                    occupation: data.occupation || 'غير محدد',
                    emergencyPhone: data.emergencyPhone || 'غير محدد',
                    status: data.status || (data.isActive ? 'active' : 'inactive'),
                    notificationPreferences: data.notificationPreferences || [],
                    relationship: data.relationship || 'ولي أمر',
                    userType: data.userType || 'parent',
                    isActive: data.isActive !== false,
                    children: data.children || [], // Include children array
                    createdAt: data.createdAt,
                    updatedAt: data.updatedAt
                };
            });

            console.log('✅ Parents fetched with all fields:', parents.length);
            return parents;
        } catch (error) {
            console.error('❌ Error getting parents:', error);
            return [];
        }
    },

    // Statistics
    async getStatistics() {
        try {
            console.log('📊 Fetching statistics...');

            // Get data with simplified queries to avoid index requirements
            const [studentsSnapshot, supervisorsSnapshot, parentsSnapshot, tripsSnapshot, complaintsSnapshot] = await Promise.all([
                db.collection('students').where('isActive', '==', true).get(),
                db.collection('users').where('userType', '==', 'supervisor').where('isActive', '==', true).get(),
                db.collection('users').where('userType', '==', 'parent').where('isActive', '==', true).get(),
                db.collection('trips').limit(100).get(), // Remove orderBy to avoid index requirement
                db.collection('complaints').where('isActive', '==', true).get()
            ]);

            // Count students by status
            const studentsData = studentsSnapshot.docs.map(doc => doc.data());
            const activeStudents = studentsData.filter(student => student.currentStatus !== 'inactive').length;
            const studentsOnBus = studentsData.filter(student => student.currentStatus === 'onBus').length;
            const studentsAtSchool = studentsData.filter(student => student.currentStatus === 'atSchool').length;
            const studentsAtHome = studentsData.filter(student => student.currentStatus === 'home').length;

            // Count trips today
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            const tripsToday = tripsSnapshot.docs.filter(doc => {
                const tripDate = doc.data().timestamp.toDate();
                return tripDate >= today;
            }).length;

            // Count complaints by status (with error handling)
            let complaintsData = [];
            let totalComplaints = 0;
            let pendingComplaints = 0;
            let inProgressComplaints = 0;
            let resolvedComplaints = 0;
            let urgentComplaints = 0;

            try {
                complaintsData = complaintsSnapshot.docs.map(doc => doc.data());
                totalComplaints = complaintsData.length;
                pendingComplaints = complaintsData.filter(c => c.status === 'pending').length;
                inProgressComplaints = complaintsData.filter(c => c.status === 'inProgress').length;
                resolvedComplaints = complaintsData.filter(c => c.status === 'resolved').length;
                urgentComplaints = complaintsData.filter(c => c.priority === 'urgent').length;
            } catch (complaintsError) {
                console.warn('⚠️ Error processing complaints data:', complaintsError);
                // Use default values (already set above)
            }

            const stats = {
                totalStudents: studentsSnapshot.size,
                totalSupervisors: supervisorsSnapshot.size,
                totalParents: parentsSnapshot.size,
                activeStudents: activeStudents,
                studentsOnBus: studentsOnBus,
                studentsAtSchool: studentsAtSchool,
                studentsAtHome: studentsAtHome,
                tripsToday: tripsToday,
                totalTrips: tripsSnapshot.size,
                totalComplaints: totalComplaints,
                pendingComplaints: pendingComplaints,
                inProgressComplaints: inProgressComplaints,
                resolvedComplaints: resolvedComplaints,
                urgentComplaints: urgentComplaints
            };

            console.log('✅ Statistics fetched:', stats);
            return stats;
        } catch (error) {
            console.error('❌ Error getting statistics:', error);

            // Return default stats
            const defaultStats = {
                totalStudents: 0,
                totalSupervisors: 0,
                totalParents: 0,
                activeStudents: 0,
                studentsOnBus: 0,
                studentsAtSchool: 0,
                studentsAtHome: 0,
                tripsToday: 0,
                totalTrips: 0,
                totalComplaints: 0,
                pendingComplaints: 0,
                inProgressComplaints: 0,
                resolvedComplaints: 0,
                urgentComplaints: 0
            };

            console.log('⚠️ Using default statistics');
            return defaultStats;
        }
    },

    // Trips
    async getTrips(limit = 50) {
        try {
            console.log('🚌 Fetching trips...');
            const snapshot = await db.collection('trips')
                .orderBy('timestamp', 'desc')
                .limit(limit)
                .get();

            const trips = snapshot.docs.map(doc => {
                const data = doc.data();
                return {
                    id: doc.id,
                    studentId: data.studentId || '',
                    studentName: data.studentName || 'غير محدد',
                    supervisorId: data.supervisorId || '',
                    supervisorName: data.supervisorName || 'غير محدد',
                    busRoute: data.busRoute || 'غير محدد',
                    tripType: data.tripType || 'toSchool',
                    action: data.action || 'boardBus',
                    timestamp: data.timestamp,
                    notes: data.notes || ''
                };
            });

            console.log('✅ Trips fetched:', trips.length);
            return trips;
        } catch (error) {
            console.error('❌ Error getting trips:', error);
            return [];
        }
    },

    // Notifications
    async getNotifications(limit = 50) {
        try {
            console.log('🔔 Fetching notifications...');
            const snapshot = await db.collection('notifications')
                .orderBy('timestamp', 'desc')
                .limit(limit)
                .get();

            const notifications = snapshot.docs.map(doc => {
                const data = doc.data();
                return {
                    id: doc.id,
                    title: data.title || 'إشعار',
                    body: data.body || data.message || '',
                    recipientId: data.recipientId || data.userId || '',
                    studentId: data.studentId || '',
                    studentName: data.studentName || '',
                    type: data.type || 'general',
                    timestamp: data.timestamp,
                    isRead: data.isRead || false
                };
            });

            console.log('✅ Notifications fetched:', notifications.length);
            return notifications;
        } catch (error) {
            console.error('❌ Error getting notifications:', error);
            return [];
        }
    },

    // Buses
    async getBuses() {
        try {
            console.log('🚌 Fetching buses...');

            // Get buses without ordering to avoid index requirement
            let snapshot;
            try {
                snapshot = await db.collection('buses')
                    .where('isActive', '==', true)
                    .get();
                console.log('✅ Buses loaded without ordering');
            } catch (filterError) {
                console.warn('⚠️ Filter failed, trying to get all buses:', filterError);
                // Fallback: get all buses without any filters
                snapshot = await db.collection('buses').get();
                console.log('✅ All buses loaded (fallback)');
            }

            const buses = snapshot.docs.map(doc => {
                const data = doc.data();
                return {
                    id: doc.id,
                    plateNumber: data.plateNumber || '',
                    description: data.description || '',
                    driverName: data.driverName || '',
                    driverPhone: data.driverPhone || '',
                    route: data.route || '',
                    capacity: data.capacity || 30,
                    hasAirConditioning: data.hasAirConditioning || false,
                    isActive: data.isActive !== false,
                    createdAt: data.createdAt?.toDate() || new Date(),
                    updatedAt: data.updatedAt?.toDate() || new Date(),
                    studentsCount: data.studentsCount || 0
                };
            }).filter(bus => bus.isActive !== false); // Filter active buses in memory

            // Sort by createdAt in memory (newest first)
            buses.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());

            console.log('✅ Buses fetched:', buses.length);
            return buses;
        } catch (error) {
            console.error('❌ Error getting buses:', error);

            // Try to get all buses without any filters as last resort
            try {
                console.log('🔄 Trying to get all buses without filters...');
                const allSnapshot = await db.collection('buses').get();
                const allBuses = allSnapshot.docs.map(doc => {
                    const data = doc.data();
                    return {
                        id: doc.id,
                        plateNumber: data.plateNumber || '',
                        description: data.description || '',
                        driverName: data.driverName || '',
                        driverPhone: data.driverPhone || '',
                        route: data.route || '',
                        capacity: data.capacity || 30,
                        hasAirConditioning: data.hasAirConditioning || false,
                        isActive: data.isActive !== false,
                        createdAt: data.createdAt,
                        updatedAt: data.updatedAt,
                        studentsCount: data.studentsCount || 0
                    };
                }).filter(bus => bus.isActive !== false); // Filter in memory

                console.log('✅ All buses fetched (fallback):', allBuses.length);
                return allBuses;
            } catch (fallbackError) {
                console.error('❌ Fallback also failed:', fallbackError);
                return [];
            }
        }
    },

    async addBus(busData) {
        try {
            console.log('🚌 Adding bus to Firebase:', busData);

            // Check if Firebase is available
            if (typeof firebase === 'undefined' || !firebase.firestore) {
                console.error('❌ Firebase not available');
                return { success: false, error: 'Firebase غير متاح' };
            }

            // Check if db is available
            if (typeof db === 'undefined') {
                console.error('❌ Database connection not available');
                return { success: false, error: 'اتصال قاعدة البيانات غير متاح' };
            }

            // Use the provided ID or generate a new one
            const busId = busData.id || ('bus_' + Date.now().toString());
            console.log('🆔 Using bus ID:', busId);

            const busDocument = {
                ...busData,
                id: busId,
                isActive: true,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };

            console.log('📄 Bus document to save:', busDocument);

            await db.collection('buses').doc(busId).set(busDocument);

            console.log('✅ Bus added to Firebase with ID:', busId);
            return { success: true, id: busId };
        } catch (error) {
            console.error('❌ Error adding bus to Firebase:', error);
            console.error('❌ Error details:', {
                code: error.code,
                message: error.message,
                stack: error.stack
            });
            return { success: false, error: error.message };
        }
    },

    async updateBus(id, busData) {
        try {
            console.log('🚌 Updating bus:', id, busData);
            await db.collection('buses').doc(id).update({
                ...busData,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            console.log('✅ Bus updated successfully');
            return { success: true };
        } catch (error) {
            console.error('❌ Error updating bus:', error);
            return { success: false, error: error.message };
        }
    },

    async deleteBus(id) {
        try {
            console.log('🚌 Deleting bus:', id);
            await db.collection('buses').doc(id).delete();
            console.log('✅ Bus deleted successfully');
            return { success: true };
        } catch (error) {
            console.error('❌ Error deleting bus:', error);
            return { success: false, error: error.message };
        }
    },

    // Test function to add a sample bus
    async addTestBus() {
        try {
            console.log('🧪 Adding test bus...');
            const testBus = {
                id: 'test_' + Date.now(),
                plateNumber: 'أ ب ج 123',
                description: 'باص تجريبي للاختبار',
                driverName: 'أحمد محمد',
                driverPhone: '01234567890',
                route: 'الخط التجريبي',
                capacity: 30,
                hasAirConditioning: true,
                isActive: true,
                studentsCount: 0
            };

            const result = await this.addBus(testBus);
            if (result.success) {
                console.log('✅ Test bus added successfully');
                return testBus;
            } else {
                throw new Error(result.error);
            }
        } catch (error) {
            console.error('❌ Error adding test bus:', error);
            throw error;
        }
    },

    // Add student with parent linking
    async addStudent(studentData) {
        try {
            console.log('👨‍🎓 Adding student with parent linking:', studentData);

            // Generate unique ID and QR code
            const studentId = Date.now().toString();
            const qrCode = studentData.qrCode || `STUDENT_${studentId}`;

            const newStudent = {
                id: studentId,
                name: studentData.name,
                parentId: studentData.parentId || '',
                parentName: studentData.parentName || '',
                parentPhone: studentData.parentPhone || '',
                qrCode: qrCode,
                schoolName: studentData.school || studentData.schoolName,
                grade: studentData.grade,
                busRoute: studentData.busRoute || 'الخط الأول',
                currentStatus: studentData.currentStatus || 'home',
                isActive: studentData.isActive !== false,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };

            // Add student to students collection
            await db.collection('students').doc(studentId).set(newStudent);
            console.log('✅ Student added to students collection');

            // If parent is linked, update parent's children list
            if (studentData.parentId && studentData.parentId !== '') {
                try {
                    console.log('🔗 Linking student to parent:', studentData.parentId);

                    // Get current parent data
                    const parentDoc = await db.collection('users').doc(studentData.parentId).get();

                    if (parentDoc.exists) {
                        const parentData = parentDoc.data();
                        const currentChildren = parentData.children || [];

                        // Add new child to parent's children array
                        const updatedChildren = [...currentChildren, {
                            id: studentId,
                            name: studentData.name,
                            grade: studentData.grade,
                            schoolName: studentData.schoolName,
                            busRoute: studentData.busRoute,
                            qrCode: qrCode,
                            addedAt: firebase.firestore.FieldValue.serverTimestamp()
                        }];

                        // Update parent document
                        await db.collection('users').doc(studentData.parentId).update({
                            children: updatedChildren,
                            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                        });

                        console.log('✅ Parent children list updated');
                    } else {
                        console.warn('⚠️ Parent not found:', studentData.parentId);
                    }

                } catch (linkError) {
                    console.error('❌ Error linking student to parent:', linkError);
                    // Don't fail the whole operation if linking fails
                }
            }

            return { success: true, id: studentId, qrCode: qrCode };
        } catch (error) {
            console.error('❌ Error adding student:', error);
            return { success: false, error: error.message };
        }
    },

    // Delete student (soft delete) with parent unlinking
    async deleteStudent(studentId) {
        try {
            console.log('🗑️ Deleting student with parent unlinking:', studentId);

            // Get current student data to find parent
            const studentDoc = await db.collection('students').doc(studentId).get();
            const studentData = studentDoc.exists ? studentDoc.data() : null;

            // Soft delete student
            await db.collection('students').doc(studentId).update({
                isActive: false,
                deletedAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });
            console.log('✅ Student soft deleted');

            // Remove student from parent's children list
            if (studentData?.parentId && studentData.parentId !== '') {
                try {
                    const parentDoc = await db.collection('users').doc(studentData.parentId).get();
                    if (parentDoc.exists) {
                        const parentData = parentDoc.data();
                        const updatedChildren = (parentData.children || []).filter(child => child.id !== studentId);

                        await db.collection('users').doc(studentData.parentId).update({
                            children: updatedChildren,
                            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                        });

                        console.log('✅ Student removed from parent children list');
                    }
                } catch (error) {
                    console.error('❌ Error removing student from parent:', error);
                    // Don't fail the whole operation
                }
            }

            return { success: true };
        } catch (error) {
            console.error('❌ Error deleting student:', error);
            return { success: false, error: error.message };
        }
    },

    // Update student with parent linking
    async updateStudent(studentId, studentData) {
        try {
            console.log('🔄 Updating student with parent linking:', studentId, studentData);

            // Get current student data to check for parent changes
            const currentStudentDoc = await db.collection('students').doc(studentId).get();
            const currentStudent = currentStudentDoc.exists ? currentStudentDoc.data() : null;

            const oldParentId = currentStudent?.parentId;
            const newParentId = studentData.parentId;

            // Update student document
            const updateData = {
                ...studentData,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };

            await db.collection('students').doc(studentId).update(updateData);
            console.log('✅ Student document updated');

            // Handle parent linking changes
            if (oldParentId !== newParentId) {
                console.log('🔄 Parent changed from', oldParentId, 'to', newParentId);

                // Remove student from old parent's children list
                if (oldParentId && oldParentId !== '') {
                    try {
                        const oldParentDoc = await db.collection('users').doc(oldParentId).get();
                        if (oldParentDoc.exists) {
                            const oldParentData = oldParentDoc.data();
                            const updatedChildren = (oldParentData.children || []).filter(child => child.id !== studentId);

                            await db.collection('users').doc(oldParentId).update({
                                children: updatedChildren,
                                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                            });

                            console.log('✅ Student removed from old parent');
                        }
                    } catch (error) {
                        console.error('❌ Error removing from old parent:', error);
                    }
                }

                // Add student to new parent's children list
                if (newParentId && newParentId !== '') {
                    try {
                        const newParentDoc = await db.collection('users').doc(newParentId).get();
                        if (newParentDoc.exists) {
                            const newParentData = newParentDoc.data();
                            const currentChildren = newParentData.children || [];

                            // Check if student is already in the list
                            const existingChild = currentChildren.find(child => child.id === studentId);

                            if (!existingChild) {
                                const updatedChildren = [...currentChildren, {
                                    id: studentId,
                                    name: studentData.name || currentStudent?.name,
                                    grade: studentData.grade || currentStudent?.grade,
                                    schoolName: studentData.schoolName || currentStudent?.schoolName,
                                    busRoute: studentData.busRoute || currentStudent?.busRoute,
                                    qrCode: currentStudent?.qrCode,
                                    addedAt: firebase.firestore.FieldValue.serverTimestamp()
                                }];

                                await db.collection('users').doc(newParentId).update({
                                    children: updatedChildren,
                                    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                                });

                                console.log('✅ Student added to new parent');
                            } else {
                                // Update existing child info
                                const updatedChildren = currentChildren.map(child =>
                                    child.id === studentId ? {
                                        ...child,
                                        name: studentData.name || child.name,
                                        grade: studentData.grade || child.grade,
                                        schoolName: studentData.schoolName || child.schoolName,
                                        busRoute: studentData.busRoute || child.busRoute,
                                        updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                                    } : child
                                );

                                await db.collection('users').doc(newParentId).update({
                                    children: updatedChildren,
                                    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                                });

                                console.log('✅ Student info updated in parent');
                            }
                        }
                    } catch (error) {
                        console.error('❌ Error adding to new parent:', error);
                    }
                }
            } else if (newParentId && newParentId !== '') {
                // Same parent, just update child info
                try {
                    const parentDoc = await db.collection('users').doc(newParentId).get();
                    if (parentDoc.exists) {
                        const parentData = parentDoc.data();
                        const currentChildren = parentData.children || [];

                        const updatedChildren = currentChildren.map(child =>
                            child.id === studentId ? {
                                ...child,
                                name: studentData.name || child.name,
                                grade: studentData.grade || child.grade,
                                schoolName: studentData.schoolName || child.schoolName,
                                busRoute: studentData.busRoute || child.busRoute,
                                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                            } : child
                        );

                        await db.collection('users').doc(newParentId).update({
                            children: updatedChildren,
                            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
                        });

                        console.log('✅ Student info updated in same parent');
                    }
                } catch (error) {
                    console.error('❌ Error updating child info in parent:', error);
                }
            }

            return { success: true };
        } catch (error) {
            console.error('❌ Error updating student:', error);
            return { success: false, error: error.message };
        }
    },

    // Add supervisor (simplified approach - create user document only)
    async addSupervisor(supervisorData) {
        try {
            console.log('🔄 Adding supervisor:', supervisorData.email);

            // Generate unique ID for supervisor
            const supervisorId = Date.now().toString() + '_supervisor';

            // Create user document in Firestore (they can register later with this email)
            const userData = {
                id: supervisorId,
                name: supervisorData.name,
                email: supervisorData.email,
                phone: supervisorData.phone,
                userType: 'supervisor',
                isActive: true,
                tempPassword: supervisorData.password, // Store temporarily for first login
                needsPasswordReset: true,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };

            await db.collection('users').doc(supervisorId).set(userData);
            console.log('✅ Supervisor document created in Firestore');

            // Also add to a pending users collection for admin approval
            await db.collection('pending_users').doc(supervisorId).set({
                ...userData,
                createdBy: firebase.auth().currentUser?.uid,
                status: 'pending_activation'
            });

            return { success: true, id: supervisorId };
        } catch (error) {
            console.error('❌ Error adding supervisor:', error);

            // Handle specific errors
            let errorMessage = error.message;
            if (error.code === 'permission-denied') {
                errorMessage = 'ليس لديك صلاحية لإضافة مشرفين';
            }

            return { success: false, error: errorMessage };
        }
    },

    // Update supervisor
    async updateSupervisor(supervisorId, supervisorData) {
        try {
            console.log('🔄 Updating supervisor:', supervisorId);

            const updateData = {
                ...supervisorData,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };

            await db.collection('users').doc(supervisorId).update(updateData);
            console.log('✅ Supervisor updated successfully');

            return { success: true };
        } catch (error) {
            console.error('❌ Error updating supervisor:', error);
            return { success: false, error: error.message };
        }
    },

    // Delete supervisor (soft delete)
    async deleteSupervisor(supervisorId) {
        try {
            console.log('🗑️ Deleting supervisor:', supervisorId);

            await db.collection('users').doc(supervisorId).update({
                isActive: false,
                deletedAt: firebase.firestore.FieldValue.serverTimestamp(),
                deletedBy: firebase.auth().currentUser?.uid || 'admin'
            });

            console.log('✅ Supervisor deleted successfully');
            return { success: true };
        } catch (error) {
            console.error('❌ Error deleting supervisor:', error);
            return { success: false, error: error.message };
        }
    },

    // Update supervisor permissions
    async updateSupervisorPermissions(supervisorId, permissions) {
        try {
            console.log('🔑 Updating supervisor permissions:', supervisorId, permissions);

            await db.collection('users').doc(supervisorId).update({
                permissions: permissions,
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            });

            console.log('✅ Supervisor permissions updated successfully');
            return { success: true };
        } catch (error) {
            console.error('❌ Error updating supervisor permissions:', error);
            return { success: false, error: error.message };
        }
    },

    // Add parent (simplified approach - create user document only)
    async addParent(parentData) {
        try {
            console.log('🔄 Adding parent:', parentData.email);

            // Generate unique ID for parent
            const parentId = Date.now().toString() + '_parent';

            // Create user document in Firestore (they can register later with this email)
            const userData = {
                id: parentId,
                name: parentData.name,
                email: parentData.email,
                phone: parentData.phone,
                userType: 'parent',
                isActive: true,
                tempPassword: parentData.password, // Store temporarily for first login
                needsPasswordReset: true,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };

            await db.collection('users').doc(parentId).set(userData);
            console.log('✅ Parent document created in Firestore');

            // Also add to a pending users collection for admin approval
            await db.collection('pending_users').doc(parentId).set({
                ...userData,
                createdBy: firebase.auth().currentUser?.uid,
                status: 'pending_activation'
            });

            return { success: true, id: parentId };
        } catch (error) {
            console.error('❌ Error adding parent:', error);

            // Handle specific errors
            let errorMessage = error.message;
            if (error.code === 'permission-denied') {
                errorMessage = 'ليس لديك صلاحية لإضافة أولياء أمور';
            }

            return { success: false, error: errorMessage };
        }
    },

    // Update parent
    async updateParent(parentId, parentData) {
        try {
            console.log('🔄 Updating parent in Firebase:', parentId);
            console.log('📋 Parent data to update:', parentData);

            // Prepare update data with detailed logging
            const updateData = {
                name: parentData.name,
                email: parentData.email,
                phone: parentData.phone,
                address: parentData.address || '',
                occupation: parentData.occupation || '',
                emergencyPhone: parentData.emergencyPhone || '',
                status: parentData.status,
                notificationPreferences: parentData.notificationPreferences || [],
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };

            // Log the exact data being sent to Firebase
            console.log('💾 Exact data being sent to Firebase:');
            console.log('- name:', updateData.name);
            console.log('- email:', updateData.email);
            console.log('- phone:', updateData.phone);
            console.log('- address:', updateData.address);
            console.log('- occupation:', updateData.occupation);
            console.log('- emergencyPhone:', updateData.emergencyPhone);
            console.log('- status:', updateData.status);
            console.log('- notificationPreferences:', updateData.notificationPreferences);

            // Update the document
            await db.collection('users').doc(parentId).update(updateData);
            console.log('✅ Parent updated successfully in Firebase');

            // Verify the update by reading the document back
            const updatedDoc = await db.collection('users').doc(parentId).get();
            if (updatedDoc.exists) {
                const updatedData = updatedDoc.data();
                console.log('🔍 Verification - Updated document data:');
                console.log('- address in DB:', updatedData.address);
                console.log('- occupation in DB:', updatedData.occupation);
                console.log('- emergencyPhone in DB:', updatedData.emergencyPhone);
            }

            return { success: true };
        } catch (error) {
            console.error('❌ Error updating parent:', error);
            console.error('❌ Error details:', error.message);
            return { success: false, error: error.message };
        }
    },

    // Delete parent (soft delete)
    async deleteParent(parentId) {
        try {
            console.log('🗑️ Deleting parent:', parentId);

            await db.collection('users').doc(parentId).update({
                isActive: false,
                deletedAt: firebase.firestore.FieldValue.serverTimestamp(),
                deletedBy: firebase.auth().currentUser?.uid || 'admin'
            });

            console.log('✅ Parent deleted successfully');
            return { success: true };
        } catch (error) {
            console.error('❌ Error deleting parent:', error);
            return { success: false, error: error.message };
        }
    },

    // Get parent's children
    async getParentChildren(parentId) {
        try {
            console.log('👶 Getting children for parent:', parentId);

            const snapshot = await db.collection('students')
                .where('parentId', '==', parentId)
                .where('isActive', '==', true)
                .get();

            const children = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));

            console.log('✅ Children fetched:', children.length);
            return children;
        } catch (error) {
            console.error('❌ Error getting parent children:', error);
            return [];
        }
    },

    // Add child to parent
    async addChildToParent(parentId, childData) {
        try {
            console.log('👶 Adding child to parent:', parentId);

            const childWithParent = {
                ...childData,
                parentId: parentId,
                isActive: true,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                updatedAt: firebase.firestore.FieldValue.serverTimestamp()
            };

            const docRef = await db.collection('students').add(childWithParent);
            console.log('✅ Child added successfully');

            return { success: true, id: docRef.id };
        } catch (error) {
            console.error('❌ Error adding child:', error);
            return { success: false, error: error.message };
        }
    },

    // Remove child from parent
    async removeChildFromParent(childId) {
        try {
            console.log('🗑️ Removing child:', childId);

            await db.collection('students').doc(childId).update({
                isActive: false,
                deletedAt: firebase.firestore.FieldValue.serverTimestamp(),
                deletedBy: firebase.auth().currentUser?.uid || 'admin'
            });

            console.log('✅ Child removed successfully');
            return { success: true };
        } catch (error) {
            console.error('❌ Error removing child:', error);
            return { success: false, error: error.message };
        }
    },

    // Send notification to parent
    async sendNotificationToParent(parentId, notificationData) {
        try {
            console.log('📤 Sending notification to parent:', parentId);

            const notification = {
                title: notificationData.title,
                body: notificationData.body,
                type: notificationData.type || 'general',
                recipientId: parentId,
                recipientType: 'parent',
                senderId: firebase.auth().currentUser?.uid || 'admin',
                senderEmail: firebase.auth().currentUser?.email || 'admin@mybus.com',
                timestamp: firebase.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                priority: notificationData.priority || 'normal',
                data: notificationData.data || {},
                status: 'sent'
            };

            const notificationRef = await db.collection('notifications').add(notification);
            console.log('✅ Notification sent successfully');

            return { success: true, notificationId: notificationRef.id };
        } catch (error) {
            console.error('❌ Error sending notification:', error);
            return { success: false, error: error.message };
        }
    },

    // Real-time listeners
    onStudentsChange(callback) {
        return db.collection('students')
            .where('isActive', '==', true)
            .orderBy('name')
            .onSnapshot(snapshot => {
                const students = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
                callback(students);
            });
    },

    onUsersChange(userType, callback) {
        return db.collection('users')
            .where('userType', '==', userType)
            .where('isActive', '==', true)
            .onSnapshot(snapshot => {
                const users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
                callback(users);
            });
    },

    // Settings functions
    async getSettings() {
        try {
            const settingsRef = db.collection('settings');
            const snapshot = await settingsRef.get();

            const settings = {};
            snapshot.forEach(doc => {
                settings[doc.id] = doc.data();
            });

            // Merge all settings into one object
            const mergedSettings = {};
            Object.values(settings).forEach(setting => {
                Object.assign(mergedSettings, setting);
            });

            return mergedSettings;
        } catch (error) {
            console.error('Error getting settings:', error);
            return {};
        }
    },

    async updateSettings(category, settingsData) {
        try {
            const settingsRef = db.collection('settings').doc(category);
            await settingsRef.set(settingsData, { merge: true });

            return { success: true };
        } catch (error) {
            console.error('Error updating settings:', error);
            return { success: false, error: error.message };
        }
    },

    // Bus routes functions
    async getBusRoutes() {
        try {
            const routesRef = db.collection('busRoutes');
            const snapshot = await routesRef.orderBy('name').get();

            const routes = [];
            snapshot.forEach(doc => {
                routes.push({
                    id: doc.id,
                    ...doc.data()
                });
            });

            return routes;
        } catch (error) {
            console.error('Error getting bus routes:', error);
            return [];
        }
    },

    async addBusRoute(routeData) {
        try {
            const routesRef = db.collection('busRoutes');
            await routesRef.add(routeData);

            return { success: true };
        } catch (error) {
            console.error('Error adding bus route:', error);
            return { success: false, error: error.message };
        }
    },

    async updateBusRoute(routeId, routeData) {
        try {
            const routeRef = db.collection('busRoutes').doc(routeId);
            await routeRef.update(routeData);

            return { success: true };
        } catch (error) {
            console.error('Error updating bus route:', error);
            return { success: false, error: error.message };
        }
    },

    async deleteBusRoute(routeId) {
        try {
            const routeRef = db.collection('busRoutes').doc(routeId);
            await routeRef.delete();

            return { success: true };
        } catch (error) {
            console.error('Error deleting bus route:', error);
            return { success: false, error: error.message };
        }
    },

    // System functions
    async exportAllData() {
        try {
            const collections = ['students', 'users', 'busRoutes', 'settings', 'trips', 'notifications'];
            const exportData = {};

            for (const collection of collections) {
                const snapshot = await db.collection(collection).get();
                exportData[collection] = [];

                snapshot.forEach(doc => {
                    exportData[collection].push({
                        id: doc.id,
                        ...doc.data()
                    });
                });
            }

            exportData.exportDate = new Date().toISOString();
            return exportData;
        } catch (error) {
            console.error('Error exporting data:', error);
            throw error;
        }
    },

    async createBackup() {
        try {
            console.log('💾 Creating backup...');
            const backupData = await this.exportAllData();

            const backupId = `backup_${Date.now()}`;
            const backupRef = db.collection('backups').doc(backupId);

            const backupInfo = {
                id: backupId,
                data: backupData,
                createdAt: firebase.firestore.FieldValue.serverTimestamp(),
                createdBy: firebase.auth().currentUser?.uid || 'admin',
                createdByEmail: firebase.auth().currentUser?.email || 'admin@mybus.com',
                size: JSON.stringify(backupData).length,
                version: '1.0',
                collections: Object.keys(backupData),
                totalRecords: Object.values(backupData).reduce((total, collection) => {
                    return total + (Array.isArray(collection) ? collection.length : 0);
                }, 0),
                status: 'completed'
            };

            await backupRef.set(backupInfo);
            console.log('✅ Backup created with ID:', backupId);

            return { success: true, backupId: backupId };
        } catch (error) {
            console.error('❌ Error creating backup:', error);
            return { success: false, error: error.message };
        }
    },

    async resetSystem() {
        try {
            const collections = ['students', 'users', 'busRoutes', 'trips', 'notifications'];

            for (const collection of collections) {
                const snapshot = await db.collection(collection).get();
                const batch = db.batch();

                snapshot.forEach(doc => {
                    batch.delete(doc.ref);
                });

                await batch.commit();
            }

            return { success: true };
        } catch (error) {
            console.error('Error resetting system:', error);
            return { success: false, error: error.message };
        }
    },

    // Real notification functions
    async sendNotification(notificationData) {
        try {
            console.log('📤 Sending notification:', notificationData);

            const notification = {
                title: notificationData.title,
                body: notificationData.body,
                type: notificationData.type || 'general',
                recipientId: notificationData.recipientId,
                recipientType: notificationData.recipientType || 'user',
                senderId: firebase.auth().currentUser?.uid || 'system',
                senderEmail: firebase.auth().currentUser?.email || 'system',
                timestamp: firebase.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                priority: notificationData.priority || 'normal',
                data: notificationData.data || {},
                status: 'sent'
            };

            const notificationRef = await db.collection('notifications').add(notification);
            console.log('✅ Notification sent with ID:', notificationRef.id);

            return { success: true, notificationId: notificationRef.id };
        } catch (error) {
            console.error('❌ Error sending notification:', error);
            return { success: false, error: error.message };
        }
    },

    async sendBulkNotifications(recipients, notificationData) {
        try {
            console.log('📤 Sending bulk notifications to', recipients.length, 'recipients');

            const batch = db.batch();
            const notificationIds = [];

            recipients.forEach(recipient => {
                const notificationRef = db.collection('notifications').doc();
                notificationIds.push(notificationRef.id);

                const notification = {
                    title: notificationData.title,
                    body: notificationData.body,
                    type: notificationData.type || 'general',
                    recipientId: recipient.id,
                    recipientType: recipient.type || 'user',
                    recipientName: recipient.name || 'مستخدم',
                    senderId: firebase.auth().currentUser?.uid || 'system',
                    senderEmail: firebase.auth().currentUser?.email || 'system',
                    timestamp: firebase.firestore.FieldValue.serverTimestamp(),
                    isRead: false,
                    priority: notificationData.priority || 'normal',
                    data: notificationData.data || {},
                    status: 'sent'
                };

                batch.set(notificationRef, notification);
            });

            await batch.commit();
            console.log('✅ Bulk notifications sent:', notificationIds.length);

            return { success: true, notificationIds: notificationIds };
        } catch (error) {
            console.error('❌ Error sending bulk notifications:', error);
            return { success: false, error: error.message };
        }
    },

    async markNotificationAsRead(notificationId) {
        try {
            await db.collection('notifications').doc(notificationId).update({
                isRead: true,
                readAt: firebase.firestore.FieldValue.serverTimestamp(),
                readBy: firebase.auth().currentUser?.uid || 'user'
            });

            return { success: true };
        } catch (error) {
            console.error('❌ Error marking notification as read:', error);
            return { success: false, error: error.message };
        }
    }
};

// Auth state management
let isProcessingAuth = false;
let lastAuthUser = null;

// Auth state observer
auth.onAuthStateChanged(async (user) => {
    // Prevent multiple simultaneous auth processing
    if (isProcessingAuth) {
        console.log('⏳ Auth processing already in progress, skipping...');
        return;
    }

    // Check if this is the same user state
    const userEmail = user ? user.email : null;
    const lastUserEmail = lastAuthUser ? lastAuthUser.email : null;

    if (userEmail === lastUserEmail) {
        // Silently skip same auth state to reduce console noise
        return;
    }

    isProcessingAuth = true;
    lastAuthUser = user;

    console.log('🔐 Auth state changed:', user ? `User: ${user.email}` : 'No user');

    try {
        if (user) {
            console.log('🔍 Checking admin status for:', user.email);

            // Quick check for admin email first
            if (user.email === 'admin@mybus.com') {
                console.log('✅ Admin email detected, granting access');
                window.currentUser = user;
                if (window.onAuthStateChanged) {
                    window.onAuthStateChanged(user);
                }
            } else {
                // Check if user is admin in database
                const isAdmin = await FirebaseService.isAdmin(user.uid);

                if (isAdmin) {
                    console.log('✅ Admin access granted');
                    window.currentUser = user;
                    if (window.onAuthStateChanged) {
                        window.onAuthStateChanged(user);
                    }
                } else {
                    console.log('❌ Admin access denied');
                    // User is not admin, sign out
                    await FirebaseService.signOut();
                    alert('ليس لديك صلاحية للوصول إلى لوحة التحكم');
                }
            }
        } else {
            console.log('👤 User signed out');
            // User is signed out
            window.currentUser = null;
            if (window.onAuthStateChanged) {
                window.onAuthStateChanged(null);
            }
        }
    } catch (error) {
        console.error('❌ Error in auth state change:', error);

        // If it's admin email, allow access despite error
        if (user && user.email === 'admin@mybus.com') {
            console.log('⚠️ Allowing admin access despite error');
            window.currentUser = user;
            if (window.onAuthStateChanged) {
                window.onAuthStateChanged(user);
            }
        } else {
            if (user) {
                await FirebaseService.signOut();
                alert('حدث خطأ في التحقق من الصلاحيات');
            }
        }
    } finally {
        // Reset processing flag after a short delay
        setTimeout(() => {
            isProcessingAuth = false;
        }, 1000);
    }
});
