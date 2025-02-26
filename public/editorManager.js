import { 
    loadProjectsFromFirestore, 
    mainTexFile,
    getCurrentProjectFiles,
    persistCurrentProjectToFirestore,
    currentProject,
    explorerTree 
} from './projectManager.js';
import { renderFileExplorer } from './uiManager.js';
import { collection, doc, getDoc, setDoc } from 'https://www.gstatic.com/firebasejs/9.6.1/firebase-firestore.js';
import { db } from './firebase-config.js';

let texEditor, bibEditor;
let currentFile = null;  // Initialize as null and set after editors are ready
let autoSaveTimeout;
let isOffline = false;
let lastSavedContent = { tex: '', bib: '' };

export function getEditors() {
    return { texEditor, bibEditor };
}

export function initializeEditor() {
    require.config({ paths: { 'vs': 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.21.2/min/vs' }});
    require(['vs/editor/editor.main'], async function() {
        try {
            // Load projects first
            await loadProjectsFromFirestore();

            // Initialize content variables
            const defaultTexContent = "\\documentclass{article}\n\\begin{document}\n\\end{document}";
            const defaultBibContent = "@article{example,\n  author = {Author},\n  title = {Title},\n  year = {2024}\n}";

            let texContent = defaultTexContent;
            let bibContent = defaultBibContent;

            // Try to load content from current project
            const currentProjectFiles = getCurrentProjectFiles();
            if (currentProject && currentProjectFiles) {
                if (mainTexFile && currentProjectFiles[mainTexFile]) {
                    texContent = currentProjectFiles[mainTexFile];
                }
                
                // Find the first .bib file in the project
                const bibFile = Object.entries(currentProjectFiles)
                    .find(([key, _]) => key.endsWith('.bib'));
                if (bibFile) {
                    bibContent = bibFile[1];
                }
            }

            // Register LaTeX language
            monaco.languages.register({ id: 'latex' });
            monaco.languages.setMonarchTokensProvider('latex', {
                tokenizer: {
                    root: [
                        [/\\[a-zA-Z]+/, 'keyword'],
                        [/%.*/, 'comment'],
                        [/\{[^}]*\}/, 'string'],
                        [/\[[^\]]*\]/, 'string'],
                        [/\$[^$]*\$/, 'string'],
                    ]
                }
            });

            // Create editors - only once
            texEditor = monaco.editor.create(document.getElementById('tex-editor'), {
                value: texContent,
                language: 'latex',
                theme: 'vs-dark',
                wordWrap: 'on',
                automaticLayout: true
            });

            bibEditor = monaco.editor.create(document.getElementById('bib-editor'), {
                value: bibContent,
                language: 'bibtex',
                theme: 'vs-dark',
                wordWrap: 'on',
                automaticLayout: true
            });

            // Set current file after editors are initialized
            currentFile = mainTexFile;

            // Set up event listeners
            texEditor.onDidChangeModelContent(() => {
                if (currentFile.endsWith(".tex")) {
                    const currentProjectFiles = getCurrentProjectFiles();
                    if (currentProjectFiles) {
                        currentProjectFiles[currentFile] = texEditor.getValue();
                        startAutoSaveDebounced();
                    }
                }
            });

            bibEditor.onDidChangeModelContent(() => {
                if (currentFile.endsWith(".bib")) {
                    const currentProjectFiles = getCurrentProjectFiles();
                    if (currentProjectFiles) {
                        currentProjectFiles[currentFile] = bibEditor.getValue();
                        startAutoSaveDebounced();
                    }
                }
            });

            // Handle container z-index
            const editorContainer = document.getElementById('editor-container');
            const previewContainer = document.getElementById('preview-container');

            editorContainer.addEventListener('mouseenter', () => {
                editorContainer.style.zIndex = '2';
                previewContainer.style.zIndex = '1';
            });

            previewContainer.addEventListener('mouseenter', () => {
                previewContainer.style.zIndex = '2';
                editorContainer.style.zIndex = '1';
            });

            // Initialize file explorer with explorerTree instead of fileStructure
            const explorerContainer = document.getElementById("file-tree");
            renderFileExplorer(explorerContainer, explorerTree);

            // Set initial focus
            texEditor.focus();

        } catch (error) {
            console.error("Error initializing editors:", error);
            throw error;
        }
    });
}

async function fetchEditorContent() {
    try {
        const docRef = doc(collection(db, "documents"), "default");
        const docSnap = await getDoc(docRef);

        if (docSnap.exists()) {
            const data = docSnap.data();
            lastSavedContent = {
                tex: data.tex || '',
                bib: data.bib || ''
            };
            
            return {
                texContent: data.tex ? decodeURIComponent(escape(atob(data.tex))) : "",
                bibContent: data.bib ? decodeURIComponent(escape(atob(data.bib))) : ""
            };
        }
        return { texContent: "", bibContent: "" };
    } catch (error) {
        console.error("Failed to fetch content:", error);
        isOffline = true;
        return { texContent: "", bibContent: "" };
    }
}

async function saveEditorContent() {
    if (!texEditor || !bibEditor || isOffline) {
        return;
    }

    try {
        const newTexContent = btoa(unescape(encodeURIComponent(texEditor.getValue())));
        const newBibContent = btoa(unescape(encodeURIComponent(bibEditor.getValue())));

        // Only save if content has changed
        if (newTexContent === lastSavedContent.tex && newBibContent === lastSavedContent.bib) {
            return;
        }

        await setDoc(doc(db, "documents", "default"), {
            tex: newTexContent,
            bib: newBibContent,
            lastModified: new Date().toISOString()
        });

        lastSavedContent = {
            tex: newTexContent,
            bib: newBibContent
        };

        console.log("Document saved successfully!");
    } catch (error) {
        console.error("Error saving document:", error);
        isOffline = true;
    }
}

// Auto-save function (waits 30 seconds after last change)
function startAutoSave() {
    clearTimeout(autoSaveTimeout); // Prevent multiple saves
    autoSaveTimeout = setTimeout(saveEditorContent, 5000); // Auto-save after 5 seconds
}

// Debouncing function for auto-save (waits for user to stop typing)
function startAutoSaveDebounced() {
    clearTimeout(autoSaveTimeout);
    autoSaveTimeout = setTimeout(() => {
        startAutoSave();  // Call the actual auto-save function after a delay
    }, 500);  // Adjust delay (500ms = waits for user to stop typing)
}