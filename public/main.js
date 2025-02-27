import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-app.js';
import { loadProjectsFromFirestore, explorerTree } from './projectManager.js';
import { initializeEditor } from './editorManager.js';
import { renderFileExplorer, setupContextMenuHandlers } from './uiManager.js';

// Load projects and initialize UI
async function initApp() {
    try {
        const uiState = await loadProjectsFromFirestore();
        initializeEditor();
        renderFileExplorer(document.getElementById('file-tree'), explorerTree, uiState);
        setupContextMenuHandlers();
    } catch (error) {
        console.error("Error initializing app:", error);
    }
}

// Start the application
initApp();