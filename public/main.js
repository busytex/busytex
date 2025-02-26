// Ensure this file is imported as type="module" in index.html

import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-app.js';
import { getFirestore } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-firestore.js';
import { db } from './firebase-config.js';
import { loadProjectsFromFirestore, explorerTree } from './projectManager.js';
import { initializeEditor } from './editorManager.js';
import { renderFileExplorer } from './uiManager.js';
import { onclick_, terminate } from './compileManager.js';

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

// Handle context menu cleanup
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