// API Base URL - use localhost for port-forward setup
const API_BASE_URL = 'http://localhost:30001/api';

// DOM Elements
const studentTableBody = document.getElementById('student-table-body');
const studentModal = document.getElementById('student-modal');
const confirmModal = document.getElementById('confirm-modal');
const studentForm = document.getElementById('student-form');
const searchInput = document.getElementById('search-input');
const addStudentBtn = document.getElementById('add-student-btn');
const closeModalBtn = document.getElementById('close-modal');
const cancelBtn = document.getElementById('cancel-btn');
const closeConfirmModalBtn = document.getElementById('close-confirm-modal');
const cancelDeleteBtn = document.getElementById('cancel-delete-btn');
const confirmDeleteBtn = document.getElementById('confirm-delete-btn');
const toast = document.getElementById('toast');
const loadingElement = document.getElementById('loading');

// State variables
let students = [];
let currentStudentId = null;
let isEditing = false;

// Initialize the application
async function init() {
    console.log('🚀 Initializing Student Management System...');
    console.log('API Base URL:', API_BASE_URL);
    setupEventListeners();
    await loadStudents();
}

// Set up event listeners
function setupEventListeners() {
    addStudentBtn.addEventListener('click', openAddModal);
    closeModalBtn.addEventListener('click', closeModal);
    cancelBtn.addEventListener('click', closeModal);
    closeConfirmModalBtn.addEventListener('click', closeConfirmModal);
    cancelDeleteBtn.addEventListener('click', closeConfirmModal);
    studentForm.addEventListener('submit', saveStudent);
    searchInput.addEventListener('input', filterStudents);
    confirmDeleteBtn.addEventListener('click', deleteStudent);
    
    console.log('✅ Event listeners set up');
}

// Load students from API
async function loadStudents() {
    showLoading(true);
    try {
        console.log('📡 Loading students from:', `${API_BASE_URL}/students`);
        const response = await fetch(`${API_BASE_URL}/students`);
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }
        
        students = await response.json();
        console.log('✅ Loaded students:', students);
        renderStudentTable();
        updateSummary();
    } catch (error) {
        console.error('❌ Error loading students:', error);
        showToast('Error loading students: ' + error.message, true);
        students = [];
        renderStudentTable();
        updateSummary();
    } finally {
        showLoading(false);
    }
}

// Show/hide loading indicator
function showLoading(show) {
    if (show) {
        loadingElement.classList.add('show');
        studentTableBody.innerHTML = '';
    } else {
        loadingElement.classList.remove('show');
    }
}

// Render student table
function renderStudentTable(studentsToRender = students) {
    studentTableBody.innerHTML = '';
    
    if (studentsToRender.length === 0) {
        studentTableBody.innerHTML = `
            <tr>
                <td colspan="6" style="text-align: center; color: #666; padding: 20px;">
                    No students found. <br>
                    <small>Try adding a student or check if the backend is running.</small>
                </td>
            </tr>
        `;
        return;
    }
    
    studentsToRender.forEach(student => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td>${student.id}</td>
            <td>${student.name}</td>
            <td>${student.age}</td>
            <td><span class="grade-badge grade-${student.grade}">${student.grade}</span></td>
            <td>${student.email}</td>
            <td>
                <div class="action-btns">
                    <button class="action-btn edit-btn" data-id="${student.id}">Edit</button>
                    <button class="action-btn delete-btn" data-id="${student.id}">Delete</button>
                </div>
            </td>
        `;
        studentTableBody.appendChild(row);
    });
    
    // Add event listeners to action buttons
    document.querySelectorAll('.edit-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const id = parseInt(e.target.getAttribute('data-id'));
            openEditModal(id);
        });
    });
    
    document.querySelectorAll('.delete-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
            const id = parseInt(e.target.getAttribute('data-id'));
            openConfirmModal(id);
        });
    });
}

// Update summary cards
function updateSummary() {
    const totalStudents = students.length;
    const gradeAStudents = students.filter(student => student.grade === 'A').length;
    const totalAge = students.reduce((sum, student) => sum + student.age, 0);
    const avgAge = students.length > 0 ? Math.round(totalAge / students.length) : 0;
    
    document.getElementById('total-students').textContent = totalStudents;
    document.getElementById('grade-a').textContent = gradeAStudents;
    document.getElementById('avg-age').textContent = avgAge;
}

// Filter students based on search input
function filterStudents() {
    const searchTerm = searchInput.value.toLowerCase();
    const filteredStudents = students.filter(student => 
        student.name.toLowerCase().includes(searchTerm) ||
        student.email.toLowerCase().includes(searchTerm) ||
        student.grade.toLowerCase().includes(searchTerm)
    );
    renderStudentTable(filteredStudents);
}

// Open modal for adding a new student
function openAddModal() {
    isEditing = false;
    document.getElementById('modal-title').textContent = 'Add New Student';
    studentForm.reset();
    document.getElementById('student-id').value = '';
    studentModal.classList.add('show');
}

// Open modal for editing a student
function openEditModal(id) {
    isEditing = true;
    const student = students.find(s => s.id === id);
    if (student) {
        document.getElementById('modal-title').textContent = 'Edit Student';
        document.getElementById('student-id').value = student.id;
        document.getElementById('name').value = student.name;
        document.getElementById('age').value = student.age;
        document.getElementById('grade').value = student.grade;
        document.getElementById('email').value = student.email;
        studentModal.classList.add('show');
    }
}

// Close the student modal
function closeModal() {
    studentModal.classList.remove('show');
}

// Open confirmation modal for deletion
function openConfirmModal(id) {
    currentStudentId = id;
    const student = students.find(s => s.id === id);
    if (student) {
        document.querySelector('#confirm-modal p').textContent = 
            `Are you sure you want to delete "${student.name}"? This action cannot be undone.`;
    }
    confirmModal.classList.add('show');
}

// Close confirmation modal
function closeConfirmModal() {
    confirmModal.classList.remove('show');
    currentStudentId = null;
}

// Save student (both add and edit)
async function saveStudent(e) {
    e.preventDefault();
    
    const studentData = {
        name: document.getElementById('name').value.trim(),
        age: parseInt(document.getElementById('age').value),
        grade: document.getElementById('grade').value,
        email: document.getElementById('email').value.trim()
    };
    
    // Validation
    if (!studentData.name || !studentData.age || !studentData.grade || !studentData.email) {
        showToast('Please fill in all fields', true);
        return;
    }
    
    if (studentData.age < 16 || studentData.age > 30) {
        showToast('Age must be between 16 and 30', true);
        return;
    }
    
    if (!studentData.email.includes('@')) {
        showToast('Please enter a valid email address', true);
        return;
    }
    
    try {
        let response;
        if (isEditing) {
            const studentId = document.getElementById('student-id').value;
            console.log('🔄 Updating student:', studentId, studentData);
            response = await fetch(`${API_BASE_URL}/students/${studentId}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(studentData)
            });
        } else {
            console.log('➕ Creating student:', studentData);
            response = await fetch(`${API_BASE_URL}/students`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(studentData)
            });
        }
        
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.error || `HTTP ${response.status}`);
        }
        
        const result = await response.json();
        showToast(result.message || 'Student saved successfully!');
        
        // Reload students to get the updated list
        await loadStudents();
        closeModal();
    } catch (error) {
        console.error('❌ Error saving student:', error);
        showToast('Error: ' + error.message, true);
    }
}

// Delete student
async function deleteStudent() {
    try {
        console.log('🗑️ Deleting student:', currentStudentId);
        const response = await fetch(`${API_BASE_URL}/students/${currentStudentId}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            const errorData = await response.json().catch(() => ({}));
            throw new Error(errorData.error || `HTTP ${response.status}`);
        }
        
        const result = await response.json();
        showToast(result.message || 'Student deleted successfully!');
        
        // Reload students to get the updated list
        await loadStudents();
        closeConfirmModal();
    } catch (error) {
        console.error('❌ Error deleting student:', error);
        showToast('Error: ' + error.message, true);
    }
}

// Show toast notification
function showToast(message, isError = false) {
    toast.textContent = message;
    toast.className = 'toast' + (isError ? ' error' : '');
    toast.classList.add('show');
    
    setTimeout(() => {
        toast.classList.remove('show');
    }, 4000);
}

// Initialize the application when DOM is loaded
document.addEventListener('DOMContentLoaded', async () => {
    console.log('🎯 Student Management System Starting...');
    await init();
});
