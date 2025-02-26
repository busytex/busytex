// Ensure this file is imported as type="module" in index.html

import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-app.js';
import { getFirestore, collection, doc, getDoc, getDocs, setDoc, updateDoc } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-firestore.js';
import { db } from './firebase-config.js';
import { loadProjectsFromFirestore, explorerTree } from './projectManager.js';
import { initializeEditor } from './editorManager.js';
import { renderFileExplorer } from './uiManager.js';
import { onclick_, terminate } from './compileManager.js';

// Store project structure

// Load projects and initialize UI
async function initApp() {
    try {
        const uiState = await loadProjectsFromFirestore();
        initializeEditor();
        renderFileExplorer(document.getElementById('file-tree'), explorerTree, uiState);
    } catch (error) {
        console.error("Error initializing app:", error);
    }
}

// Store auto-save timeout
let autoSaveTimeout;

// Add these state variables at the top with other declarations
let lastSavedContent = { tex: '', bib: '' };
let isOffline = false;

// Update the click handler to remove active class when clicking outside
document.addEventListener('click', (e) => {
    if (!e.target.closest('.context-menu')) {
        const menu = document.querySelector('.context-menu');
        const explorer = document.querySelector('.file-explorer');
        if (menu) {
            menu.remove();
            explorer.classList.remove('context-active');
        }
    }
});

// Add handler to remove active class when mouse leaves explorer
document.querySelector('.file-explorer').addEventListener('mouseleave', (e) => {
    if (!document.querySelector('.context-menu')) {
        e.currentTarget.classList.remove('context-active');
    }
});

// Start the application
initApp();