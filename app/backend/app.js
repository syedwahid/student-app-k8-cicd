const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;

console.log('🚀 Starting Student Management Backend...');

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// In-memory storage for demo
let students = [
    { id: 1, name: 'John Doe', age: 20, grade: 'A', email: 'john@school.com' },
    { id: 2, name: 'Jane Smith', age: 21, grade: 'B', email: 'jane@school.com' },
    { id: 3, name: 'Mike Johnson', age: 19, grade: 'A', email: 'mike@school.com' },
    { id: 4, name: 'Sarah Wilson', age: 22, grade: 'C', email: 'sarah@school.com' },
    { id: 5, name: 'Tom Brown', age: 18, grade: 'B', email: 'tom@school.com' }
];

let nextId = 6;

// Health check
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: 'Backend is working!',
        timestamp: new Date().toISOString()
    });
});

// Get all students
app.get('/api/students', (req, res) => {
    res.json(students);
});

// Get student by ID
app.get('/api/students/:id', (req, res) => {
    const id = parseInt(req.params.id);
    const student = students.find(s => s.id === id);
    if (!student) {
        return res.status(404).json({ error: 'Student not found' });
    }
    res.json(student);
});

// Create student
app.post('/api/students', (req, res) => {
    const { name, age, grade, email } = req.body;
    
    if (!name || !age || !grade || !email) {
        return res.status(400).json({ error: 'All fields are required' });
    }
    
    const newStudent = {
        id: nextId++,
        name,
        age: parseInt(age),
        grade,
        email
    };
    
    students.push(newStudent);
    res.status(201).json(newStudent);
});

// Update student
app.put('/api/students/:id', (req, res) => {
    const id = parseInt(req.params.id);
    const { name, age, grade, email } = req.body;
    
    if (!name || !age || !grade || !email) {
        return res.status(400).json({ error: 'All fields are required' });
    }
    
    const studentIndex = students.findIndex(s => s.id === id);
    if (studentIndex === -1) {
        return res.status(404).json({ error: 'Student not found' });
    }
    
    students[studentIndex] = { id, name, age: parseInt(age), grade, email };
    res.json(students[studentIndex]);
});

// Delete student
app.delete('/api/students/:id', (req, res) => {
    const id = parseInt(req.params.id);
    const studentIndex = students.findIndex(s => s.id === id);
    
    if (studentIndex === -1) {
        return res.status(404).json({ error: 'Student not found' });
    }
    
    const deletedStudent = students.splice(studentIndex, 1)[0];
    res.json({ message: 'Student deleted successfully', student: deletedStudent });
});

// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ Backend server running on port ${PORT}`);
    console.log(`✅ Health: http://localhost:${PORT}/api/health`);
    console.log(`✅ Students: http://localhost:${PORT}/api/students`);
});