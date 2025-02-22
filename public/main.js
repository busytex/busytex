// Ensure this file is imported as type="module" in index.html

import { initializeApp } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-app.js';
import { getFirestore, collection, doc, getDoc, getDocs, setDoc, updateDoc } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-firestore.js';
import { db } from './firebase-config.js';
import { loadProjectsFromFirestore, fileStructure } from './projectManager.js';
import { initializeEditor } from './editorManager.js';
import { renderFileExplorer } from './uiManager.js';

// Store project structure

// Load projects and initialize UI
async function initApp() {
    try {
        await loadProjectsFromFirestore();
        initializeEditor();
        renderFileExplorer(document.getElementById('file-tree'), fileStructure);
    } catch (error) {
        console.error("Error initializing app:", error);
    }
}

// Ensure this file is imported as type="module" in index.html

const texmf_local = ['./texmf', './.texmf'];

const paths_list = Array.from(document.head.getElementsByTagName('link'))
    .filter(link => link.rel === 'busytex')
    .map(link => [link.id, link.href]);

const texlive_data_packages_js = paths_list
    .filter(([id, href]) => id.startsWith('texlive_'))
    .map(([id, href]) => href);

const paths = { ...Object.fromEntries(paths_list), texlive_data_packages_js };

let worker = null;
let texEditor = null;
let bibEditor = null;

const workerCheckbox = document.getElementById('worker');
const preloadCheckbox = document.getElementById('preload');
const verboseSelect = document.getElementById('verbose');
const driverSelect = document.getElementById('tex_driver');
const bibtexCheckbox = document.getElementById('bibtex');
const autoCheckbox = document.getElementById('checked_texlive_auto');
const previewElement = document.getElementById('preview');
const elapsedElement = document.getElementById('elapsed');
const ubuntuPackageCheckboxes = {
    recommended: document.getElementById('checked_texlive_ubuntu_recommended'),
    extra: document.getElementById('checked_texlive_ubuntu_extra'),
    science: document.getElementById('checked_texlive_ubuntu_science')
};
const compileButton = document.getElementById("compile-button");
const spinnerElement = document.getElementById('spinner');

// Store auto-save timeout
let autoSaveTimeout;

// Add these state variables at the top with other declarations
let lastSavedContent = { tex: '', bib: '' };
let isOffline = false;

let currentFile = "main.tex";

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